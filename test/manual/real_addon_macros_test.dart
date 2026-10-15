// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

void main() {
  test(
    'installs, verifies and removes the real LiveSectionAnalyzer addon macros (D-126)',
    () async {
      final root = Directory('/tmp/opencode/fcl_addon_macros_e2e');
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
          version: '1.1.3',
          channel: BuildChannel.stable,
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
        name: 'MacrosSmoke',
        buildId: 'b1',
      )).valueOrNull!;

      final catalog = AddonCatalog(
        downloader: Downloader(
          source: HttpDownloadSource(http.Client()),
          cacheDirectory: paths.addonsCacheDir,
        ),
        dao: db.catalogCacheDao,
        cacheDirectory: paths.addonsCacheDir,
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

      final addon = controller.byId('LiveSectionAnalyzer');
      expect(addon, isNotNull, reason: 'LiveSectionAnalyzer must exist in the real catalog');

      final installed = await controller.install(
        addonId: 'LiveSectionAnalyzer',
        branchRef: addon!.primaryBranch.gitRef,
        profileId: profile.id,
      );
      expect(installed.isOk, isTrue, reason: '${installed.errorOrNull}');

      final profilePaths = paths.profilePaths(profile.id);
      final addonDirectory = p.join(profilePaths.mod, 'LiveSectionAnalyzer');
      final sourceMacro = File(
        p.join(addonDirectory, 'macro', 'LiveSectionAnalyzer.FCMacro'),
      );
      final installedMacro = File(
        p.join(profilePaths.macros, 'LiveSectionAnalyzer.FCMacro'),
      );
      expect(sourceMacro.existsSync(), isTrue);
      expect(installedMacro.existsSync(), isTrue);
      expect(installedMacro.readAsBytesSync(), sourceMacro.readAsBytesSync());

      final digest = File(
        p.join(addonDirectory, 'AM_INSTALLATION_DIGEST.txt'),
      );
      expect(digest.existsSync(), isTrue);
      expect(digest.readAsStringSync(), contains(installedMacro.path));
      // ignore: avoid_print
      print('digest:\n${digest.readAsStringSync()}');

      final entry =
          (jsonDecode(
                    File(p.join(profilePaths.mod, 'manifest.json')).readAsStringSync(),
                  )
                  as Map<String, dynamic>)['LiveSectionAnalyzer']
              as Map<String, dynamic>;
      // ignore: avoid_print
      print('manifest entry: $entry');
      expect(entry['branch_display_name'], addon.primaryBranch.gitRef);
      expect(entry['freecad_version'], ['1', '1', '3']);
      expect(entry['extra_files'], [installedMacro.path]);

      final referenceProfile = Platform.environment['FCL_ADDON_MANAGER_PROFILE'];
      if (referenceProfile != null && referenceProfile.isNotEmpty) {
        final referenceManifest = File(p.join(referenceProfile, 'Mod', 'manifest.json'));
        if (referenceManifest.existsSync()) {
          final referenceEntry =
              (jsonDecode(referenceManifest.readAsStringSync()) as Map<String, dynamic>)
                      ['LiveSectionAnalyzer']
                  as Map<String, dynamic>;
          expect(entry.keys.toSet(), referenceEntry.keys.toSet());
          expect(entry['migrated'], referenceEntry['migrated']);
          expect(entry['branch_display_name'], referenceEntry['branch_display_name']);
        }
        final referenceDigest = File(
          p.join(referenceProfile, 'Mod', 'LiveSectionAnalyzer', 'AM_INSTALLATION_DIGEST.txt'),
        );
        if (referenceDigest.existsSync()) {
          final referenceHeader = referenceDigest.readAsLinesSync().first.split(' on ').first;
          expect(digest.readAsLinesSync().first.split(' on ').first, referenceHeader);
        }
      }

      final removed = await controller.remove(
        addonId: 'LiveSectionAnalyzer',
        profileId: profile.id,
      );
      expect(removed.isOk, isTrue);
      expect(installedMacro.existsSync(), isFalse);
      expect(Directory(addonDirectory).existsSync(), isFalse);
      final manifest = jsonDecode(
        File(p.join(profilePaths.mod, 'manifest.json')).readAsStringSync(),
      );
      expect((manifest as Map<String, dynamic>).containsKey('LiveSectionAnalyzer'), isFalse);

      controller.dispose();
      await db.close();
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    },
    skip: Platform.environment['FCL_REAL_ADDON_MACROS'] != '1'
        ? 'Manual test: set FCL_REAL_ADDON_MACROS=1 to download and install LiveSectionAnalyzer'
        : null,
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
