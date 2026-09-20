import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart'
    show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/builds_controller.dart';
import 'package:freecad_launcher/ui/updates/updates_status_chip.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_addon_catalog.dart';
import '../helpers/fake_download.dart';
import '../helpers/fake_releases.dart';

Addon _addon(String id, {required String version, DateTime? lastUpdateTime}) {
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
        lastUpdateTime: lastUpdateTime,
        metadata: AddonMetadata(
          name: id,
          description: '',
          version: version,
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

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_updates_ui');
    final paths = AppPaths(dataRoot: tempDirectory.path);
    db = AppDatabase.inMemory();
    final downloadSource = FakeDownloadSource();
    final catalog = FakeAddonCatalog(
      downloader: Downloader(
        source: downloadSource,
        cacheDirectory: p.join(tempDirectory.path, 'addons'),
      ),
      dao: db.catalogCacheDao,
      cacheDirectory: p.join(tempDirectory.path, 'addons'),
    );
    catalog.result = AddonCatalogResult(
      addons: [
        _addon(
          'A2plus',
          version: '1.2',
          lastUpdateTime: DateTime.utc(2026, 9, 19),
        ),
      ],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    await db.installedAddonsDao.save(
      sampleAddon(
        addonId: 'A2plus',
        version: '1.0',
        catalogLastUpdate: DateTime.utc(2026, 9, 1),
      ),
    );
    final addons = AddonsController(
      database: db,
      catalog: catalog,
      installer: AddonInstaller(
        downloader: Downloader(
          source: downloadSource,
          cacheDirectory: p.join(tempDirectory.path, 'downloads'),
        ),
      ),
      paths: paths,
    );
    addons.start();
    await addons.load();
    await pumpEventQueue();
    final builds = BuildsController(
      database: db,
      catalog: FakeReleasesCatalog(),
      downloader: Downloader(
        source: downloadSource,
        cacheDirectory: p.join(tempDirectory.path, 'downloads'),
      ),
      installer: FakeBuildInstaller(),
      paths: paths,
      platform: BuildPlatform.linux,
      arch: 'x86_64',
    );
    services = AppServices(
      paths: paths,
      database: db,
      addonsController: addons,
      buildsController: builds,
    );
  });

  tearDown(() async {
    await services.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> pumpChip(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: UpdatesStatusChip())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the update count and opens the summary sheet', (
    tester,
  ) async {
    await pumpChip(tester);

    expect(find.text('1 update'), findsOneWidget);

    await tester.tap(find.text('1 update'));
    await tester.pumpAndSettle();

    expect(find.text('Updates available'), findsOneWidget);
    expect(find.text('A2plus'), findsOneWidget);
    expect(find.textContaining('v1.0'), findsOneWidget);

    await tester.tap(find.text('Check updates'));
    await tester.pumpAndSettle();
    expect(find.text('1 update'), findsWidgets);
  });

  testWidgets('hides the chip for pinned addons', (tester) async {
    await tester.runAsync(() async {
      final result = await services.addons.pin(
        addonId: 'A2plus',
        profileId: 'profile-1',
      );
      expect(result.isOk, isTrue);
      for (var attempt = 0; attempt < 100; attempt++) {
        if (services.addons.isPinned('profile-1', 'A2plus')) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('pin did not propagate to the installed addon signal');
    });
    await pumpChip(tester);

    expect(find.text('1 update'), findsNothing);
  });

  testWidgets('pre-checks outdated addons and toggles the selection', (
    tester,
  ) async {
    await pumpChip(tester);
    await tester.tap(find.text('1 update'));
    await tester.pumpAndSettle();

    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(find.text('Update selected (1)'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    expect(find.text('Update selected (0)'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Update selected (0)'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();

    expect(find.text('Update selected (1)'), findsOneWidget);
  });
}
