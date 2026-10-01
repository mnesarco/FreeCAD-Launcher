// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/cancellation.dart';
import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/addon_id_rules.dart';
import 'package:freecad_launcher/domain/addons/addon_source.dart';
import 'package:freecad_launcher/domain/addons/addon_update_rules.dart';
import 'package:freecad_launcher/domain/addons/repository_archive.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/domain/python/requirements_parser.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/addon_manifest_reader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/pip_runner.dart';
import 'package:freecad_launcher/platform/python_env.dart';
import 'package:freecad_launcher/state/jobs_controller.dart';

enum AddonInstalledFilter { installed, notInstalled }

enum CustomRequirementsDecision { installPackages, addonOnly, cancel }

typedef CustomRequirementsHandler =
    Future<CustomRequirementsDecision> Function(List<PythonRequirement> requirements);

class AddonsController {
  AddonsController({
    required AppDatabase database,
    required AddonCatalog catalog,
    required AddonInstaller installer,
    required AppPaths paths,
    PipRunner? pipRunner,
    PythonEnvResolver? pythonResolver,
    JobsController? jobs,
    DateTime Function()? clock,
  }) : _database = database,
       _catalog = catalog,
       _installer = installer,
       _paths = paths,
       _pipRunner = pipRunner,
       _pythonResolver = pythonResolver,
       _jobs = jobs,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final AddonCatalog _catalog;
  final AddonInstaller _installer;
  final AppPaths _paths;
  final PipRunner? _pipRunner;
  final PythonEnvResolver? _pythonResolver;
  final JobsController? _jobs;
  final DateTime Function() _clock;

  final addons = signal<List<Addon>>([]);
  final loading = signal(false);
  final loaded = signal(false);
  final error = signal<AppError?>(null);
  final freshness = signal<CatalogFreshness?>(null);
  final query = signal('');
  final contentFilter = signal<Set<AddonContentType>>({});
  final installedFilter = signal<Set<AddonInstalledFilter>>({});
  final freecadFilter = signal<String?>(null);
  final installedCounts = signal<Map<String, int>>({});
  final installedAddons = signal<List<InstalledAddon>>([]);
  final disabledAddons = signal<Map<String, Set<String>>>({});
  final installing = signal<Set<String>>({});
  final installErrors = signal<Map<String, AppError>>({});
  final requirementsInstalling = signal<Set<String>>({});
  final requirementsErrors = signal<Map<String, AppError>>({});
  final freecadVersions = signal<List<String>>([]);
  final selectedBranches = signal<Map<String, String>>({});

  StreamSubscription<List<InstalledAddon>>? _installedSubscription;
  StreamSubscription<List<Build>>? _buildsSubscription;

  late final filteredAddons = computed<List<Addon>>(() {
    final currentQuery = query.value;
    final contents = contentFilter.value;
    final installed = installedFilter.value;
    final version = freecadFilter.value;
    final counts = installedCounts.value;

    final wantInstalled = installed.contains(AddonInstalledFilter.installed);
    final wantNotInstalled = installed.contains(AddonInstalledFilter.notInstalled);

    return addons.value.where((addon) {
      if (!addon.matchesQuery(currentQuery)) {
        return false;
      }
      if (contents.isNotEmpty && !addon.content.any(contents.contains)) {
        return false;
      }
      final count = counts[addon.id] ?? 0;
      if (wantInstalled != wantNotInstalled) {
        if (wantInstalled && count == 0) {
          return false;
        }
        if (wantNotInstalled && count > 0) {
          return false;
        }
      }
      if (version != null && !isCompatibleWith(addon, version)) {
        return false;
      }
      return true;
    }).toList();
  });

  void start() {
    _installedSubscription ??= _database.installedAddonsDao.watchAll().listen((rows) {
      installedAddons.value = rows;
      final counts = <String, int>{};
      for (final row in rows) {
        counts[row.addonId] = (counts[row.addonId] ?? 0) + 1;
      }
      installedCounts.value = counts;
      unawaited(refreshDisabledState(rows));
    });
    _buildsSubscription ??= _database.buildsDao.watchAll().listen((builds) {
      final versions = <String>{};
      for (final build in builds) {
        if (FreeCadVersion.tryParse(build.version) != null) {
          versions.add(build.version);
        }
      }
      final sorted = versions.toList()
        ..sort((a, b) {
          final left = FreeCadVersion.tryParse(a);
          final right = FreeCadVersion.tryParse(b);
          if (left == null || right == null) {
            return 0;
          }
          return right.compareTo(left);
        });
      freecadVersions.value = sorted;
    });
    if (!loaded.value && !loading.value) {
      unawaited(load());
    }
  }

