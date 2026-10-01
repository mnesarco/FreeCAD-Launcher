// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/news_feed.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_download.dart';
import '../helpers/test_database.dart';

void main() {
  const rss = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>FreeCAD News</title>
    <item>
      <title>Older &amp; stable</title>
      <link>https://blog.freecad.org/older</link>
      <pubDate>Mon, 01 Sep 2025 10:00:00 +0000</pubDate>
      <description>&lt;p&gt;First &lt;b&gt;post&lt;/b&gt; body&lt;/p&gt;</description>
    </item>
    <item>
      <title>Newer release</title>
      <link>https://blog.freecad.org/newer</link>
      <pubDate>Tue, 02 Sep 2025 10:00:00 +0000</pubDate>
    </item>
    <item>
      <title>No link</title>
      <pubDate>Wed, 03 Sep 2025 10:00:00 +0000</pubDate>
    </item>
  </channel>
</rss>
''';

  const atom = '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>FreeCAD Blog</title>
  <entry>
    <title>Atom entry</title>
    <link rel="alternate" href="https://blog.freecad.org/atom-entry"/>
    <updated>2025-09-04T08:30:00Z</updated>
    <summary>Short summary</summary>
  </entry>
</feed>
''';

  late Directory tempDirectory;
  late AppDatabase db;
  late FakeDownloadSource source;
  late NewsFeed feed;
  late DateTime now;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_news_feed');
    db = createTestDatabase();
    source = FakeDownloadSource();
    now = DateTime.utc(2026, 9, 20, 12);
    feed = NewsFeed(
      downloader: Downloader(
        source: source,
        cacheDirectory: p.join(tempDirectory.path, 'downloads'),
      ),
      dao: db.catalogCacheDao,
      cacheDirectory: p.join(tempDirectory.path, 'news'),
      clock: () => now,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('parses RSS items sorted newest first', () {
    final items = parseNewsFeed(rss);

    expect(items, hasLength(2));
    expect(items.first.title, 'Newer release');
    expect(items.first.link, 'https://blog.freecad.org/newer');
    expect(items.first.publishedAt, DateTime.utc(2025, 9, 2, 10));
    expect(items.last.title, 'Older & stable');
    expect(items.last.summary, 'First post body');
  });

  test('parses Atom entries', () {
    final items = parseNewsFeed(atom);

    expect(items, hasLength(1));
    expect(items.single.title, 'Atom entry');
    expect(items.single.link, 'https://blog.freecad.org/atom-entry');
    expect(items.single.publishedAt, DateTime.utc(2025, 9, 4, 8, 30));
    expect(items.single.summary, 'Short summary');
  });

  test('downloads once, serves the cache and refetches on URL change', () async {
    source.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);

    final first = await feed.load(sourceUrl: 'https://example.invalid/a.rss');
    expect(first.items, hasLength(2));
    expect(source.requests, hasLength(1));

    final second = await feed.load(sourceUrl: 'https://example.invalid/a.rss');
    expect(second.items, hasLength(2));
    expect(source.requests, hasLength(1));

    final third = await feed.load(sourceUrl: 'https://example.invalid/b.rss');
    expect(third.items, hasLength(2));
    expect(source.requests, hasLength(2));
  });

  test('falls back to the cached items when offline', () async {
    source.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);
    await feed.load(sourceUrl: 'https://example.invalid/a.rss');

    now = now.add(const Duration(hours: 7));
    source.error = const DownloadException('offline');
    final stale = await feed.load(sourceUrl: 'https://example.invalid/a.rss');

    expect(stale.isStale, isTrue);
    expect(stale.items, hasLength(2));
    expect(stale.error, isNotNull);
  });

  test('rejects invalid feed URLs', () async {
    await expectLater(
      feed.load(sourceUrl: 'not a url'),
      throwsA(isA<NewsFeedException>()),
    );
  });
}
