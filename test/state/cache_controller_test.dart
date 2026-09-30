// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:freecad_launcher/domain/settings/app_settings.dart';
import 'package:freecad_launcher/platform/cache_service.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/cache_controller.dart';

import '../helpers/test_database.dart';

void main() {
  late Directory root;
  late AppDatabase db;
  late CacheService service;
  late CacheController controller;
  late DateTime now;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('fcl_cache_controller');
    db = createTestDatabase();
    now = DateTime.utc(2026, 9, 20, 12);
    final paths = AppPaths(dataRoot: root.path);
    await paths.ensureBaseDirectories();
    service = CacheService(
      paths: paths,
      cacheDao: db.catalogCacheDao,
      clock: () => now,
    );
    controller = CacheController(service: service);
  });

  tearDown(() async {
    await db.close();
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('refresh, clear and prune keep the sizes signal current', () async {
    final paths = AppPaths(dataRoot: root.path);
    File('${paths.downloadsCacheDir}/build.zip')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1024, 0));

    await controller.refresh();
    expect(controller.sizes.value[CacheCategory.downloads], 1024);

    final freed = await controller.clear(CacheCategory.downloads);
    expect(freed, 1024);
    expect(controller.sizes.value[CacheCategory.downloads], 0);
    expect(controller.busy.value, isFalse);

    final old = File('${paths.downloadsCacheDir}/old.zip')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(2048, 0));
    old.setLastModifiedSync(now.subtract(const Duration(days: 10)));

    final pruned = await controller.prune(CacheRetention.days7);
    expect(pruned, 2048);
    expect(controller.sizes.value[CacheCategory.downloads], 0);
  });
}
