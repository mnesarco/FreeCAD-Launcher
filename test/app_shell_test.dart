// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/app.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/catalog/news_feed.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/macros_controller.dart';
import 'package:freecad_launcher/state/news_controller.dart';
import 'package:freecad_launcher/state/app_services.dart';

import 'helpers/fake_addon_catalog.dart';
import 'helpers/fake_download.dart';

void main() {
  late AppDatabase database;
  late AppServices services;
  late FakeAddonCatalog fakeCatalog;

  setUp(() {
    database = AppDatabase.inMemory();
    fakeCatalog = FakeAddonCatalog(
      downloader: Downloader(
        source: FakeDownloadSource(),
        cacheDirectory: '/tmp/freecad_launcher_test/addons',
      ),
      dao: database.catalogCacheDao,
      cacheDirectory: '/tmp/freecad_launcher_test/addons',
    )..result = const AddonCatalogResult(
      addons: [],
      freshness: CatalogFreshness.fresh,
    );
    services = AppServices(
      paths: AppPaths(dataRoot: '/tmp/freecad_launcher_test'),
      database: database,
      addonsController: AddonsController(
        database: database,
        installer: AddonInstaller(
          downloader: Downloader(
            source: FakeDownloadSource(),
            cacheDirectory: '/tmp/freecad_launcher_test/downloads',
          ),
        ),
        paths: AppPaths(dataRoot: '/tmp/freecad_launcher_test'),
        catalog: fakeCatalog,
      ),
      macrosController: MacrosController(
        database: database,
        catalog: MacroCatalog(
          downloader: Downloader(
            source: FakeDownloadSource(),
            cacheDirectory: '/tmp/freecad_launcher_test/macros',
          ),
          dao: database.catalogCacheDao,
          cacheDirectory: '/tmp/freecad_launcher_test/macros',
        ),
        paths: AppPaths(dataRoot: '/tmp/freecad_launcher_test'),
      )..loaded.value = true,
      newsController: NewsController(
        feed: NewsFeed(
          downloader: Downloader(
            source: FakeDownloadSource()..error = const DownloadException('offline'),
            cacheDirectory: '/tmp/freecad_launcher_test/downloads',
          ),
          dao: database.catalogCacheDao,
          cacheDirectory: '/tmp/freecad_launcher_test/news',
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

  testWidgets('shell shows all navigation destinations', (tester) async {
    await pumpApp(tester);

    for (final label in ['Home', 'Profiles', 'Versions', 'Addons', 'Macros', 'Settings']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('status bar shows active jobs and opens the jobs dialog', (tester) async {
    final gate = Completer<void>();
    final run = services.jobs.run<void>(
      kind: JobKind.install,
      label: 'Install FreeCAD 1.1.3',
      task: (context) async {
        context.report(fraction: 0.5, detail: 'Downloading');
        await gate.future;
      },
    );

    await pumpApp(tester);

    expect(find.textContaining('Install FreeCAD 1.1.3'), findsOneWidget);    await tester.tap(find.textContaining('Install FreeCAD 1.1.3'));
    await tester.pumpAndSettle();

    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Downloading'), findsOneWidget);

    gate.complete();
    await run;
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('navigating shows each section empty state', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome to FreeCAD Launcher'), findsOneWidget);

    Future<void> open(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open('Profiles');
    expect(find.text('No profiles yet'), findsOneWidget);

    await open('Versions');
    expect(find.text('No FreeCAD versions installed'), findsOneWidget);

    await open('Addons');
    expect(find.text('Catalog is empty'), findsOneWidget);

    await open('Macros');
    expect(find.text('No macros'), findsOneWidget);

    await open('Settings');
    expect(find.text('Data directory:'), findsOneWidget);
    expect(find.text('/tmp/freecad_launcher_test'), findsOneWidget);
  });

  testWidgets('keyboard shortcuts switch sections and act on the active one', (tester) async {
    await pumpApp(tester);

    await sendShortcut(tester, LogicalKeyboardKey.digit4);
    expect(find.text('Catalog is empty'), findsOneWidget);

    final before = fakeCatalog.loads;
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();
    expect(fakeCatalog.loads, greaterThan(before));

    await sendShortcut(tester, LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode?.hasFocus, isTrue);

    await sendShortcut(tester, LogicalKeyboardKey.digit1);
    expect(find.text('Welcome to FreeCAD Launcher'), findsOneWidget);

    await sendShortcut(tester, LogicalKeyboardKey.digit6);
    expect(find.text('Data directory:'), findsOneWidget);
  });

  testWidgets('Ctrl+N opens the create-profile dialog', (tester) async {
    await pumpApp(tester);

    await sendShortcut(tester, LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();

    expect(find.text('Create profile'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Create profile'), findsNothing);
  });
}

Future<void> sendShortcut(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}
