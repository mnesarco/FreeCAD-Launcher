// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart'
    show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/addon_update.dart';
import 'package:freecad_launcher/domain/builds/asset_classifier.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/builds/build_update.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';
import 'package:freecad_launcher/domain/settings/app_settings.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/builds_controller.dart';
import 'package:freecad_launcher/state/updates_controller.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_addon_catalog.dart';
import '../helpers/fake_download.dart';
import '../helpers/fake_releases.dart';
import '../helpers/test_database.dart';

Addon addon(String id, {String version = '1.0', DateTime? lastUpdateTime}) {
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

List<int> addonZip(Map<String, String> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    final bytes = utf8.encode(entry.value);
    archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
  }
  return ZipEncoder().encode(archive);
}

BuildCandidate candidate(String version, BuildKind kind) {
  return BuildCandidate(
    versionLabel: version,
    channel: BuildChannel.stable,
    platform: BuildPlatform.linux,
    arch: 'x86_64',
    kind: kind,
    assetName: 'FreeCAD_$version.AppImage',
    downloadUrl: 'https://example.invalid/$version',
    sizeBytes: 1,
    version: FreeCadVersion.tryParse(version),
  );
}

void main() {
  late Directory tempDirectory;
  late AppDatabase db;
  late FakeAddonCatalog catalog;
  late FakeDownloadSource downloadSource;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'fcl_updates_controller',
    );
    db = createTestDatabase();
    downloadSource = FakeDownloadSource();
    catalog = FakeAddonCatalog(
      downloader: Downloader(
        source: downloadSource,
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

  AddonsController addonsController() {
    return AddonsController(
      database: db,
      catalog: catalog,
      installer: AddonInstaller(
        downloader: Downloader(
          source: downloadSource,
          cacheDirectory: p.join(tempDirectory.path, 'downloads'),
        ),
      ),
      paths: AppPaths(dataRoot: tempDirectory.path),
      clock: () => DateTime.utc(2026, 9, 20, 12),
    );
  }

  BuildsController buildsController({FakeReleasesCatalog? releasesCatalog}) {
    return BuildsController(
      database: db,
      catalog: releasesCatalog ?? FakeReleasesCatalog(),
      downloader: Downloader(
        source: downloadSource,
        cacheDirectory: p.join(tempDirectory.path, 'downloads'),
      ),
      installer: FakeBuildInstaller(),
      paths: AppPaths(dataRoot: tempDirectory.path),
      platform: BuildPlatform.linux,
      arch: 'x86_64',
    );
  }

  UpdatesController updatesController(
    AddonsController addons,
    BuildsController builds,
  ) {
    return UpdatesController(
      addons: addons,
      builds: builds,
      settingsDao: db.settingsDao,
      clock: () => DateTime.utc(2026, 9, 20, 12),
    );
  }

  test('check flags outdated addons and persists the timestamp', () async {
    catalog.result = AddonCatalogResult(
      addons: [
        addon(
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

    final addons = addonsController();
    addons.start();
    await pumpEventQueue();
    await addons.load();
    await pumpEventQueue();
    final updates = updatesController(addons, buildsController());

    expect(updates.outdated.value.single.addonId, 'A2plus');
    expect(updates.outdated.value.single.catalogVersion, '1.2');
    expect(updates.forProfile('profile-1'), hasLength(1));
    expect(updates.isOutdated('profile-1', 'A2plus'), isTrue);

    final count = await updates.check();
    expect(count, 1);
    expect(updates.lastCheckedAt.value, DateTime.utc(2026, 9, 20, 12));
    expect(
      await db.settingsDao.getValue(addonUpdateLastCheckedKey),
      DateTime.utc(2026, 9, 20, 12).toIso8601String(),
    );
  });

  test('checkIfDue skips manual and recent checks, runs when due', () async {
    catalog.result = AddonCatalogResult(
      addons: const [],
      freshness: CatalogFreshness.fresh,
    );
    var now = DateTime.utc(2026, 9, 20, 12);
    final updates = UpdatesController(
      addons: addonsController(),
      builds: buildsController(),
      settingsDao: db.settingsDao,
      clock: () => now,
    );

    expect(await updates.checkIfDue(UpdateCadence.manual), isNull);
    expect(catalog.loads, 0);

    expect(await updates.checkIfDue(UpdateCadence.daily), 0);
    expect(catalog.loads, 1);

    expect(await updates.checkIfDue(UpdateCadence.daily), isNull);
    expect(catalog.loads, 1);

    now = now.add(const Duration(days: 1, minutes: 1));
    expect(await updates.checkIfDue(UpdateCadence.daily), 0);
    expect(
      await db.settingsDao.getValue(addonUpdateLastCheckedKey),
      now.toIso8601String(),
    );
  });

  test('excludes pinned addons per profile', () async {
    catalog.result = AddonCatalogResult(
      addons: [
        addon(
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

    final addons = addonsController();
    addons.start();
    await pumpEventQueue();
    await addons.load();
    await pumpEventQueue();
    final updates = updatesController(addons, buildsController());
    expect(updates.outdated.value, hasLength(1));

    expect(
      (await addons.pin(addonId: 'A2plus', profileId: 'profile-1')).isOk,
      isTrue,
    );
    await pumpEventQueue();
    expect(updates.outdated.value, isEmpty);
    expect(updates.outdatedByProfile.value, isEmpty);

    expect(
      (await addons.unpin(addonId: 'A2plus', profileId: 'profile-1')).isOk,
      isTrue,
    );
    await pumpEventQueue();
    expect(updates.outdated.value, hasLength(1));
  });

  test(
    'reports nothing when the installed version matches the catalog',
    () async {
      catalog.result = AddonCatalogResult(
        addons: [
          addon(
            'A2plus',
            version: '1.0',
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
          catalogLastUpdate: DateTime.utc(2026, 9, 19),
        ),
      );

      final addons = addonsController();
      addons.start();
      await pumpEventQueue();
      await addons.load();
      await pumpEventQueue();
      final updates = updatesController(addons, buildsController());

      expect(updates.outdated.value, isEmpty);
      expect(await updates.check(), 0);
    },
  );

  test('check returns null when the catalogs are unavailable', () async {
    catalog.error = Exception('offline');
    final addons = addonsController();
    final builds = buildsController(
      releasesCatalog: FakeReleasesCatalog(error: Exception('offline')),
    );
    final updates = updatesController(addons, builds);

    expect(await updates.check(), isNull);
    expect(updates.lastCheckedAt.value, isNull);
    expect(await db.settingsDao.getValue(addonUpdateLastCheckedKey), isNull);
    expect(await db.settingsDao.getValue(buildUpdateLastCheckedKey), isNull);
  });

  test(
    'flags newer stable releases of the same kind and stamps the build timestamp',
    () async {
      final builds = buildsController();
      builds.installedBuilds.value = [
        sampleBuild(id: 'stable-appimage', version: '1.1.3'),
        sampleBuild(
          id: 'stable-archive',
          version: '1.1.3',
          kind: BuildKind.archive,
        ),
        sampleBuild(id: 'current', version: '2.0.0'),
        sampleBuild(
          id: 'weekly',
          version: '1.1.3',
          channel: BuildChannel.weekly,
        ),
        sampleBuild(
          id: 'custom',
          version: '9.9.9',
          kind: BuildKind.custom,
          channel: BuildChannel.custom,
        ),
      ];
      builds.availableBuilds.value = [
        candidate('2.0.0', BuildKind.appimage),
        candidate('2.0.0', BuildKind.archive),
      ];
      final addons = addonsController();
      final updates = updatesController(addons, builds);

      final flagged = {
        for (final update in updates.outdatedBuilds.value) update.buildId,
      };
      expect(flagged, {'stable-appimage', 'stable-archive'});
      expect(
        updates.outdatedBuilds.value.first,
        isA<BuildUpdate>().having(
          (update) => update.latestVersion,
          'latestVersion',
          '2.0.0',
        ),
      );
      expect(updates.outdatedCount.value, 2);

      final count = await updates.check();
      expect(count, 2);
      expect(updates.lastCheckedAt.value, DateTime.utc(2026, 9, 20, 12));
      expect(
        await db.settingsDao.getValue(buildUpdateLastCheckedKey),
        DateTime.utc(2026, 9, 20, 12).toIso8601String(),
      );
    },
  );

  test('applyUpdates updates every selected addon sequentially', () async {
    catalog.result = AddonCatalogResult(
      addons: [
        addon(
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
    downloadSource.streamFactory = () => Stream.fromIterable([
      addonZip({'A2plus-master/InitGui.py': 'gui'}),
    ]);
    final addons = addonsController();
    addons.start();
    await pumpEventQueue();
    await addons.load();
    await pumpEventQueue();
    final updates = updatesController(addons, buildsController());

    final summary = await updates.applyUpdates(updates.outdated.value);

    expect(summary.count(AddonUpdateApplyStatus.updated), 1);
    expect(summary.failures, isEmpty);
    expect(updates.applying.value, isFalse);
    expect(updates.applyTotal.value, 1);
    expect(updates.applyCompleted.value, 1);
    await pumpEventQueue();
    expect(updates.outdated.value, isEmpty);
    expect(
      (await db.installedAddonsDao.getByAddon('profile-1', 'A2plus'))!.version,
      '1.2',
    );
  });

  test(
    'applyUpdates is failure-tolerant and keeps failures outdated',
    () async {
      catalog.result = AddonCatalogResult(
        addons: [
          addon(
            'A2plus',
            version: '1.2',
            lastUpdateTime: DateTime.utc(2026, 9, 19),
          ),
          addon(
            'Broken',
            version: '2.0',
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
      await db.installedAddonsDao.save(
        sampleAddon(
          id: 'addon-2',
          addonId: 'Broken',
          displayName: 'Broken',
          version: '1.0',
          catalogLastUpdate: DateTime.utc(2026, 9, 1),
        ),
      );
      final source = FakeDownloadSourceWithResponses((uri) async {
        if (uri.toString().contains('Broken')) {
          throw Exception('boom');
        }
        return DownloadStream(
          bytes: bytesStream(addonZip({'A2plus-master/InitGui.py': 'gui'})),
        );
      });
      final addons = AddonsController(
        database: db,
        catalog: catalog,
        installer: AddonInstaller(
          downloader: Downloader(
            source: source,
            cacheDirectory: p.join(tempDirectory.path, 'downloads'),
          ),
        ),
        paths: AppPaths(dataRoot: tempDirectory.path),
        clock: () => DateTime.utc(2026, 9, 20, 12),
      );
      addons.start();
      await pumpEventQueue();
      await addons.load();
      await pumpEventQueue();
      final updates = updatesController(addons, buildsController());
      expect(updates.outdated.value, hasLength(2));

      final summary = await updates.applyUpdates(updates.outdated.value);

      expect(summary.count(AddonUpdateApplyStatus.updated), 1);
      expect(summary.count(AddonUpdateApplyStatus.failed), 1);
      expect(summary.failures.single.update.addonId, 'Broken');
      expect(summary.failures.single.error, isNotNull);
      expect(updates.applyCompleted.value, 2);
      await pumpEventQueue();
      expect(updates.outdated.value.single.addonId, 'Broken');
    },
  );
}
