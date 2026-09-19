import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/addon_update_rules.dart';

/// A bundle item as stored, without the drift types.
class BundlePlanEntry {
  const BundlePlanEntry({required this.addonId, this.gitRef});

  final String addonId;
  final String? gitRef;
}

/// The subset of an installed addon the planner needs.
class BundlePlanInstalledAddon {
  const BundlePlanInstalledAddon({
    required this.addonId,
    this.gitRef,
    this.version,
    this.catalogLastUpdate,
  });

  final String addonId;
  final String? gitRef;
  final String? version;
  final DateTime? catalogLastUpdate;
}

enum BundleItemAction { install, update, skip, unavailable }

class BundleApplyPlanItem {
  const BundleApplyPlanItem({
    required this.addonId,
    required this.action,
    this.addonName,
    this.branchRef,
    this.installedVersion,
    this.catalogVersion,
    this.hasRequirements = false,
  });

  final String addonId;
  final BundleItemAction action;
  final String? addonName;
  final String? branchRef;
  final String? installedVersion;
  final String? catalogVersion;
  final bool hasRequirements;

  bool get isActionable =>
      action == BundleItemAction.install || action == BundleItemAction.update;

  /// True when the addon itself is missing from the catalog (as opposed to a
  /// missing branch of a known addon).
  bool get isAddonMissing => action == BundleItemAction.unavailable && addonName == null;
}

class BundleApplyPlan {
  const BundleApplyPlan(this.items);

  final List<BundleApplyPlanItem> items;

  List<BundleApplyPlanItem> get actionable => [
    for (final item in items)
      if (item.isActionable) item,
  ];

  int count(BundleItemAction action) =>
      items.where((item) => item.action == action).length;

  bool get hasRequirements => actionable.any((item) => item.hasRequirements);
}

BundleApplyPlan planBundleApply({
  required List<BundlePlanEntry> entries,
  required List<Addon> catalog,
  required List<BundlePlanInstalledAddon> installed,
}) {
  final byId = {for (final addon in catalog) addon.id: addon};
  final installedById = {for (final row in installed) row.addonId: row};

  final items = <BundleApplyPlanItem>[];
  for (final entry in entries) {
    final addon = byId[entry.addonId];
    if (addon == null) {
      items.add(
        BundleApplyPlanItem(addonId: entry.addonId, action: BundleItemAction.unavailable),
      );
      continue;
    }
    final targetRef = entry.gitRef ?? addon.primaryBranch.gitRef;
    AddonBranch? branch;
    for (final candidate in addon.branches) {
      if (candidate.gitRef == targetRef) {
        branch = candidate;
        break;
      }
    }
    if (branch == null) {
      items.add(
        BundleApplyPlanItem(
          addonId: entry.addonId,
          action: BundleItemAction.unavailable,
          addonName: addon.displayName,
          branchRef: targetRef,
        ),
      );
      continue;
    }

    final hasRequirements = (branch.metadata?.requirements ?? '').trim().isNotEmpty;
    final row = installedById[entry.addonId];
    if (row == null) {
      items.add(
        BundleApplyPlanItem(
          addonId: entry.addonId,
          action: BundleItemAction.install,
          addonName: addon.displayName,
          branchRef: targetRef,
          catalogVersion: branch.metadata?.version,
          hasRequirements: hasRequirements,
        ),
      );
      continue;
    }

    final branchChanged = (row.gitRef ?? '') != targetRef;
    final contentChanged = addonContentChanged(
      catalogLastUpdate: branch.lastUpdateTime,
      catalogVersion: branch.metadata?.version,
      installedCatalogLastUpdate: row.catalogLastUpdate,
      installedVersion: row.version,
    );
    if (branchChanged || contentChanged) {
      items.add(
        BundleApplyPlanItem(
          addonId: entry.addonId,
          action: BundleItemAction.update,
          addonName: addon.displayName,
          branchRef: targetRef,
          installedVersion: row.version,
          catalogVersion: branch.metadata?.version,
          hasRequirements: hasRequirements,
        ),
      );
    } else {
      items.add(
        BundleApplyPlanItem(
          addonId: entry.addonId,
          action: BundleItemAction.skip,
          addonName: addon.displayName,
          branchRef: targetRef,
          installedVersion: row.version,
          catalogVersion: branch.metadata?.version,
          hasRequirements: hasRequirements,
        ),
      );
    }
  }
  return BundleApplyPlan(items);
}
