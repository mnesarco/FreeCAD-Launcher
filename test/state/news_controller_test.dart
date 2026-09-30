// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/news_feed.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/state/news_controller.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_download.dart';
import '../helpers/test_database.dart';

void main() {
  const rss = '''
<?xml version="1.0"?>
<rss version="2.0"><channel>
  <item><title>Hello</title><link>https://blog.freecad.org/hello</link></item>
</channel></rss>
''';

  late Directory tempDirectory;
  late AppDatabase db;
  late FakeDownloadSource source;
  late NewsController controller;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_news_controller');
    db = createTestDatabase();
    source = FakeDownloadSource();
    controller = NewsController(
      feed: NewsFeed(
        downloader: Downloader(
          source: source,
          cacheDirectory: p.join(tempDirectory.path, 'downloads'),
        ),
        dao: db.catalogCacheDao,
        cacheDirectory: p.join(tempDirectory.path, 'news'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('loads items and clears errors', () async {
    source.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);

    await controller.load('https://example.invalid/feed.rss');

    expect(controller.items.value.single.title, 'Hello');
    expect(controller.loaded.value, isTrue);
    expect(controller.loading.value, isFalse);
    expect(controller.error.value, isNull);
    expect(controller.stale.value, isFalse);
  });

  test('reports hard failures and recovers on retry', () async {
    source.error = const DownloadException('offline');

    await controller.load('https://example.invalid/feed.rss');

    expect(controller.items.value, isEmpty);
    expect(controller.error.value, isNotNull);
    expect(controller.loading.value, isFalse);

    source.error = null;
    source.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);
    await controller.retry('https://example.invalid/feed.rss');

    expect(controller.items.value.single.title, 'Hello');
    expect(controller.error.value, isNull);
  });
}
