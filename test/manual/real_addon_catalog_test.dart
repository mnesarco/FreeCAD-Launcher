// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog_parser.dart';
import 'package:freecad_launcher/domain/addons/addon_dependencies.dart';

void main() {
  test(
    'parses the real addon catalog cache zip',
    () async {
      final file = File(Platform.environment['FCL_CATALOG_ZIP'] ?? 'addon_catalog_cache.zip');
      expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');

      final addons = parseAddonCatalog(AddonCatalog.extractCatalogJson(await file.readAsBytes()));

      final branches = addons.fold<int>(0, (sum, addon) => sum + addon.branches.length);
      final withMetadata = addons.where((addon) => addon.primaryBranch.metadata != null).length;
      final multiBranch = addons.where((addon) => addon.branches.length > 1).length;
      // ignore: avoid_print
      print(
        'addons=${addons.length} branches=$branches '
        'withMetadata=$withMetadata multiBranch=$multiBranch',
      );

      expect(addons, isNotEmpty);
      expect(addons.any((addon) => addon.id == 'A2plus'), isTrue);
      for (var index = 1; index < addons.length; index++) {
        expect(
          addons[index - 1].displayName.toLowerCase().compareTo(
            addons[index].displayName.toLowerCase(),
          ),
          lessThanOrEqualTo(0),
        );
      }

      final a2plus = addons.firstWhere((addon) => addon.id == 'A2plus');
      expect(a2plus.version, isNotEmpty);
      expect(a2plus.primaryBranch.zipUrl, startsWith('https://'));
      // ignore: avoid_print
      print('A2plus version=${a2plus.version} tags=${a2plus.tags.toList()}');

      final withDependencies = addons
          .where((addon) => addon.branches.any((branch) => branch.hasDependencies))
          .length;
      // ignore: avoid_print
      print('addons with <depend>=$withDependencies');
      expect(withDependencies, greaterThan(40));

      final ondsel = addons.firstWhere((addon) => addon.id == 'Ondsel-Lens');
      final ondselDeps = ondsel.primaryBranch.metadata!.dependencies;
      expect(ondselDeps.map((dependency) => dependency.name), containsAll(['pyjwt', 'tzlocal']));
      final ondselPlan = resolveAddonDependencies(
        addonId: ondsel.id,
        dependencies: ondselDeps,
        catalog: addons,
      );
      expect(
        ondselPlan.requiredPython.map((entry) => entry.requirement.name),
        containsAll(['pyjwt', 'tzlocal']),
      );

      final beltrami = addons.firstWhere((addon) => addon.id == 'Beltrami');
      final beltramiPlan = resolveAddonDependencies(
        addonId: beltrami.id,
        dependencies: beltrami.primaryBranch.metadata!.dependencies,
        catalog: addons,
      );
      expect(beltramiPlan.requiredAddons.map((entry) => entry.addon!.id), contains('Curves'));
      expect(
        beltramiPlan.requiredPython.map((entry) => entry.requirement.name),
        containsAll(['scipy', 'numpy']),
      );
      expect(beltramiPlan.internalWorkbenches, containsAll(['part', 'sketcher', 'spreadsheet']));
      // ignore: avoid_print
      print(
        'Beltrami addons=${beltramiPlan.requiredAddons.map((e) => e.addon!.id).toList()} '
        'python=${beltramiPlan.requiredPython.map((e) => e.requirement.name).toList()}',
      );
    },
    skip: Platform.environment['FCL_REAL_CATALOG'] != '1'
        ? 'Manual test: set FCL_REAL_CATALOG=1 to parse the real catalog zip'
        : null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
