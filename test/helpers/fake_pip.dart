// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/pip_runner.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_env.dart';

class FakePipRunner extends PipRunner {
  FakePipRunner()
    : super(
        processRunner: ProcessRunner(),
        paths: AppPaths(dataRoot: '/tmp'),
      );

  bool success = true;
  final List<
    ({String? pythonPath, String? appImagePath, String targetDirectory, List<String> packages})
  >
  calls = [];

  @override
  Future<PipResult> install({
    String? pythonPath,
    String? appImagePath,
    required String targetDirectory,
    required List<String> packages,
    required String label,
    void Function(String line)? onOutput,
    Duration timeout = const Duration(minutes: 30),
  }) async {
    calls.add((
      pythonPath: pythonPath,
      appImagePath: appImagePath,
      targetDirectory: targetDirectory,
      packages: packages,
    ));
    return PipResult(
      exitCode: success ? 0 : 1,
      logPath: '/tmp/pip.log',
      outputTail: success ? '' : 'pip failed',
    );
  }
}

class FakePythonEnvResolver extends PythonEnvResolver {
  FakePythonEnvResolver(this.pythonPath) : super(processRunner: ProcessRunner());

  final String? pythonPath;

  @override
  Future<String?> resolve({
    required BuildKind kind,
    required String buildDirectory,
    required String executablePath,
    String? storedPythonPath,
    bool allowExtraction = true,
    void Function(String line)? onOutput,
  }) async {
    return pythonPath;
  }
}