  Future<void> load({bool forceRefresh = false}) async {
    final stopwatch = Stopwatch()..start();
    loading.value = true;
    error.value = null;
    try {
      final result = await _catalog.load(forceRefresh: forceRefresh);
      addons.value = result.addons;
      freshness.value = result.freshness;
      loaded.value = true;
      appLogger.info(
        'addon catalog: ${result.addons.length} addons in '
        '${stopwatch.elapsedMilliseconds} ms (${result.freshness.name})',
        tag: 'perf',
      );
    } on Object catch (failure, stackTrace) {
      appLogger.error(
        'addon catalog load failed',
        error: failure,
        stackTrace: stackTrace,
        tag: 'catalog',
      );
      error.value = AppError.from(failure, retryable: true);
    } finally {
      loading.value = false;
    }
  }

  Future<void> ensureCachedCatalog() async {
    if (loaded.value || loading.value || addons.value.isNotEmpty) {
      return;
    }
    final cached = await _catalog.cachedAddons();
    if (cached != null && cached.isNotEmpty) {
      addons.value = cached;
    }
  }

  bool isCompatibleWith(Addon addon, String version) {
    final target = FreeCadVersion.tryParse(version);
    if (target == null) {
      return true;
    }
    final branch = addon.primaryBranch;
    final min = branch.freecadMin == null ? null : FreeCadVersion.tryParse(branch.freecadMin!);
    final max = branch.freecadMax == null ? null : FreeCadVersion.tryParse(branch.freecadMax!);
    if (min != null && target.compareTo(min) < 0) {
      return false;
    }
    if (max != null && target.compareTo(max) > 0) {
      return false;
    }
    return true;
  }

  String branchRefFor(Addon addon) {
    return selectedBranches.value[addon.id] ?? addon.primaryBranch.gitRef;
  }

  void selectBranch(String addonId, String gitRef) {
    selectedBranches.value = {...selectedBranches.value, addonId: gitRef};
  }

  void toggleContentFilter(AddonContentType content) {
    final current = {...contentFilter.value};
    if (!current.remove(content)) {
      current.add(content);
    }
    contentFilter.value = current;
  }

  void toggleInstalledFilter(AddonInstalledFilter filter) {
    final current = {...installedFilter.value};
    if (!current.remove(filter)) {
      current.add(filter);
    }
    installedFilter.value = current;
  }

  int get activeFilterCount =>
      contentFilter.value.length + installedFilter.value.length;

  void clearFilters() {
    contentFilter.value = {};
    installedFilter.value = {};
  }

  void setFreecadFilter(String? version) {
    freecadFilter.value = version;
  }

  Addon? byId(String addonId) {
    for (final addon in addons.value) {
      if (addon.id == addonId) {
        return addon;
      }
    }
    return null;
  }

  AddonBranch branchOf(Addon addon, String gitRef) {
    for (final branch in addon.branches) {
      if (branch.gitRef == gitRef) {
        return branch;
      }
    }
    return addon.primaryBranch;
  }

  Set<String> profilesWithAddon(String addonId) {
    return {
      for (final row in installedAddons.value)
        if (row.addonId == addonId) row.profileId,
    };
  }

  bool isInstalledIn(String profileId, String addonId) {
    return installedAddons.value.any(
      (row) => row.profileId == profileId && row.addonId == addonId,
    );
  }

  InstalledAddon? installedFor(String profileId, String addonId) {
    for (final row in installedAddons.value) {
      if (row.profileId == profileId && row.addonId == addonId) {
        return row;
      }
    }
    return null;
  }

  bool isPinned(String profileId, String addonId) {
    return installedFor(profileId, addonId)?.pinnedAt != null;
  }

  Future<Result<void>> pin({required String addonId, required String profileId}) {
    return _setPinned(profileId: profileId, addonId: addonId, pinned: true);
  }

  Future<Result<void>> unpin({required String addonId, required String profileId}) {
    return _setPinned(profileId: profileId, addonId: addonId, pinned: false);
  }

  Future<Result<void>> _setPinned({
    required String profileId,
    required String addonId,
    required bool pinned,
  }) async {
    try {
      final updated = await _database.installedAddonsDao.setPinnedAt(
        profileId,
        addonId,
        pinned ? _clock() : null,
      );
      if (updated == 0) {
        return const Err(AppError(message: 'Addon is not installed in this profile'));
      }
      return const Ok(null);
    } on Object catch (error) {
      return Err(AppError.from(error, retryable: true));
    }
  }

  static const String disabledMarkerName = 'ADDON_DISABLED';

  bool isAddonDisabled(String profileId, String addonId) {
    return disabledAddons.value[profileId]?.contains(addonId) ?? false;
  }

