// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../helpers/fake_addon_catalog.dart';
import '../helpers/fake_download.dart';

void main() {
  const zipUrl = 'https://github.com/kbwbe/A2plus/archive/refs/heads/master.zip';

  test(
    'installs, updates (with backup) and removes the real A2plus addon',
    () async {
      final root = Directory('/tmp/opencode/fcl_addon_e2e');
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      final paths = AppPaths(dataRoot: root.path);
      await paths.ensureBaseDirectories();
      final db = AppDatabase.inMemory();
      final now = DateTime.now().toUtc();
      await db.buildsDao.save(
        Build(
          id: 'b1',
          kind: BuildKind.appimage,
          version: '1.0.2',
          channel: BuildChannel.custom,
          platform: BuildPlatform.linux,
          arch: BuildArch.x86_64,
          localPath: '/tmp/fake/FreeCAD',
          pythonVersion: '3.11',
          status: BuildStatus.installed,
          verified: false,
          installedAt: now,
          updatedAt: now,
        ),
      );
      final repository = ProfilesRepository(
        database: db,
        paths: paths,
        platform: BuildPlatform.linux,
      );
      final profile = (await repository.create(
        name: 'AddonSmoke',
        buildId: 'b1',
      )).valueOrNull!;

      final catalog = FakeAddonCatalog(
        downloader: Downloader(
          source: FakeDownloadSource(),
          cacheDirectory: p.join(root.path, 'catalog'),
        ),
        dao: db.catalogCacheDao,
        cacheDirectory: p.join(root.path, 'catalog'),
      )..result = AddonCatalogResult(
        addons: [
          Addon(
            id: 'A2plus',
            branches: [
              AddonBranch(
                gitRef: 'master',
                displayName: 'master',
                repositoryUrl: 'https://github.com/kbwbe/A2plus',
                zipUrl: zipUrl,
                curated: true,
                sparseCache: false,
                lastUpdateTime: DateTime.utc(2026, 9, 19),
                metadata: const AddonMetadata(
                  name: 'A2plus',
                  description: 'Assembly workbench',
                  version: '0.4.68',
                  license: 'LGPL-2.1-or-later',
                  minPython: '3.10',
                  tags: [],
                  people: [],
                  content: {AddonContentType.workbench},
                  requirements: '',
                ),
              ),
            ],
          ),
        ],
        freshness: CatalogFreshness.refreshed,
      );

      final controller = AddonsController(
        database: db,
        catalog: catalog,
        installer: AddonInstaller(
          downloader: Downloader(
            source: HttpDownloadSource(http.Client()),
            cacheDirectory: paths.downloadsCacheDir,
          ),
        ),
        paths: paths,
      );
      await controller.load();
      controller.start();

      final modDirectory = p.join(paths.profilePaths(profile.id).mod, 'A2plus');

      final installed = await controller.install(
        addonId: 'A2plus',
        branchRef: 'master',
        profileId: profile.id,
      );
      expect(installed.isOk, isTrue);
      expect(File(p.join(modDirectory, 'package.xml')).existsSync(), isTrue);
      // ignore: avoid_print
      print('installed path=$modDirectory');

      await pumpEventQueue();
      await db.installedAddonsDao.save(
        (await db.installedAddonsDao.getByAddon(profile.id, 'A2plus'))!.copyWith(
          catalogLastUpdate: Value(DateTime.utc(2020, 1, 1)),
        ),
      );
      await pumpEventQueue();
      expect(controller.isUpdateAvailable(profile.id, 'A2plus'), isTrue);

      final updated = await controller.update(
        addonId: 'A2plus',
        branchRef: 'master',
        profileId: profile.id,
      );
      expect(updated.isOk, isTrue);
      final backups = Directory(paths.profilePaths(profile.id).backups);
      final backupDirectories = backups.existsSync()
          ? backups.listSync().whereType<Directory>().toList()
          : <Directory>[];
      // ignore: avoid_print
      print('backups=${backupDirectories.map((d) => p.basename(d.path)).toList()}');
      expect(backupDirectories, isNotEmpty);
      expect(
        File(p.join(backupDirectories.first.path, 'package.xml')).existsSync(),
        isTrue,
      );
      expect(File(p.join(modDirectory, 'package.xml')).existsSync(), isTrue);

      final removed = await controller.remove(
        addonId: 'A2plus',
        profileId: profile.id,
      );
      expect(removed.isOk, isTrue);
      expect(Directory(modDirectory).existsSync(), isFalse);
      expect(await db.installedAddonsDao.getByAddon(profile.id, 'A2plus'), isNull);
      expect(backupDirectories.first.existsSync(), isTrue);

      controller.dispose();
      await db.close();
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    },
    skip: Platform.environment['FCL_REAL_ADDON'] != '1'
        ? 'Manual test: set FCL_REAL_ADDON=1 to download and install the real A2plus'
        : null,
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
