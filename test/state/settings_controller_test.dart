import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/settings/app_settings.dart';
import 'package:freecad_launcher/platform/cli_wrapper.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/state/settings_controller.dart';

import '../helpers/fake_process.dart';

void main() {
  late Directory tempDirectory;
  late FakeProcessLauncher launcher;
  late CliWrapperInstaller installer;
  late AppDatabase database;
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
    database = AppDatabase.inMemory();
    controller = SettingsController(
      cliWrapper: installer,
      settingsDao: database.settingsDao,
    );
  });

  tearDown(() async {
    await database.close();
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

  test('persists and reloads theme, cadence, log level and retention', () async {
    await controller.setThemeMode(AppThemeMode.light);
    await controller.setUpdateCadence(UpdateCadence.daily);
    await controller.setLogLevel(LogLevel.debug);
    await controller.setCacheRetention(CacheRetention.days7);
    await controller.setNewsFeedUrl('https://blog.freecad.org/feed/');

    final reloaded = SettingsController(
      cliWrapper: installer,
      settingsDao: database.settingsDao,
    );
    await reloaded.load();

    expect(reloaded.themeMode.value, AppThemeMode.light);
    expect(reloaded.updateCadence.value, UpdateCadence.daily);
    expect(reloaded.logLevel.value, LogLevel.debug);
    expect(reloaded.cacheRetention.value, CacheRetention.days7);
    expect(reloaded.newsFeedUrl.value, 'https://blog.freecad.org/feed/');
  });

  test('load keeps defaults for missing or unknown values', () async {
    await database.settingsDao.setValue(SettingsKeys.themeMode, 'bogus');
    await database.settingsDao.setValue(SettingsKeys.updateCadence, 'bogus');
    await database.settingsDao.setValue(SettingsKeys.cacheRetention, 'bogus');

    await controller.load();

    expect(controller.themeMode.value, AppThemeMode.dark);
    expect(controller.updateCadence.value, UpdateCadence.manual);
    expect(controller.logLevel.value, LogLevel.info);
    expect(controller.cacheRetention.value, CacheRetention.days30);
    expect(controller.newsFeedUrl.value, defaultNewsFeedUrl);
  });

  test('empty news feed URLs reset to the default', () async {
    await controller.setNewsFeedUrl('   ');

    expect(controller.newsFeedUrl.value, defaultNewsFeedUrl);
    expect(
      await database.settingsDao.getValue(SettingsKeys.newsFeedUrl),
      defaultNewsFeedUrl,
    );
  });
}
