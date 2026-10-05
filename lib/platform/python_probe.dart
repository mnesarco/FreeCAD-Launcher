// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/launch_environment.dart';
import 'package:freecad_launcher/platform/process.dart';

class BundledPython {
  const BundledPython({required this.executablePath, required this.version});

  final String executablePath;
  final String version;
}

class PythonDetection {
  const PythonDetection({this.python, this.version, this.reason});

  final BundledPython? python;

  /// Version learned without a usable interpreter path (e.g. a headless probe
  /// whose prefix vanished with an AppImage mount).
  final String? version;

  final String? reason;

  bool get found => python != null;

  String? get detectedVersion => python?.version ?? version;
}

abstract interface class PythonProbe {
  Future<PythonDetection> detect({
    required BuildKind kind,
    required String installDirectory,
    required String executablePath,
    String? knownVersion,
  });

  Future<PythonDetection> detectFromFreeCad({required String executablePath});

  Future<PythonDetection> detectInterpreter({required String executablePath});
}

class ProcessPythonProbe implements PythonProbe {
  ProcessPythonProbe({required ProcessRunner processRunner}) : _processRunner = processRunner;

  static const Duration _interpreterTimeout = Duration(seconds: 30);
  static const Duration _headlessTimeout = Duration(seconds: 60);

  static const String _probeScript =
      "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')";

  static const String _outputTag = 'freecad-launcher:out';

  static const String _freeCadProbeMacro =
      "import json, sys, platform, FreeCAD\n"
      "data = {'python': platform.python_version(), 'prefix': sys.prefix, "
      "'executable': sys.executable}\n"
      "FreeCAD.Console.PrintMessage('[$_outputTag]' + json.dumps(data) + "
      "'[/$_outputTag]\\n')\n"
      "sys.exit(0)\n";

  static const List<String> _scriptNames = ['python.exe', 'python', 'python3.exe', 'python3'];

  static final RegExp _versionedName = RegExp(r'^python3(\.\d+)?(\.exe)?$');

  final ProcessRunner _processRunner;

  @override
  Future<PythonDetection> detect({
    required BuildKind kind,
    required String installDirectory,
    required String executablePath,
    String? knownVersion,
  }) async {
    if (kind == BuildKind.appimage) {
      final extracted = _locateInterpreter(
        kind: kind,
        installDirectory: installDirectory,
        executablePath: executablePath,
      );
      if (extracted != null) {
        return _probeInterpreter(extracted);
      }

      final detection = await detectFromFreeCad(executablePath: executablePath);
      if (detection.detectedVersion != null) {
        return detection;
      }
      if (knownVersion != null && knownVersion.isNotEmpty) {
        return PythonDetection(
          python: BundledPython(executablePath: executablePath, version: knownVersion),
        );
      }
      return detection;
    }

    if (knownVersion != null && knownVersion.isNotEmpty) {
      return PythonDetection(
        python: BundledPython(executablePath: executablePath, version: knownVersion),
      );
    }

    final executable = _locateInterpreter(
      kind: kind,
      installDirectory: installDirectory,
      executablePath: executablePath,
    );
    if (executable == null) {
      return PythonDetection(reason: 'No bundled Python interpreter found under $installDirectory');
    }

    return _probeInterpreter(executable);
  }

  @override
  Future<PythonDetection> detectFromFreeCad({required String executablePath}) async {
    final resolved = _resolveExecutable(executablePath);
    final headless = _headlessExecutable(resolved);

    final outcome = await _runHeadlessProbe(headless);
    final headlessResult = outcome.result;

    final version = headlessResult?.version;
    for (final candidate in _interpreterCandidates(
      resolved,
      prefix: headlessResult?.prefix,
      reportedExecutable: headlessResult?.executable,
    )) {
      final detection = await _probeInterpreter(candidate);
      if (!detection.found) {
        continue;
      }
      if (version == null || detection.python!.version == version) {
        return detection;
      }
    }

    if (version != null) {
      return PythonDetection(
        version: version,
        reason: 'Python $version detected; the interpreter path must be selected manually',
      );
    }
    return PythonDetection(reason: outcome.error ?? 'No Python interpreter found');
  }

  @override
  Future<PythonDetection> detectInterpreter({required String executablePath}) {
    return _probeInterpreter(executablePath);
  }

