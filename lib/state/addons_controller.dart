import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/paths.dart';

enum AddonInstalledFilter { installed, notInstalled }

class AddonsController {
  AddonsController({
    required AppDatabase database,
    required AddonCatalog catalog,
    required AddonInstaller installer,
    required AppPaths paths,
    DateTime Function()? clock,
  }) : _database = database,
       _catalog = catalog,
       _installer = installer,
       _paths = paths,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final AddonCatalog _catalog;
  final AddonInstaller _installer;
  final AppPaths _paths;
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

  Future<Result<void>> install({
    required String addonId,
    required String branchRef,
    required String profileId,
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
      await _installer.install(
        zipUri: Uri.parse(branch.zipUrl),
        destinationDirectory: p.join(_paths.profilePaths(profileId).mod, addon.id),
        downloadDirectory: _paths.downloadsCacheDir,
        assetName: '${addon.id}-${branch.gitRef}.zip',
      );
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
      return const Ok(null);
    } on Object catch (error) {
      final appError = error is AppError ? error : AppError.from(error, retryable: true);
      installErrors.value = {...installErrors.value, addonId: appError};
      return Err(appError);
    } finally {
      installing.value = {...installing.value}..remove(addonId);
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
