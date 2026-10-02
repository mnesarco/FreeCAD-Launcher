// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/file_actions.dart';
import 'package:freecad_launcher/platform/process.dart';

import '../helpers/fake_process.dart';

void main() {
  late FakeProcessLauncher launcher;
  late FileActions actions;

  setUp(() {
    launcher = FakeProcessLauncher();
    actions = FileActions(
      processRunner: ProcessRunner(launcher: launcher),
      platform: BuildPlatform.linux,
    );
  });

  test('openDirectory passes the parent environment to the opener', () async {
    final future = actions.openDirectory('/data/root');
    await pumpEventQueue();
    launcher.handles.single.exit(0);
    await future;

    expect(launcher.specs.single.executable, 'xdg-open');
    expect(launcher.specs.single.arguments, ['/data/root']);
    expect(launcher.specs.single.includeParentEnvironment, isFalse);
    expect(launcher.specs.single.environment['PATH'], Platform.environment['PATH']);
  });

  test('openerEnvironment strips AppImage runtime variables', () {
    final environment = openerEnvironment({
      'DISPLAY': ':0',
      'APPDIR': '/tmp/.mount_FC',
      'APPIMAGE': '/home/u/FreeCADLauncher.AppImage',
      'LD_LIBRARY_PATH': '/tmp/.mount_FC/usr/lib:/opt/lib',
      'XDG_DATA_DIRS': '/tmp/.mount_FC/usr/share:/usr/local/share:/usr/share',
    });

    expect(environment['DISPLAY'], ':0');
    expect(environment.containsKey('APPDIR'), isFalse);
    expect(environment.containsKey('APPIMAGE'), isFalse);
    expect(environment.containsKey('LD_LIBRARY_PATH'), isFalse);
    expect(environment['XDG_DATA_DIRS'], '/usr/local/share:/usr/share');
  });

  test('openerEnvironment keeps non-AppImage environments untouched', () {
    final environment = openerEnvironment({
      'DISPLAY': ':0',
      'LD_LIBRARY_PATH': '/opt/lib',
      'XDG_DATA_DIRS': '/usr/local/share:/usr/share',
    });

    expect(environment['LD_LIBRARY_PATH'], '/opt/lib');
    expect(environment['XDG_DATA_DIRS'], '/usr/local/share:/usr/share');
  });

  test('reveal opens the containing directory on Linux', () async {
    final future = actions.reveal('/data/logs/app.log');
    await pumpEventQueue();
    launcher.handles.single.exit(0);
    await future;

    expect(launcher.specs.single.executable, 'xdg-open');
    expect(launcher.specs.single.arguments, ['/data/logs']);
  });

  test('non-zero exits surface as FileActionException', () async {
    final future = actions.openDirectory('/data/root');
    await pumpEventQueue();
    launcher.handles.single.emitStderr('no display');
    launcher.handles.single.exit(3);

    await expectLater(
      future,
      throwsA(
        isA<FileActionException>()
            .having((error) => error.exitCode, 'exitCode', 3)
            .having((error) => error.stderr, 'stderr', contains('no display')),
      ),
    );
  });
}
