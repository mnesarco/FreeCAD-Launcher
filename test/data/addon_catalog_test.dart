import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_download.dart';
import '../helpers/test_database.dart';

void main() {
  late Directory tempDirectory;
  late String addonsDirectory;
  late FakeDownloadSource source;
  late Downloader downloader;
  late AppDatabase db;
  late DateTime now;

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

  List<int> catalogZip(String json) {
    final bytes = utf8.encode(json);
    final archive = Archive()
      ..addFile(ArchiveFile('addon_catalog_cache.json', bytes.length, bytes));
    return ZipEncoder().encode(archive);
  }

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_addon_catalog');
    addonsDirectory = p.join(tempDirectory.path, 'addons');
    source = FakeDownloadSource();
    downloader = Downloader(source: source, cacheDirectory: addonsDirectory);
    db = createTestDatabase();
    now = DateTime.utc(2026, 9, 19, 12);
  });

  tearDown(() async {
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  AddonCatalog catalog() {
    return AddonCatalog(
      downloader: downloader,
      dao: db.catalogCacheDao,
      cacheDirectory: addonsDirectory,
      clock: () => now,
    );
  }

  test('downloads, parses and serves the catalog from cache within the TTL', () async {
    source.streamFactory = () => Stream.fromIterable([catalogZip(catalogJson)]);
    final subject = catalog();

    final first = await subject.load();

    expect(first.freshness, CatalogFreshness.refreshed);
    expect(first.addons.single.id, 'A2plus');
    expect(source.requests, hasLength(1));
    expect(File(subject.payloadPath).existsSync(), isTrue);

    final second = await subject.load();

    expect(second.freshness, CatalogFreshness.fresh);
    expect(second.addons.single.id, 'A2plus');
    expect(source.requests, hasLength(1));
  });

  test('refreshes after the TTL and on demand', () async {
    source.streamFactory = () => Stream.fromIterable([catalogZip(catalogJson)]);
    final subject = catalog();
    await subject.load();

    now = now.add(const Duration(hours: 7));
    final refreshed = await subject.load();

    expect(refreshed.freshness, CatalogFreshness.refreshed);
    expect(source.requests, hasLength(2));

    await subject.load(forceRefresh: true);
    expect(source.requests, hasLength(3));
  });

  test('falls back to the stale cached catalog when offline', () async {
    source.streamFactory = () => Stream.fromIterable([catalogZip(catalogJson)]);
    final subject = catalog();
    await subject.load();

    now = now.add(const Duration(hours: 7));
    source.error = const DownloadException('offline');

    final stale = await subject.load();

    expect(stale.freshness, CatalogFreshness.stale);
    expect(stale.addons.single.id, 'A2plus');
    expect(stale.error, isNotNull);
    expect(stale.isStale, isTrue);
    expect((await db.catalogCacheDao.get(AddonCatalog.cacheKey))!.status.name, 'stale');
  });

  test('throws when there is no cache and the download fails', () async {
    source.error = const DownloadException('offline');

    await expectLater(
      catalog().load(),
      throwsA(isA<AddonCatalogUnavailableException>()),
    );
  });

  test('rejects a zip without a JSON entry', () {
    final archive = Archive()
      ..addFile(ArchiveFile('readme.txt', 3, utf8.encode('abc')));
    final bytes = ZipEncoder().encode(archive);

    expect(
      () => AddonCatalog.extractCatalogJson(bytes),
      throwsA(isA<FormatException>()),
    );
  });
}
