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
import 'package:freecad_launcher/core/path_segments.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/addon_dependencies.dart';
import 'package:freecad_launcher/domain/addons/addon_id_rules.dart';
import 'package:freecad_launcher/domain/addons/addon_source.dart';
import 'package:freecad_launcher/domain/addons/addon_update_rules.dart';
import 'package:freecad_launcher/domain/addons/package_xml.dart';
import 'package:freecad_launcher/domain/addons/repository_archive.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/domain/python/python_names.dart';
import 'package:freecad_launcher/domain/python/python_stdlib_names.dart';
import 'package:freecad_launcher/domain/python/requirements_parser.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/addon_manifest_reader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/pip_runner.dart';
import 'package:freecad_launcher/platform/python_env.dart';
import 'package:freecad_launcher/platform/python_execution.dart';
import 'package:freecad_launcher/platform/python_package_probe.dart';
import 'package:freecad_launcher/state/jobs_controller.dart';

enum AddonInstalledFilter { installed, notInstalled }

class AddonsController {
  AddonsController({
    required AppDatabase database,
    required AddonCatalog catalog,
    required AddonInstaller installer,
    required AppPaths paths,
    PipRunner? pipRunner,
    PythonEnvResolver? pythonResolver,
    PythonPackageProbe? packageProbe,
    Future<bool> Function()? fuseAvailable,
    JobsController? jobs,
    DateTime Function()? clock,
  }) : _database = database,
       _catalog = catalog,
       _installer = installer,
       _paths = paths,
       _pipRunner = pipRunner,
       _pythonExecution = pythonResolver == null
           ? null
           : PythonExecutionResolver(envResolver: pythonResolver, fuseAvailable: fuseAvailable),
       _packageProbe = packageProbe,
       _jobs = jobs,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final AddonCatalog _catalog;
  final AddonInstaller _installer;
  final AppPaths _paths;
  final PipRunner? _pipRunner;
  final PythonExecutionResolver? _pythonExecution;
  final PythonPackageProbe? _packageProbe;
  final JobsController? _jobs;
  final DateTime Function() _clock;

  final Map<String, Map<String, bool>> _probeCache = {};

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
  final installWarnings = signal<Map<String, List<String>>>({});
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