  Future<void> refreshDisabledState([List<InstalledAddon>? rows]) async {
    final current = rows ?? installedAddons.value;
    final result = <String, Set<String>>{};
    for (final row in current) {
      final marker = File(
        p.join(_modPath(row.profileId, row.addonId), disabledMarkerName),
      );
      if (marker.existsSync()) {
        (result[row.profileId] ??= <String>{}).add(row.addonId);
      }
    }
    disabledAddons.value = result;
  }

  Future<Result<void>> setAddonDisabled({
    required String addonId,
    required String profileId,
    required bool disabled,
  }) async {
    final installed = await _database.installedAddonsDao.getByAddon(profileId, addonId);
    if (installed == null) {
      return const Err(AppError(message: 'Addon is not installed in this profile'));
    }
    final directory = Directory(_modPath(profileId, addonId));
    if (!directory.existsSync()) {
      return const Err(AppError(message: 'Addon files not found in this profile'));
    }
    try {
      final marker = File(p.join(directory.path, disabledMarkerName));
      if (disabled) {
        if (!marker.existsSync()) {
          marker.writeAsStringSync('Disabled by FreeCAD Launcher\n');
        }
      } else if (marker.existsSync()) {
        marker.deleteSync();
      }
      _applyDisabledState(profileId, addonId, disabled);
      return const Ok(null);
    } on Object catch (error) {
      _applyDisabledState(
        profileId,
        addonId,
        File(p.join(directory.path, disabledMarkerName)).existsSync(),
      );
      return Err(AppError.from(error, retryable: true));
    }
  }

  void _applyDisabledState(String profileId, String addonId, bool disabled) {
    final current = {
      for (final entry in disabledAddons.value.entries) entry.key: {...entry.value},
    };
    final ids = current[profileId] ?? <String>{};
    if (disabled) {
      ids.add(addonId);
    } else {
      ids.remove(addonId);
    }
    if (ids.isEmpty) {
      current.remove(profileId);
    } else {
      current[profileId] = ids;
    }
    disabledAddons.value = current;
  }

  bool isUpdateAvailable(String profileId, String addonId) {
    final installed = installedFor(profileId, addonId);
    if (installed == null) {
      return false;
    }
    if (!addonSourceFromStorage(installed.source).isCatalog) {
      return false;
    }
    final addon = byId(addonId);
    if (addon == null) {
      return false;
    }
    final branch = branchOf(addon, installed.gitRef ?? addon.primaryBranch.gitRef);
    return addonContentChanged(
      catalogLastUpdate: branch.lastUpdateTime,
      catalogVersion: branch.metadata?.version,
      installedCatalogLastUpdate: installed.catalogLastUpdate,
      installedVersion: installed.version,
    );
  }

  Future<Result<void>> update({
    required String addonId,
    required String branchRef,
    required String profileId,
  }) async {
    final jobs = _jobs;
    if (jobs == null) {
      return _updateInternal(
        addonId: addonId,
        branchRef: branchRef,
        profileId: profileId,
      );
    }
    final result = await jobs.run<Result<void>>(
      kind: JobKind.install,
      label: 'Update ${byId(addonId)?.displayName ?? addonId}',
      onRetry: () async {
        await update(addonId: addonId, branchRef: branchRef, profileId: profileId);
      },
      task: (context) => _updateInternal(
        addonId: addonId,
        branchRef: branchRef,
        profileId: profileId,
        context: context,
      ),
    );
    return result ?? const Err(AppError(message: 'Update cancelled'));
  }

  Future<Result<void>> _updateInternal({
    required String addonId,
    required String branchRef,
    required String profileId,
    JobContext? context,
  }) async {
    if (installedFor(profileId, addonId) == null) {
      return const Err(AppError(message: 'Addon is not installed in this profile'));
    }
    if (isPinned(profileId, addonId)) {
      return const Err(AppError(message: 'Addon is pinned; unpin it before updating'));
    }
    try {
      context?.report(detail: 'Backing up current addon');
      await _backupAddon(profileId, addonId);
    } on Object catch (error) {
      final appError = AppError.from(error, retryable: true);
      context?.fail(appError.message);
      return Err(appError);
    }
    final result = await _installInternal(
      addonId: addonId,
      branchRef: branchRef,
      profileId: profileId,
      context: context,
    );
    if (result.isErr) {
      return Err(AppError(message: 'Update failed: ${result.errorOrNull}'));
    }
    return const Ok(null);
  }

  Future<Result<void>> remove({
    required String addonId,
    required String profileId,
  }) async {
    final installed = await _database.installedAddonsDao.getByAddon(profileId, addonId);
    if (installed == null) {
      return const Err(AppError(message: 'Addon is not installed in this profile'));
    }
    try {
      final directory = p.join(_paths.profilePaths(profileId).mod, addonId);
      deleteAddonEntry(directory);
      final deleted = await _database.installedAddonsDao.deleteAddon(profileId, addonId);
      if (deleted == 0) {
        return const Err(AppError(message: 'Addon is not installed in this profile'));
      }
      return const Ok(null);
    } on Object catch (error) {
      return Err(AppError.from(error, retryable: true));
    }
  }

