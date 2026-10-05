// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/catalog/news_feed.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
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
        )..result = const AddonCatalogResult(addons: [], freshness: CatalogFreshness.fresh),
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

  Future<void> pumpHome(
    WidgetTester tester, {
    ValueChanged<String>? onOpenProfile,
    ValueChanged<Profile>? onLaunchProfile,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        AppScope(
          services: services,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: HomeView(onOpenProfile: onOpenProfile, onLaunchProfile: onLaunchProfile),
            ),
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

  Future<void> seedInstalledBuild({String id = 'build-1', String version = '1.1.3'}) async {
    final directory = Directory(p.join(tempDirectory.path, 'builds', id))
      ..createSync(recursive: true);
    final executable = File(p.join(directory.path, 'FreeCAD.AppImage'))..createSync();
    await db.buildsDao.save(sampleBuild(id: id, version: version, localPath: executable.path));
  }

  testWidgets('shows stats, recent profiles, updates and news', (tester) async {
    await seedInstalledBuild();
    await db.profilesDao.save(sampleProfile());
    await db.profilesDao.touchLastUsed('profile-1', DateTime.utc(2026, 9, 20, 11));
    await db.installedAddonsDao.save(sampleAddon(addonId: 'A2plus'));
    await db.macrosDao.save(
      sampleMacro(profileId: 'profile-1', name: 'Camera', fileName: 'Camera.FCMacro'),
    );
    await db.pythonPackagesDao.save(samplePackage(name: 'six'));
    newsSource.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);

    await pumpHome(tester);

    expect(find.text('Recent profiles'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Last used profile'), findsNothing);
    expect(find.text('Everything is up to date'), findsOneWidget);
    expect(find.text('FreeCAD 1.2 released'), findsOneWidget);
    expect(find.text('The 1.2 release brings a new sketcher.'), findsOneWidget);
  });

  testWidgets('shows the brand hero with a live summary and quick actions', (tester) async {
    await seedInstalledBuild();
    await db.profilesDao.save(sampleProfile());
    await db.installedAddonsDao.save(sampleAddon(addonId: 'A2plus'));
    newsSource.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);

    await pumpHome(tester);

    expect(find.text('FreeCAD Launcher'), findsOneWidget);
    expect(find.text('1 profiles · 1 versions · 1 addons'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'New profile'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Check for updates'), findsOneWidget);
  });

  testWidgets('creating a profile opens its detail view', (tester) async {
    await seedInstalledBuild();
    String? opened;
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HomeView(onOpenProfile: (profileId) => opened = profileId)),
        ),
      ),
    );
    await settle(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'New profile'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Fresh');
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await settle(tester);
    await tester.tap(find.textContaining('1.1.3').last);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);

    final profile = await services.profilesRepository.getByName('Fresh');
    expect(profile, isNotNull);
    expect(opened, profile!.id);
  });

  testWidgets('hero shows the tagline on first run', (tester) async {
    newsSource.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);

    await pumpHome(tester);

    expect(
      find.text('Isolated FreeCAD environments, addons and packages in one place.'),
      findsOneWidget,
    );
  });

  testWidgets('hides the recent profiles row when nobody used a profile', (tester) async {
    await seedInstalledBuild();
    await db.profilesDao.save(sampleProfile());
    newsSource.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);

    await pumpHome(tester);

    expect(find.text('Recent profiles'), findsNothing);
    expect(find.text('Default'), findsNothing);
  });

  testWidgets('lists up to five recent profiles, newest first', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await seedInstalledBuild();
    for (var index = 0; index < 6; index++) {
      await db.profilesDao.save(sampleProfile(id: 'profile-$index', name: 'P$index'));
      await db.profilesDao.touchLastUsed('profile-$index', DateTime.utc(2026, 9, 10 + index));
    }
    newsSource.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);

    await pumpHome(tester);

    expect(find.text('Recent profiles'), findsOneWidget);
    expect(find.text('P5'), findsOneWidget);
    expect(find.text('P4'), findsOneWidget);
    expect(find.text('P1'), findsOneWidget);
    expect(find.text('P0'), findsNothing);
    expect(tester.getTopLeft(find.text('P5')).dx, lessThan(tester.getTopLeft(find.text('P4')).dx));
  });

  testWidgets('hides recent profiles whose build is unhealthy', (tester) async {
    await seedInstalledBuild();
    await db.buildsDao.save(
      sampleBuild(id: 'build-missing', version: '1.2.0', status: BuildStatus.missing),
    );
    await db.profilesDao.save(sampleProfile(id: 'healthy', name: 'Healthy'));
    await db.profilesDao.save(
      sampleProfile(id: 'unhealthy', name: 'Unhealthy', buildId: 'build-missing'),
    );
    await db.profilesDao.touchLastUsed('healthy', DateTime.utc(2026, 9, 20));
    await db.profilesDao.touchLastUsed('unhealthy', DateTime.utc(2026, 9, 21));
    newsSource.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);

    await pumpHome(tester);

    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('Unhealthy'), findsNothing);
  });

  testWidgets('shows the running badge on a recent profile', (tester) async {
    await seedInstalledBuild();
    await db.profilesDao.save(sampleProfile());
    await db.profilesDao.touchLastUsed('profile-1', DateTime.utc(2026, 9, 20));
    newsSource.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);

    await pumpHome(tester);
    services.profiles.runningProfiles.value = {'profile-1'};
    await settle(tester);

    expect(find.text('Running'), findsOneWidget);
  });

  testWidgets('tapping a recent profile card launches it', (tester) async {
    await seedInstalledBuild();
    await db.profilesDao.save(sampleProfile());
    await db.profilesDao.touchLastUsed('profile-1', DateTime.utc(2026, 9, 20));
    newsSource.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);
    String? launched;

    await pumpHome(tester, onLaunchProfile: (profile) => launched = profile.id);
    await tester.tap(find.text('Default'));
    await settle(tester);

    expect(launched, 'profile-1');
  });

  testWidgets('the card chevron opens the profile detail', (tester) async {
    await seedInstalledBuild();
    await db.profilesDao.save(sampleProfile());
    await db.profilesDao.touchLastUsed('profile-1', DateTime.utc(2026, 9, 20));
    newsSource.streamFactory = () => Stream.fromIterable([utf8.encode(rss)]);
    String? opened;

    await pumpHome(tester, onOpenProfile: (profileId) => opened = profileId);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await settle(tester);

    expect(opened, 'profile-1');
  });

  testWidgets('shows at most ten news posts', (tester) async {
    await seedInstalledBuild();
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
