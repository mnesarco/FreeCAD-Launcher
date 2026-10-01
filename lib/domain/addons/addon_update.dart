// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
class AddonUpdate {
  const AddonUpdate({
    required this.profileId,
    required this.addonId,
    required this.displayName,
    required this.branchRef,
    this.installedVersion,
    this.catalogVersion,
  });

  final String profileId;
  final String addonId;
  final String displayName;
  final String branchRef;
  final String? installedVersion;
  final String? catalogVersion;
}

enum AddonUpdateApplyStatus { updated, failed }

class AddonUpdateApplyResult {
  const AddonUpdateApplyResult({
    required this.update,
    required this.status,
    this.error,
  });

  final AddonUpdate update;
  final AddonUpdateApplyStatus status;
  final String? error;
}

class AddonUpdateApplySummary {
  const AddonUpdateApplySummary(this.results);

  final List<AddonUpdateApplyResult> results;

  int count(AddonUpdateApplyStatus status) =>
      results.where((result) => result.status == status).length;

  List<AddonUpdateApplyResult> get failures => [
    for (final result in results)
      if (result.status == AddonUpdateApplyStatus.failed) result,
  ];
}
