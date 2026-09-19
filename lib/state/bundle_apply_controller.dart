import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/domain/bundles/bundle_planner.dart';

enum BundleApplyItemStatus { installed, updated, skipped, failed }

class BundleApplyItemResult {
  const BundleApplyItemResult({required this.item, required this.status, this.error});

  final BundleApplyPlanItem item;
  final BundleApplyItemStatus status;
  final String? error;
}

class BundleApplySummary {
  const BundleApplySummary(this.results);

  final List<BundleApplyItemResult> results;

  int count(BundleApplyItemStatus status) =>
      results.where((result) => result.status == status).length;

  List<BundleApplyItemResult> get failures => [
    for (final result in results)
      if (result.status == BundleApplyItemStatus.failed) result,
  ];
}

typedef BundleAddonInstall =
    Future<Result<void>> Function({
      required String addonId,
      required String branchRef,
      required String profileId,
      required bool installRequirements,
    });

typedef BundleAddonUpdate =
    Future<Result<void>> Function({
      required String addonId,
      required String branchRef,
      required String profileId,
    });

class BundleApplyController {
  BundleApplyController({required BundleAddonInstall install, required BundleAddonUpdate update})
    : _install = install,
      _update = update;

  final BundleAddonInstall _install;
  final BundleAddonUpdate _update;

  final applying = signal(false);
  final completed = signal(0);
  final total = signal(0);
  final currentAddonId = signal<String?>(null);

  Future<BundleApplySummary> apply({
    required String profileId,
    required List<BundleApplyPlanItem> items,
    bool installRequirements = false,
  }) async {
    applying.value = true;
    total.value = items.length;
    completed.value = 0;
    currentAddonId.value = null;
    final results = <BundleApplyItemResult>[];
    try {
      for (final item in items) {
        currentAddonId.value = item.addonId;
        final BundleApplyItemResult result;
        switch (item.action) {
          case BundleItemAction.install:
            final install = await _install(
              addonId: item.addonId,
              branchRef: item.branchRef!,
              profileId: profileId,
              installRequirements: installRequirements && item.hasRequirements,
            );
            result = install.fold(
              (_) => BundleApplyItemResult(
                item: item,
                status: BundleApplyItemStatus.installed,
              ),
              (error) => BundleApplyItemResult(
                item: item,
                status: BundleApplyItemStatus.failed,
                error: error.toString(),
              ),
            );
          case BundleItemAction.update:
            final update = await _update(
              addonId: item.addonId,
              branchRef: item.branchRef!,
              profileId: profileId,
            );
            result = update.fold(
              (_) => BundleApplyItemResult(
                item: item,
                status: BundleApplyItemStatus.updated,
              ),
              (error) => BundleApplyItemResult(
                item: item,
                status: BundleApplyItemStatus.failed,
                error: error.toString(),
              ),
            );
          case BundleItemAction.skip:
            result = BundleApplyItemResult(
              item: item,
              status: BundleApplyItemStatus.skipped,
            );
          case BundleItemAction.unavailable:
            result = BundleApplyItemResult(
              item: item,
              status: BundleApplyItemStatus.skipped,
            );
        }
        results.add(result);
        completed.value = results.length;
      }
    } finally {
      applying.value = false;
      currentAddonId.value = null;
    }
    return BundleApplySummary(results);
  }
}
