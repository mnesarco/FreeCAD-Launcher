import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/addon_update_rules.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/domain/python/requirements_parser.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/pip_runner.dart';
import 'package:freecad_launcher/platform/python_env.dart';
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
    loading.value = true;
    error.value = null;
    try {
      final result = await _catalog.load(forceRefresh: forceRefresh);
      addons.value = result.addons;
      freshness.value = result.freshness;
      loaded.value = true;
    } on Object catch (failure) {
      error.value = AppError.from(failure, retryable: true);
    } finally {
      loading.value = false;
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

  bool isUpdateAvailable(String profileId, String addonId) {
    final installed = installedFor(profileId, addonId);
    if (installed == null) {
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
    if (installedFor(profileId, addonId) == null) {
      return const Err(AppError(message: 'Addon is not installed in this profile'));
    }
    try {
      final directory = Directory(p.join(_paths.profilePaths(profileId).mod, addonId));
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
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
          hasRequirements: branch.hasRequirements,
        ),
      );
      if (installRequirements && branch.hasRequirements) {
        context?.report(detail: 'Installing Python packages');
        await _installRequirements(
          profile: profile,
          addon: addon,
          branch: branch,
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
    required Addon addon,
    required AddonBranch branch,
    required DateTime installedAt,
    JobContext? context,
  }) async {
    final requirements = parseRequirements(
      branch.metadata?.requirements ?? '',
    ).where((requirement) => requirement.valid).toList();
    if (requirements.isEmpty) {
      return;
    }
    final runner = _pipRunner;
    final resolver = _pythonResolver;
    if (runner == null || resolver == null) {
      return;
    }

    requirementsInstalling.value = {...requirementsInstalling.value, addon.id};
    requirementsErrors.value = {...requirementsErrors.value}..remove(addon.id);
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
        label: addon.id,
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
            source: 'addon:${addon.id}',
            installedAt: installedAt,
          ),
        );
      }
    } on Object catch (error) {
      requirementsErrors.value = {
        ...requirementsErrors.value,
        addon.id: error is AppError ? error : AppError.from(error, retryable: true),
      };
    } finally {
      requirementsInstalling.value = {...requirementsInstalling.value}..remove(addon.id);
    }
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
