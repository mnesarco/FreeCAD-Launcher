// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/core/log.dart';

enum AppThemeMode { system, light, dark }

enum UpdateCadence { manual, daily, weekly }

abstract final class SettingsKeys {
  static const themeMode = 'theme_mode';
  static const updateCadence = 'update_check_interval';
  static const logLevel = 'log_level';
  static const cacheRetention = 'cache_retention_days';
  static const newsFeedUrl = 'news_feed_url';
}

const String defaultNewsFeedUrl = 'https://blog.freecad.org/feed/atom/';

enum CacheRetention { forever, days7, days30, days90 }

extension CacheRetentionDays on CacheRetention {
  int? get days => switch (this) {
    CacheRetention.forever => null,
    CacheRetention.days7 => 7,
    CacheRetention.days30 => 30,
    CacheRetention.days90 => 90,
  };
}

extension UpdateCadenceInterval on UpdateCadence {
  Duration? get interval => switch (this) {
    UpdateCadence.manual => null,
    UpdateCadence.daily => const Duration(days: 1),
    UpdateCadence.weekly => const Duration(days: 7),
  };
}

bool isUpdateCheckDue(
  DateTime? lastCheckedAt,
  UpdateCadence cadence,
  DateTime now,
) {
  final interval = cadence.interval;
  if (interval == null) {
    return false;
  }
  if (lastCheckedAt == null) {
    return true;
  }
  return !now.isBefore(lastCheckedAt.add(interval));
}

AppThemeMode appThemeModeFromStorage(String? value) => switch (value) {
  'system' => AppThemeMode.system,
  'light' => AppThemeMode.light,
  _ => AppThemeMode.dark,
};

UpdateCadence updateCadenceFromStorage(String? value) => switch (value) {
  'daily' => UpdateCadence.daily,
  'weekly' => UpdateCadence.weekly,
  _ => UpdateCadence.manual,
};

LogLevel logLevelFromStorage(String? value) => switch (value) {
  'debug' => LogLevel.debug,
  'warn' => LogLevel.warn,
  'error' => LogLevel.error,
  _ => LogLevel.info,
};

CacheRetention cacheRetentionFromStorage(String? value) => switch (value) {
  '0' => CacheRetention.forever,
  '7' => CacheRetention.days7,
  '90' => CacheRetention.days90,
  _ => CacheRetention.days30,
};
