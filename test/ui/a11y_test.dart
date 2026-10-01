// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/app.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/catalog/news_feed.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart'
    show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/macros_controller.dart';
import 'package:freecad_launcher/state/news_controller.dart';

import '../helpers/fake_addon_catalog.dart';
import '../helpers/fake_download.dart';

void main() {
  late AppDatabase database;
  late AppServices services;

  setUp(() {
    database = AppDatabase.inMemory();
    final paths = AppPaths(dataRoot: '/tmp/freecad_launcher_a11y');
    services = AppServices(
      paths: paths,
      database: database,
      addonsController: AddonsController(
        database: database,
        installer: AddonInstaller(
          downloader: Downloader(
            source: FakeDownloadSource(),
            cacheDirectory: '/tmp/freecad_launcher_a11y/downloads',
          ),
        ),
        paths: paths,
        catalog: FakeAddonCatalog(
          downloader: Downloader(
            source: FakeDownloadSource(),
            cacheDirectory: '/tmp/freecad_launcher_a11y/addons',
          ),
          dao: database.catalogCacheDao,
          cacheDirectory: '/tmp/freecad_launcher_a11y/addons',
        )..result = const AddonCatalogResult(
          addons: [],
          freshness: CatalogFreshness.fresh,
        ),
      ),
      macrosController: MacrosController(
        database: database,
        catalog: MacroCatalog(
          downloader: Downloader(
            source: FakeDownloadSource(),
            cacheDirectory: '/tmp/freecad_launcher_a11y/macros',
          ),
          dao: database.catalogCacheDao,
          cacheDirectory: '/tmp/freecad_launcher_a11y/macros',
        ),
        paths: paths,
      )..loaded.value = true,
      newsController: NewsController(
        feed: NewsFeed(
          downloader: Downloader(
            source: FakeDownloadSource()..error = const DownloadException('offline'),
            cacheDirectory: '/tmp/freecad_launcher_a11y/downloads',
          ),
          dao: database.catalogCacheDao,
          cacheDirectory: '/tmp/freecad_launcher_a11y/news',
        ),
      ),
    );
  });

  tearDown(() => services.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(FreeCadLauncherApp(services: services));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  Future<void> checkSection(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  testWidgets('screens pass the a11y guidelines', (tester) async {
    await pumpApp(tester);
    for (final label in [
      'Home',
      'Profiles',
      'Versions',
      'Addons',
      'Macros',
      'Settings',
    ]) {
      await checkSection(tester, label);
    }
  });
}
