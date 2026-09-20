import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:freecad_launcher/ui/addons/addons_view.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_addon_catalog.dart';
import '../helpers/fake_download.dart';

Addon _addon(
  String id, {
  required String description,
  List<String> tags = const [],
  Set<AddonContentType> content = const {AddonContentType.workbench},
  List<(String, String)> extraBranches = const [],
}) {
  AddonBranch branch(String gitRef, String displayName) {
    return AddonBranch(
      gitRef: gitRef,
      displayName: displayName,
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
        content: content,
        requirements: '',
      ),
    );
  }

  return Addon(
    id: id,
    branches: [
      branch('master', 'master'),
      for (final (gitRef, displayName) in extraBranches)
        branch(gitRef, displayName),
    ],
  );
}

void main() {
  late Directory tempDirectory;
  late AppDatabase db;
  late AppServices services;
  late FakeAddonCatalog catalog;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_addons_ui');
    final paths = AppPaths(dataRoot: tempDirectory.path);
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
        _addon(
          'MacroTool',
          description: 'Macro helper',
          tags: ['utility'],
          content: {AddonContentType.macro},
        ),
      ],
      freshness: CatalogFreshness.fresh,
    );
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
        catalog: catalog,
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

  Future<void> pumpAddons(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppScope(
          services: services,
          child: const Scaffold(body: AddonsView()),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('renders the catalog grid and filters by search', (tester) async {
    await pumpAddons(tester);

    expect(find.text('A2plus'), findsOneWidget);
    expect(find.text('MacroTool'), findsOneWidget);
    expect(catalog.loads, 1);

    await tester.enterText(find.byType(TextField), 'assembly');
    await settle(tester);

    expect(find.text('A2plus'), findsOneWidget);
    expect(find.text('MacroTool'), findsNothing);
  });

  testWidgets('opens the addon detail with branches', (tester) async {
    await pumpAddons(tester);

    await tester.tap(find.text('A2plus'));
    await settle(tester);

    expect(find.text('Assembly workbench'), findsOneWidget);
    expect(find.text('Branches'), findsOneWidget);
    expect(find.text('master'), findsWidgets);
    expect(find.text('MIT'), findsOneWidget);
    expect(find.text('Create a profile first to install addons.'), findsOneWidget);
  });

  testWidgets('selecting a branch updates the radio group immediately', (tester) async {
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    catalog.result = AddonCatalogResult(
      addons: [
        _addon(
          'A2plus',
          description: 'Assembly workbench',
          extraBranches: [('dev', 'development')],
        ),
      ],
      freshness: CatalogFreshness.fresh,
    );
    await pumpAddons(tester);

    await tester.tap(find.text('A2plus'));
    await settle(tester);

    RadioGroup<String> group() =>
        tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>));
    expect(group().groupValue, 'master');

    await tester.ensureVisible(find.text('development'));
    await settle(tester);
    await tester.tap(find.text('development'));
    await settle(tester);

    expect(group().groupValue, 'dev');
    expect(services.addons.selectedBranches.value['A2plus'], 'dev');
  });

  testWidgets('keeps the search query after opening a detail and going back', (tester) async {
    await pumpAddons(tester);

    await tester.enterText(find.byType(TextField), 'assembly');
    await settle(tester);
    expect(find.text('A2plus'), findsOneWidget);
    expect(find.text('MacroTool'), findsNothing);

    await tester.tap(find.text('A2plus'));
    await settle(tester);
    expect(find.text('Branches'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await settle(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'assembly');
    expect(find.text('A2plus'), findsOneWidget);
    expect(find.text('MacroTool'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await settle(tester);
    expect(find.text('MacroTool'), findsOneWidget);
  });

  group('with an installed addon', () {
    setUp(() async {
      await db.buildsDao.save(sampleBuild());
      final profile = (await services.profilesRepository.create(
        name: 'Dev',
        buildId: 'build-1',
      )).valueOrNull!;
      await db.installedAddonsDao.save(
        sampleAddon(
          profileId: profile.id,
          addonId: 'A2plus',
          displayName: 'A2plus',
          version: '0.9.0',
        ),
      );
    });

    testWidgets('shows Update and Remove actions for an outdated addon', (tester) async {
      await pumpAddons(tester);
      await tester.tap(find.text('A2plus'));
      await settle(tester);

      await tester.scrollUntilVisible(
        find.text('Branches'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await settle(tester);

      expect(find.text('Update'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('A newer version is available in the catalog.'), findsOneWidget);
    });
  });

  testWidgets('multi-select filter menu toggles several filters', (tester) async {
    Future<void> tapMenuItem(String label) async {
      final item = find.ancestor(
        of: find.text(label),
        matching: find.byType(MenuItemButton),
      );
      await tester.tap(item.hitTestable().first);
      await settle(tester);
    }

    Future<void> closeMenu() async {
      await tester.tap(find.byType(TextField));
      await settle(tester);
    }

    await pumpAddons(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await settle(tester);
    await tapMenuItem('Workbench');
    await tapMenuItem('Macro');
    await closeMenu();

    expect(find.text('A2plus'), findsOneWidget);
    expect(find.text('MacroTool'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await settle(tester);
    await tapMenuItem('Workbench');
    await closeMenu();

    expect(find.text('A2plus'), findsNothing);
    expect(find.text('MacroTool'), findsOneWidget);
  });
}
