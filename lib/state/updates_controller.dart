// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/data/daos/settings_dao.dart';
import 'package:freecad_launcher/domain/addons/addon_update.dart';
import 'package:freecad_launcher/domain/addons/addon_update_rules.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/builds/build_update.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';
import 'package:freecad_launcher/domain/settings/app_settings.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/builds_controller.dart';

const addonUpdateLastCheckedKey = 'updates.addons.lastCheckedAt';
const buildUpdateLastCheckedKey = 'updates.builds.lastCheckedAt';

class UpdatesController {
  UpdatesController({
    required AddonsController addons,
    required BuildsController builds,
    required SettingsDao settingsDao,
    DateTime Function()? clock,
  }) : _addons = addons,
       _builds = builds,
       _settingsDao = settingsDao,
       _clock = clock ?? DateTime.now;

  final AddonsController _addons;
  final BuildsController _builds;
  final SettingsDao _settingsDao;
  final DateTime Function() _clock;

  final checking = signal(false);
  final addonLastCheckedAt = signal<DateTime?>(null);
  final buildLastCheckedAt = signal<DateTime?>(null);
  final applying = signal(false);
  final applyCompleted = signal(0);
  final applyTotal = signal(0);
  final applyCurrentAddonId = signal<String?>(null);

  late final lastCheckedAt = computed<DateTime?>(() {
    final addon = addonLastCheckedAt.value;
    final build = buildLastCheckedAt.value;
    if (addon == null) {
      return build;
    }
    if (build == null) {
      return addon;
    }
    return build.isAfter(addon) ? build : addon;
  });

  bool _started = false;
  Future<void>? _restoreFuture;

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
      final branch = _addons.branchOf(
        addon,
        installed.gitRef ?? addon.primaryBranch.gitRef,
      );
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
      final byName = a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      );
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

  late final outdatedBuilds = computed<List<BuildUpdate>>(() {
    final candidates = _builds.availableBuilds.value;
    if (candidates.isEmpty) {
      return const [];
    }
    final result = <BuildUpdate>[];
    for (final build in _builds.installedBuilds.value) {
      if (build.channel != BuildChannel.stable ||
          build.kind == BuildKind.custom ||
          build.status != BuildStatus.installed) {
        continue;
      }
      final installed = FreeCadVersion.tryParse(build.version);
      if (installed == null) {
        continue;
      }
      for (final candidate in candidates) {
        final latest = candidate.version;
        if (candidate.kind != build.kind || latest == null) {
          continue;
        }
        if (latest.compareTo(installed) <= 0) {
          break;
        }
        result.add(
          BuildUpdate(
            buildId: build.id,
            installedVersion: build.version,
            latestVersion: candidate.versionLabel,
            candidateId: candidate.id,
          ),
        );
        break;
      }
    }
    result.sort((a, b) => b.latestVersion.compareTo(a.latestVersion));
    return result;
  });

  late final outdatedCount = computed(
    () => outdated.value.length + outdatedBuilds.value.length,
  );

  bool isOutdated(String profileId, String addonId) {
    return outdated.value.any(
      (update) => update.profileId == profileId && update.addonId == addonId,
    );
  }

  List<AddonUpdate> forProfile(String profileId) =>
      outdatedByProfile.value[profileId] ?? const [];

  Future<AddonUpdateApplySummary> applyUpdates(
    List<AddonUpdate> updates,
  ) async {
    applying.value = true;
    applyTotal.value = updates.length;
    applyCompleted.value = 0;
    applyCurrentAddonId.value = null;
    final results = <AddonUpdateApplyResult>[];
    try {
      for (final update in updates) {
        applyCurrentAddonId.value = update.addonId;
        final result = await _addons.update(
          addonId: update.addonId,
          branchRef: update.branchRef,
          profileId: update.profileId,
        );
        results.add(
          AddonUpdateApplyResult(
            update: update,
            status: result.isOk
                ? AddonUpdateApplyStatus.updated
                : AddonUpdateApplyStatus.failed,
            error: result.isErr ? '${result.errorOrNull}' : null,
          ),
        );
        applyCompleted.value = results.length;
      }
    } finally {
      applying.value = false;
      applyCurrentAddonId.value = null;
    }
    return AddonUpdateApplySummary(results);
  }

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    final restore = _restoreLastChecked();
    _restoreFuture = restore;
    unawaited(restore);
  }

  Future<int?> checkIfDue(UpdateCadence cadence) async {
    start();
    await _restoreFuture;
    if (!isUpdateCheckDue(lastCheckedAt.value, cadence, _clock())) {
      return null;
    }
    return check();
  }

  Future<void> _restoreLastChecked() async {
    final addonRaw = await _settingsDao.getValue(addonUpdateLastCheckedKey);
    final addonParsed = addonRaw == null ? null : DateTime.tryParse(addonRaw);
    if (addonParsed != null) {
      addonLastCheckedAt.value = addonParsed;
    }
    final buildRaw = await _settingsDao.getValue(buildUpdateLastCheckedKey);
    final buildParsed = buildRaw == null ? null : DateTime.tryParse(buildRaw);
    if (buildParsed != null) {
      buildLastCheckedAt.value = buildParsed;
    }
  }

  Future<int?> check() async {
    checking.value = true;
    try {
      if (!_addons.loaded.value && !_addons.loading.value) {
        await _addons.load();
      }
      if (_builds.availableBuilds.value.isEmpty &&
          !_builds.loadingCatalog.value) {
        await _builds.loadCatalog();
      }
      final addonsReachable =
          _addons.addons.value.isNotEmpty || _addons.error.value == null;
      final buildsReachable =
          _builds.availableBuilds.value.isNotEmpty ||
          _builds.catalogError.value == null;
      if (!addonsReachable && !buildsReachable) {
        return null;
      }
      final now = _clock();
      addonLastCheckedAt.value = now;
      buildLastCheckedAt.value = now;
      await _settingsDao.setValue(
        addonUpdateLastCheckedKey,
        now.toIso8601String(),
      );
      await _settingsDao.setValue(
        buildUpdateLastCheckedKey,
        now.toIso8601String(),
      );
      return outdatedCount.value;
    } finally {
      checking.value = false;
    }
  }
}
