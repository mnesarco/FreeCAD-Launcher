// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';

import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/addon_dependencies.dart';
import 'package:freecad_launcher/domain/addons/package_xml.dart';

void main() {
  group('parsePackageXml dependencies', () {
    test('parses depend tags from the root and nested content items', () {
      final info = parsePackageXml('''
<?xml version="1.0" encoding="UTF-8"?>
<package format="1" xmlns="https://wiki.freecad.org/Package_Metadata">
  <name>Test</name>
  <depend>numpy</depend>
  <depend type="python" optional="True" version_gte="1.2">scipy</depend>
  <content>
    <workbench>
      <name>Test</name>
      <depend type="addon" version_lte="2.0">Curves</depend>
      <depend type="internal">part</depend>
    </workbench>
  </content>
</package>
''');

      expect(info, isNotNull);
      final dependencies = info!.dependencies;
      expect(dependencies, hasLength(4));
      expect(dependencies[0].name, 'numpy');
      expect(dependencies[0].type, AddonDependencyType.automatic);
      expect(dependencies[0].optional, isFalse);
      expect(dependencies[1].name, 'scipy');
      expect(dependencies[1].type, AddonDependencyType.python);
      expect(dependencies[1].optional, isTrue);
      expect(dependencies[1].versionGte, '1.2');
      expect(dependencies[2].name, 'Curves');
      expect(dependencies[2].type, AddonDependencyType.addon);
      expect(dependencies[2].versionLte, '2.0');
      expect(dependencies[3].name, 'part');
      expect(dependencies[3].type, AddonDependencyType.internal);
    });

    test('unknown type and optional spellings fall back sensibly', () {
      final info = parsePackageXml('''
<package>
  <depend type="whatever" optional="TRUE">a</depend>
  <depend type="PyThOn" optional="false">b</depend>
  <depend>   </depend>
</package>
''');

      expect(info!.dependencies, hasLength(2));
      expect(info.dependencies[0].type, AddonDependencyType.automatic);
      expect(info.dependencies[0].optional, isTrue);
      expect(info.dependencies[1].type, AddonDependencyType.python);
      expect(info.dependencies[1].optional, isFalse);
    });
  });

  group('resolveAddonDependencies', () {
    test('automatic matches catalog ids and display names', () {
      final plan = resolveAddonDependencies(
        addonId: 'Root',
        catalog: [
          addon('Curves', displayName: 'Curves WB'),
          addon('Other'),
        ],
        dependencies: const [
          AddonDependency(name: 'Curves'),
          AddonDependency(name: 'Curves WB'),
        ],
      );

      expect(plan.requiredAddons, hasLength(1));
      expect(plan.requiredAddons.single.addon!.id, 'Curves');
      expect(plan.orderedAddons, hasLength(1));
    });

    test('automatic resolves internal workbenches with WB/Workbench suffixes', () {
      final plan = resolveAddonDependencies(
        addonId: 'Root',
        catalog: const [],
        dependencies: const [
          AddonDependency(name: 'PartWorkbench'),
          AddonDependency(name: 'SketcherWB'),
          AddonDependency(name: 'spreadsheet'),
        ],
      );

      expect(plan.internalWorkbenches, {'part', 'sketcher', 'spreadsheet'});
      expect(plan.requiredPython, isEmpty);
      expect(plan.unresolved, isEmpty);
    });

    test('automatic falls back to Python; explicit internal unknown is unresolved', () {
      final plan = resolveAddonDependencies(
        addonId: 'Root',
        catalog: const [],
        dependencies: const [
          AddonDependency(name: 'numpy'),
          AddonDependency(name: 'py-slvs'),
          AddonDependency(name: 'not-a-real-workbench', type: AddonDependencyType.internal),
        ],
      );

      expect(plan.requiredPython.map((entry) => entry.requirement.name), ['numpy', 'py-slvs']);
      expect(plan.unresolved, ['not-a-real-workbench']);
    });

    test('missing explicit addon falls back to Python (AddonManager parity)', () {
      final plan = resolveAddonDependencies(
        addonId: 'Root',
        catalog: const [],
        dependencies: const [
          AddonDependency(name: 'Missing Addon', type: AddonDependencyType.addon),
        ],
      );

      expect(plan.requiredAddons, isEmpty);
      expect(plan.requiredPython.single.requirement.name, 'Missing Addon');
    });

    test('recurses through installed addons for their missing dependencies', () {
      final catalog = [
        addon('B', dependencies: const [AddonDependency(name: 'C')]),
        addon('C'),
      ];
      final plan = resolveAddonDependencies(
        addonId: 'Root',
        catalog: catalog,
        installedAddonIds: {'B'},
        dependencies: const [AddonDependency(name: 'B')],
      );

      expect(plan.requiredAddons.map((entry) => entry.addon!.id), ['C']);
      expect(plan.orderedAddons.map((entry) => entry.addon!.id), ['C']);
    });

    test('orders dependent addons deepest first', () {
      final catalog = [
        addon('B', dependencies: const [AddonDependency(name: 'C')]),
        addon('C', dependencies: const [AddonDependency(name: 'D')]),
        addon('D'),
      ];
      final plan = resolveAddonDependencies(
        addonId: 'Root',
        catalog: catalog,
        dependencies: const [AddonDependency(name: 'B')],
      );

      expect(plan.orderedAddons.map((entry) => entry.addon!.id), ['D', 'C', 'B']);
      expect(plan.requiredAddons, hasLength(3));
    });

    test('ignores cycles back to the addon being installed', () {
      final catalog = [
        addon('B', dependencies: const [AddonDependency(name: 'Root')]),
      ];
      final plan = resolveAddonDependencies(
        addonId: 'Root',
        catalog: catalog,
        dependencies: const [AddonDependency(name: 'B')],
      );

      expect(plan.requiredAddons.map((entry) => entry.addon!.id), ['B']);
    });

    test('dedupes Python packages, requirements.txt wins, required beats optional', () {
      final plan = resolveAddonDependencies(
        addonId: 'Root',
        catalog: const [],
        requirementsText: 'pyjwt>=2.0\nrequests',
        dependencies: const [
          AddonDependency(name: 'pyjwt'),
          AddonDependency(name: 'openpyxl', optional: true),
          AddonDependency(name: 'openpyxl'),
          AddonDependency(name: 'tzlocal', optional: true),
        ],
      );

      expect(plan.requiredPython.map((entry) => entry.requirement.display), [
        'pyjwt>=2.0',
        'requests',
        'openpyxl',
      ]);
      expect(plan.optionalPython.map((entry) => entry.requirement.name), ['tzlocal']);
      expect(plan.requiredPython.first.declaredByAddonId, 'Root');
    });

    test('filters Python candidates already available and keeps invalid options', () {
      final plan = resolveAddonDependencies(
        addonId: 'Root',
        catalog: const [],
        requirementsText: 'requests\n--index-url https://example.invalid/simple',
        availablePythonPackages: {'requests'},
        dependencies: const [AddonDependency(name: 'Requests')],
      );

      expect(plan.requiredPython, isEmpty);
      expect(plan.invalidRequirements, hasLength(1));
      expect(plan.invalidRequirements.single.error, contains('Unsupported pip option'));
    });

    test('merges plans with required winning over optional and deduping', () {
      final first = resolveAddonDependencies(
        addonId: 'A',
        catalog: const [],
        requirementsText: 'numpy',
        dependencies: const [
          AddonDependency(name: 'shared', optional: true),
          AddonDependency(name: 'scipy'),
        ],
      );
      final second = resolveAddonDependencies(
        addonId: 'B',
        catalog: const [],
        dependencies: const [
          AddonDependency(name: 'shared'),
          AddonDependency(name: 'numpy'),
          AddonDependency(name: 'part', type: AddonDependencyType.internal),
        ],
      );

      final merged = mergeDependencyPlans([first, second]);

      expect(merged.requiredPython.map((entry) => entry.requirement.name).toSet(), {
        'numpy',
        'scipy',
        'shared',
      });
      expect(merged.optionalPython, isEmpty);
      expect(merged.internalWorkbenches, {'part'});
    });

    test('tracks the declaring addon for transitive Python packages', () {
      final catalog = [
        addon(
          'B',
          dependencies: const [AddonDependency(name: 'scipy', type: AddonDependencyType.python)],
        ),
      ];
      final plan = resolveAddonDependencies(
        addonId: 'Root',
        catalog: catalog,
        dependencies: const [AddonDependency(name: 'B')],
      );

      final scipy = plan.requiredPython.single;
      expect(scipy.requirement.name, 'scipy');
      expect(scipy.declaredByAddonId, 'B');
    });
  });
}

Addon addon(String id, {String? displayName, List<AddonDependency> dependencies = const []}) {
  return Addon(
    id: id,
    branches: [
      AddonBranch(
        gitRef: 'main',
        displayName: 'main',
        repositoryUrl: 'https://example.invalid/$id',
        zipUrl: 'https://example.invalid/$id.zip',
        curated: true,
        sparseCache: false,
        metadata: AddonMetadata(
          name: displayName ?? id,
          description: '',
          version: '1.0.0',
          license: null,
          minPython: '3.10',
          tags: const [],
          people: const [],
          content: const {AddonContentType.workbench},
          requirements: '',
          dependencies: dependencies,
        ),
      ),
    ],
  );
}
