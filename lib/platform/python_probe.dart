import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/process.dart';

class BundledPython {
  const BundledPython({required this.executablePath, required this.version});

  final String executablePath;
  final String version;
}

class PythonDetection {
  const PythonDetection({this.python, this.reason});

  final BundledPython? python;
  final String? reason;

  bool get found => python != null;
}

abstract interface class PythonProbe {
  Future<PythonDetection> detect({
    required BuildKind kind,
    required String installDirectory,
    required String executablePath,
    String? knownVersion,
  });
}

class ProcessPythonProbe implements PythonProbe {
  ProcessPythonProbe({required ProcessRunner processRunner}) : _processRunner = processRunner;

  static const String _probeScript =
      "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')";

  static const List<String> _scriptNames = [
    'python.exe',
    'python',
    'python3.exe',
    'python3',
  ];

  final ProcessRunner _processRunner;

  @override
  Future<PythonDetection> detect({
    required BuildKind kind,
    required String installDirectory,
    required String executablePath,
    String? knownVersion,
  }) async {
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
      return PythonDetection(
        reason: kind == BuildKind.appimage
            ? 'The AppImage must be extracted before its Python can be probed; '
                  'install from the catalog to use the asset-name version'
            : 'No bundled Python interpreter found under $installDirectory',
      );
    }

    final result = await _processRunner.run(
      ProcessSpec(executable: executable, arguments: ['-c', _probeScript]),
      timeout: const Duration(seconds: 30),
    );

    if (!result.isSuccess) {
      return PythonDetection(
        reason: 'Python probe failed with exit code ${result.exitCode}',
      );
    }

    final output = result.stdout.trim().split('\n').last.trim();
    final match = RegExp(r'^(\d+)\.(\d+)$').firstMatch(output);
    if (match == null) {
      return PythonDetection(reason: 'Unexpected Python version output: "$output"');
    }

    return PythonDetection(
      python: BundledPython(
        executablePath: executable,
        version: '${match[1]}.${match[2]}',
      ),
    );
  }

  String? _locateInterpreter({
    required BuildKind kind,
    required String installDirectory,
    required String executablePath,
  }) {
    if (kind == BuildKind.appimage) {
      return _findIn([p.join(installDirectory, 'squashfs-root', 'usr', 'bin')]);
    }

    final executableDirectory = p.dirname(executablePath);
    final directories = [
      executableDirectory,
      p.join(executableDirectory, 'bin'),
      p.join(executableDirectory, '..', 'Resources', 'bin'),
      p.join(installDirectory, 'bin'),
      p.join(installDirectory, 'usr', 'bin'),
      p.join(installDirectory, 'FreeCAD.app', 'Contents', 'Resources', 'bin'),
    ];
    return _findIn(directories);
  }

  String? _findIn(List<String> directories) {
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
        if (_scriptNames.contains(name) || RegExp(r'^python3(\.\d+)?(\.exe)?$').hasMatch(name)) {
          candidates[name] = entity;
        }
      }
      if (candidates.isEmpty) {
        continue;
      }

      for (final preferred in _scriptNames) {
        final match = candidates[preferred];
        if (match != null) {
          return match.path;
        }
      }
      final versioned = candidates.keys.where((name) => name.startsWith('python3')).toList()
        ..sort((a, b) => b.compareTo(a));
      if (versioned.isNotEmpty) {
        return candidates[versioned.first]!.path;
      }
    }
    return null;
  }
}
