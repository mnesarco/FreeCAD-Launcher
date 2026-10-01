// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/daos/settings_dao.dart';
import 'package:freecad_launcher/domain/settings/app_settings.dart';
import 'package:freecad_launcher/platform/cli_wrapper.dart';

class SettingsController {
  SettingsController({
    required CliWrapperInstaller cliWrapper,
    required SettingsDao settingsDao,
  }) : _cliWrapper = cliWrapper,
       _settingsDao = settingsDao;

  final CliWrapperInstaller _cliWrapper;
  final SettingsDao _settingsDao;

  final wrapperInstalled = signal(false);
  final wrapperOnPath = signal(false);
  final wrapperPath = signal('');
  final wrapperDirectory = signal<String?>(null);
  final wrapperBusy = signal(false);

  final themeMode = signal(AppThemeMode.dark);
  final updateCadence = signal(UpdateCadence.manual);
  final logLevel = signal(LogLevel.info);
  final cacheRetention = signal(CacheRetention.days30);
  final newsFeedUrl = signal(defaultNewsFeedUrl);

  Future<void> load() async {
    final values = await _settingsDao.getAll();
    themeMode.value = appThemeModeFromStorage(values[SettingsKeys.themeMode]);
    updateCadence.value = updateCadenceFromStorage(
      values[SettingsKeys.updateCadence],
    );
    logLevel.value = logLevelFromStorage(values[SettingsKeys.logLevel]);
    cacheRetention.value = cacheRetentionFromStorage(
      values[SettingsKeys.cacheRetention],
    );
    final feedUrl = values[SettingsKeys.newsFeedUrl]?.trim();
    newsFeedUrl.value =
        feedUrl == null || feedUrl.isEmpty ? defaultNewsFeedUrl : feedUrl;
  }

  Future<void> setThemeMode(AppThemeMode value) async {
    themeMode.value = value;
    await _settingsDao.setValue(SettingsKeys.themeMode, value.name);
  }

  Future<void> setUpdateCadence(UpdateCadence value) async {
    updateCadence.value = value;
    await _settingsDao.setValue(SettingsKeys.updateCadence, value.name);
  }

  Future<void> setLogLevel(LogLevel value) async {
    logLevel.value = value;
    await _settingsDao.setValue(SettingsKeys.logLevel, value.name);
  }

  Future<void> setCacheRetention(CacheRetention value) async {
    cacheRetention.value = value;
    await _settingsDao.setValue(
      SettingsKeys.cacheRetention,
      '${value.days ?? 0}',
    );
  }

  Future<void> setNewsFeedUrl(String value) async {
    final trimmed = value.trim();
    newsFeedUrl.value = trimmed.isEmpty ? defaultNewsFeedUrl : trimmed;
    await _settingsDao.setValue(SettingsKeys.newsFeedUrl, newsFeedUrl.value);
  }

  void refreshWrapper() {
    final status = _cliWrapper.status();
    wrapperInstalled.value = status.installed;
    wrapperOnPath.value = status.onPath;
    wrapperPath.value = status.path;
    wrapperDirectory.value = status.directory;
  }

  Future<Result<void>> installWrapper() async {
    wrapperBusy.value = true;
    try {
      final result = await _cliWrapper.install();
      refreshWrapper();
      return result;
    } finally {
      wrapperBusy.value = false;
    }
  }

  Future<Result<void>> removeWrapper() async {
    wrapperBusy.value = true;
    try {
      final result = await _cliWrapper.remove();
      refreshWrapper();
      return result;
    } finally {
      wrapperBusy.value = false;
    }
  }
}
