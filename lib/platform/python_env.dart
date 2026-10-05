// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_probe.dart';

class PythonEnvResolver {
  PythonEnvResolver({required ProcessRunner processRunner}) : _processRunner = processRunner;

  final ProcessRunner _processRunner;

  /// Resolves the build's Python interpreter.
  ///
  /// For AppImages, [allowExtraction] controls whether `--appimage-extract`
  /// may run when no extracted tree exists yet. Callers that only need a cheap
  /// availability check (e.g. the dependency consent dialog) pass `false` so a
  /// multi-hundred-MB extraction is never triggered without user consent;
  /// pip installs use the default `true`.
  Future<String?> resolve({
    required BuildKind kind,
    required String buildDirectory,
    required String executablePath,
    String? storedPythonPath,
    bool allowExtraction = true,
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
        final pythonDirectory = _appImagePythonDirectory(buildDirectory);
        final existing = locateInterpreterIn(pythonDirectory);
        if (existing != null || !allowExtraction) {
          return existing;
        }
        return _extractAppImage(buildDirectory, executablePath, onOutput);
    }
  }

  String _appImagePythonDirectory(String buildDirectory) =>
      p.join(buildDirectory, 'extracted', 'squashfs-root', 'usr', 'bin');

  Future<String?> _extractAppImage(
    String buildDirectory,
    String executablePath,
    void Function(String line)? onOutput,
  ) async {
    final extractionRoot = p.join(buildDirectory, 'extracted');
    final pythonDirectory = _appImagePythonDirectory(buildDirectory);
    final root = Directory(extractionRoot);
    try {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      root.createSync(recursive: true);
    } on Object {
      return null;
    }

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
