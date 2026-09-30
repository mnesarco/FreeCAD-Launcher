// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
