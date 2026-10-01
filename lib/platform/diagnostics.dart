// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';

enum DiagnosticStatus { ok, warning, error, notApplicable }

abstract final class DiagnosticIds {
  static const String dataDirectory = 'data_directory';
  static const String fuse = 'fuse';
  static const String gatekeeper = 'gatekeeper';
  static const String diskSpace = 'disk_space';
  static const String network = 'network';
}

/// Performs one request to [uri] and completes when a response is received;
/// any HTTP status counts as reachable, transport errors count as failures.
typedef NetworkProbe = Future<void> Function(Uri uri);

class DiagnosticResult {
  const DiagnosticResult({required this.id, required this.status, this.detail});

  final String id;
  final DiagnosticStatus status;
  final String? detail;
}

class DiagnosticsReport {
  const DiagnosticsReport(this.results);

  final List<DiagnosticResult> results;

  bool get hasErrors => results.any((result) => result.status == DiagnosticStatus.error);
}

class DiagnosticsService {
  DiagnosticsService({
    required this.paths,
    required this.platform,
    ProcessRunner? processRunner,
    Map<String, String>? environment,
    bool Function()? fuseDeviceExists,
    NetworkProbe? networkProbe,
    this.networkProbeTimeout = const Duration(seconds: 5),
    this.minimumFreeBytes = 1 << 30,
  }) : _processRunner = processRunner ?? ProcessRunner(),
       _environment = environment ?? Platform.environment,
       _fuseDeviceExists = fuseDeviceExists ?? (() => File('/dev/fuse').existsSync()),
       _networkProbe = networkProbe;

  static const List<({String label, String url})> networkTargets = [
    (label: 'GitHub API', url: 'https://api.github.com/rate_limit'),
    (label: 'FreeCAD addons and macros', url: 'https://addons.freecad.org/'),
    (label: 'FreeCAD blog news', url: 'https://blog.freecad.org/feed/atom/'),
  ];

  final AppPaths paths;
  final BuildPlatform platform;
  final int minimumFreeBytes;
  final Duration networkProbeTimeout;

  final ProcessRunner _processRunner;
  final Map<String, String> _environment;
  final bool Function() _fuseDeviceExists;
  final NetworkProbe? _networkProbe;

  Future<DiagnosticsReport> runAll() async {
    final results = [
      await checkDataDirectory(),
      await checkFuse(),
      await checkGatekeeper(),
      await checkDiskSpace(),
      await checkNetwork(),
    ];
    return DiagnosticsReport(results);
  }

  Future<bool> fuseAvailable() async {
    return (await checkFuse()).status == DiagnosticStatus.ok;
  }

  Future<DiagnosticResult> checkDataDirectory() async {
    final probe = File(p.join(paths.dataRoot, '.write-test-$pid'));
    try {
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return const DiagnosticResult(
        id: DiagnosticIds.dataDirectory,
        status: DiagnosticStatus.ok,
      );
    } on FileSystemException catch (error) {
      return DiagnosticResult(
        id: DiagnosticIds.dataDirectory,
        status: DiagnosticStatus.error,
        detail: error.message,
      );
    }
  }

  Future<DiagnosticResult> checkFuse() async {
    if (platform != BuildPlatform.linux) {
      return const DiagnosticResult(id: DiagnosticIds.fuse, status: DiagnosticStatus.notApplicable);
    }

    final deviceExists = _fuseDeviceExists();
    final helper = _findInPath(['fusermount3', 'fusermount']);

    if (deviceExists && helper != null) {
      return DiagnosticResult(id: DiagnosticIds.fuse, status: DiagnosticStatus.ok, detail: helper);
    }

    final missing = <String>[
      if (!deviceExists) '/dev/fuse',
      if (helper == null) 'fusermount',
    ];
    return DiagnosticResult(
      id: DiagnosticIds.fuse,
      status: DiagnosticStatus.warning,
      detail: 'Missing: ${missing.join(', ')}; AppImages will run with APPIMAGE_EXTRACT_AND_RUN',
    );
  }

