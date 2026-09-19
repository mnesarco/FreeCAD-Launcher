import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_addon_catalog.dart';
import '../helpers/fake_download.dart';
import '../helpers/test_database.dart';

Addon addon(
  String id, {
  String? name,
  String description = '',
  List<String> tags = const [],
  Set<AddonContentType> content = const {AddonContentType.workbench},
  String? freecadMin,
  String? freecadMax,
  String version = '',
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
        freecadMin: freecadMin,
        freecadMax: freecadMax,
        metadata: AddonMetadata(
          name: name ?? id,
          description: description,
          version: version,
          license: 'MIT',
          minPython: '3.10',
          tags: tags,
          people: const [],
          content: content,
          requirements: '',
        ),
      ),
    ],
  );
}

void main() {
  late Directory tempDirectory;
  late AppDatabase db;
  late FakeAddonCatalog catalog;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_addons_controller');
    db = createTestDatabase();
    catalog = FakeAddonCatalog(
      downloader: Downloader(
        source: FakeDownloadSource(),
        cacheDirectory: p.join(tempDirectory.path, 'addons'),
      ),
      dao: db.catalogCacheDao,
      cacheDirectory: p.join(tempDirectory.path, 'addons'),
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  AddonsController controller() => AddonsController(database: db, catalog: catalog);

  test('loads the catalog and reports errors', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus', name: 'A2plus')],
      freshness: CatalogFreshness.refreshed,
      fetchedAt: DateTime.utc(2026, 9, 19),
    );
    final subject = controller();

    await subject.load();

    expect(subject.loaded.value, isTrue);
    expect(subject.addons.value.single.id, 'A2plus');
    expect(subject.freshness.value, CatalogFreshness.refreshed);

    catalog.error = const AddonCatalogUnavailableException('offline');
    await subject.load(forceRefresh: true);

    expect(subject.error.value, isNotNull);
    subject.dispose();
  });

  test('filters by text, tag, content and installed state', () async {
    catalog.result = AddonCatalogResult(
      addons: [
        addon('A2plus', description: 'Assembly workbench', tags: ['assembly']),
        addon(
          'MacroTool',
          content: {AddonContentType.macro},
          tags: ['utility'],
        ),
      ],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    await db.installedAddonsDao.save(sampleAddon(addonId: 'MacroTool'));
    final subject = controller();
    await subject.load();
    subject.start();
    await pumpEventQueue();

    expect(subject.filteredAddons.value, hasLength(2));

    subject.query.value = 'assembly';
    expect(subject.filteredAddons.value.single.id, 'A2plus');

    subject.query.value = '#utility';
    expect(subject.filteredAddons.value.single.id, 'MacroTool');

    subject.query.value = '';
    subject.toggleContentFilter(AddonContentType.macro);
    expect(subject.filteredAddons.value.single.id, 'MacroTool');

    subject.toggleContentFilter(AddonContentType.workbench);
    expect(subject.filteredAddons.value.map((item) => item.id).toSet(), {'A2plus', 'MacroTool'});
    subject.toggleContentFilter(AddonContentType.workbench);

    subject.toggleContentFilter(AddonContentType.macro);
    subject.toggleInstalledFilter(AddonInstalledFilter.installed);
    expect(subject.filteredAddons.value.single.id, 'MacroTool');

    subject.toggleInstalledFilter(AddonInstalledFilter.installed);
    subject.toggleInstalledFilter(AddonInstalledFilter.notInstalled);
    expect(subject.filteredAddons.value.single.id, 'A2plus');

    subject.toggleInstalledFilter(AddonInstalledFilter.installed);
    expect(subject.filteredAddons.value, hasLength(2));

    expect(subject.activeFilterCount, 2);
    subject.clearFilters();
    expect(subject.activeFilterCount, 0);
    expect(subject.filteredAddons.value, hasLength(2));
    subject.dispose();
  });

  test('filters by installed build versions', () async {
    catalog.result = AddonCatalogResult(
      addons: [
        addon('Old', freecadMin: '0.19', freecadMax: '0.21'),
        addon('New', freecadMin: '1.0'),
        addon('Free'),
      ],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild(version: '1.1.3'));
    final subject = controller();
    await subject.load();
    subject.start();

    subject.setFreecadFilter('1.1.3');
    final ids = subject.filteredAddons.value.map((item) => item.id).toSet();
    expect(ids, {'New', 'Free'});
    expect(subject.isCompatibleWith(subject.addons.value.first, '1.1.3'), isFalse);
    subject.dispose();
  });

  test('selects branches per addon', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus')],
      freshness: CatalogFreshness.fresh,
    );
    final subject = controller();
    await subject.load();

    expect(subject.branchRefFor(subject.addons.value.single), 'master');
    subject.selectBranch('A2plus', 'dev');
    expect(subject.branchRefFor(subject.addons.value.single), 'dev');
    subject.dispose();
  });
}
