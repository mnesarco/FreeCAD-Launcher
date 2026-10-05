// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_env.dart';
import 'package:freecad_launcher/platform/python_execution.dart';

import '../helpers/fake_process.dart';

class _RecordingResolver extends PythonEnvResolver {
  _RecordingResolver({this.pythonPath = '/opt/freecad/bin/python'})
    : super(processRunner: ProcessRunner(launcher: FakeProcessLauncher()));

  final String? pythonPath;
  int calls = 0;

  @override
  Future<String?> resolve({
    required BuildKind kind,
    required String buildDirectory,
    required String executablePath,
    String? storedPythonPath,
    bool allowExtraction = true,
    void Function(String line)? onOutput,
  }) async {
    calls++;
    return pythonPath;
  }
}

void main() {
  late _RecordingResolver envResolver;

  setUp(() {
    envResolver = _RecordingResolver();
  });

  Future<PythonExecution?> resolve({
    BuildKind kind = BuildKind.appimage,
    Future<bool> Function()? fuseAvailable,
    bool allowAppImageMacro = true,
  }) {
    return PythonExecutionResolver(envResolver: envResolver, fuseAvailable: fuseAvailable).resolve(
      kind: kind,
      buildDirectory: '/data/builds/b1',
      executablePath: '/data/builds/b1/FreeCAD.AppImage',
      allowAppImageMacro: allowAppImageMacro,
    );
  }

  test('uses the AppImage in place when FUSE is available', () async {
    final execution = await resolve(fuseAvailable: () async => true);

    expect(execution, isA<PythonAppImageExecution>());
    expect(
      (execution! as PythonAppImageExecution).appImagePath,
      '/data/builds/b1/FreeCAD.AppImage',
    );
    expect(envResolver.calls, 0);
  });

  test('falls back to the interpreter when FUSE is unavailable', () async {
    final execution = await resolve(fuseAvailable: () async => false);

    expect(execution, isA<PythonInterpreterExecution>());
    expect((execution! as PythonInterpreterExecution).pythonPath, '/opt/freecad/bin/python');
    expect(envResolver.calls, 1);
  });

  test('preview mode skips the AppImage macro even with FUSE', () async {
    final execution = await resolve(fuseAvailable: () async => true, allowAppImageMacro: false);

    expect(execution, isA<PythonInterpreterExecution>());
    expect(envResolver.calls, 1);
  });

  test('non-AppImage builds always use the interpreter', () async {
    final execution = await resolve(kind: BuildKind.archive, fuseAvailable: () async => true);

    expect(execution, isA<PythonInterpreterExecution>());
    expect(envResolver.calls, 1);
  });

  test('without a fuse probe (legacy wiring) the interpreter path is used', () async {
    final execution = await resolve();

    expect(execution, isA<PythonInterpreterExecution>());
  });

  test('returns null when the environment resolver finds nothing', () async {
    envResolver = _RecordingResolver(pythonPath: null);
    final execution = await resolve(fuseAvailable: () async => false);

    expect(execution, isNull);
  });
}
