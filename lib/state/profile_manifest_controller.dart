// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_manifest.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';
import 'package:freecad_launcher/domain/profiles/profile_rules.dart';
import 'package:freecad_launcher/platform/freecad_preferences.dart';
import 'package:freecad_launcher/platform/host.dart';
import 'package:freecad_launcher/platform/paths.dart';

typedef ManifestAddonInstall =
    Future<Result<void>> Function({
      required String addonId,
      required String? branchRef,
      required String profileId,
      required bool installRequirements,
    });

typedef ManifestPackageInstall =
    Future<Result<void>> Function({
      required String profileId,
      required String specText,
      required String source,
    });

class ManifestImportPreview {
  const ManifestImportPreview({
    required this.manifest,
    required this.suggestedName,
    this.matchingBuild,
    this.usableBuilds = const [],
    this.absolutePaths = const [],
    this.missingBundles = const [],
  });

  final ProfileManifest manifest;
  final String suggestedName;
  final Build? matchingBuild;
  final List<Build> usableBuilds;
  final List<ManifestAbsolutePath> absolutePaths;
  final List<String> missingBundles;
}

class ManifestImportOutcome {
  const ManifestImportOutcome({
    required this.profile,
    this.addonsInstalled = 0,
    this.addonsFailed = const [],
    this.packagesInstalled = 0,
    this.packagesFailed = const [],
    this.warnings = const [],
  });

  final Profile profile;
  final int addonsInstalled;
  final List<String> addonsFailed;
  final int packagesInstalled;
  final List<String> packagesFailed;
  final List<String> warnings;

  bool get hasFailures => addonsFailed.isNotEmpty || packagesFailed.isNotEmpty;
}

class ProfileManifestController {
  ProfileManifestController({
    required AppDatabase database,
    required ProfilesRepository repository,
    required AppPaths paths,
    required BuildPlatform platform,
    String? arch,
    DateTime Function()? clock,
    ManifestAddonInstall? installAddon,
    ManifestPackageInstall? installPackages,
    FreeCadPreferences freecadPreferences = const FreeCadPreferences(),
  }) : _database = database,
       _repository = repository,
       _paths = paths,
       _platform = platform,
       _arch = arch ?? hostArch,
       _clock = clock ?? DateTime.now,
       _installAddon = installAddon,
       _installPackages = installPackages,
       _freecadPreferences = freecadPreferences;

  final AppDatabase _database;
  final ProfilesRepository _repository;
  final AppPaths _paths;
  final BuildPlatform _platform;
  final String _arch;
  final DateTime Function() _clock;
  final ManifestAddonInstall? _installAddon;
  final ManifestPackageInstall? _installPackages;
  final FreeCadPreferences _freecadPreferences;

  Future<Result<ProfileManifest>> exportManifest(String profileId) async {
    final profile = await _repository.getById(profileId);
    if (profile == null) {
      return const Err(AppError(message: 'Profile not found'));
    }
    final build = await _database.buildsDao.getById(profile.buildId);
    final addons = await _database.installedAddonsDao.getByProfile(profileId);
    final packages = await _database.pythonPackagesDao.getByProfile(profileId);
    final macros = await _database.macrosDao.getByProfile(profileId);
    final bundles = await _containedBundleNames({for (final addon in addons) addon.addonId});
    final config = _readConfig(_paths.profilePaths(profileId));

    return Ok(
      ProfileManifest(
        exportedAt: _clock().toUtc(),
        source: ManifestSource(os: _platform.name, arch: _arch),
        profile: ManifestProfileInfo(
          name: profile.name,
          build: build?.version,
          channel: build?.channel.name,
          python: profile.pythonVersion,
        ),
        addons: [
          for (final addon in addons)
            ManifestAddon(
              id: addon.addonId,
              gitRef: addon.gitRef,
              version: addon.version,
              pinned: addon.pinnedAt != null,
            ),
        ],
        pythonPackages: [
          for (final package in packages)
            ManifestPackage(name: package.name, version: package.version, source: package.source),
        ],
        bundles: bundles,
        macros: [for (final macro in macros) macro.fileName],
        config: config,
        configFiles: [
          for (final fileName in manifestConfigFileNames)
            if (config.containsKey(fileName)) fileName,
        ],
      ),
    );
  }

  Future<Result<String>> exportJson(String profileId) async {
    final manifest = await exportManifest(profileId);
    return manifest.fold((value) => Ok(encodeProfileManifest(value)), Err.new);
  }

  Future<Result<ManifestImportPreview>> previewImport(String json) async {
    final decoded = decodeProfileManifest(json);
    if (decoded.isErr) {
      return Err(decoded.errorOrNull!);
    }
    final manifest = decoded.valueOrNull!;
    final builds = await _database.buildsDao.getAll();
    final usable = [
      for (final build in builds)
        if (_isUsable(build)) build,
    ];
    final matching = _matchBuild(usable, manifest.profile.build, manifest.profile.channel);

    final knownBundles = {
      for (final bundle in await _database.bundlesDao.getAll()) bundle.name.trim().toLowerCase(),
    };

    return Ok(
      ManifestImportPreview(
        manifest: manifest,
        suggestedName: await _suggestName(manifest.profile.name),
        matchingBuild: matching,
        usableBuilds: usable,
        absolutePaths: findConfigAbsolutePaths(manifest.config),
        missingBundles: [
          for (final name in manifest.bundles)
            if (!knownBundles.contains(name.trim().toLowerCase())) name,
        ],
      ),
    );
  }

