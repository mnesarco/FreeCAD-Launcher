import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/cli_wrapper.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/state/settings_controller.dart';

import '../helpers/fake_process.dart';

void main() {
  late Directory tempDirectory;
  late FakeProcessLauncher launcher;
  late CliWrapperInstaller installer;
  late SettingsController controller;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_settings_controller');
    launcher = FakeProcessLauncher();
    installer = CliWrapperInstaller(
      platform: BuildPlatform.linux,
      processRunner: ProcessRunner(launcher: launcher),
      homeDirectory: tempDirectory.path,
      localAppData: tempDirectory.path,
      appExecutable: '/opt/app/freecad_launcher',
      pathEnvironment: '',
    );
    controller = SettingsController(cliWrapper: installer);
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('installs, refreshes and removes the wrapper', () async {
    if (Platform.isWindows) {
      return;
    }
    controller.refreshWrapper();
    expect(controller.wrapperInstalled.value, isFalse);
    expect(controller.wrapperOnPath.value, isFalse);
    expect(controller.wrapperPath.value, installer.wrapperPath);

    final install = controller.installWrapper();
    await pumpEventQueue();
    launcher.handles.single.exit(0);
    final installed = await install;

    expect(installed.isOk, isTrue);
    expect(controller.wrapperInstalled.value, isTrue);
    expect(controller.wrapperBusy.value, isFalse);

    final removed = await controller.removeWrapper();

    expect(removed.isOk, isTrue);
    expect(controller.wrapperInstalled.value, isFalse);
  });
}
