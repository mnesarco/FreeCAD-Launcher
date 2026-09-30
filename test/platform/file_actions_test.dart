// SPDX-License-Identifier: GPL-3.0-or-later
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

  test('openDirectory inherits the parent environment', () async {
    final future = actions.openDirectory('/data/root');
    await pumpEventQueue();
    launcher.handles.single.exit(0);
    await future;

    expect(launcher.specs.single.executable, 'xdg-open');
    expect(launcher.specs.single.arguments, ['/data/root']);
    expect(launcher.specs.single.includeParentEnvironment, isTrue);
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
