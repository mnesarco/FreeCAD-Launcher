import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';

enum AddonInstalledFilter { installed, notInstalled }

class AddonsController {
  AddonsController({required AppDatabase database, required AddonCatalog catalog})
    : _database = database,
      _catalog = catalog;

  final AppDatabase _database;
  final AddonCatalog _catalog;

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

  void dispose() {
    _installedSubscription?.cancel();
    _installedSubscription = null;
    _buildsSubscription?.cancel();
    _buildsSubscription = null;
  }
}
