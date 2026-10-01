// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/catalog/news_feed.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart'
    show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/macros_controller.dart';
import 'package:freecad_launcher/state/news_controller.dart';
import 'package:freecad_launcher/ui/home/home_view.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_addon_catalog.dart';
import '../helpers/fake_download.dart';
import '../helpers/test_database.dart';

void main() {
  const rss = '''
<?xml version="1.0"?>
<rss version="2.0"><channel>
  <item>
    <title>FreeCAD 1.2 released</title>
    <link>https://blog.freecad.org/1-2</link>
    <pubDate>Tue, 02 Sep 2025 10:00:00 +0000</pubDate>
    <description>&lt;p&gt;The &lt;b&gt;1.2&lt;/b&gt; release brings a new sketcher.&lt;/p&gt;</description>
  </item>
</channel></rss>
''';

  late Directory tempDirectory;
  late AppDatabase db;
  late FakeDownloadSource newsSource;
  late AppServices services;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_home_ui');
    final paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    db = createTestDatabase();
    newsSource = FakeDownloadSource();
    services = AppServices(
      paths: paths,
      database: db,
      addonsController: AddonsController(
        database: db,
        installer: AddonInstaller(
          downloader: Downloader(
            source: FakeDownloadSource(),
            cacheDirectory: p.join(tempDirectory.path, 'downloads'),
          ),
        ),
        paths: paths,
        catalog: FakeAddonCatalog(
          downloader: Downloader(
            source: FakeDownloadSource(),
            cacheDirectory: p.join(tempDirectory.path, 'addons'),
          ),
          dao: db.catalogCacheDao,
          cacheDirectory: p.join(tempDirectory.path, 'addons'),
        )..result = const AddonCatalogResult(
          addons: [],
          freshness: CatalogFreshness.fresh,
        ),
      ),
      macrosController: MacrosController(
        database: db,
        catalog: MacroCatalog(
          downloader: Downloader(
            source: FakeDownloadSource(),
            cacheDirectory: p.join(tempDirectory.path, 'macros'),
          ),
          dao: db.catalogCacheDao,
          cacheDirectory: p.join(tempDirectory.path, 'macros'),
        ),
        paths: paths,
      )..loaded.value = true,
      newsController: NewsController(
        feed: NewsFeed(
          downloader: Downloader(
            source: newsSource,
            cacheDirectory: p.join(tempDirectory.path, 'downloads'),
          ),
          dao: db.catalogCacheDao,
          cacheDirectory: p.join(tempDirectory.path, 'news'),
        ),
      ),
    );
  });

  tearDown(() async {
    await services.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        AppScope(
          services: services,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: HomeView()),
          ),
        ),
      );
      for (var attempt = 0; attempt < 50; attempt++) {
        if (services.news.loaded.value) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await settle(tester);
  }

  testWidgets('shows stats, last used profile, updates and news', (tester) async {
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    await db.profilesDao.touchLastUsed('profile-1', DateTime.utc(2026, 9, 20, 11));
    await db.installedAddonsDao.save(sampleAddon(addonId: 'A2plus'));
    await db.macrosDao.save(
      sampleMacro(profileId: 'profile-1', name: 'Camera', fileName: 'Camera.FCMacro'),
    );
    await db.pythonPackagesDao.save(samplePackage(name: 'six'));
    newsSource.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);

    await pumpHome(tester);

    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Versions'), findsOneWidget);
    expect(find.text('Profiles'), findsOneWidget);
    expect(find.text('Addons'), findsOneWidget);
    expect(find.text('Macros'), findsOneWidget);
    expect(find.text('Python packages'), findsOneWidget);
    expect(find.text('Last used profile'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Launch'), findsOneWidget);
    expect(find.text('Everything is up to date'), findsOneWidget);
    expect(find.text('FreeCAD 1.2 released'), findsOneWidget);
    expect(find.text('The 1.2 release brings a new sketcher.'), findsOneWidget);
  });

  testWidgets('shows at most ten news posts', (tester) async {
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    final items = [
      for (var index = 0; index < 12; index++)
        '<item><title>Post $index</title>'
            '<link>https://blog.freecad.org/$index</link>'
            '<pubDate>Tue, ${(index + 1).toString().padLeft(2, '0')} Sep 2025 10:00:00 +0000</pubDate></item>',
    ].join();
    newsSource.streamFactory = () => Stream.fromIterable([
      utf8.encode('<?xml version="1.0"?><rss version="2.0"><channel>$items</channel></rss>'),
    ]);

    await pumpHome(tester);

    expect(find.text('Post 11'), findsOneWidget);
    expect(find.text('Post 2'), findsOneWidget);
    expect(find.text('Post 1'), findsNothing);
    expect(find.text('Post 0'), findsNothing);
  });

  testWidgets('first run shows the getting-started checklist', (tester) async {
    newsSource.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);

    await pumpHome(tester);

    expect(find.text('Welcome to FreeCAD Launcher'), findsOneWidget);
    expect(find.text('Add a FreeCAD version'), findsOneWidget);
    expect(find.text('Create a profile'), findsOneWidget);
    expect(find.text('Install addons'), findsOneWidget);
  });

  testWidgets('news failures show an inline error with retry', (tester) async {
    newsSource.error = const DownloadException('offline');

    await pumpHome(tester);

    await tester.scrollUntilVisible(
      find.text('Could not load the news feed.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Could not load the news feed.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