  int get activeFilterCount => contentFilter.value.length + installedFilter.value.length;

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
    return installedAddons.value.any((row) => row.profileId == profileId && row.addonId == addonId);
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
      final marker = File(p.join(_modPath(row.profileId, row.addonId), disabledMarkerName));
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
    AddonDependencySelection? selection,
    AddonDependencyHandler? onDependencies,
  }) async {
    final jobs = _jobs;
    if (jobs == null) {
      return _updateInternal(
        addonId: addonId,
        branchRef: branchRef,
        profileId: profileId,
        selection: selection,
        onDependencies: onDependencies,
      );
    }
    final result = await jobs.run<Result<void>>(
      kind: JobKind.install,
      label: 'Update ${byId(addonId)?.displayName ?? addonId}',
      onRetry: () async {
        await update(
          addonId: addonId,
          branchRef: branchRef,
          profileId: profileId,
          selection: selection,
          onDependencies: onDependencies,
        );
      },
      task: (context) => _updateInternal(
        addonId: addonId,
        branchRef: branchRef,
        profileId: profileId,
        selection: selection,
        onDependencies: onDependencies,
        context: context,
      ),
    );
    return result ?? const Err(AppError(message: 'Update cancelled'));
  }

  Future<Result<void>> _updateInternal({
    required String addonId,
    required String branchRef,
    required String profileId,
    AddonDependencySelection? selection,
    AddonDependencyHandler? onDependencies,
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
      selection: selection,
      onDependencies: onDependencies,
      context: context,
    );
    if (result.isErr) {
      return Err(AppError(message: 'Update failed: ${result.errorOrNull}'));
    }
    return const Ok(null);
  }

  Future<Result<void>> remove({required String addonId, required String profileId}) async {
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
      p.join(_paths.profilePaths(profileId).backups, 'addon-${safePathSegment(addonId)}-$stamp'),
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
    AddonDependencySelection? selection,
    AddonDependencyHandler? onDependencies,
  }) async {
    final jobs = _jobs;
    if (jobs == null) {
      return _installInternal(
        addonId: addonId,
        branchRef: branchRef,
        profileId: profileId,
        selection: selection,
        onDependencies: onDependencies,
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
          selection: selection,
          onDependencies: onDependencies,
        );
      },
      task: (context) => _installInternal(
        addonId: addonId,
        branchRef: branchRef,
        profileId: profileId,
        selection: selection,
        onDependencies: onDependencies,
        context: context,
      ),
    );
    return result ?? const Err(AppError(message: 'Install cancelled'));
  }

  Future<Result<void>> _installInternal({
    required String addonId,
    required String branchRef,
    required String profileId,
    AddonDependencySelection? selection,
    AddonDependencyHandler? onDependencies,
    JobContext? context,
    bool asDependency = false,
    Set<String> chain = const {},
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
    installWarnings.value = {...installWarnings.value}..remove(addonId);
    requirementsErrors.value = {...requirementsErrors.value}
      ..remove(requirementErrorKey(profileId, addonId));
    PreparedAddonInstall? prepared;
    try {
      context?.report(detail: 'Downloading addon');
      final archivePath = await _installer.downloadArchive(
        uri: Uri.parse(branch.zipUrl),
        directory: _paths.downloadsCacheDir,
        assetName: '${addon.id}-${branch.gitRef}.zip',
        cancellationToken: context?.token,
        onProgress: (progress) => context?.report(
          fraction: progress.fraction,
          receivedBytes: progress.receivedBytes,
          totalBytes: progress.totalBytes,
          detail: 'Downloading addon',
        ),
      );
      if (context?.token.isCancelled ?? false) {
        throw const AddonInstallException('Addon installation cancelled');
      }
      context?.report(detail: 'Extracting addon');
      prepared = await _installer.prepareFromArchive(
        archivePath: archivePath,
        destinationDirectory: p.join(_paths.profilePaths(profileId).mod, addon.id),
        cancellationToken: context?.token,
      );
      _recordInstallWarnings(addon.id, prepared.skippedEntries, context: context);
      final requirementsText =
          readRequirementsFromDirectory(prepared.contentRoot) ?? branch.metadata?.requirements;
      var hasPythonDependencies = false;
      if (!asDependency) {
        final dependencies = _stagedDependencies(prepared.contentRoot, branch);
        // Never extract a bundled AppImage just to build the consent preview;
        // the full probe runs once the user has accepted the dependencies.
        var plan = await _dependencyPlan(
          addonId: addon.id,
          dependencies: dependencies,
          requirementsText: requirementsText,
          profileId: profileId,
          allowExtraction: false,
        );
        selection ??= await _decideDependencies(plan: plan, onDependencies: onDependencies);
        if (selection == null) {
          return const Err(AppError(message: 'Install cancelled'));
        }
        if (selection.installRequired) {
          plan = await _dependencyPlan(
            addonId: addon.id,
            dependencies: dependencies,
            requirementsText: requirementsText,
            profileId: profileId,
            context: context,
          );
        }
        hasPythonDependencies = plan.requiredPython.isNotEmpty || plan.optionalPython.isNotEmpty;
        await _runDependencies(
          plan: plan,
          selection: selection,
          profile: profile,
          addonId: addon.id,
          chain: {...chain, addon.id},
          context: context,
        );
      } else {
        hasPythonDependencies = _declaresPythonDependencies(branch, requirementsText);
      }
      context?.report(detail: 'Installing files');
      await _installer.commitPrepared(prepared, cancellationToken: context?.token);
      prepared = null;
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
          hasRequirements: hasPythonDependencies,
        ),
      );
      return const Ok(null);
    } on Object catch (error) {
      try {
        if (prepared != null) {
          _installer.discardPrepared(prepared);
        }
      } on Object {
        // Staging cleanup is best-effort.
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

  bool _declaresPythonDependencies(AddonBranch branch, String? requirementsText) {
    if (requirementsText != null && requirementsText.trim().isNotEmpty) {
      return true;
    }
    if (branch.hasRequirements) {
      return true;
    }
    return branch.metadata?.dependencies.any(
          (dependency) => dependency.type == AddonDependencyType.python,
        ) ??
        false;
  }

  /// Resolves the dependency closure for one catalog branch, filtered by what
  /// the profile already has (installed addons and importable Python packages).
  /// Used by the UI to build the pre-install consent dialog.
  Future<AddonDependencyPlan> prepareDependencies({
    required String addonId,
    required String branchRef,
    required String profileId,
    String? requirementsText,
  }) async {
    final addon = byId(addonId);
    final branch = addon == null ? null : branchOf(addon, branchRef);
    return _dependencyPlan(
      addonId: addonId,
      dependencies: branch?.metadata?.dependencies ?? const [],
      requirementsText: requirementsText ?? branch?.metadata?.requirements,
      profileId: profileId,
      allowExtraction: false,
      allowAppImageMacro: false,
    );
  }

  /// Display names of installed addons in [profileId] whose dependency closure
  /// includes [addonId] (removal warning, D-111).
  List<String> dependentsOf(String profileId, String addonId) {
    final dependents = <String>[];
    for (final row in installedAddons.value) {
      if (row.profileId != profileId || row.addonId == addonId) {
        continue;
      }
      final addon = byId(row.addonId);
      if (addon == null) {
        continue;
      }
      final branch = branchOf(addon, row.gitRef ?? addon.primaryBranch.gitRef);
      final plan = resolveAddonDependencies(
        addonId: addon.id,
        dependencies: branch.metadata?.dependencies ?? const [],
        catalog: addons.value,
      );
      final dependsOnAddon = [
        ...plan.requiredAddons,
        ...plan.optionalAddons,
      ].any((dependency) => dependency.addon?.id == addonId);
      if (dependsOnAddon) {
        dependents.add(row.displayName);
      }
    }
    return dependents;
  }

  Future<AddonDependencyPlan> _dependencyPlan({
    required String addonId,
    required List<AddonDependency> dependencies,
    required String? requirementsText,
    required String profileId,
    bool allowExtraction = true,
    bool allowAppImageMacro = true,
    JobContext? context,
  }) async {
    final profile = await _database.profilesDao.getById(profileId);
    if (profile == null) {
      return const AddonDependencyPlan();
    }
    final build = await _database.buildsDao.getById(profile.buildId);
    final freecadVersion = build?.version;
    final installed = await _database.installedAddonsDao.getByProfile(profileId);
    final installedIds = {for (final row in installed) row.addonId};

    AddonBranch selectBranch(Addon candidate) => _dependencyBranch(candidate, freecadVersion);

    final candidates = resolveAddonDependencies(
      addonId: addonId,
      dependencies: dependencies,
      catalog: addons.value,
      requirementsText: requirementsText,
      installedAddonIds: installedIds,
      branchOf: selectBranch,
    );
    final pythonCandidates = [...candidates.requiredPython, ...candidates.optionalPython];
    if (pythonCandidates.isEmpty) {
      return candidates;
    }
    final available = await _availablePythonPackages(
      profile,
      pythonCandidates,
      allowExtraction: allowExtraction,
      allowAppImageMacro: allowAppImageMacro,
      context: context,
    );
    if (available.isEmpty) {
      return candidates;
    }
    return resolveAddonDependencies(
      addonId: addonId,
      dependencies: dependencies,
      catalog: addons.value,
      requirementsText: requirementsText,
      installedAddonIds: installedIds,
      availablePythonPackages: available,
      branchOf: selectBranch,
    );
  }

  Future<AddonDependencySelection?> _decideDependencies({
    required AddonDependencyPlan plan,
    required AddonDependencyHandler? onDependencies,
  }) async {
    if (!plan.hasInstallable && plan.invalidRequirements.isEmpty) {
      return AddonDependencySelection.none;
    }
    if (onDependencies == null) {
      return AddonDependencySelection.requiredOnly;
    }
    return onDependencies(plan);
  }

  Future<void> _runDependencies({
    required AddonDependencyPlan plan,
    required AddonDependencySelection selection,
    required Profile profile,
    required String addonId,
    required Set<String> chain,
    JobContext? context,
  }) async {
    if (!selection.installRequired) {
      return;
    }
    final python = <ResolvedPythonRequirement>[
      ...plan.requiredPython,
      for (final entry in plan.optionalPython)
        if (selection.optionalPackageNames.contains(
          normalizePythonPackageName(entry.requirement.name),
        ))
          entry,
    ];
    if (python.isNotEmpty) {
      context?.report(detail: 'Installing Python packages');
      await _installPythonRequirements(
        profile: profile,
        requirements: python,
        addonId: addonId,
        context: context,
      );
    }

    final dependentAddons = <ResolvedAddonDependency>[
      ...plan.requiredAddons,
      for (final entry in plan.optionalAddons)
        if (selection.optionalAddonIds.contains(entry.addon!.id)) entry,
    ];
    for (final dependency in dependentAddons) {
      final addon = dependency.addon!;
      final branchRef = dependency.branchRef ?? addon.primaryBranch.gitRef;
      if (chain.contains(addon.id) || installedFor(profile.id, addon.id) != null) {
        continue;
      }
      context?.report(detail: 'Installing dependency ${addon.displayName}');
      await _installInternal(
        addonId: addon.id,
        branchRef: branchRef,
        profileId: profile.id,
        asDependency: true,
        chain: {...chain, addon.id},
        context: context,
      );
    }
  }

  Future<void> _installPythonRequirements({
    required Profile profile,
    required List<ResolvedPythonRequirement> requirements,
    required String addonId,
    JobContext? context,
  }) async {
    if (requirements.isEmpty) {
      return;
    }
    final runner = _pipRunner;
    if (runner == null) {
      return;
    }
    final errorKey = requirementErrorKey(profile.id, addonId);

    requirementsInstalling.value = {...requirementsInstalling.value, errorKey};
    requirementsErrors.value = {...requirementsErrors.value}..remove(errorKey);
    try {
      final execution = await _resolveExecution(profile, context: context);
      if (execution == null) {
        throw const AddonInstallException('No Python execution target found for this build');
      }
      Future<PipResult> runPip(List<String> specs) => runner.install(
        pythonPath: execution is PythonInterpreterExecution ? execution.pythonPath : null,
        appImagePath: execution is PythonAppImageExecution ? execution.appImagePath : null,
        targetDirectory: _pythonTargetDirectory(profile),
        packages: specs,
        label: addonId,
      );
      final targetDirectory = _pythonTargetDirectory(profile);
      final installedEntries = <ResolvedPythonRequirement>[];
      var pending = requirements;

      if (pending.length > 1) {
        final batch = await runPip([
          for (final entry in pending) requirementSpec(entry.requirement),
        ]);
        context?.setLogPath(batch.logPath);
        if (batch.isSuccess) {
          installedEntries.addAll(pending);
          pending = const [];
        }
      }

      final failures = <String>[];
      for (final entry in pending) {
        final result = await runPip([requirementSpec(entry.requirement)]);
        context?.setLogPath(result.logPath);
        if (result.isSuccess) {
          installedEntries.add(entry);
        } else {
          failures.add('${entry.requirement.name}: ${result.outputTail}');
        }
      }

      final now = _clock();
      for (final entry in installedEntries) {
        await _database.pythonPackagesDao.save(
          PythonPackage(
            id: const Uuid().v4(),
            profileId: profile.id,
            name: entry.requirement.name,
            targetDir: targetDirectory,
            source: 'addon:${entry.declaredByAddonId}',
            installedAt: now,
          ),
        );
      }
      if (failures.isNotEmpty) {
        throw AddonInstallException('pip failed: ${failures.join('; ')}');
      }
    } on Object catch (error) {
      requirementsErrors.value = {
        ...requirementsErrors.value,
        errorKey: error is AppError ? error : AppError.from(error, retryable: true),
      };
    } finally {
      requirementsInstalling.value = {...requirementsInstalling.value}..remove(errorKey);
    }
  }

  Future<PythonExecution?> _resolveExecution(
    Profile profile, {
    bool allowExtraction = true,
    bool allowAppImageMacro = true,
    JobContext? context,
  }) async {
    final resolver = _pythonExecution;
    if (resolver == null) {
      return null;
    }
    final build = await _database.buildsDao.getById(profile.buildId);
    if (build == null) {
      return null;
    }
    var extractedFiles = 0;
    return resolver.resolve(
      kind: build.kind,
      buildDirectory: _paths.existingBuildDir(build.id) ?? _paths.buildDir(build.id),
      executablePath: build.localPath,
      storedPythonPath: build.pythonPath,
      allowExtraction: allowExtraction,
      allowAppImageMacro: allowAppImageMacro,
      onOutput: context == null
          ? null
          : (_) {
              extractedFiles++;
              if (extractedFiles % 25 == 0) {
                context.report(detail: 'Preparing Python ($extractedFiles files)');
              }
            },
    );
  }

  String _pythonTargetDirectory(Profile profile) => p.join(
    _paths.profilePaths(profile.id).additionalPythonPackages,
    'py${profile.pythonVersion.replaceAll('.', '')}',
  );

  Future<Set<String>> _availablePythonPackages(
    Profile profile,
    Iterable<ResolvedPythonRequirement> candidates, {
    bool allowExtraction = true,
    bool allowAppImageMacro = true,
    JobContext? context,
  }) async {
    final names = <String>{
      for (final entry in candidates)
        if (normalizePythonPackageName(entry.requirement.name).isNotEmpty)
          normalizePythonPackageName(entry.requirement.name),
    };
    if (names.isEmpty) {
      return const {};
    }
    // Only successful probe results are cached: a fallback answer (no
    // execution target yet) must not prevent a real probe once one exists.
    final cacheKey = '${profile.buildId}:${profile.id}';
    final cache = _probeCache[cacheKey] ??= {};
    final available = {
      for (final entry in cache.entries)
        if (entry.value) entry.key,
    };
    final missing = names.where((name) => !cache.containsKey(name)).toList();
    if (missing.isEmpty) {
      return available;
    }

    Set<String>? probed;
    final probe = _packageProbe;
    if (probe != null) {
      final execution = await _resolveExecution(
        profile,
        allowExtraction: allowExtraction,
        allowAppImageMacro: allowAppImageMacro,
        context: context,
      );
      final targetDirectory = _pythonTargetDirectory(profile);
      if (execution is PythonInterpreterExecution) {
        probed = await probe.availablePackages(
          pythonPath: execution.pythonPath,
          targetDirectory: targetDirectory,
          names: missing,
        );
      } else if (execution is PythonAppImageExecution) {
        probed = await probe.availablePackagesInFreeCad(
          executablePath: execution.appImagePath,
          targetDirectory: targetDirectory,
          names: missing,
        );
      }
    }
    if (probed != null) {
      for (final name in missing) {
        cache[name] = probed.contains(name);
      }
      available.addAll(probed);
      return available;
    }

    final recorded = await _database.pythonPackagesDao.getByProfile(profile.id);
    final recordedNames = {for (final row in recorded) normalizePythonPackageName(row.name)};
    for (final name in missing) {
      if (recordedNames.contains(name) || pythonStdlibModuleNames.contains(name)) {
        available.add(name);
      }
    }
    return available;
  }

  AddonBranch _dependencyBranch(Addon addon, String? freecadVersion) {
    final target = freecadVersion == null ? null : FreeCadVersion.tryParse(freecadVersion);
    if (target != null) {
      for (final branch in addon.branches) {
        final min = branch.freecadMin == null ? null : FreeCadVersion.tryParse(branch.freecadMin!);
        final max = branch.freecadMax == null ? null : FreeCadVersion.tryParse(branch.freecadMax!);
        if (min != null && target.compareTo(min) < 0) {
          continue;
        }
        if (max != null && target.compareTo(max) > 0) {
          continue;
        }
        return branch;
      }
    }
    return addon.primaryBranch;
  }

  List<AddonDependency> _stagedDependencies(String root, AddonBranch branch) {
    try {
      return readPackageXmlInfo(root).dependencies;
    } on Object {
      return branch.metadata?.dependencies ?? const [];
    }
  }

  Future<Result<void>> installFromRepository({
    required String repositoryUrl,
    required String gitRef,
    required String profileId,
    AddonDependencyHandler? onDependencies,
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
      onDependencies: onDependencies,
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
    AddonDependencyHandler? onDependencies,
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
      onDependencies: onDependencies,
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
    AddonDependencyHandler? onDependencies,
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
      onDependencies: onDependencies,
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
    AddonDependencyHandler? onDependencies,
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
      onDependencies: onDependencies,
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
    AddonDependencyHandler? onDependencies,
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
      onDependencies: onDependencies,
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
    AddonDependencyHandler? onDependencies,
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
          onDependencies: onDependencies,
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
          onDependencies: onDependencies,
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
          onDependencies: onDependencies,
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
      skippedEntries: prepared.skippedEntries,
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
      skippedEntries: prepared.skippedEntries,
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
    AddonDependencySelection? selection,
    AddonDependencyHandler? onDependencies,
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
        selection: selection,
        onDependencies: onDependencies,
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
          selection: selection,
          onDependencies: onDependencies,
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
        selection: selection,
        onDependencies: onDependencies,
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
    AddonDependencySelection? selection,
    AddonDependencyHandler? onDependencies,
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
    installWarnings.value = {...installWarnings.value}..remove(addonId);
    requirementsErrors.value = {...requirementsErrors.value}
      ..remove(requirementErrorKey(profileId, addonId));
    _CustomPreparedContent? prepared;
    try {
      if (replaceExisting) {
        context?.report(detail: 'Backing up current addon');
        await _backupAddon(profileId, addonId);
      }
      prepared = await prepare(context?.token, context);
      _recordInstallWarnings(addonId, prepared.skippedEntries, context: context);
      context?.report(detail: 'Reading addon metadata');
      final info = readPackageXmlInfo(prepared.root);
      final requirementsText = readRequirementsFromDirectory(prepared.root);
      // The consent preview must not trigger a silent AppImage extraction.
      var plan = await _dependencyPlan(
        addonId: addonId,
        dependencies: info.dependencies,
        requirementsText: requirementsText,
        profileId: profileId,
        allowExtraction: false,
      );
      final resolvedSelection =
          selection ?? await _decideDependencies(plan: plan, onDependencies: onDependencies);
      if (resolvedSelection == null) {
        prepared.discard();
        prepared = null;
        return const Err(AppError(message: 'Install cancelled'));
      }
      if (resolvedSelection.installRequired) {
        plan = await _dependencyPlan(
          addonId: addonId,
          dependencies: info.dependencies,
          requirementsText: requirementsText,
          profileId: profileId,
          context: context,
        );
      }
      final hasPythonDependencies =
          plan.requiredPython.isNotEmpty || plan.optionalPython.isNotEmpty;
      await _runDependencies(
        plan: plan,
        selection: resolvedSelection,
        profile: profile,
        addonId: addonId,
        chain: {addonId},
        context: context,
      );
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
          hasRequirements: hasPythonDependencies,
        ),
      );
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

  void _recordInstallWarnings(
    String addonId,
    List<SkippedArchiveEntry> entries, {
    JobContext? context,
  }) {
    if (entries.isEmpty) {
      return;
    }
    final messages = [
      for (final entry in entries)
        entry.symlinkTarget == null || entry.symlinkTarget!.isEmpty
            ? '${entry.path} (symbolic link)'
            : '${entry.path} -> ${entry.symlinkTarget}',
    ];
    installWarnings.value = {...installWarnings.value, addonId: messages};
    for (final message in messages) {
      appLogger.warn('Skipped symbolic link in addon "$addonId": $message', tag: 'addons');
    }
    context?.report(detail: 'Skipped ${messages.length} symbolic link(s)');
  }

  void clearInstallError(String addonId) {
    installErrors.value = {...installErrors.value}..remove(addonId);
    installWarnings.value = {...installWarnings.value}..remove(addonId);
  }

  void dispose() {
    _installedSubscription?.cancel();
    _installedSubscription = null;
    _buildsSubscription?.cancel();
    _buildsSubscription = null;
  }
}

class _CustomPreparedContent {
  const _CustomPreparedContent({
    required this.root,
    required this.commit,
    required this.discard,
    this.skippedEntries = const [],
  });

  final String root;
  final Future<AddonInstallResult> Function() commit;
  final Future<void> Function() discard;
  final List<SkippedArchiveEntry> skippedEntries;
}
