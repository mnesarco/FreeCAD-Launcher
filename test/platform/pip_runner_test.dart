// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/freecad_macro_runner.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/pip_runner.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_process.dart';

void main() {
  late Directory tempDirectory;
  late AppPaths paths;
  late FakeProcessLauncher launcher;
  late PipRunner runner;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_pip_runner');
    paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    launcher = FakeProcessLauncher();
    runner = PipRunner(
      processRunner: ProcessRunner(launcher: launcher),
      paths: paths,
    );
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> waitForHandle(int index) async {
    for (var attempt = 0; attempt < 250 && launcher.handles.length <= index; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  test('runs pip with --target and streams output to a log', () async {
    final target = p.join(tempDirectory.path, 'target');
    final future = runner.install(
      pythonPath: '/opt/freecad/bin/python',
      targetDirectory: target,
      packages: const ['numpy>=1.26', 'six'],
      label: 'A2plus',
    );
    await waitForHandle(0);
    launcher.handles[0]
      ..emitStdout('Collecting numpy\n')
      ..emitStderr('warning\n')
      ..exit(0);
    final result = await future;

    expect(result.isSuccess, isTrue);
    expect(Directory(target).existsSync(), isTrue);
    final spec = launcher.specs.single;
    expect(spec.executable, '/opt/freecad/bin/python');
    expect(spec.arguments, [
      '-m',
      'pip',
      'install',
      '--upgrade',
      '--target',
      target,
      'numpy>=1.26',
      'six',
      '--disable-pip-version-check',
      '--no-warn-script-location',
    ]);
    expect(spec.environment.containsKey('PYTHONPATH'), isFalse);
    expect(spec.environment['PIP_NO_INPUT'], '1');
    expect(File(result.logPath).readAsStringSync(), contains('Collecting numpy'));
    expect(result.outputTail, contains('warning'));
  });

  test('reports pip failures with the output tail', () async {
    final future = runner.install(
      pythonPath: '/opt/freecad/bin/python',
      targetDirectory: p.join(tempDirectory.path, 'target'),
      packages: const ['missing-package'],
      label: 'A2plus',
    );
    await waitForHandle(0);
    launcher.handles[0]
      ..emitStderr('ERROR: No matching distribution\n')
      ..exit(1);
    final result = await future;

    expect(result.isSuccess, isFalse);
    expect(result.exitCode, 1);
    expect(result.outputTail, contains('No matching distribution'));
  });

  test('installs inside the AppImage through a macro without extracting', () async {
    final target = p.join(tempDirectory.path, 'appimage-target');
    final future = runner.install(
      appImagePath: '/opt/FreeCAD.AppImage',
      targetDirectory: target,
      packages: const ['pyjwt', 'tzlocal'],
      label: 'Ondsel-Lens',
    );
    await waitForHandle(0);

    final spec = launcher.specs.single;
    expect(spec.executable, '/opt/FreeCAD.AppImage');
    expect(spec.arguments[0], '-c');
    expect(spec.arguments[1], '-M');
    expect(spec.environment['PIP_CACHE_DIR'], p.join(paths.cacheDir, 'pip'));
    final macro = File(spec.arguments.last).readAsStringSync();
    expect(macro, contains("'install'"));
    expect(macro, contains('pyjwt'));
    expect(macro, contains(jsonEncode(target)));

    final logPath = _logPathOf(macro);
    File(logPath).writeAsStringSync('Collecting pyjwt\nSuccessfully installed pyjwt tzlocal\n');
    launcher.handles[0]
      ..emitStdout(
        '[${FreeCadMacroRunner.outputTag}]{"ok": true, "code": 0}'
        '[/${FreeCadMacroRunner.outputTag}]\n',
      )
      ..exit(0);
    final result = await future;

    expect(result.isSuccess, isTrue);
    expect(result.logPath, logPath);
    expect(result.outputTail, contains('Successfully installed'));
  });

  test('reports failures from the in-AppImage pip macro', () async {
    final future = runner.install(
      appImagePath: '/opt/FreeCAD.AppImage',
      targetDirectory: p.join(tempDirectory.path, 'appimage-fail'),
      packages: const ['missing-package'],
      label: 'Broken',
    );
    await waitForHandle(0);
    final macro = File(launcher.specs.single.arguments.last).readAsStringSync();
    final logPath = _logPathOf(macro);
    File(logPath).writeAsStringSync('ERROR: No matching distribution found\n');
    launcher.handles[0]
      ..emitStdout(
        '[${FreeCadMacroRunner.outputTag}]{"ok": false, "code": 1}'
        '[/${FreeCadMacroRunner.outputTag}]\n',
      )
      ..exit(0);
    final result = await future;

    expect(result.isSuccess, isFalse);
    expect(result.outputTail, contains('No matching distribution'));
  });

  test('requires exactly one pip execution target', () {
    expect(
      () => runner.install(
        targetDirectory: p.join(tempDirectory.path, 'none'),
        packages: const ['six'],
        label: 'None',
      ),
      throwsArgumentError,
    );
    expect(
      () => runner.install(
        pythonPath: '/usr/bin/python3',
        appImagePath: '/opt/FreeCAD.AppImage',
        targetDirectory: p.join(tempDirectory.path, 'both'),
        packages: const ['six'],
        label: 'Both',
      ),
      throwsArgumentError,
    );
  });

  test('refuses to run a FreeCAD executable as the Python interpreter', () async {
    final future = runner.install(
      pythonPath: '/opt/FreeCAD/bin/FreeCAD.exe',
      targetDirectory: p.join(tempDirectory.path, 'guard'),
      packages: const ['six'],
      label: 'Guard',
    );

    await expectLater(future, throwsArgumentError);
    expect(launcher.specs, isEmpty);
  });

  test('serializes pip jobs', () async {
    final first = runner.install(
      pythonPath: '/opt/freecad/bin/python',
      targetDirectory: p.join(tempDirectory.path, 't1'),
      packages: const ['six'],
      label: 'One',
    );
    final second = runner.install(
      pythonPath: '/opt/freecad/bin/python',
      targetDirectory: p.join(tempDirectory.path, 't2'),
      packages: const ['six'],
      label: 'Two',
    );
    await waitForHandle(0);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(launcher.specs, hasLength(1));

    launcher.handles[0].exit(0);
    await waitForHandle(1);
    launcher.handles[1].exit(0);

    expect((await first).isSuccess, isTrue);
    expect((await second).isSuccess, isTrue);
    expect(launcher.specs, hasLength(2));
  });
}

String _logPathOf(String macro) {
  final match = RegExp(r'log_path = ("(?:[^"\\]|\\.)*")').firstMatch(macro);
  return jsonDecode(match!.group(1)!) as String;
}