  Future<PythonDetection> _probeInterpreter(String executable) async {
    final ProcessResult result;
    try {
      result = await _processRunner.run(
        ProcessSpec(executable: executable, arguments: ['-c', _probeScript]),
        timeout: _interpreterTimeout,
      );
    } on ProcessTimeoutException {
      return PythonDetection(reason: 'Python probe timed out for $executable');
    } on Object catch (error) {
      return PythonDetection(reason: 'Python probe failed: $error');
    }

    if (!result.isSuccess) {
      return PythonDetection(reason: 'Python probe failed with exit code ${result.exitCode}');
    }

    final output = result.stdout.trim().split('\n').last.trim();
    final match = RegExp(r'^(\d+)\.(\d+)$').firstMatch(output);
    if (match == null) {
      return PythonDetection(reason: 'Unexpected Python version output: "$output"');
    }

    return PythonDetection(
      python: BundledPython(executablePath: executable, version: '${match[1]}.${match[2]}'),
    );
  }

  Future<_HeadlessProbeOutcome> _runHeadlessProbe(String headlessExecutable) async {
    final scriptDirectory = await Directory.systemTemp.createTemp('fcl-python-probe-');
    final script = File(p.join(scriptDirectory.path, 'FCL_PythonProbe.FCMacro'));
    final home = Directory(p.join(scriptDirectory.path, 'home'))..createSync();
    final temp = Directory(p.join(scriptDirectory.path, 'temp'))..createSync();
    await script.writeAsString(_freeCadProbeMacro);
    try {
      final ProcessResult result;
      try {
        result = await _processRunner.run(
          ProcessSpec(
            executable: headlessExecutable,
            arguments: ['-c', '-M', scriptDirectory.path, script.path],
            environment: _probeEnvironment(home.path, temp.path),
          ),
          timeout: _headlessTimeout,
        );
      } on ProcessTimeoutException {
        return const _HeadlessProbeOutcome(error: 'FreeCAD headless probe timed out');
      } on Object catch (error) {
        return _HeadlessProbeOutcome(error: 'FreeCAD headless probe failed: $error');
      }

      final payload = _parseProbePayload(result.stdout);
      final python = payload?['python'];
      final version = python is String ? _majorMinor(python) : null;
      if (version == null) {
        return _HeadlessProbeOutcome(
          error:
              'FreeCAD headless probe produced no Python version '
              '(exit code ${result.exitCode})',
        );
      }

      return _HeadlessProbeOutcome(
        result: _HeadlessProbeResult(
          version: version,
          prefix: payload?['prefix'] as String?,
          executable: payload?['executable'] as String?,
        ),
      );
    } finally {
      await _cleanUpProbeDirectory(scriptDirectory);
    }
  }

  Future<void> _cleanUpProbeDirectory(Directory directory) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (!directory.existsSync()) {
          return;
        }
        await directory.delete(recursive: true);
        return;
      } on FileSystemException {
        // An AppImage FUSE mount inside the probe TMPDIR can still be tearing
        // down (ENOTCONN); retry briefly, then leave the directory to the OS.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
    appLogger.warn('Could not remove the Python probe directory ${directory.path}');
  }

  Map<String, Object?>? _parseProbePayload(String stdout) {
    final tag = RegExp('\\[$_outputTag\\](.*?)\\[/$_outputTag\\]', dotAll: true);
    Map<String, Object?>? payload;
    for (final match in tag.allMatches(stdout)) {
      try {
        final decoded = jsonDecode(match.group(1)!.trim());
        if (decoded is Map<String, Object?>) {
          payload = decoded;
        }
      } on FormatException {
        continue;
      }
    }
    return payload;
  }

  String? _majorMinor(String version) {
    final match = RegExp(r'^(\d+)\.(\d+)').firstMatch(version.trim());
    return match == null ? null : '${match[1]}.${match[2]}';
  }

  Map<String, String> _probeEnvironment(String home, String temp) {
    final environment = Map<String, String>.from(Platform.environment);
    removeSanitizedEnvironmentKeys(environment);
    environment['FREECAD_USER_HOME'] = home;
    environment['FREECAD_USER_TEMP'] = temp;
    if (!Platform.isWindows) {
      environment['HOME'] = home;
      environment['TMPDIR'] = temp;
    }
    return environment;
  }

  List<String> _interpreterCandidates(
    String resolvedExecutable, {
    String? prefix,
    String? reportedExecutable,
  }) {
    final candidates = <String>[];
    if (reportedExecutable != null &&
        p.basename(reportedExecutable).toLowerCase().startsWith('python')) {
      candidates.add(reportedExecutable);
    }

    final directories = <String>[
      ..._interpreterDirectories(
        kind: BuildKind.archive,
        installDirectory: p.dirname(resolvedExecutable),
        executablePath: resolvedExecutable,
      ),
    ];
    if (prefix != null && Directory(prefix).existsSync()) {
      directories.add(p.join(prefix, 'bin'));
    }

    for (final candidate in _findAllIn(directories)) {
      if (!candidates.contains(candidate)) {
        candidates.add(candidate);
      }
    }
    return candidates.where((path) => File(path).existsSync()).toList();
  }

  String _resolveExecutable(String executablePath) {
    try {
      return File(executablePath).resolveSymbolicLinksSync();
    } on FileSystemException {
      return executablePath;
    }
  }

  String _headlessExecutable(String resolvedExecutable) {
    final name = p.basename(resolvedExecutable).toLowerCase();
    if (name.startsWith('freecadcmd')) {
      return resolvedExecutable;
    }

    final directory = p.dirname(resolvedExecutable);
    for (final candidate in const ['FreeCADCmd', 'freecadcmd', 'FreeCADCmd.exe']) {
      final file = File(p.join(directory, candidate));
      if (file.existsSync()) {
        return file.path;
      }
    }
    return resolvedExecutable;
  }

  String? _locateInterpreter({
    required BuildKind kind,
    required String installDirectory,
    required String executablePath,
  }) {
    return locateBundledInterpreter(
      kind: kind,
      installDirectory: installDirectory,
      executablePath: executablePath,
    );
  }

  List<String> _interpreterDirectories({
    required BuildKind kind,
    required String installDirectory,
    required String executablePath,
  }) {
    return interpreterDirectories(
      kind: kind,
      installDirectory: installDirectory,
      executablePath: executablePath,
    );
  }

  List<String> _findAllIn(List<String> directories) {
    return findInterpretersIn(directories);
  }
}