  Future<Result<ManifestImportOutcome>> importManifest({
    required ManifestImportPreview preview,
    required String name,
    required String buildId,
    bool reinstall = true,
    bool installRequirements = false,
    void Function(String step)? onStep,
  }) async {
    final created = await _repository.create(name: name, buildId: buildId);
    if (created.isErr) {
      return Err(created.errorOrNull!);
    }
    final profile = created.valueOrNull!;
    final paths = _paths.profilePaths(profile.id);

    try {
      _writeConfig(paths, preview.manifest.config);
      _freecadPreferences.ensureMacroPath(userCfgPath: paths.userCfg, macroPath: paths.macros);
    } on Object catch (error) {
      await _repository.delete(profile.id);
      return Err(
        AppError(
          message: 'Could not write the profile configuration',
          detail: '$error',
          retryable: true,
        ),
      );
    }

    final addonsInstalled = <String>[];
    final addonsFailed = <String>[];
    var packagesInstalled = 0;
    final packagesFailed = <String>[];

    if (reinstall) {
      for (final addon in preview.manifest.addons) {
        onStep?.call(addon.id);
        final install = _installAddon;
        if (install == null) {
          addonsFailed.add('${addon.id}: installation is unavailable');
          continue;
        }
        final result = await install(
          addonId: addon.id,
          branchRef: addon.gitRef,
          profileId: profile.id,
          installRequirements: installRequirements,
        );
        if (result.isOk) {
          addonsInstalled.add(addon.id);
          if (addon.pinned) {
            await _database.installedAddonsDao.setPinnedAt(profile.id, addon.id, _clock());
          }
        } else {
          addonsFailed.add('${addon.id}: ${result.errorOrNull}');
        }
      }

      final groups = <String, List<ManifestPackage>>{};
      for (final package in preview.manifest.pythonPackages) {
        if (_isAddonSourced(package)) {
          continue;
        }
        groups.putIfAbsent(package.source ?? 'manual', () => []).add(package);
      }
      if (groups.isNotEmpty) {
        onStep?.call('Python packages');
      }
      for (final entry in groups.entries) {
        final install = _installPackages;
        if (install == null) {
          packagesFailed.addAll([
            for (final package in entry.value) '${package.name}: installation is unavailable',
          ]);
          continue;
        }
        final result = await install(
          profileId: profile.id,
          specText: [for (final package in entry.value) _packageSpec(package)].join('\n'),
          source: entry.key,
        );
        if (result.isOk) {
          packagesInstalled += entry.value.length;
        } else {
          packagesFailed.addAll([
            for (final package in entry.value) '${package.name}: ${result.errorOrNull}',
          ]);
        }
      }
    }

    return Ok(
      ManifestImportOutcome(
        profile: profile,
        addonsInstalled: addonsInstalled.length,
        addonsFailed: addonsFailed,
        packagesInstalled: packagesInstalled,
        packagesFailed: packagesFailed,
        warnings: [
          for (final name in preview.missingBundles) 'Collection "$name" is not available',
        ],
      ),
    );
  }

  Future<List<String>> _containedBundleNames(Set<String> installedAddonIds) async {
    if (installedAddonIds.isEmpty) {
      return const [];
    }
    final result = <String>[];
    for (final bundle in await _database.bundlesDao.getAll()) {
      final items = await _database.bundlesDao.getItems(bundle.id);
      if (items.isEmpty) {
        continue;
      }
      if (items.every((item) => installedAddonIds.contains(item.addonId))) {
        result.add(bundle.name);
      }
    }
    return result;
  }

  Future<String> _suggestName(String raw) async {
    var base = normalizeProfileName(raw);
    if (base.isEmpty) {
      base = 'Imported profile';
    }
    if (base.length > maxProfileNameLength) {
      base = base.substring(0, maxProfileNameLength);
    }
    if (await _repository.getByName(base) == null) {
      return base;
    }
    for (var index = 1; index < 1000; index++) {
      final suffix = index == 1 ? ' (imported)' : ' (imported $index)';
      final room = maxProfileNameLength - suffix.length;
      final candidate = '${room >= base.length ? base : base.substring(0, room)}$suffix';
      if (await _repository.getByName(candidate) == null) {
        return candidate;
      }
    }
    return base;
  }

  Build? _matchBuild(List<Build> usable, String? version, String? channel) {
    if (version == null) {
      return null;
    }
    for (final build in usable) {
      if (build.version == version && (channel == null || build.channel.name == channel)) {
        return build;
      }
    }
    for (final build in usable) {
      if (build.version == version) {
        return build;
      }
    }
    return null;
  }

  bool _isUsable(Build build) {
    return build.status == BuildStatus.installed &&
        (build.pythonVersion?.trim().isNotEmpty ?? false);
  }

  bool _isAddonSourced(ManifestPackage package) {
    return package.source?.startsWith('addon:') ?? false;
  }

  String _packageSpec(ManifestPackage package) {
    final version = package.version?.trim();
    if (version == null || version.isEmpty) {
      return package.name;
    }
    return '${package.name}==$version';
  }

  Map<String, String> _readConfig(ProfilePaths paths) {
    final result = <String, String>{};
    for (final fileName in manifestConfigFileNames) {
      final file = File(p.join(paths.root, fileName));
      if (!file.existsSync()) {
        continue;
      }
      try {
        result[fileName] = file.readAsStringSync();
      } on FileSystemException {
        // Unreadable config files are omitted from the manifest.
      }
    }
    return result;
  }

  void _writeConfig(ProfilePaths paths, Map<String, String> config) {
    for (final entry in config.entries) {
      if (!manifestConfigFileNames.contains(entry.key)) {
        continue;
      }
      File(p.join(paths.root, entry.key)).writeAsStringSync(entry.value);
    }
  }
}