  Future<DiagnosticResult> checkGatekeeper() async {
    if (platform != BuildPlatform.macos) {
      return const DiagnosticResult(
        id: DiagnosticIds.gatekeeper,
        status: DiagnosticStatus.notApplicable,
      );
    }

    final result = await _processRunner.run(
      const ProcessSpec(executable: 'spctl', arguments: ['--status']),
    );
    final output = '${result.stdout}\n${result.stderr}'.trim();

    if (!result.isSuccess) {
      return DiagnosticResult(
        id: DiagnosticIds.gatekeeper,
        status: DiagnosticStatus.error,
        detail: output.isEmpty ? 'spctl exited with code ${result.exitCode}' : output,
      );
    }
    if (output.toLowerCase().contains('disabled')) {
      return DiagnosticResult(
        id: DiagnosticIds.gatekeeper,
        status: DiagnosticStatus.warning,
        detail: output,
      );
    }
    return DiagnosticResult(
      id: DiagnosticIds.gatekeeper,
      status: DiagnosticStatus.ok,
      detail: output.isEmpty ? null : output,
    );
  }

  Future<DiagnosticResult> checkDiskSpace() async {
    if (platform == BuildPlatform.windows) {
      return const DiagnosticResult(
        id: DiagnosticIds.diskSpace,
        status: DiagnosticStatus.notApplicable,
        detail: 'Disk space probe is not implemented on Windows yet',
      );
    }

    final result = await _processRunner.run(
      ProcessSpec(executable: 'df', arguments: ['-k', '-P', paths.dataRoot]),
    );
    if (!result.isSuccess) {
      return DiagnosticResult(
        id: DiagnosticIds.diskSpace,
        status: DiagnosticStatus.error,
        detail: result.stderr.trim().isEmpty ? 'df exited with code ${result.exitCode}' : result.stderr.trim(),
      );
    }

    final lines = result.stdout.trim().split('\n');
    if (lines.length < 2) {
      return const DiagnosticResult(
        id: DiagnosticIds.diskSpace,
        status: DiagnosticStatus.warning,
        detail: 'Unexpected df output',
      );
    }

    final columns = lines.last.trim().split(RegExp(r'\s+'));
    final availableKb = columns.length >= 4 ? int.tryParse(columns[3]) : null;
    if (availableKb == null) {
      return const DiagnosticResult(
        id: DiagnosticIds.diskSpace,
        status: DiagnosticStatus.warning,
        detail: 'Unexpected df output',
      );
    }

    final availableBytes = availableKb * 1024;
    if (availableBytes >= minimumFreeBytes) {
      return DiagnosticResult(
        id: DiagnosticIds.diskSpace,
        status: DiagnosticStatus.ok,
        detail: '${_formatBytes(availableBytes)} free',
      );
    }
    return DiagnosticResult(
      id: DiagnosticIds.diskSpace,
      status: DiagnosticStatus.warning,
      detail: '${_formatBytes(availableBytes)} free, minimum is ${_formatBytes(minimumFreeBytes)}',
    );
  }

  Future<DiagnosticResult> checkNetwork() async {
    final probe = _networkProbe;
    if (probe == null) {
      return const DiagnosticResult(
        id: DiagnosticIds.network,
        status: DiagnosticStatus.notApplicable,
      );
    }

    final reachable = <String>[];
    final failures = <String>[];
    await Future.wait(
      networkTargets.map((target) async {
        try {
          await probe(Uri.parse(target.url)).timeout(networkProbeTimeout);
          reachable.add(target.label);
        } on Object catch (error) {
          failures.add('${target.label}: $error');
        }
      }),
    );

    if (failures.isEmpty) {
      return DiagnosticResult(
        id: DiagnosticIds.network,
        status: DiagnosticStatus.ok,
        detail: reachable.join(', '),
      );
    }
    return DiagnosticResult(
      id: DiagnosticIds.network,
      status: DiagnosticStatus.warning,
      detail: failures.join('; '),
    );
  }

  String? _findInPath(List<String> names) {
    final pathValue = _environment['PATH'] ?? _environment['Path'] ?? '';
    final separator = Platform.isWindows ? ';' : ':';
    for (final directory in pathValue.split(separator)) {
      if (directory.isEmpty) {
        continue;
      }
      for (final name in names) {
        final candidate = File(p.join(directory, name));
        if (candidate.existsSync()) {
          return candidate.path;
        }
      }
    }
    return null;
  }
}

String _formatBytes(int bytes) {
  const int mib = 1024 * 1024;
  if (bytes >= mib) {
    return '${(bytes / mib).toStringAsFixed(1)} MiB';
  }
  return '${(bytes / 1024).toStringAsFixed(0)} KiB';
}
