// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/macros_controller.dart';
import 'package:freecad_launcher/ui/macros/installed_macros.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_download.dart';

MacroCatalogEntry _entry(String name, String comment) => MacroCatalogEntry(
  name: name,
  code: 'print(1)',
  comment: comment,
  onGit: true,
  srcFilename: 'FreeCAD-macros/Utility/$name.FCMacro',
);

typedef _InstallCall = ({String name, String profileId});

class _SpyMacrosController extends MacrosController {
  _SpyMacrosController({required super.database, required super.catalog, required super.paths});

  final installs = <_InstallCall>[];

  @override
  Future<Result<void>> install({required String name, required String profileId}) async {
    installs.add((name: name, profileId: profileId));
    return const Ok(null);
  }
}

void main() {
  late Directory tempDirectory;
  late AppDatabase db;
  late _SpyMacrosController macros;
  late AppServices services;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_profile_macros');
    final paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    db = AppDatabase.inMemory();
    macros = _SpyMacrosController(
      database: db,
      catalog: MacroCatalog(
        downloader: Downloader(source: FakeDownloadSource(), cacheDirectory: paths.macrosCacheDir),
        dao: db.catalogCacheDao,
        cacheDirectory: paths.macrosCacheDir,
      ),
      paths: paths,
    );
    macros.loaded.value = true;
    macros.macros.value = [_entry('Foto', 'Camera helper'), _entry('TreeHelper', 'BIM tools')];
    services = AppServices(paths: paths, database: db, macrosController: macros);
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
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

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: InstalledMacrosList(profileId: 'profile-1')),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('adds a catalog macro to the profile', (tester) async {
    await pumpList(tester);

    expect(find.text('No macros'), findsOneWidget);
    await tester.tap(find.text('Add macro'));
    await settle(tester);

    expect(find.text('Add macro to profile'), findsOneWidget);
    expect(find.text('Foto'), findsOneWidget);
    expect(find.text('TreeHelper'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'camera');
    await settle(tester);
    expect(find.text('Foto'), findsOneWidget);
    expect(find.text('TreeHelper'), findsNothing);

    await tester.tap(
      find.descendant(of: find.widgetWithText(ListTile, 'Foto'), matching: find.text('Install')),
    );
    await settle(tester);

    expect(macros.installs, hasLength(1));
    expect(macros.installs.single.name, 'Foto');
    expect(macros.installs.single.profileId, 'profile-1');
    expect(find.text('Macro installed'), findsOneWidget);
  });

  testWidgets('marks macros already installed in the profile', (tester) async {
    final macrosDir = Directory(services.paths.profilePaths('profile-1').macros)
      ..createSync(recursive: true);
    File(p.join(macrosDir.path, 'Foto.FCMacro')).writeAsStringSync('print(1)');
    await db.macrosDao.save(
      sampleMacro(profileId: 'profile-1', name: 'Foto', fileName: 'Foto.FCMacro'),
    );

    await pumpList(tester);

    expect(find.text('Add macro'), findsOneWidget);
    await tester.tap(find.text('Add macro'));
    await settle(tester);

    final installedRow = find.widgetWithText(ListTile, 'Foto');
    expect(find.descendant(of: installedRow, matching: find.text('Installed')), findsOneWidget);
    expect(find.descendant(of: installedRow, matching: find.text('Install')), findsNothing);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'TreeHelper'),
        matching: find.text('Install'),
      ),
      findsOneWidget,
    );
  });
}
