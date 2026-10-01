// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/github_releases_client.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fake_http.dart';
import '../../helpers/fixtures.dart';

void main() {
  GitHubReleasesClient buildClient({
    required FakeHttp fake,
    String? Function()? tokenProvider,
  }) {
    return GitHubReleasesClient(client: fake.client, tokenProvider: tokenProvider);
  }

  test('builds the request URL and headers', () async {
    final fake = FakeHttp.json('[]');

    await buildClient(fake: fake).fetchReleases(page: 2, perPage: 50);

    final request = fake.requests.single;
    expect(request.url.host, 'api.github.com');
    expect(request.url.path, '/repos/FreeCAD/FreeCAD/releases');
    expect(request.url.queryParameters, {'per_page': '50', 'page': '2'});
    expect(request.headers['Accept'], 'application/vnd.github+json');
    expect(request.headers['X-GitHub-Api-Version'], '2022-11-28');
    expect(request.headers['User-Agent'], contains('FreeCAD Launcher'));
    expect(request.headers.containsKey('Authorization'), isFalse);
  });

  test('returns the body, etag and rate limit on 200', () async {
    final body = loadFixture('github_releases_1.1.3.json');
    final fake = FakeHttp(
      (_) async => http.Response(
        body,
        200,
        headers: {
          'etag': 'W/"abc"',
          'last-modified': 'Thu, 18 Sep 2026 10:00:00 GMT',
          'x-ratelimit-limit': '60',
          'x-ratelimit-remaining': '42',
          'x-ratelimit-reset': '1780000000',
        },
      ),
    );

    final response = await buildClient(fake: fake).fetchReleases();

    expect(response.isOk, isTrue);
    expect(response.body, body);
    expect(response.etag, 'W/"abc"');
    expect(response.lastModified, 'Thu, 18 Sep 2026 10:00:00 GMT');
    expect(response.rateLimit.limit, 60);
    expect(response.rateLimit.remaining, 42);
    expect(response.rateLimit.resetAt, DateTime.fromMillisecondsSinceEpoch(1780000000000, isUtc: true));
  });

  test('sends conditional headers and reports 304', () async {
    final fake = FakeHttp((request) async {
      return http.Response('', 304, headers: {'etag': 'W/"abc"'});
    });

    final response = await buildClient(fake: fake).fetchReleases(
      etag: 'W/"abc"',
      lastModified: 'Thu, 18 Sep 2026 10:00:00 GMT',
    );

    final request = fake.requests.single;
    expect(request.headers['If-None-Match'], 'W/"abc"');
    expect(request.headers['If-Modified-Since'], 'Thu, 18 Sep 2026 10:00:00 GMT');
    expect(response.isNotModified, isTrue);
    expect(response.body, isNull);
  });

  test('adds a bearer token when the provider returns one', () async {
    final fake = FakeHttp.json('[]');

    await buildClient(fake: fake, tokenProvider: () => 'ghp_secret').fetchReleases();

    expect(fake.requests.single.headers['Authorization'], 'Bearer ghp_secret');
  });

  test('omits the token when the provider is empty', () async {
    final fake = FakeHttp.json('[]');

    await buildClient(fake: fake, tokenProvider: () => '').fetchReleases();

    expect(fake.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('flags an exhausted rate limit on 403', () async {
    final fake = FakeHttp(
      (_) async => http.Response(
        '{"message":"API rate limit exceeded"}',
        403,
        headers: {
          'x-ratelimit-limit': '60',
          'x-ratelimit-remaining': '0',
          'x-ratelimit-reset': '1780000000',
        },
      ),
    );

    final response = await buildClient(fake: fake).fetchReleases();

    expect(response.isRateLimited, isTrue);
    expect(response.rateLimit.isExhausted, isTrue);
    expect(response.body, contains('rate limit'));
  });

  test('propagates transport errors', () async {
    final fake = FakeHttp((_) async => throw http.ClientException('offline'));

    await expectLater(
      buildClient(fake: fake).fetchReleases(),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('parses the next page from the Link header', () {
    expect(
      ReleasesResponse.nextPageFromLink(
        '<https://api.github.com/repos/FreeCAD/FreeCAD/releases?page=3>; rel="next", '
        '<https://api.github.com/repos/FreeCAD/FreeCAD/releases?page=9>; rel="last"',
      ),
      3,
    );
    expect(
      ReleasesResponse.nextPageFromLink('<https://api.github.com/x?page=9>; rel="last"'),
      isNull,
    );
    expect(ReleasesResponse.nextPageFromLink(null), isNull);
  });
}
