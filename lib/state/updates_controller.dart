import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/data/daos/settings_dao.dart';
import 'package:freecad_launcher/domain/addons/addon_update.dart';
import 'package:freecad_launcher/domain/addons/addon_update_rules.dart';
import 'package:freecad_launcher/state/addons_controller.dart';

const addonUpdateLastCheckedKey = 'updates.addons.lastCheckedAt';

class UpdatesController {
  UpdatesController({
    required AddonsController addons,
    required SettingsDao settingsDao,
    DateTime Function()? clock,
  }) : _addons = addons,
       _settingsDao = settingsDao,
       _clock = clock ?? DateTime.now;

  final AddonsController _addons;
  final SettingsDao _settingsDao;
  final DateTime Function() _clock;

  final checking = signal(false);
  final lastCheckedAt = signal<DateTime?>(null);

  bool _started = false;

  late final outdated = computed<List<AddonUpdate>>(() {
    final result = <AddonUpdate>[];
    for (final installed in _addons.installedAddons.value) {
      if (installed.pinnedAt != null) {
        continue;
      }
      final addon = _addons.byId(installed.addonId);
      if (addon == null) {
        continue;
      }
      final branch = _addons.branchOf(addon, installed.gitRef ?? addon.primaryBranch.gitRef);
      final changed = addonContentChanged(
        catalogLastUpdate: branch.lastUpdateTime,
        catalogVersion: branch.metadata?.version,
        installedCatalogLastUpdate: installed.catalogLastUpdate,
        installedVersion: installed.version,
      );
      if (!changed) {
        continue;
      }
      result.add(
        AddonUpdate(
          profileId: installed.profileId,
          addonId: installed.addonId,
          displayName: installed.displayName,
          branchRef: branch.gitRef,
          installedVersion: installed.version,
          catalogVersion: branch.metadata?.version,
        ),
      );
    }
    result.sort((a, b) {
      final byName = a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      if (byName != 0) {
        return byName;
      }
      return a.profileId.compareTo(b.profileId);
    });
    return result;
  });

  late final outdatedByProfile = computed<Map<String, List<AddonUpdate>>>(() {
    final grouped = <String, List<AddonUpdate>>{};
    for (final update in outdated.value) {
      grouped.putIfAbsent(update.profileId, () => []).add(update);
    }
    return grouped;
  });

  bool isOutdated(String profileId, String addonId) {
    return outdated.value.any(
      (update) => update.profileId == profileId && update.addonId == addonId,
    );
  }

  List<AddonUpdate> forProfile(String profileId) =>
      outdatedByProfile.value[profileId] ?? const [];

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    unawaited(_restoreLastChecked());
  }

  Future<void> _restoreLastChecked() async {
    final raw = await _settingsDao.getValue(addonUpdateLastCheckedKey);
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    if (parsed != null) {
      lastCheckedAt.value = parsed;
    }
  }

  Future<int?> check() async {
    checking.value = true;
    try {
      if (!_addons.loaded.value && !_addons.loading.value) {
        await _addons.load();
      }
      if (_addons.error.value != null && _addons.addons.value.isEmpty) {
        return null;
      }
      final now = _clock();
      lastCheckedAt.value = now;
      await _settingsDao.setValue(addonUpdateLastCheckedKey, now.toIso8601String());
      return outdated.value.length;
    } finally {
      checking.value = false;
    }
  }
}