class _HeadlessProbeResult {
  const _HeadlessProbeResult({required this.version, this.prefix, this.executable});

  final String version;
  final String? prefix;
  final String? executable;
}

class _HeadlessProbeOutcome {
  const _HeadlessProbeOutcome({this.result, this.error});

  final _HeadlessProbeResult? result;
  final String? error;
}

String? locateBundledInterpreter({
  required BuildKind kind,
  required String installDirectory,
  required String executablePath,
}) {
  final directories = interpreterDirectories(
    kind: kind,
    installDirectory: installDirectory,
    executablePath: executablePath,
  );
  final candidates = findInterpretersIn(directories);
  return candidates.isEmpty ? null : candidates.first;
}

String? locateInterpreterIn(String directory) {
  final candidates = findInterpretersIn([directory]);
  return candidates.isEmpty ? null : candidates.first;
}

List<String> interpreterDirectories({
  required BuildKind kind,
  required String installDirectory,
  required String executablePath,
}) {
  if (kind == BuildKind.appimage) {
    return [p.join(installDirectory, 'squashfs-root', 'usr', 'bin')];
  }

  final executableDirectory = p.dirname(executablePath);
  return [
    executableDirectory,
    p.join(executableDirectory, 'bin'),
    p.join(executableDirectory, '..', 'Resources', 'bin'),
    p.join(installDirectory, 'bin'),
    p.join(installDirectory, 'usr', 'bin'),
    p.join(installDirectory, 'FreeCAD.app', 'Contents', 'Resources', 'bin'),
  ];
}

List<String> findInterpretersIn(List<String> directories) {
  final results = <String>[];
  final seen = <String>{};
  for (final directory in directories) {
    final resolved = p.normalize(directory);
    if (!Directory(resolved).existsSync()) {
      continue;
    }

    final candidates = <String, File>{};
    for (final entity in Directory(resolved).listSync(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final name = p.basename(entity.path).toLowerCase();
      if (ProcessPythonProbe._scriptNames.contains(name) ||
          ProcessPythonProbe._versionedName.hasMatch(name)) {
        candidates[name] = entity;
      }
    }
    if (candidates.isEmpty) {
      continue;
    }

    for (final preferred in ProcessPythonProbe._scriptNames) {
      final match = candidates[preferred];
      if (match != null && seen.add(match.path)) {
        results.add(match.path);
      }
    }
    final versioned = candidates.keys.where((name) => name.startsWith('python3')).toList()
      ..sort((a, b) => b.compareTo(a));
    for (final name in versioned) {
      final match = candidates[name]!;
      if (seen.add(match.path)) {
        results.add(match.path);
      }
    }
  }
  return results;
}
