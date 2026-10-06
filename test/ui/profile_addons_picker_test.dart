// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/addon_dependencies.dart';
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
  AddonDependencySelection? selection,
});

typedef _RemoveCall = ({String addonId, String profileId});

class _SpyAddonsController extends AddonsController {
  _SpyAddonsController({
    required super.database,
    required super.installer,
    required super.paths,
    required super.catalog,
  });

  final installs = <_InstallCall>[];
  final removes = <_RemoveCall>[];
  List<String> dependents = const [];
  AppError? requirementsFailure;

  @override
  List<String> dependentsOf(String profileId, String addonId) => dependents;

  @override
  Future<Result<void>> install({
    required String addonId,
    required String branchRef,
    required String profileId,
    AddonDependencySelection? selection,
    AddonDependencyHandler? onDependencies,
  }) async {
    installs.add((
      addonId: addonId,
      branchRef: branchRef,
      profileId: profileId,
      selection: selection,
    ));
    final failure = requirementsFailure;
    if (failure != null) {
      requirementsErrors.value = {
        ...requirementsErrors.value,
        requirementErrorKey(profileId, addonId): failure,
      };
    }
    return const Ok(null);
  }

  @override
  Future<Result<void>> remove({required String addonId, required String profileId}) async {
    removes.add((addonId: addonId, profileId: profileId));
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
    expect(addons.installs.single.selection, isNull);
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

  testWidgets('removes an installed addon after confirmation', (tester) async {
    await db.installedAddonsDao.save(
      sampleAddon(profileId: profile.id, addonId: 'A2plus', displayName: 'A2plus'),
    );
    await openAddonsTab(tester);

    await tester.tap(find.byTooltip('Remove'));
    await settle(tester);
    expect(find.text('Remove this addon?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await settle(tester);
    expect(addons.removes, isEmpty);

    await tester.tap(find.byTooltip('Remove'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await settle(tester);

    expect(addons.removes, hasLength(1));
    expect(addons.removes.single.addonId, 'A2plus');
    expect(addons.removes.single.profileId, profile.id);
    expect(find.text('Addon removed'), findsOneWidget);
  });

  testWidgets('warns when other installed addons depend on the removed addon', (tester) async {
    await db.installedAddonsDao.save(
      sampleAddon(profileId: profile.id, addonId: 'A2plus', displayName: 'A2plus'),
    );
    addons.dependents = ['Beltrami'];
    await openAddonsTab(tester);

    await tester.tap(find.byTooltip('Remove'));
    await settle(tester);

    expect(find.textContaining('Required by: Beltrami'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await settle(tester);
    expect(addons.removes, isEmpty);
  });

  testWidgets('requirements consent gates the install', (tester) async {
    await openAddonsTab(tester);
    await openPicker(tester);
    await tapInstall(tester, 'RequiresPy');

    expect(find.text('Required Python packages'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
    await settle(tester);
    expect(addons.installs, isEmpty);

    await openPicker(tester);
    await tapInstall(tester, 'RequiresPy');
    await tester.tap(find.text('Addon only'));
    await settle(tester);

    expect(addons.installs, hasLength(1));
    expect(addons.installs.single.selection?.installRequired, isFalse);
  });

  testWidgets('shows a failed dependency install on the installed addon row', (tester) async {
    await db.installedAddonsDao.save(
      sampleAddon(profileId: profile.id, addonId: 'A2plus', displayName: 'A2plus'),
    );
    addons.requirementsErrors.value = {
      requirementErrorKey(profile.id, 'A2plus'): const AppError(
        message: 'the ssl module is unavailable',
      ),
    };
    await openAddonsTab(tester);

    expect(find.textContaining('Python packages failed'), findsOneWidget);
    expect(find.textContaining('the ssl module is unavailable'), findsOneWidget);
  });

  testWidgets('reports a dependency failure after the addon is installed', (tester) async {
    addons.requirementsFailure = const AppError(message: 'the ssl module is unavailable');
    await openAddonsTab(tester);
    await openPicker(tester);
    await tapInstall(tester, 'A2plus');

    expect(find.textContaining('Addon installed'), findsOneWidget);
    expect(find.textContaining('Python packages failed'), findsOneWidget);
    expect(find.textContaining('the ssl module is unavailable'), findsOneWidget);
  });
}
