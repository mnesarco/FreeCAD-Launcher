// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';

import 'test_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.inMemory());
  tearDown(() => db.close());

  group('CatalogCacheDao', () {
    test('puts, reads and removes entries', () async {
      await db.catalogCacheDao.put(sampleCacheEntry());

      final entry = await db.catalogCacheDao.get('github:releases:stable');
      expect(entry, isNotNull);
      expect(entry!.etag, 'W/"abc"');
      expect(entry.status, CacheStatus.ok);

      await db.catalogCacheDao.remove('github:releases:stable');

      expect(await db.catalogCacheDao.get('github:releases:stable'), isNull);
      expect(await db.catalogCacheDao.getAll(), isEmpty);
    });

    test('upserts an existing key', () async {
      await db.catalogCacheDao.put(sampleCacheEntry());
      await db.catalogCacheDao.put(
        sampleCacheEntry(payloadPath: '/data/cache/new.json', status: CacheStatus.stale),
      );

      final entries = await db.catalogCacheDao.getAll();
      expect(entries, hasLength(1));
      expect(entries.single.payloadPath, '/data/cache/new.json');
      expect(entries.single.status, CacheStatus.stale);
    });
  });

  group('SettingsDao', () {
    test('stores and updates values', () async {
      await db.settingsDao.setValue('theme_mode', 'dark');

      expect(await db.settingsDao.getValue('theme_mode'), 'dark');

      await db.settingsDao.setValue('theme_mode', 'light');
      expect(await db.settingsDao.getValue('theme_mode'), 'light');

      await db.settingsDao.remove('theme_mode');
      expect(await db.settingsDao.getValue('theme_mode'), isNull);
    });

    test('round-trips JSON values', () async {
      await db.settingsDao.setJson('update_check_interval', {'hours': 6});

      expect(await db.settingsDao.getJson('update_check_interval'), {'hours': 6});
      expect(await db.settingsDao.getJson('missing'), isNull);
    });

    test('getAll returns every entry', () async {
      await db.settingsDao.setValue('a', '1');
      await db.settingsDao.setValue('b', '2');

      expect(await db.settingsDao.getAll(), {'a': '1', 'b': '2'});
    });
  });
}
