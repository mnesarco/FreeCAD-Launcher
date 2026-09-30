// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:freecad_launcher/platform/checksum.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_download.dart';
import '../helpers/test_database.dart';

List<int> macroZip(Map<String, Object?> macros) {
  final archive = Archive();
  final bytes = utf8.encode(jsonEncode(macros));
  archive.addFile(ArchiveFile('macro_cache.json', bytes.length, bytes));
  return ZipEncoder().encode(archive);
}

const _macros = {
  'Foto': {
    'name': 'Foto',
    'on_git': true,
    'code': 'print(1)',
    'license': '',
    'other_files': "['']",
  },
};

void main() {
  late Directory tempDirectory;
  late AppDatabase db;
  late String cacheDirectory;
  late List<Uri> requests;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_macro_catalog');
    db = createTestDatabase();
    cacheDirectory = p.join(tempDirectory.path, 'macros');
    requests = [];
  });

  tearDown(() async {
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  MacroCatalog catalog({
    required Future<DownloadStream> Function(Uri uri) handler,
    DateTime Function()? clock,
  }) {
    return MacroCatalog(
      downloader: Downloader(
        source: FakeDownloadSourceWithResponses((uri) {
          requests.add(uri);
          return handler(uri);
        }),
        cacheDirectory: cacheDirectory,
      ),
      dao: db.catalogCacheDao,
      cacheDirectory: cacheDirectory,
      sourceUrl: Uri.parse('https://example.invalid/macro_cache.zip'),
      clock: clock ?? () => DateTime.utc(2026, 9, 19, 16),
    );
  }

  Future<DownloadStream> zipHandler(Uri uri, List<int> zipBytes) async {
    if (uri.path.endsWith('.sha256')) {
      final hash = sha256OfBytes(zipBytes);
      final bytes = utf8.encode('$hash  macro_cache.zip\n');
      return DownloadStream(bytes: bytesStream(bytes), contentLength: bytes.length);
    }
    return DownloadStream(bytes: bytesStream(zipBytes), contentLength: zipBytes.length);
  }

  test('downloads the zip and sidecar, verifies the hash and caches it', () async {
    final zipBytes = macroZip(_macros);
    final subject = catalog(handler: (uri) => zipHandler(uri, zipBytes));

    final result = await subject.load();

    expect(result.freshness, CatalogFreshness.refreshed);
    expect(result.macros.single.name, 'Foto');
    expect(requests.map((uri) => uri.path), [
      '/macro_cache.zip.sha256',
      '/macro_cache.zip',
    ]);
    final row = await db.catalogCacheDao.get(MacroCatalog.cacheKey);
    expect(row!.status, CacheStatus.ok);
    expect(row.etag, sha256OfBytes(zipBytes));
    expect(File(subject.payloadPath).existsSync(), isTrue);

    final cached = await subject.load();
    expect(cached.freshness, CatalogFreshness.fresh);
    expect(cached.macros.single.name, 'Foto');
    expect(requests, hasLength(2));
  });

  test('skips the zip download when the sidecar hash is unchanged', () async {
    final zipBytes = macroZip(_macros);
    var now = DateTime.utc(2026, 9, 19, 16);
    final subject = catalog(
      handler: (uri) => zipHandler(uri, zipBytes),
      clock: () => now,
    );
    await subject.load();
    requests.clear();

    now = now.add(const Duration(hours: 7));
    final result = await subject.load();

    expect(result.freshness, CatalogFreshness.fresh);
    expect(requests.map((uri) => uri.path), ['/macro_cache.zip.sha256']);
    final row = await db.catalogCacheDao.get(MacroCatalog.cacheKey);
    expect(row!.fetchedAt, now);
  });

  test('falls back to the stale cache when the download fails', () async {
    final zipBytes = macroZip(_macros);
    var fail = false;
    final subject = catalog(
      handler: (uri) async {
        if (fail) {
          throw const SocketException('offline');
        }
        return zipHandler(uri, zipBytes);
      },
    );
    await subject.load();

    fail = true;
    final result = await subject.load(forceRefresh: true);

    expect(result.freshness, CatalogFreshness.stale);
    expect(result.macros.single.name, 'Foto');
    expect(result.error, isNotNull);
    final row = await db.catalogCacheDao.get(MacroCatalog.cacheKey);
    expect(row!.status, CacheStatus.stale);
  });

  test('throws without a cache when the payload is unavailable', () async {
    final subject = catalog(handler: (uri) async => throw const SocketException('offline'));

    await expectLater(subject.load(), throwsA(isA<MacroCatalogException>()));
  });

  test('rejects a checksum mismatch', () async {
    final zipBytes = macroZip(_macros);
    final subject = catalog(handler: (uri) async {
      if (uri.path.endsWith('.sha256')) {
        final bytes = utf8.encode('${'0' * 64}  macro_cache.zip\n');
        return DownloadStream(bytes: bytesStream(bytes), contentLength: bytes.length);
      }
      return DownloadStream(bytes: bytesStream(zipBytes), contentLength: zipBytes.length);
    });

    await expectLater(subject.load(), throwsA(isA<MacroCatalogException>()));
  });
}
