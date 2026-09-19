import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_probe.dart';

class PythonEnvResolver {
  PythonEnvResolver({required ProcessRunner processRunner})
    : _processRunner = processRunner;

  final ProcessRunner _processRunner;

  Future<String?> resolve({
    required BuildKind kind,
    required String buildDirectory,
    required String executablePath,
    String? storedPythonPath,
    void Function(String line)? onOutput,
  }) async {
    if (storedPythonPath != null && File(storedPythonPath).existsSync()) {
      return storedPythonPath;
    }

    switch (kind) {
      case BuildKind.custom:
        return locateBundledInterpreter(
          kind: kind,
          installDirectory: p.dirname(executablePath),
          executablePath: executablePath,
        );
      case BuildKind.archive:
      case BuildKind.dmg:
        return locateBundledInterpreter(
          kind: kind,
          installDirectory: buildDirectory,
          executablePath: executablePath,
        );
      case BuildKind.appimage:
        return _ensureAppImageExtraction(buildDirectory, executablePath, onOutput);
    }
  }

  Future<String?> _ensureAppImageExtraction(
    String buildDirectory,
    String executablePath,
    void Function(String line)? onOutput,
  ) async {
    final extractionRoot = p.join(buildDirectory, 'extracted');
    final pythonDirectory = p.join(extractionRoot, 'squashfs-root', 'usr', 'bin');
    final existing = locateInterpreterIn(pythonDirectory);
    if (existing != null) {
      return existing;
    }

    final root = Directory(extractionRoot);
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
    root.createSync(recursive: true);

    final ProcessResult result;
    try {
      result = await _processRunner.run(
        ProcessSpec(
          executable: executablePath,
          arguments: const ['--appimage-extract'],
          workingDirectory: extractionRoot,
        ),
        timeout: const Duration(minutes: 15),
        onStdout: onOutput,
        onStderr: onOutput,
      );
    } on Object {
      return null;
    }
    if (!result.isSuccess) {
      return null;
    }
    return locateInterpreterIn(pythonDirectory);
  }
}
