// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/github_releases_client.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/release_info.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../helpers/fake_http.dart';
import '../../helpers/fixtures.dart';

void main() {
  late AppDatabase db;
  late Directory cacheDirectory;
  late DateTime now;
  late DateTime staleTime;

  setUp(() {
    db = AppDatabase.inMemory();
    cacheDirectory = Directory.systemTemp.createTempSync('fcl_releases_catalog_test');
    now = DateTime.utc(2026, 9, 18, 12);
    staleTime = now.subtract(const Duration(hours: 7));
  });

  tearDown(() async {
    await db.close();
    if (cacheDirectory.existsSync()) {
      cacheDirectory.deleteSync(recursive: true);
    }
  });

  String payloadPath() => p.join(cacheDirectory.path, ReleasesCatalog.payloadFileName);

  Future<void> primeCache({
    required String payload,
    required DateTime fetchedAt,
    String? etag,
    CacheStatus status = CacheStatus.ok,
  }) async {
    await File(payloadPath()).writeAsString(payload);
    await db.catalogCacheDao.put(
      CatalogCacheEntry(
        key: ReleasesCatalog.cacheKey,
        etag: etag,
        payloadPath: payloadPath(),
        fetchedAt: fetchedAt,
        status: status,
      ),
    );
  }

  ReleasesCatalog buildCatalog(FakeHttp fake, {Duration ttl = const Duration(hours: 6)}) {
    return ReleasesCatalog(
      client: GitHubReleasesClient(client: fake.client),
      dao: db.catalogCacheDao,
      cacheDirectory: cacheDirectory.path,
      ttl: ttl,
      clock: () => now,
    );
  }

  test('serves a fresh cache without any network request', () async {
    await primeCache(payload: loadFixture('github_releases_1.1.3.json'), fetchedAt: now.subtract(const Duration(hours: 1)));
    final fake = FakeHttp.json('[]');

    final result = await buildCatalog(fake).load();

    expect(result.freshness, CatalogFreshness.fresh);
    expect(result.releases.single.tagName, '1.1.3');
    expect(result.isStale, isFalse);
    expect(fake.requestCount, 0);
  });

  test('refetches an expired cache and stores payload and entry', () async {
    final body = loadFixture('github_releases_1.1.3.json');
    await primeCache(payload: '[]', fetchedAt: staleTime, etag: 'W/"old"');
    final fake = FakeHttp(
      (_) async => http.Response(body, 200, headers: {'etag': 'W/"new"'}),
    );

    final result = await buildCatalog(fake).load();

    expect(result.freshness, CatalogFreshness.refreshed);
    expect(result.releases.single.tagName, '1.1.3');
    expect(fake.requestCount, 1);
    expect(fake.requests.single.headers['If-None-Match'], 'W/"old"');

    final entry = (await db.catalogCacheDao.get(ReleasesCatalog.cacheKey))!;
    expect(entry.etag, 'W/"new"');
    expect(entry.status, CacheStatus.ok);
    expect(entry.fetchedAt, now);
    expect(
      parseReleasesJson(File(payloadPath()).readAsStringSync()).single.tagName,
      '1.1.3',
    );
  });

  test('handles 304 by refreshing the stored payload timestamp', () async {
    final body = loadFixture('github_releases_1.1.3.json');
    await primeCache(payload: body, fetchedAt: staleTime, etag: 'W/"abc"');
    final fake = FakeHttp((_) async => http.Response('', 304));

    final result = await buildCatalog(fake).load();

    expect(result.freshness, CatalogFreshness.refreshed);
    expect(result.releases.single.tagName, '1.1.3');
    expect(fake.requests.single.headers['If-None-Match'], 'W/"abc"');

    final entry = (await db.catalogCacheDao.get(ReleasesCatalog.cacheKey))!;
    expect(entry.fetchedAt, now);
    expect(entry.status, CacheStatus.ok);
    expect(entry.etag, 'W/"abc"');
  });

  test('falls back to stale cache on transport errors', () async {
    final body = loadFixture('github_releases_1.1.3.json');
    await primeCache(payload: body, fetchedAt: staleTime, etag: 'W/"abc"');
    final fake = FakeHttp((_) async => throw http.ClientException('offline'));

    final result = await buildCatalog(fake).load();

    expect(result.isStale, isTrue);
    expect(result.error, isA<http.ClientException>());
    expect(result.releases.single.tagName, '1.1.3');
    expect((await db.catalogCacheDao.get(ReleasesCatalog.cacheKey))!.status, CacheStatus.stale);
  });

  test('falls back to stale cache when rate limited', () async {
    await primeCache(payload: loadFixture('github_releases_1.1.3.json'), fetchedAt: staleTime);
    final fake = FakeHttp(
      (_) async => http.Response(
        '{"message":"API rate limit exceeded"}',
        403,
        headers: {'x-ratelimit-remaining': '0'},
      ),
    );

    final result = await buildCatalog(fake).load();

    expect(result.isStale, isTrue);
    expect(result.error, isA<ReleasesHttpException>());
  });

  test('throws when offline with no cache', () async {
    final fake = FakeHttp((_) async => throw http.ClientException('offline'));

    await expectLater(
      buildCatalog(fake).load(),
      throwsA(isA<CatalogUnavailableException>()),
    );
  });

  test('follows the Link header across pages', () async {
    final page1 = loadFixture('github_releases_1.1.3.json');
    const page2 = '[{"tag_name":"1.1.2","prerelease":false,"html_url":"","assets":[]}]';
    final fake = FakeHttp((request) async {
      if (request.url.queryParameters['page'] == '1') {
        return http.Response(
          page1,
          200,
          headers: {
            'link':
                '<https://api.github.com/repos/FreeCAD/FreeCAD/releases?per_page=100&page=2>; rel="next", '
                '<https://api.github.com/repos/FreeCAD/FreeCAD/releases?per_page=100&page=2>; rel="last"',
          },
        );
      }
      return http.Response(page2, 200);
    });

    final result = await buildCatalog(fake).load();

    expect(result.releases.map((release) => release.tagName), ['1.1.3', '1.1.2']);
    expect(fake.requestCount, 2);
    expect(fake.requests.last.url.queryParameters['page'], '2');
  });

  test('forceRefresh bypasses a fresh cache', () async {
    await primeCache(payload: '[]', fetchedAt: now.subtract(const Duration(minutes: 5)));
    final fake = FakeHttp.json(loadFixture('github_releases_1.1.3.json'));

    final result = await buildCatalog(fake).load(forceRefresh: true);

    expect(result.freshness, CatalogFreshness.refreshed);
    expect(fake.requestCount, 1);
    expect(result.releases.single.tagName, '1.1.3');
  });
}
