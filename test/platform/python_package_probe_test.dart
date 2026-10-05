// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/freecad_macro_runner.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_package_probe.dart';

import '../helpers/fake_process.dart';

void main() {
  late FakeProcessLauncher launcher;
  late PythonPackageProbe probe;

  setUp(() {
    launcher = FakeProcessLauncher();
    probe = PythonPackageProbe(processRunner: ProcessRunner(launcher: launcher));
  });

  Future<void> waitForHandle(int index) async {
    for (var attempt = 0; attempt < 250 && launcher.handles.length <= index; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  test('parses and normalizes available packages', () async {
    final future = probe.availablePackages(
      pythonPath: '/opt/freecad/bin/python',
      targetDirectory: '/nonexistent/target',
      names: const ['Requests', 'pyjwt', 'math'],
    );
    await waitForHandle(0);
    launcher.handles[0]
      ..emitStdout('${PythonPackageProbe.marker}["requests", "pyjwt"]\n')
      ..exit(0);
    final result = await future;

    expect(result, {'requests', 'pyjwt'});
    final spec = launcher.specs.single;
    expect(spec.executable, '/opt/freecad/bin/python');
    expect(spec.arguments.sublist(0, 2), ['-c', startsWith('import importlib.metadata')]);
    expect(spec.arguments.sublist(2), containsAll(['requests', 'pyjwt', 'math']));
    expect(spec.environment['PYTHONPATH'], isNull);
    expect(spec.environment['PYTHONNOUSERSITE'], '1');
  });

  test('adds the profile target directory to PYTHONPATH when it exists', () async {
    final target = Directory.systemTemp.createTempSync('fcl_probe_target');
    addTearDown(() => target.deleteSync(recursive: true));

    final future = probe.availablePackages(
      pythonPath: '/usr/bin/python3',
      targetDirectory: target.path,
      names: const ['numpy'],
    );
    await waitForHandle(0);
    launcher.handles[0]
      ..emitStdout('${PythonPackageProbe.marker}[]\n')
      ..exit(0);
    await future;

    expect(launcher.specs.single.environment['PYTHONPATH'], target.path);
  });

  test('returns null on a failed interpreter run', () async {
    final future = probe.availablePackages(
      pythonPath: '/missing/python',
      targetDirectory: '/tmp',
      names: const ['numpy'],
    );
    await waitForHandle(0);
    launcher.handles[0]
      ..emitStderr('cannot start\n')
      ..exit(1);

    expect(await future, isNull);
  });

  test('returns null when no marker is printed', () async {
    final future = probe.availablePackages(
      pythonPath: '/usr/bin/python3',
      targetDirectory: '/tmp',
      names: const ['numpy'],
    );
    await waitForHandle(0);
    launcher.handles[0]
      ..emitStdout('some unrelated output\n')
      ..exit(0);

    expect(await future, isNull);
  });

  test('checks availability inside the AppImage through a macro', () async {
    final future = probe.availablePackagesInFreeCad(
      executablePath: '/opt/FreeCAD.AppImage',
      targetDirectory: '/nonexistent/target',
      names: const ['Requests', 'math'],
    );
    await waitForHandle(0);

    final spec = launcher.specs.single;
    expect(spec.executable, '/opt/FreeCAD.AppImage');
    expect(spec.arguments[0], '-c');
    final macro = File(spec.arguments.last).readAsStringSync();
    expect(macro, contains('find_spec'));
    expect(macro, contains('sys.path.append'));

    launcher.handles[0]
      ..emitStdout(
        '[${FreeCadMacroRunner.outputTag}]{"available": ["requests"]}'
        '[/${FreeCadMacroRunner.outputTag}]\n',
      )
      ..exit(0);

    expect(await future, {'requests'});
  });

  test('returns null when the in-AppImage probe reports nothing', () async {
    final future = probe.availablePackagesInFreeCad(
      executablePath: '/opt/FreeCAD.AppImage',
      targetDirectory: '/nonexistent/target',
      names: const ['requests'],
    );
    await waitForHandle(0);
    launcher.handles[0].exit(1);
    await waitForHandle(1);
    launcher.handles[1].exit(1);

    expect(await future, isNull);
  });

  test('does not launch for an empty candidate list', () async {
    final result = await probe.availablePackages(
      pythonPath: '/usr/bin/python3',
      targetDirectory: '/tmp',
      names: const ['', '-not-a-package'],
    );

    expect(result, isEmpty);
    expect(launcher.specs, isEmpty);
  });
}