  Future<String?> _backupAddon(String profileId, String addonId) async {
    final source = Directory(p.join(_paths.profilePaths(profileId).mod, addonId));
    if (!source.existsSync()) {
      return null;
    }
    final stamp = _clock().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final target = Directory(
      p.join(_paths.profilePaths(profileId).backups, 'addon-$addonId-$stamp'),
    );
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: true, followLinks: false)) {
      final relative = p.relative(entity.path, from: source.path);
      final destination = p.join(target.path, relative);
      if (entity is File) {
        await Directory(p.dirname(destination)).create(recursive: true);
        await entity.copy(destination);
      } else if (entity is Directory) {
        await Directory(destination).create(recursive: true);
      }
    }
    return target.path;
  }

  Future<Result<void>> install({
    required String addonId,
    required String branchRef,
    required String profileId,
    bool installRequirements = false,
  }) async {
    final jobs = _jobs;
    if (jobs == null) {
      return _installInternal(
        addonId: addonId,
        branchRef: branchRef,
        profileId: profileId,
        installRequirements: installRequirements,
      );
    }
    final result = await jobs.run<Result<void>>(
      kind: JobKind.install,
      label: 'Install ${byId(addonId)?.displayName ?? addonId}',
      onRetry: () async {
        await install(
          addonId: addonId,
          branchRef: branchRef,
          profileId: profileId,
          installRequirements: installRequirements,
        );
      },
      task: (context) => _installInternal(
        addonId: addonId,
        branchRef: branchRef,
        profileId: profileId,
        installRequirements: installRequirements,
        context: context,
      ),
    );
    return result ?? const Err(AppError(message: 'Install cancelled'));
  }

  Future<Result<void>> _installInternal({
    required String addonId,
    required String branchRef,
    required String profileId,
    bool installRequirements = false,
    JobContext? context,
  }) async {
    final addon = byId(addonId);
    if (addon == null) {
      return const Err(AppError(message: 'Addon not found'));
    }
    final branch = branchOf(addon, branchRef);
    final profile = await _database.profilesDao.getById(profileId);
    if (profile == null) {
      return const Err(AppError(message: 'Profile not found'));
    }

    installing.value = {...installing.value, addonId};
    installErrors.value = {...installErrors.value}..remove(addonId);
    try {
      context?.report(detail: 'Downloading addon');
      await _installer.install(
        zipUri: Uri.parse(branch.zipUrl),
        destinationDirectory: p.join(_paths.profilePaths(profileId).mod, addon.id),
        downloadDirectory: _paths.downloadsCacheDir,
        assetName: '${addon.id}-${branch.gitRef}.zip',
        cancellationToken: context?.token,
        onProgress: (progress) => context?.report(
          fraction: progress.fraction,
          receivedBytes: progress.receivedBytes,
          totalBytes: progress.totalBytes,
          detail: 'Downloading addon',
        ),
      );
      context?.report(detail: 'Installing files');
      final now = _clock();
      await _database.installedAddonsDao.save(
        InstalledAddon(
          id: const Uuid().v4(),
          profileId: profileId,
          addonId: addon.id,
          displayName: addon.displayName,
          gitRef: branch.gitRef,
          version: branch.metadata?.version,
          installedAt: now,
          updatedAt: now,
          catalogLastUpdate: branch.lastUpdateTime,
          sourceUrl: branch.zipUrl,
          source: AddonSource.catalog.name,
          hasRequirements: branch.hasRequirements,
        ),
      );
      if (installRequirements && branch.hasRequirements) {
        context?.report(detail: 'Installing Python packages');
        await _installRequirements(
          profile: profile,
          addonId: addon.id,
          requirementsText: branch.metadata?.requirements ?? '',
          installedAt: now,
          context: context,
        );
      }
      return const Ok(null);
    } on Object catch (error) {
      final appError = error is AppError ? error : AppError.from(error, retryable: true);
      installErrors.value = {...installErrors.value, addonId: appError};
      context?.fail(appError.message);
      return Err(appError);
    } finally {
      installing.value = {...installing.value}..remove(addonId);
    }
  }

  Future<void> _installRequirements({
    required Profile profile,
    required String addonId,
    required String requirementsText,
    required DateTime installedAt,
    JobContext? context,
  }) async {
    final requirements = parseRequirements(
      requirementsText,
    ).where((requirement) => requirement.valid).toList();
    if (requirements.isEmpty) {
      return;
    }
    final runner = _pipRunner;
    final resolver = _pythonResolver;
    if (runner == null || resolver == null) {
      return;
    }

    requirementsInstalling.value = {...requirementsInstalling.value, addonId};
    requirementsErrors.value = {...requirementsErrors.value}..remove(addonId);
    try {
      final build = await _database.buildsDao.getById(profile.buildId);
      if (build == null) {
        throw const AddonInstallException('Build not found');
      }
      final interpreter = await resolver.resolve(
        kind: build.kind,
        buildDirectory: _paths.buildDir(build.id),
        executablePath: build.localPath,
        storedPythonPath: build.pythonPath,
      );
      if (interpreter == null) {
        throw const AddonInstallException(
          'No bundled Python interpreter found for this build',
        );
      }
      final targetDirectory = p.join(
        _paths.profilePaths(profile.id).additionalPythonPackages,
        'py${profile.pythonVersion.replaceAll('.', '')}',
      );
      final result = await runner.install(
        pythonPath: interpreter,
        targetDirectory: targetDirectory,
        packages: requirements.map(requirementSpec).toList(),
        label: addonId,
      );
      context?.setLogPath(result.logPath);
      if (!result.isSuccess) {
        throw AddonInstallException('pip failed: ${result.outputTail}');
      }
      for (final requirement in requirements) {
        await _database.pythonPackagesDao.save(
          PythonPackage(
            id: const Uuid().v4(),
            profileId: profile.id,
            name: requirement.name,
            targetDir: targetDirectory,
            source: 'addon:$addonId',
            installedAt: installedAt,
          ),
        );
      }
    } on Object catch (error) {
      requirementsErrors.value = {
        ...requirementsErrors.value,
        addonId: error is AppError ? error : AppError.from(error, retryable: true),
      };
    } finally {
      requirementsInstalling.value = {...requirementsInstalling.value}..remove(addonId);
    }
  }


  Future<Result<void>> installFromRepository({
    required String repositoryUrl,
    required String gitRef,
    required String profileId,
    CustomRequirementsHandler? onRequirements,
  }) {
    final resolution = resolveRepositoryArchive(repositoryUrl, gitRef);
    final uri = resolution.uri;
    if (uri == null) {
      return Future.value(Err(_archiveResolutionError(resolution.issue!)));
    }
    final addonId = _repositoryAddonId(repositoryUrl, resolution);
    if (addonId == null) {
      return Future.value(
        const Err(AppError(message: 'Could not derive the addon id from the repository URL')),
      );
    }
    final ref = gitRef.trim();
    return _runCustomInstall(
      label: 'Install $addonId',
      addonId: addonId,
      source: AddonSource.repo,
      profileId: profileId,
      sourceUrl: repositoryUrl.trim(),
      gitRef: ref.isEmpty ? null : ref,
      onRequirements: onRequirements,
      prepare: (token, context) => _prepareRepositoryArchive(
        addonId: addonId,
        uri: uri,
        gitRef: ref,
        direct: resolution.direct,
        profileId: profileId,
        token: token,
        context: context,
      ),
    );
  }

  Future<Result<void>> updateFromRepository({
    required String addonId,
    required String profileId,
    CustomRequirementsHandler? onRequirements,
  }) async {
    final existing = await _database.installedAddonsDao.getByAddon(profileId, addonId);
    if (existing == null) {
      return Future.value(const Err(AppError(message: 'Addon is not installed in this profile')));
    }
    if (addonSourceFromStorage(existing.source) != AddonSource.repo) {
      return Future.value(
        const Err(AppError(message: 'This addon was not installed from a repository')),
      );
    }
    if (existing.pinnedAt != null) {
      return const Err(AppError(message: 'Addon is pinned; unpin it before updating'));
    }
    final repositoryUrl = existing.sourceUrl;
    if (repositoryUrl == null || repositoryUrl.trim().isEmpty) {
      return Future.value(const Err(AppError(message: 'Repository URL is missing')));
    }
    final resolution = resolveRepositoryArchive(repositoryUrl, existing.gitRef);
    final uri = resolution.uri;
    if (uri == null) {
      return Future.value(Err(_archiveResolutionError(resolution.issue!)));
    }
    if (_repositoryAddonId(repositoryUrl, resolution) != addonId) {
      return Future.value(
        const Err(AppError(message: 'The repository no longer matches this addon')),
      );
    }
    final ref = existing.gitRef?.trim() ?? '';
    return _runCustomInstall(
      label: 'Update ${existing.displayName}',
      addonId: addonId,
      source: AddonSource.repo,
      profileId: profileId,
      sourceUrl: repositoryUrl.trim(),
      gitRef: ref.isEmpty ? null : ref,
      replaceExisting: true,
      onRequirements: onRequirements,
      prepare: (token, context) => _prepareRepositoryArchive(
        addonId: addonId,
        uri: uri,
        gitRef: ref,
        direct: resolution.direct,
        profileId: profileId,
        token: token,
        context: context,
      ),
    );
  }

  Future<Result<void>> installFromArchive({
    required String archivePath,
    required String profileId,
    String? addonId,
    CustomRequirementsHandler? onRequirements,
  }) {
    final file = File(archivePath);
    if (!file.existsSync()) {
      return Future.value(const Err(AppError(message: 'Archive not found')));
    }
    final id = addonId ?? addonIdFromArchivePath(archivePath);
    if (id == null) {
      return Future.value(
        const Err(AppError(message: 'Could not derive the addon id from the archive name')),
      );
    }
    final absolute = file.absolute.path;
    return _runCustomInstall(
      label: 'Install $id',
      addonId: id,
      source: AddonSource.zip,
      profileId: profileId,
      sourcePath: absolute,
      onRequirements: onRequirements,
      prepare: (token, context) => _prepareLocalArchive(
        addonId: id,
        archivePath: absolute,
        profileId: profileId,
        token: token,
      ),
    );
  }

  Future<Result<void>> reinstallFromArchive({
    required String addonId,
    required String profileId,
    required String archivePath,
    CustomRequirementsHandler? onRequirements,
  }) async {
    final existing = await _database.installedAddonsDao.getByAddon(profileId, addonId);
    if (existing == null) {
      return Future.value(const Err(AppError(message: 'Addon is not installed in this profile')));
    }
    if (addonSourceFromStorage(existing.source) != AddonSource.zip) {
      return Future.value(
        const Err(AppError(message: 'This addon was not installed from an archive')),
      );
    }
    final file = File(archivePath);
    if (!file.existsSync()) {
      return Future.value(const Err(AppError(message: 'Archive not found')));
    }
    final absolute = file.absolute.path;
    return _runCustomInstall(
      label: 'Reinstall ${existing.displayName}',
      addonId: addonId,
      source: AddonSource.zip,
      profileId: profileId,
      sourcePath: absolute,
      replaceExisting: true,
      onRequirements: onRequirements,
      prepare: (token, context) => _prepareLocalArchive(
        addonId: addonId,
        archivePath: absolute,
        profileId: profileId,
        token: token,
      ),
    );
  }

  Future<Result<void>> installFromDirectory({
    required String sourcePath,
    required String profileId,
    String? addonId,
    CustomRequirementsHandler? onRequirements,
  }) {
    final source = Directory(sourcePath);
    if (!source.existsSync()) {
      return Future.value(const Err(AppError(message: 'Directory not found')));
    }
    final normalized = p.normalize(source.absolute.path);
    final modRoot = p.normalize(_paths.profilePaths(profileId).mod);
    if (normalized == modRoot || p.isWithin(modRoot, normalized)) {
      return Future.value(
        const Err(AppError(message: 'Choose a directory outside the profile Mod folder')),
      );
    }
    final id = addonId ?? addonIdFromDirectory(normalized);
    return _runCustomInstall(
      label: 'Link $id',
      addonId: id,
      source: AddonSource.symlink,
      profileId: profileId,
      sourcePath: normalized,
      onRequirements: onRequirements,
      prepare: (token, context) async => _CustomPreparedContent(
        root: normalized,
        commit: () => _installer.linkDirectory(
          sourceDirectory: normalized,
          destinationDirectory: _modPath(profileId, id),
        ),
        discard: () async {},
      ),
    );
  }

  Future<Result<void>> installCustomInProfile({
    required InstalledAddon addon,
    required String profileId,
    String? archivePath,
    CustomRequirementsHandler? onRequirements,
  }) {
    final source = addonSourceFromStorage(addon.source);
    switch (source) {
      case AddonSource.catalog:
        return Future.value(
          const Err(AppError(message: 'Only custom addons can be installed this way')),
        );
      case AddonSource.repo:
        final repositoryUrl = addon.sourceUrl;
        if (repositoryUrl == null || repositoryUrl.trim().isEmpty) {
          return Future.value(const Err(AppError(message: 'Repository URL is missing')));
        }
        return installFromRepository(
          repositoryUrl: repositoryUrl,
          gitRef: addon.gitRef ?? '',
          profileId: profileId,
          onRequirements: onRequirements,
        );
      case AddonSource.zip:
        final path = archivePath ?? addon.sourcePath;
        if (path == null || !File(path).existsSync()) {
          return Future.value(const Err(AppError(message: 'Archive not found')));
        }
        return installFromArchive(
          archivePath: path,
          profileId: profileId,
          addonId: addon.addonId,
          onRequirements: onRequirements,
        );
      case AddonSource.symlink:
        final path = addon.sourcePath;
        if (path == null || !Directory(path).existsSync()) {
          return Future.value(const Err(AppError(message: 'Source directory not found')));
        }
        return installFromDirectory(
          sourcePath: path,
          profileId: profileId,
          addonId: addon.addonId,
          onRequirements: onRequirements,
        );
    }
  }

  Future<_CustomPreparedContent> _prepareRepositoryArchive({
    required String addonId,
    required Uri uri,
    required String gitRef,
    required bool direct,
    required String profileId,
    CancellationToken? token,
    JobContext? context,
  }) async {
    context?.report(detail: 'Downloading addon');
    final archivePath = await _installer.downloadArchive(
      uri: uri,
      directory: _paths.downloadsCacheDir,
      assetName: _archiveAssetName(addonId, uri, gitRef, direct: direct),
      cancellationToken: token,
      onProgress: (progress) => context?.report(
        fraction: progress.fraction,
        receivedBytes: progress.receivedBytes,
        totalBytes: progress.totalBytes,
        detail: 'Downloading addon',
      ),
    );
    final prepared = await _installer.prepareFromArchive(
      archivePath: archivePath,
      destinationDirectory: _modPath(profileId, addonId),
      cancellationToken: token,
    );
    return _CustomPreparedContent(
      root: prepared.contentRoot,
      commit: () => _installer.commitPrepared(prepared, cancellationToken: token),
      discard: () async => _installer.discardPrepared(prepared),
    );
  }

  Future<_CustomPreparedContent> _prepareLocalArchive({
    required String addonId,
    required String archivePath,
    required String profileId,
    CancellationToken? token,
  }) async {
    final prepared = await _installer.prepareFromArchive(
      archivePath: archivePath,
      destinationDirectory: _modPath(profileId, addonId),
      cancellationToken: token,
    );
    return _CustomPreparedContent(
      root: prepared.contentRoot,
      commit: () => _installer.commitPrepared(prepared, cancellationToken: token),
      discard: () async => _installer.discardPrepared(prepared),
    );
  }

  Future<Result<void>> _runCustomInstall({
    required String label,
    required String addonId,
    required AddonSource source,
    required String profileId,
    String? sourceUrl,
    String? sourcePath,
    String? gitRef,
    bool replaceExisting = false,
    CustomRequirementsHandler? onRequirements,
    required Future<_CustomPreparedContent> Function(CancellationToken? token, JobContext? context)
    prepare,
  }) async {
    final jobs = _jobs;
    if (jobs == null) {
      return _installCustomInternal(
        addonId: addonId,
        source: source,
        profileId: profileId,
        sourceUrl: sourceUrl,
        sourcePath: sourcePath,
        gitRef: gitRef,
        replaceExisting: replaceExisting,
        onRequirements: onRequirements,
        prepare: prepare,
      );
    }
    final result = await jobs.run<Result<void>>(
      kind: JobKind.install,
      label: label,
      onRetry: () async {
        await _runCustomInstall(
          label: label,
          addonId: addonId,
          source: source,
          profileId: profileId,
          sourceUrl: sourceUrl,
          sourcePath: sourcePath,
          gitRef: gitRef,
          replaceExisting: replaceExisting,
          onRequirements: onRequirements,
          prepare: prepare,
        );
      },
      task: (context) => _installCustomInternal(
        addonId: addonId,
        source: source,
        profileId: profileId,
        sourceUrl: sourceUrl,
        sourcePath: sourcePath,
        gitRef: gitRef,
        replaceExisting: replaceExisting,
        onRequirements: onRequirements,
        prepare: prepare,
        context: context,
      ),
    );
    return result ?? const Err(AppError(message: 'Install cancelled'));
  }

  Future<Result<void>> _installCustomInternal({
    required String addonId,
    required AddonSource source,
    required String profileId,
    String? sourceUrl,
    String? sourcePath,
    String? gitRef,
    required bool replaceExisting,
    CustomRequirementsHandler? onRequirements,
    required Future<_CustomPreparedContent> Function(CancellationToken? token, JobContext? context)
    prepare,
    JobContext? context,
  }) async {
    if (validateAddonId(addonId) != null) {
      return Err(AppError(message: 'Invalid addon id "$addonId"'));
    }
    final profile = await _database.profilesDao.getById(profileId);
    if (profile == null) {
      return const Err(AppError(message: 'Profile not found'));
    }

    final existing = await _database.installedAddonsDao.getByAddon(profileId, addonId);
    if (replaceExisting) {
      if (existing == null) {
        return const Err(AppError(message: 'Addon is not installed in this profile'));
      }
      if (existing.pinnedAt != null) {
        return const Err(AppError(message: 'Addon is pinned; unpin it before updating'));
      }
    } else {
      if (existing != null) {
        return Err(
          AppError(
            message: 'Addon "$addonId" is already installed in this profile; remove it first',
          ),
        );
      }
      final destination = _modPath(profileId, addonId);
      if (FileSystemEntity.typeSync(destination, followLinks: false) !=
          FileSystemEntityType.notFound) {
        return Err(
          AppError(
            message: 'A folder named "$addonId" already exists in the profile; remove it first',
          ),
        );
      }
    }

    installing.value = {...installing.value, addonId};
    installErrors.value = {...installErrors.value}..remove(addonId);
    _CustomPreparedContent? prepared;
    try {
      if (replaceExisting) {
        context?.report(detail: 'Backing up current addon');
        await _backupAddon(profileId, addonId);
      }
      prepared = await prepare(context?.token, context);
      context?.report(detail: 'Reading addon metadata');
      final info = readPackageXmlInfo(prepared.root);
      final requirementsText = readRequirementsFromDirectory(prepared.root);
      var installPackages = false;
      if (requirementsText != null) {
        final requirements = parseRequirements(
          requirementsText,
        ).where((requirement) => requirement.valid).toList();
        if (requirements.isNotEmpty && onRequirements != null) {
          final decision = await onRequirements(requirements);
          if (decision == CustomRequirementsDecision.cancel) {
            prepared.discard();
            prepared = null;
            return const Err(AppError(message: 'Install cancelled'));
          }
          installPackages = decision == CustomRequirementsDecision.installPackages;
        }
      }
      context?.report(detail: 'Installing files');
      await prepared.commit();
      prepared = null;

      final now = _clock();
      final name = info.name.trim().isEmpty ? addonId : info.name.trim();
      final version = info.version.trim().isEmpty ? null : info.version.trim();
      await _database.installedAddonsDao.save(
        InstalledAddon(
          id: existing?.id ?? const Uuid().v4(),
          profileId: profileId,
          addonId: addonId,
          displayName: name,
          gitRef: gitRef,
          version: version,
          installedAt: existing?.installedAt ?? now,
          updatedAt: now,
          catalogLastUpdate: null,
          sourceUrl: sourceUrl,
          source: source.name,
          sourcePath: sourcePath,
          hasRequirements: requirementsText != null,
        ),
      );
      if (installPackages && requirementsText != null) {
        context?.report(detail: 'Installing Python packages');
        await _installRequirements(
          profile: profile,
          addonId: addonId,
          requirementsText: requirementsText,
          installedAt: now,
          context: context,
        );
      }
      return const Ok(null);
    } on Object catch (error) {
      try {
        prepared?.discard();
      } on Object {
        // The staging directory is best-effort cleanup.
      }
      prepared = null;
      final appError = error is AppError ? error : AppError.from(error, retryable: true);
      installErrors.value = {...installErrors.value, addonId: appError};
      context?.fail(appError.message);
      return Err(appError);
    } finally {
      installing.value = {...installing.value}..remove(addonId);
    }
  }

  String _modPath(String profileId, String addonId) =>
      p.join(_paths.profilePaths(profileId).mod, addonId);

  String _archiveAssetName(String addonId, Uri uri, String gitRef, {required bool direct}) {
    if (direct) {
      final name = p.basename(uri.path);
      if (name.isNotEmpty) {
        return name;
      }
    }
    final ref = _safeFileToken(gitRef);
    return ref.isEmpty ? '$addonId.zip' : '$addonId-$ref.zip';
  }

  String _safeFileToken(String value) => value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');

  String? _repositoryAddonId(String repositoryUrl, ArchiveResolution resolution) {
    if (resolution.direct && resolution.uri != null) {
      return addonIdFromArchivePath(resolution.uri!.path);
    }
    return addonIdFromRepositoryUrl(repositoryUrl);
  }

  AppError _archiveResolutionError(ArchiveResolutionIssue issue) {
    final message = switch (issue) {
      ArchiveResolutionIssue.invalidUrl => 'Enter a valid http(s) repository or archive URL',
      ArchiveResolutionIssue.unsupportedScheme => 'Only http(s) URLs are supported',
      ArchiveResolutionIssue.unsupportedHost => 'Unsupported host; paste a direct archive URL',
      ArchiveResolutionIssue.missingRef => 'Enter a branch, tag or ref',
    };
    return AppError(message: message);
  }

  void clearInstallError(String addonId) {
    installErrors.value = {...installErrors.value}..remove(addonId);
  }

  void dispose() {
    _installedSubscription?.cancel();
    _installedSubscription = null;
    _buildsSubscription?.cancel();
    _buildsSubscription = null;
  }
}

class _CustomPreparedContent {
  const _CustomPreparedContent({required this.root, required this.commit, required this.discard});

  final String root;
  final Future<AddonInstallResult> Function() commit;
  final Future<void> Function() discard;
}
