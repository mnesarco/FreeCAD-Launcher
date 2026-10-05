// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/freecad_macro_runner.dart';
import 'package:freecad_launcher/platform/process.dart';

import '../helpers/fake_process.dart';

void main() {
  late FakeProcessLauncher launcher;
  late FreeCadMacroRunner runner;

  setUp(() {
    launcher = FakeProcessLauncher();
    runner = FreeCadMacroRunner(processRunner: ProcessRunner(launcher: launcher));
  });

  Future<void> waitForHandle(int index) async {
    for (var attempt = 0; attempt < 250 && launcher.handles.length <= index; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  test('writes a macro, runs it headless with an isolated environment and parses JSON', () async {
    final future = runner.run(
      executablePath: '/opt/FreeCAD.AppImage',
      macroBody: 'print("hello")',
      tag: 'test-tag',
    );
    await waitForHandle(0);

    final spec = launcher.specs.single;
    expect(spec.executable, '/opt/FreeCAD.AppImage');
    expect(spec.arguments[0], '-c');
    expect(spec.arguments[1], '-M');
    final macroDirectory = spec.arguments[2];
    final macroPath = spec.arguments[3];
    expect(macroPath, endsWith('FCL_Macro.FCMacro'));
    expect(File(macroPath).readAsStringSync(), 'print("hello")');
    expect(spec.environment['FREECAD_USER_HOME'], isNotNull);
    expect(spec.environment['FREECAD_USER_TEMP'], isNotNull);
    expect(spec.environment.containsKey('PYTHONPATH'), isFalse);
    expect(spec.environment.containsKey('APPIMAGE_EXTRACT_AND_RUN'), isFalse);

    launcher.handles[0]
      ..emitStdout('noise\n[test-tag]{"ok": true, "code": 0}[/test-tag]\n')
      ..exit(0);
    final outcome = await future;

    expect(outcome.payloadMap?['ok'], isTrue);
    expect(Directory(macroDirectory).existsSync(), isFalse);
  });

  test('runAppImage retries with APPIMAGE_EXTRACT_AND_RUN when no payload arrives', () async {
    final future = runner.runAppImage(appImagePath: '/opt/FreeCAD.AppImage', macroBody: 'print(1)');
    await waitForHandle(0);
    launcher.handles[0]
      ..emitStderr('fuse mount failed\n')
      ..exit(1);

    await waitForHandle(1);
    expect(launcher.specs[1].environment['APPIMAGE_EXTRACT_AND_RUN'], '1');
    launcher.handles[1]
      ..emitStdout(
        '[${FreeCadMacroRunner.outputTag}]{"ok": true}[/${FreeCadMacroRunner.outputTag}]\n',
      )
      ..exit(0);
    final outcome = await future;

    expect(outcome.hasPayload, isTrue);
    expect(launcher.specs, hasLength(2));
  });

  test('runAppImage keeps the first outcome when both attempts fail', () async {
    final future = runner.runAppImage(appImagePath: '/opt/FreeCAD.AppImage', macroBody: 'print(1)');
    await waitForHandle(0);
    launcher.handles[0]
      ..emitStderr('first failure\n')
      ..exit(1);
    await waitForHandle(1);
    launcher.handles[1]
      ..emitStderr('second failure\n')
      ..exit(2);
    final outcome = await future;

    expect(outcome.hasPayload, isFalse);
    expect(outcome.exitCode, 1);
    expect(launcher.specs, hasLength(2));
  });

  test('parsePayload keeps the last valid tagged JSON', () {
    const stdout = '[tag]{"a": 1}[/tag]\nbroken [tag]{oops}[/tag]\n[tag]{"b": 2}[/tag]\n';
    expect(FreeCadMacroRunner.parsePayload(stdout, tag: 'tag'), {'b': 2});
    expect(FreeCadMacroRunner.parsePayload('nothing', tag: 'tag'), isNull);
  });
}
