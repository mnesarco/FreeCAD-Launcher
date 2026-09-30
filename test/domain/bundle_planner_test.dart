// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/bundles/bundle_planner.dart';

Addon addon(
  String id, {
  String version = '1.0.0',
  String requirements = '',
  DateTime? lastUpdate,
  List<String> branches = const ['master'],
}) {
  return Addon(
    id: id,
    branches: [
      for (final ref in branches)
        AddonBranch(
          gitRef: ref,
          displayName: ref,
          repositoryUrl: 'https://example.invalid/$id',
          zipUrl: 'https://example.invalid/$id-$ref.zip',
          curated: true,
          sparseCache: false,
          lastUpdateTime: lastUpdate,
          metadata: AddonMetadata(
            name: id,
            description: '',
            version: version,
            license: 'MIT',
            minPython: '3.10',
            tags: const [],
            people: const [],
            content: const {AddonContentType.workbench},
            requirements: requirements,
          ),
        ),
    ],
  );
}

void main() {
  test('plans installs for missing addons using the default branch', () {
    final plan = planBundleApply(
      entries: const [BundlePlanEntry(addonId: 'A2plus')],
      catalog: [addon('A2plus')],
      installed: const [],
    );

    final item = plan.items.single;
    expect(item.action, BundleItemAction.install);
    expect(item.branchRef, 'master');
    expect(item.addonName, 'A2plus');
    expect(item.catalogVersion, '1.0.0');
    expect(item.hasRequirements, isFalse);
    expect(plan.actionable, hasLength(1));
    expect(plan.count(BundleItemAction.install), 1);
  });

  test('skips addons installed on the same branch and version', () {
    final plan = planBundleApply(
      entries: const [BundlePlanEntry(addonId: 'A2plus', gitRef: 'master')],
      catalog: [addon('A2plus')],
      installed: const [
        BundlePlanInstalledAddon(addonId: 'A2plus', gitRef: 'master', version: '1.0.0'),
      ],
    );

    expect(plan.items.single.action, BundleItemAction.skip);
    expect(plan.actionable, isEmpty);
  });

  test('plans updates for version changes and branch switches', () {
    final byVersion = planBundleApply(
      entries: const [BundlePlanEntry(addonId: 'A2plus')],
      catalog: [addon('A2plus', version: '2.0.0')],
      installed: const [
        BundlePlanInstalledAddon(addonId: 'A2plus', gitRef: 'master', version: '1.0.0'),
      ],
    );

    final item = byVersion.items.single;
    expect(item.action, BundleItemAction.update);
    expect(item.installedVersion, '1.0.0');
    expect(item.catalogVersion, '2.0.0');

    final byBranch = planBundleApply(
      entries: const [BundlePlanEntry(addonId: 'A2plus', gitRef: 'dev')],
      catalog: [addon('A2plus', branches: const ['master', 'dev'])],
      installed: const [
        BundlePlanInstalledAddon(addonId: 'A2plus', gitRef: 'master', version: '1.0.0'),
      ],
    );

    expect(byBranch.items.single.action, BundleItemAction.update);
    expect(byBranch.items.single.branchRef, 'dev');
  });

  test('plans updates when the catalog timestamp is newer', () {
    final plan = planBundleApply(
      entries: const [BundlePlanEntry(addonId: 'A2plus')],
      catalog: [addon('A2plus', lastUpdate: DateTime.utc(2026, 9, 18))],
      installed: const [
        BundlePlanInstalledAddon(
          addonId: 'A2plus',
          gitRef: 'master',
          version: '1.0.0',
          catalogLastUpdate: null,
        ),
      ],
    );

    expect(plan.items.single.action, BundleItemAction.update);
  });

  test('marks unknown addons and missing branches as unavailable', () {
    final plan = planBundleApply(
      entries: const [
        BundlePlanEntry(addonId: 'Ghost'),
        BundlePlanEntry(addonId: 'A2plus', gitRef: 'gone'),
      ],
      catalog: [addon('A2plus')],
      installed: const [],
    );

    final ghost = plan.items[0];
    expect(ghost.action, BundleItemAction.unavailable);
    expect(ghost.isAddonMissing, isTrue);
    expect(ghost.addonName, isNull);

    final goneBranch = plan.items[1];
    expect(goneBranch.action, BundleItemAction.unavailable);
    expect(goneBranch.isAddonMissing, isFalse);
    expect(goneBranch.branchRef, 'gone');
  });

  test('flags requirements on the branch metadata', () {
    final plan = planBundleApply(
      entries: const [BundlePlanEntry(addonId: 'WithReqs')],
      catalog: [addon('WithReqs', requirements: 'six\nnumpy')],
      installed: const [],
    );

    expect(plan.hasRequirements, isTrue);
    expect(plan.items.single.hasRequirements, isTrue);
  });

  test('skips pinned addons even when an update is available', () {
    final plan = planBundleApply(
      entries: const [BundlePlanEntry(addonId: 'A2plus', gitRef: 'dev')],
      catalog: [addon('A2plus', version: '2.0.0', branches: const ['master', 'dev'])],
      installed: const [
        BundlePlanInstalledAddon(
          addonId: 'A2plus',
          gitRef: 'master',
          version: '1.0.0',
          pinned: true,
        ),
      ],
    );

    final item = plan.items.single;
    expect(item.action, BundleItemAction.skip);
    expect(item.pinned, isTrue);
    expect(plan.actionable, isEmpty);
  });
}
