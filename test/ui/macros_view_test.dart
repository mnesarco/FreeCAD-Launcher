// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/domain/macros/macro_types.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/macros_controller.dart';
import 'package:freecad_launcher/ui/macros/macros_view.dart';
import 'package:path/path.dart' as p;
import '../data/test_fixtures.dart';
import '../helpers/fake_download.dart';

MacroCatalogEntry _entry(String name, String comment) {
  return MacroCatalogEntry(
    name: name,
    code: 'print(1)',
    comment: comment,
    onGit: true,
    srcFilename: 'FreeCAD-macros/Utility/$name.FCMacro',
  );
}

void main() {
  late Directory tempDirectory;
  late AppDatabase db;
  late AppServices services;
  late MacrosController controller;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_macros_ui');
    final paths = AppPaths(dataRoot: tempDirectory.path);
    db = AppDatabase.inMemory();
    controller = MacrosController(
      database: db,
      catalog: MacroCatalog(
        downloader: Downloader(
          source: FakeDownloadSource(),
          cacheDirectory: paths.macrosCacheDir,
        ),
        dao: db.catalogCacheDao,
        cacheDirectory: paths.macrosCacheDir,
      ),
      paths: paths,
    );
    controller.loaded.value = true;
    controller.macros.value = [
      _entry('Foto', 'Camera helper'),
      _entry('TreeHelper', 'BIM tools'),
    ];
    services = AppServices(paths: paths, database: db, macrosController: controller);
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

  Future<void> pumpMacros(WidgetTester tester, {bool catalog = false}) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: MacrosView()),
        ),
      ),
    );
    await settle(tester);
    if (catalog) {
      await tester.tap(find.text('Catalog'));
      await settle(tester);
    }
  }

  testWidgets('renders the catalog and filters by search', (tester) async {
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    await pumpMacros(tester, catalog: true);

    expect(find.text('Foto'), findsOneWidget);
    expect(find.text('TreeHelper'), findsOneWidget);
    expect(find.textContaining('Unknown license'), findsNWidgets(2));
    expect(find.text('Install'), findsNWidgets(2));

    await tester.tap(find.text('Install').first);
    await settle(tester);
    expect(find.text('Select the target profile'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'camera');
    await settle(tester);

    expect(find.text('Foto'), findsOneWidget);
    expect(find.text('TreeHelper'), findsNothing);
  });

  testWidgets('scrolls the profile list when there are many profiles', (tester) async {
    await db.buildsDao.save(sampleBuild());
    for (var index = 0; index < 30; index++) {
      await db.profilesDao.save(
        sampleProfile(id: 'profile-$index', name: 'Profile $index'),
      );
    }
    await pumpMacros(tester, catalog: true);

    await tester.tap(find.text('Install').first);
    await settle(tester);

    expect(find.text('Profile 0').hitTestable(), findsOneWidget);
    expect(find.text('Profile 29').hitTestable(), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Profile 29'),
      80,
      scrollable: find
          .descendant(of: find.byType(AlertDialog), matching: find.byType(Scrollable))
          .first,
    );
    expect(find.text('Profile 29').hitTestable(), findsOneWidget);
  });

  testWidgets('shows the installed badge for an installed macro', (tester) async {
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    await db.macrosDao.save(
      sampleMacro(
        profileId: 'profile-1',
        name: 'Foto',
        fileName: 'Foto.FCMacro',
        source: MacroSource.catalog,
      ),
    );
    File(
      p.join(tempDirectory.path, 'profiles', 'profile-1', 'Macros', 'Foto.FCMacro'),
    ).createSync(recursive: true);
    await pumpMacros(tester);

    expect(find.text('Foto'), findsOneWidget);

    await tester.tap(find.text('Catalog'));
    await settle(tester);
    expect(find.textContaining('Installed in 1 profile'), findsOneWidget);
    expect(find.text('Install'), findsNWidgets(2));

    await tester.tap(find.text('Install').first);
    await settle(tester);
    expect(find.text('Select the target profile'), findsOneWidget);
    final installButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Install'),
      ),
    );
    expect(installButton.onPressed, isNull);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'camera');
    await settle(tester);
    expect(find.textContaining('Installed in 1 profile'), findsOneWidget);
  });
}
