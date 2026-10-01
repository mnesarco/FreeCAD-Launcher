// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_manifest.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/profile_manifest_controller.dart';

import '../data/test_fixtures.dart';
import '../helpers/test_database.dart';

class RecordedAddonInstall {
  const RecordedAddonInstall({
    required this.addonId,
    required this.branchRef,
    required this.profileId,
    required this.installRequirements,
  });

  final String addonId;
  final String? branchRef;
  final String profileId;
  final bool installRequirements;
}

class RecordedPackageInstall {
  const RecordedPackageInstall({
    required this.profileId,
    required this.specText,
    required this.source,
  });

  final String profileId;
  final String specText;
  final String source;
}

void main() {
  late Directory tempDirectory;
  late AppPaths paths;
  late AppDatabase db;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_profile_manifest');
    paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  ProfilesRepository repositoryFor(BuildPlatform platform) {
    return ProfilesRepository(
      database: db,
      paths: paths,
      platform: platform,
      clock: () => DateTime.utc(2026, 9, 20, 12),
    );
  }

  ProfileManifestController controllerFor({
    BuildPlatform platform = BuildPlatform.linux,
    ProfilesRepository? repository,
    ManifestAddonInstall? installAddon,
    ManifestPackageInstall? installPackages,
  }) {
    return ProfileManifestController(
      database: db,
      repository: repository ?? repositoryFor(platform),
      paths: paths,
      platform: platform,
      arch: 'x86_64',
      clock: () => DateTime.utc(2026, 9, 20, 12),
      installAddon: installAddon,
      installPackages: installPackages,
    );
  }

  ProfileManifest manifestFor({
    required String name,
    String? build = '1.1.3',
    String? channel = 'stable',
    String? configPath,
    List<ManifestAddon> addons = const [],
    List<ManifestPackage> packages = const [],
    List<String> bundles = const [],
  }) {
    return ProfileManifest(
      exportedAt: DateTime.utc(2026, 9, 20, 10),
      source: const ManifestSource(os: 'linux', arch: 'x86_64'),
      profile: ManifestProfileInfo(name: name, build: build, channel: channel, python: '3.11'),
      addons: addons,
      pythonPackages: packages,
      bundles: bundles,
      config: {
        if (configPath != null)
          'user.cfg':
              '<FCParameters><BaseApp><Preferences>'
              '<FCText Name="MacroPath">/home/ana/Macros/</FCText>'
              '<FCText Name="ToolDir">$configPath</FCText>'
              '</Preferences></BaseApp></FCParameters>',
      },
      configFiles: const ['user.cfg'],
    );
  }

  group('export', () {
    test('gathers profile metadata, addons, packages, contained bundles and config', () async {
      await db.buildsDao.save(sampleBuild());
      final created = await repositoryFor(
        BuildPlatform.linux,
      ).create(name: 'Dev', buildId: 'build-1');
      final profile = created.valueOrNull!;
      await db.installedAddonsDao.save(
        sampleAddon(profileId: profile.id, addonId: 'A2plus', version: '0.4.60'),
      );
      await db.installedAddonsDao.setPinnedAt(
        profile.id,
        'A2plus',
        DateTime.utc(2026, 9, 20, 9),
      );
      await db.pythonPackagesDao.save(
        samplePackage(profileId: profile.id, name: 'numpy', source: 'requirements'),
      );
      await db.macrosDao.save(
        sampleMacro(profileId: profile.id, name: 'MyMacro', fileName: 'MyMacro.FCMacro'),
      );
      await db.bundlesDao.save(sampleBundle(name: 'Mechanical'));
      await db.bundlesDao.addItem(sampleBundleItem(bundleId: 'bundle-1', addonId: 'A2plus'));
      await db.bundlesDao.save(sampleBundle(id: 'bundle-2', name: 'Incomplete'));
      await db.bundlesDao.addItem(sampleBundleItem(bundleId: 'bundle-2', addonId: 'Fasteners'));
      File(paths.profilePaths(profile.id).userCfg).writeAsStringSync(
        '<FCParameters><FCText Name="ToolDir">/opt/tools</FCText></FCParameters>',
      );

      final controller = controllerFor();
      final encoded = await controller.exportJson(profile.id);

      expect(encoded.isOk, isTrue);
      final manifest = decodeProfileManifest(encoded.valueOrNull!).valueOrNull!;
      expect(manifest.exportedAt, DateTime.utc(2026, 9, 20, 12));
      expect(manifest.source.os, 'linux');
      expect(manifest.source.arch, 'x86_64');
      expect(manifest.profile.name, 'Dev');
      expect(manifest.profile.build, '1.1.3');
      expect(manifest.profile.channel, 'stable');
      expect(manifest.profile.python, '3.11');
      expect(manifest.addons.single.id, 'A2plus');
      expect(manifest.addons.single.version, '0.4.60');
      expect(manifest.addons.single.pinned, isTrue);
      expect(manifest.pythonPackages.single.name, 'numpy');
      expect(manifest.pythonPackages.single.source, 'requirements');
      expect(manifest.bundles, ['Mechanical']);
      expect(manifest.macros, ['MyMacro.FCMacro']);
      expect(manifest.configFiles, ['user.cfg']);
      expect(manifest.config['user.cfg'], contains('/opt/tools'));
      expect(findConfigAbsolutePaths(manifest.config).single.path, '/opt/tools');
    });

    test('reports missing profiles', () async {
      final controller = controllerFor();
      final result = await controller.exportJson('nope');

      expect(result.isErr, isTrue);
      expect(result.errorOrNull!.message, contains('Profile not found'));
    });
  });

  group('preview', () {
    test('suggests an imported name for a clash and matches the build', () async {
      await db.buildsDao.save(sampleBuild());
      await repositoryFor(BuildPlatform.linux).create(name: 'Dev', buildId: 'build-1');

      final controller = controllerFor();
      final encoded = encodeProfileManifest(
        manifestFor(
          name: 'Dev',
          configPath: '/home/ana/tools',
          addons: const [ManifestAddon(id: 'A2plus', gitRef: 'master')],
          bundles: const ['Mechanical'],
        ),
      );
      final preview = await controller.previewImport(encoded);

      expect(preview.isOk, isTrue);
      final value = preview.valueOrNull!;
      expect(value.suggestedName, 'Dev (imported)');
      expect(value.matchingBuild!.id, 'build-1');
      expect(value.usableBuilds.single.id, 'build-1');
      expect(value.absolutePaths.map((entry) => entry.path), contains('/home/ana/tools'));
      expect(value.missingBundles, ['Mechanical']);
    });

    test('leaves the build unset when no usable build matches', () async {
      await db.buildsDao.save(sampleBuild(version: '1.0.2', pythonVersion: null));
      final controller = controllerFor();

      final preview = await controller.previewImport(
        encodeProfileManifest(manifestFor(name: 'Dev', build: '1.1.3')),
      );

      expect(preview.valueOrNull!.matchingBuild, isNull);
      expect(preview.valueOrNull!.usableBuilds, isEmpty);
      expect(preview.valueOrNull!.suggestedName, 'Dev');
    });
  });

  group('import', () {
    test('creates the profile, writes config and reinstalls content', () async {
      await db.buildsDao.save(sampleBuild());
      await repositoryFor(BuildPlatform.linux).create(name: 'Dev', buildId: 'build-1');
      final addonCalls = <RecordedAddonInstall>[];
      final packageCalls = <RecordedPackageInstall>[];
      final controller = controllerFor(
        installAddon:
            ({
              required String addonId,
              required String? branchRef,
              required String profileId,
              required bool installRequirements,
            }) async {
              addonCalls.add(
                RecordedAddonInstall(
                  addonId: addonId,
                  branchRef: branchRef,
                  profileId: profileId,
                  installRequirements: installRequirements,
                ),
              );
              await db.installedAddonsDao.save(
                sampleAddon(
                  id: 'row-$addonId',
                  profileId: profileId,
                  addonId: addonId,
                  gitRef: branchRef,
                ),
              );
              return const Ok(null);
            },
        installPackages:
            ({required String profileId, required String specText, required String source}) async {
              packageCalls.add(
                RecordedPackageInstall(profileId: profileId, specText: specText, source: source),
              );
              return const Ok(null);
            },
      );
      final manifest = manifestFor(
        name: 'Dev',
        configPath: '/home/ana/tools',
        addons: const [
          ManifestAddon(id: 'A2plus', gitRef: 'master', pinned: true),
          ManifestAddon(id: 'Fasteners'),
        ],
        packages: const [
          ManifestPackage(name: 'numpy', version: '1.26.4', source: 'requirements'),
          ManifestPackage(name: 'six', source: 'manual'),
          ManifestPackage(name: 'skipme', source: 'addon:A2plus'),
        ],
      );
      final preview = (await controller.previewImport(
        encodeProfileManifest(manifest),
      )).valueOrNull!;

      final steps = <String>[];
      final result = await controller.importManifest(
        preview: preview,
        name: preview.suggestedName,
        buildId: preview.matchingBuild!.id,
        installRequirements: true,
        onStep: steps.add,
      );

      expect(result.isOk, isTrue);
      final outcome = result.valueOrNull!;
      expect(outcome.profile.name, 'Dev (imported)');
      expect(outcome.addonsInstalled, 2);
      expect(outcome.packagesInstalled, 2);
      expect(outcome.addonsFailed, isEmpty);
      expect(outcome.packagesFailed, isEmpty);

      expect(addonCalls.length, 2);
      expect(addonCalls.first.addonId, 'A2plus');
      expect(addonCalls.first.branchRef, 'master');
      expect(addonCalls.first.profileId, outcome.profile.id);
      expect(addonCalls.first.installRequirements, isTrue);
      expect(addonCalls.last.addonId, 'Fasteners');
      expect(addonCalls.last.branchRef, isNull);
      expect(steps, ['A2plus', 'Fasteners', 'Python packages']);

      expect(packageCalls.length, 2);
      final requirementsCall = packageCalls.firstWhere((call) => call.source == 'requirements');
      expect(requirementsCall.specText, 'numpy==1.26.4');
      final manualCall = packageCalls.firstWhere((call) => call.source == 'manual');
      expect(manualCall.specText, 'six');

      final pinnedRow = await db.installedAddonsDao.getByAddon(outcome.profile.id, 'A2plus');
      expect(pinnedRow!.pinnedAt, isNotNull);
      final unpinnedRow = await db.installedAddonsDao.getByAddon(
        outcome.profile.id,
        'Fasteners',
      );
      expect(unpinnedRow!.pinnedAt, isNull);

      final configFile = File(paths.profilePaths(outcome.profile.id).userCfg);
      final config = configFile.readAsStringSync();
      expect(config, contains('/home/ana/tools'));
      expect(config, contains(paths.profilePaths(outcome.profile.id).macros));
    });

    test('skips custom-source addons instead of reinstalling them', () async {
      await db.buildsDao.save(sampleBuild());
      await repositoryFor(BuildPlatform.linux).create(name: 'Dev', buildId: 'build-1');
      final addonCalls = <RecordedAddonInstall>[];
      final controller = controllerFor(
        installAddon:
            ({
              required String addonId,
              required String? branchRef,
              required String profileId,
              required bool installRequirements,
            }) async {
              addonCalls.add(
                RecordedAddonInstall(
                  addonId: addonId,
                  branchRef: branchRef,
                  profileId: profileId,
                  installRequirements: installRequirements,
                ),
              );
              return const Ok(null);
            },
      );
      final manifest = manifestFor(
        name: 'Dev',
        addons: const [
          ManifestAddon(id: 'A2plus', gitRef: 'master'),
          ManifestAddon(id: 'DevAddon', source: 'symlink'),
          ManifestAddon(id: 'RepoAddon', source: 'repo'),
        ],
      );
      final preview = (await controller.previewImport(
        encodeProfileManifest(manifest),
      )).valueOrNull!;

      final result = await controller.importManifest(
        preview: preview,
        name: preview.suggestedName,
        buildId: preview.matchingBuild!.id,
        installRequirements: false,
      );

      expect(result.isOk, isTrue);
      final outcome = result.valueOrNull!;
      expect(outcome.addonsInstalled, 1);
      expect(outcome.addonsSkipped, ['DevAddon', 'RepoAddon']);
      expect(addonCalls.single.addonId, 'A2plus');
    });

    test('forces MacroPath when the manifest has no config', () async {
      await db.buildsDao.save(sampleBuild());
      final controller = controllerFor();
      final manifest = ProfileManifest(
        profile: const ManifestProfileInfo(name: 'Fresh', build: '1.1.3', channel: 'stable'),
      );
      final preview = (await controller.previewImport(
        encodeProfileManifest(manifest),
      )).valueOrNull!;

      final result = await controller.importManifest(
        preview: preview,
        name: preview.suggestedName,
        buildId: preview.matchingBuild!.id,
        reinstall: false,
      );

      expect(result.isOk, isTrue);
      final profile = result.valueOrNull!.profile;
      expect(profile.name, 'Fresh');
      final config = File(paths.profilePaths(profile.id).userCfg);
      expect(config.existsSync(), isTrue);
      expect(config.readAsStringSync(), contains(paths.profilePaths(profile.id).macros));
    });

    test('collects addon and package failures without aborting', () async {
      await db.buildsDao.save(sampleBuild());
      final controller = controllerFor(
        installAddon:
            ({
              required String addonId,
              required String? branchRef,
              required String profileId,
              required bool installRequirements,
            }) async => Err(AppError(message: 'boom')),
        installPackages:
            ({required String profileId, required String specText, required String source}) async =>
                Err(AppError(message: 'pip failed')),
      );
      final manifest = manifestFor(
        name: 'Dev',
        addons: const [ManifestAddon(id: 'A2plus', gitRef: 'master')],
        packages: const [ManifestPackage(name: 'numpy', version: '1.26.4', source: 'manual')],
      );
      final preview = (await controller.previewImport(
        encodeProfileManifest(manifest),
      )).valueOrNull!;

      final result = await controller.importManifest(
        preview: preview,
        name: preview.suggestedName,
        buildId: preview.matchingBuild!.id,
      );

      final outcome = result.valueOrNull!;
      expect(outcome.hasFailures, isTrue);
      expect(outcome.addonsFailed.single, 'A2plus: boom');
      expect(outcome.packagesFailed.single, 'numpy: pip failed');
      expect(await db.profilesDao.getById(outcome.profile.id), isNotNull);
    });
  });

  test('imports a Linux-exported manifest on a Windows-configured launcher', () async {
    await db.buildsDao.save(sampleBuild(platform: BuildPlatform.windows));
    final linuxRepository = repositoryFor(BuildPlatform.linux);
    final created = await linuxRepository.create(name: 'Dev', buildId: 'build-1');
    final sourceProfile = created.valueOrNull!;
    await db.installedAddonsDao.save(sampleAddon(profileId: sourceProfile.id, addonId: 'A2plus'));
    File(paths.profilePaths(sourceProfile.id).userCfg).writeAsStringSync(
      '<FCParameters><FCText Name="ToolDir">/home/ana/tools</FCText></FCParameters>',
    );

    final exported = await controllerFor(repository: linuxRepository).exportJson(sourceProfile.id);
    final manifest = decodeProfileManifest(exported.valueOrNull!).valueOrNull!;
    expect(manifest.source.os, 'linux');

    final windowsRepository = repositoryFor(BuildPlatform.windows);
    final controller = controllerFor(
      platform: BuildPlatform.windows,
      repository: windowsRepository,
    );
    final preview = (await controller.previewImport(exported.valueOrNull!)).valueOrNull!;
    expect(preview.matchingBuild!.id, 'build-1');
    expect(preview.absolutePaths.single.path, '/home/ana/tools');

    final result = await controller.importManifest(
      preview: preview,
      name: preview.suggestedName,
      buildId: preview.matchingBuild!.id,
      reinstall: false,
    );

    expect(result.isOk, isTrue);
    final profile = result.valueOrNull!.profile;
    final pathsInWindows = paths.profilePaths(profile.id);
    expect(Directory(pathsInWindows.appDataRoaming).existsSync(), isTrue);
    expect(Directory(pathsInWindows.xdgConfig).existsSync(), isFalse);
    expect(File(pathsInWindows.userCfg).readAsStringSync(), contains('/home/ana/tools'));
  });
}
