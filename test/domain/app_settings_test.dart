// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/domain/settings/app_settings.dart';

void main() {
  group('isUpdateCheckDue', () {
    final now = DateTime.utc(2026, 9, 20, 12);

    test('manual never checks', () {
      expect(isUpdateCheckDue(null, UpdateCadence.manual, now), isFalse);
      expect(
        isUpdateCheckDue(
          now.subtract(const Duration(days: 30)),
          UpdateCadence.manual,
          now,
        ),
        isFalse,
      );
    });

    test('daily checks when never checked or the interval elapsed', () {
      expect(isUpdateCheckDue(null, UpdateCadence.daily, now), isTrue);
      expect(
        isUpdateCheckDue(
          now.subtract(const Duration(hours: 23)),
          UpdateCadence.daily,
          now,
        ),
        isFalse,
      );
      expect(
        isUpdateCheckDue(
          now.subtract(const Duration(days: 1)),
          UpdateCadence.daily,
          now,
        ),
        isTrue,
      );
      expect(
        isUpdateCheckDue(
          now.subtract(const Duration(days: 2)),
          UpdateCadence.daily,
          now,
        ),
        isTrue,
      );
    });

    test('weekly checks only after seven days', () {
      expect(
        isUpdateCheckDue(
          now.subtract(const Duration(days: 6, hours: 23)),
          UpdateCadence.weekly,
          now,
        ),
        isFalse,
      );
      expect(
        isUpdateCheckDue(
          now.subtract(const Duration(days: 7)),
          UpdateCadence.weekly,
          now,
        ),
        isTrue,
      );
    });
  });

  group('storage parsing', () {
    test('theme mode defaults to dark', () {
      expect(appThemeModeFromStorage('system'), AppThemeMode.system);
      expect(appThemeModeFromStorage('light'), AppThemeMode.light);
      expect(appThemeModeFromStorage('dark'), AppThemeMode.dark);
      expect(appThemeModeFromStorage(null), AppThemeMode.dark);
      expect(appThemeModeFromStorage('bogus'), AppThemeMode.dark);
    });

    test('cadence defaults to manual', () {
      expect(updateCadenceFromStorage('daily'), UpdateCadence.daily);
      expect(updateCadenceFromStorage('weekly'), UpdateCadence.weekly);
      expect(updateCadenceFromStorage('manual'), UpdateCadence.manual);
      expect(updateCadenceFromStorage(null), UpdateCadence.manual);
      expect(updateCadenceFromStorage('bogus'), UpdateCadence.manual);
    });

    test('log level defaults to info', () {
      expect(logLevelFromStorage('debug'), LogLevel.debug);
      expect(logLevelFromStorage('warn'), LogLevel.warn);
      expect(logLevelFromStorage('error'), LogLevel.error);
      expect(logLevelFromStorage('info'), LogLevel.info);
      expect(logLevelFromStorage(null), LogLevel.info);
      expect(logLevelFromStorage('bogus'), LogLevel.info);
    });

    test('cache retention defaults to 30 days', () {
      expect(cacheRetentionFromStorage('0'), CacheRetention.forever);
      expect(cacheRetentionFromStorage('7'), CacheRetention.days7);
      expect(cacheRetentionFromStorage('30'), CacheRetention.days30);
      expect(cacheRetentionFromStorage('90'), CacheRetention.days90);
      expect(cacheRetentionFromStorage(null), CacheRetention.days30);
      expect(cacheRetentionFromStorage('bogus'), CacheRetention.days30);
      expect(CacheRetention.forever.days, isNull);
      expect(CacheRetention.days7.days, 7);
      expect(CacheRetention.days30.days, 30);
      expect(CacheRetention.days90.days, 90);
    });
  });
}
