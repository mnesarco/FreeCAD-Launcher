// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/profiles/profiles_view.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_addon_catalog.dart';
import '../helpers/fake_download.dart';

Addon _addon(
  String id, {
  required String description,
  List<String> tags = const [],
  String requirements = '',
}) {
  return Addon(
    id: id,
    branches: [
      AddonBranch(
        gitRef: 'master',
        displayName: 'master',
        repositoryUrl: 'https://example.invalid/$id',
        zipUrl: 'https://example.invalid/$id.zip',
        curated: true,
        sparseCache: false,
        metadata: AddonMetadata(
          name: id,
          description: description,
          version: '1.0.0',
          license: 'MIT',
          minPython: '3.10',
          tags: tags,
          people: const [],
          content: const {AddonContentType.workbench},
          requirements: requirements,
        ),
      ),
    ],
  );
}

typedef _InstallCall = ({
  String addonId,
  String branchRef,
  String profileId,
  bool installRequirements,
});

class _SpyAddonsController extends AddonsController {
  _SpyAddonsController({
    required super.database,
    required super.installer,
    required super.paths,
    required super.catalog,
  });

  final installs = <_InstallCall>[];

  @override
  Future<Result<void>> install({
    required String addonId,
    required String branchRef,
    required String profileId,
    bool installRequirements = false,
  }) async {
    installs.add((
      addonId: addonId,
      branchRef: branchRef,
      profileId: profileId,
      installRequirements: installRequirements,
    ));
    return const Ok(null);
  }
}

void main() {
  late Directory tempDirectory;
  late AppDatabase db;
  late FakeAddonCatalog catalog;
  late _SpyAddonsController addons;
  late AppServices services;
  late Profile profile;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_profile_addons');
    final paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    db = AppDatabase.inMemory();
    catalog = FakeAddonCatalog(
      downloader: Downloader(
        source: FakeDownloadSource(),
        cacheDirectory: p.join(tempDirectory.path, 'addons'),
      ),
      dao: db.catalogCacheDao,
      cacheDirectory: p.join(tempDirectory.path, 'addons'),
    );
    catalog.result = AddonCatalogResult(
      addons: [
        _addon('A2plus', description: 'Assembly workbench', tags: ['assembly']),
        _addon('MacroTool', description: 'Macro helper', tags: ['utility']),
        _addon('RequiresPy', description: 'Needs Python deps', requirements: 'six\nrequests'),
      ],
      freshness: CatalogFreshness.fresh,
    );
    catalog.cached = catalog.result!.addons;
    addons = _SpyAddonsController(
      database: db,
      installer: AddonInstaller(
        downloader: Downloader(
          source: FakeDownloadSource(),
          cacheDirectory: p.join(tempDirectory.path, 'downloads'),
        ),
      ),
      paths: paths,
      catalog: catalog,
    );
    services = AppServices(paths: paths, database: db, addonsController: addons);
    await db.buildsDao.save(sampleBuild());
    await services.profilesRepository.create(name: 'Dev', buildId: 'build-1');
    profile = (await services.profilesRepository.getByName('Dev'))!;
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

  Future<void> openAddonsTab(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ProfilesView()),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Dev'));
    await settle(tester);
    await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text('Addons')));
    await settle(tester);
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.text('Add addon'));
    await settle(tester);
  }

  Future<void> tapInstall(WidgetTester tester, String addonName) async {
    await tester.tap(
      find.descendant(of: find.widgetWithText(ListTile, addonName), matching: find.text('Install')),
    );
    await settle(tester);
  }

  testWidgets('adds a catalog addon to the profile', (tester) async {
    await openAddonsTab(tester);

    expect(find.text('No addons installed'), findsOneWidget);
    await openPicker(tester);

    expect(find.text('Add addon to profile'), findsOneWidget);
    expect(find.text('A2plus'), findsOneWidget);
    expect(find.text('MacroTool'), findsOneWidget);

    await tapInstall(tester, 'A2plus');

    expect(addons.installs, hasLength(1));
    expect(addons.installs.single.addonId, 'A2plus');
    expect(addons.installs.single.branchRef, 'master');
    expect(addons.installs.single.profileId, profile.id);
    expect(addons.installs.single.installRequirements, isFalse);
    expect(find.text('Addon installed'), findsOneWidget);
  });

  testWidgets('search filters by text and #tag', (tester) async {
    await openAddonsTab(tester);
    await openPicker(tester);

    await tester.enterText(find.byType(TextField).last, 'assembly');
    await settle(tester);
    expect(find.text('A2plus'), findsOneWidget);
    expect(find.text('MacroTool'), findsNothing);
    expect(find.text('RequiresPy'), findsNothing);

    await tester.enterText(find.byType(TextField).last, '#utility');
    await settle(tester);
    expect(find.text('MacroTool'), findsOneWidget);
    expect(find.text('A2plus'), findsNothing);
  });

  testWidgets('marks addons already installed in the profile', (tester) async {
    await db.installedAddonsDao.save(
      sampleAddon(profileId: profile.id, addonId: 'A2plus', displayName: 'A2plus'),
    );
    await openAddonsTab(tester);
    await openPicker(tester);

    final row = find.widgetWithText(ListTile, 'A2plus');
    expect(find.descendant(of: row, matching: find.text('Installed')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('Install')), findsNothing);
  });

  testWidgets('requirements consent gates the install', (tester) async {
    await openAddonsTab(tester);
    await openPicker(tester);
    await tapInstall(tester, 'RequiresPy');

    expect(find.text('Python packages required'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
    await settle(tester);
    expect(addons.installs, isEmpty);

    await openPicker(tester);
    await tapInstall(tester, 'RequiresPy');
    await tester.tap(find.text('Addon only'));
    await settle(tester);

    expect(addons.installs, hasLength(1));
    expect(addons.installs.single.installRequirements, isFalse);
  });
}
