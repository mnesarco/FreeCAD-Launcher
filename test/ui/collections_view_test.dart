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

import '../helpers/fake_addon_catalog.dart';
import '../helpers/fake_download.dart';

Addon _addon(String id, {required String description}) {
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
          tags: const [],
          people: const [],
          content: const {AddonContentType.workbench},
          requirements: '',
        ),
      ),
    ],
  );
}

void main() {
  late Directory tempDirectory;
  late AppDatabase db;
  late AppServices services;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_collections_ui');
    final paths = AppPaths(dataRoot: tempDirectory.path);
    db = AppDatabase.inMemory();
    final catalog = FakeAddonCatalog(
      downloader: Downloader(
        source: FakeDownloadSource(),
        cacheDirectory: p.join(tempDirectory.path, 'addons'),
      ),
      dao: db.catalogCacheDao,
      cacheDirectory: p.join(tempDirectory.path, 'addons'),
    );
    catalog.result = AddonCatalogResult(
      addons: [_addon('A2plus', description: 'Assembly workbench')],
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

  Future<void> pumpCollections(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AddonsView()),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Collections'));
    await settle(tester);
  }

  testWidgets('creates a collection and shows it in the list', (tester) async {
    await pumpCollections(tester);

    expect(find.text('No collections yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'New collection').first);
    await settle(tester);
    expect(find.text('New collection'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'Essentials');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    expect(find.text('Essentials'), findsOneWidget);
    expect(find.text('Collection created'), findsOneWidget);
    expect(find.textContaining('0 addon'), findsOneWidget);
    expect(find.text('No addons in this collection yet.'), findsOneWidget);
  });

  testWidgets('rejects a duplicate name in the dialog', (tester) async {
    await services.bundles.create(name: 'Essentials');
    await pumpCollections(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'New collection').first);
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'essentials');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    expect(find.text('A collection with this name already exists.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('opens a collection, adds and removes an addon, then deletes it', (tester) async {
    await services.bundles.create(name: 'Base');
    await pumpCollections(tester);

    await tester.tap(find.text('Base'));
    await settle(tester);
    expect(find.text('No addons in this collection yet.'), findsOneWidget);

    await tester.tap(find.text('Add addon'));
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Add addon'),
      ),
    );
    await settle(tester);

    expect(find.text('A2plus'), findsOneWidget);
    expect(find.text('master'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await settle(tester);
    expect(find.text('No addons in this collection yet.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);

    expect(find.text('No collections yet'), findsOneWidget);
    expect(find.text('Collection deleted'), findsOneWidget);
  });
}
