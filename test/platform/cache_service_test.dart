// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:freecad_launcher/domain/settings/app_settings.dart';
import 'package:freecad_launcher/platform/cache_service.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';

import '../helpers/fake_download.dart';
import '../helpers/test_database.dart';

void main() {
  late Directory root;
  late AppDatabase db;
  late CacheService service;
  late DateTime now;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('fcl_cache_service');
    db = createTestDatabase();
    now = DateTime.utc(2026, 9, 20, 12);
    final paths = AppPaths(dataRoot: root.path);
    await paths.ensureBaseDirectories();
    service = CacheService(
      paths: paths,
      cacheDao: db.catalogCacheDao,
      clock: () => now,
    );
  });

  tearDown(() async {
    await db.close();
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  void write(String path, int bytes, {DateTime? modified}) {
    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(List<int>.filled(bytes, 0));
    if (modified != null) {
      file.setLastModifiedSync(modified);
    }
  }

  test('reports sizes per category', () async {
    final paths = AppPaths(dataRoot: root.path);
    write('${paths.downloadsCacheDir}/build.zip', 1024);
    write('${paths.githubCacheDir}/releases.json', 2048);
    write('${paths.addonsCacheDir}/addons.zip', 4096);
    write('${paths.macrosCacheDir}/macros.zip', 512);

    final sizes = await service.sizes();

    expect(sizes[CacheCategory.downloads], 1024);
    expect(sizes[CacheCategory.github], 2048);
    expect(sizes[CacheCategory.addons], 4096);
    expect(sizes[CacheCategory.macros], 512);
  });

  test('clearing a category frees files and drops its cache row', () async {
    final paths = AppPaths(dataRoot: root.path);
    write('${paths.addonsCacheDir}/addons.zip', 4096);
    await db.catalogCacheDao.put(
      CatalogCacheEntry(
        key: 'addons:catalog',
        payloadPath: '${paths.addonsCacheDir}/addons.zip',
        fetchedAt: now,
        status: CacheStatus.ok,
      ),
    );

    final freed = await service.clear(CacheCategory.addons);

    expect(freed, 4096);
    expect(Directory(paths.addonsCacheDir).listSync(), isEmpty);
    expect(await db.catalogCacheDao.get('addons:catalog'), isNull);
    expect((await service.sizes())[CacheCategory.addons], 0);
  });

  test('prunes downloads older than the retention window', () async {
    final paths = AppPaths(dataRoot: root.path);
    write(
      '${paths.downloadsCacheDir}/old.zip',
      1024,
      modified: now.subtract(const Duration(days: 40)),
    );
    write(
      '${paths.downloadsCacheDir}/recent.zip',
      2048,
      modified: now.subtract(const Duration(days: 2)),
    );

    final freed = await service.pruneDownloads(CacheRetention.days30);

    expect(freed, 1024);
    expect(File('${paths.downloadsCacheDir}/old.zip').existsSync(), isFalse);
    expect(File('${paths.downloadsCacheDir}/recent.zip').existsSync(), isTrue);
  });

  test('forever retention keeps everything', () async {
    final paths = AppPaths(dataRoot: root.path);
    write(
      '${paths.downloadsCacheDir}/old.zip',
      1024,
      modified: now.subtract(const Duration(days: 400)),
    );

    expect(await service.pruneDownloads(CacheRetention.forever), 0);
    expect(File('${paths.downloadsCacheDir}/old.zip').existsSync(), isTrue);
  });

  test('clearing a catalog makes the next load refetch it', () async {
    const catalogJson = '''
{
  "A2plus": [
    {
      "repository": "https://github.com/kbwbe/A2plus",
      "git_ref": "master",
      "branch_display_name": "master",
      "zip_url": "https://github.com/kbwbe/A2plus/archive/refs/heads/master.zip",
      "curated": true,
      "sparse_cache": false
    }
  ]
}
''';
    final jsonBytes = utf8.encode(catalogJson);
    final zip = ZipEncoder().encode(
      Archive()
        ..addFile(
          ArchiveFile('addon_catalog_cache.json', jsonBytes.length, jsonBytes),
        ),
    );
    final paths = AppPaths(dataRoot: root.path);
    final source = FakeDownloadSource()
      ..streamFactory = () => Stream.fromIterable([zip]);
    final catalog = AddonCatalog(
      downloader: Downloader(
        source: source,
        cacheDirectory: paths.downloadsCacheDir,
      ),
      dao: db.catalogCacheDao,
      cacheDirectory: paths.addonsCacheDir,
    );

    await catalog.load();
    expect(source.requests, hasLength(1));

    await service.clear(CacheCategory.addons);
    expect(File(catalog.payloadPath).existsSync(), isFalse);

    final reloaded = await catalog.load();
    expect(source.requests, hasLength(2));
    expect(reloaded.addons.single.id, 'A2plus');
  });
}
