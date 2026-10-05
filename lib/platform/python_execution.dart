// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/python_env.dart';

sealed class PythonExecution {
  const PythonExecution();
}

/// The bundled interpreter is reachable on disk (archive/dmg/custom builds, or
/// an AppImage that was extracted on a FUSE-less system).
final class PythonInterpreterExecution extends PythonExecution {
  const PythonInterpreterExecution(this.pythonPath);

  final String pythonPath;
}

/// Python runs inside the mounted AppImage through headless macros, so the
/// image is never extracted (D-112).
final class PythonAppImageExecution extends PythonExecution {
  const PythonAppImageExecution(this.appImagePath);

  final String appImagePath;
}

/// Chooses how Python code (pip, availability probes) executes for a build.
class PythonExecutionResolver {
  PythonExecutionResolver({
    required PythonEnvResolver envResolver,
    Future<bool> Function()? fuseAvailable,
  }) : _envResolver = envResolver,
       _fuseAvailable = fuseAvailable;

  final PythonEnvResolver _envResolver;

  /// When provided and FUSE is available, AppImages are executed in place.
  /// When absent (legacy/tests) the resolver falls back to interpreter paths.
  final Future<bool> Function()? _fuseAvailable;

  Future<PythonExecution?> resolve({
    required BuildKind kind,
    required String buildDirectory,
    required String executablePath,
    String? storedPythonPath,
    bool allowExtraction = true,
    bool allowAppImageMacro = true,
    void Function(String line)? onOutput,
  }) async {
    // AppImages are a Linux format; Windows/macOS never execute them in place
    // even if a custom `.AppImage` was registered (the interpreter/fallback
    // path keeps its previous behavior there).
    if (Platform.isLinux &&
        kind == BuildKind.appimage &&
        allowAppImageMacro &&
        _fuseAvailable != null &&
        await _fuseAvailable()) {
      return PythonAppImageExecution(executablePath);
    }
    final interpreter = await _envResolver.resolve(
      kind: kind,
      buildDirectory: buildDirectory,
      executablePath: executablePath,
      storedPythonPath: storedPythonPath,
      allowExtraction: allowExtraction,
      onOutput: onOutput,
    );
    return interpreter == null ? null : PythonInterpreterExecution(interpreter);
  }
}
