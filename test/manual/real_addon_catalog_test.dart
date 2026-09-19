import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog_parser.dart';

void main() {
  test(
    'parses the real addon catalog cache zip',
    () async {
      final file = File(
        Platform.environment['FCL_CATALOG_ZIP'] ?? 'addon_catalog_cache.zip',
      );
      expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');

      final addons = parseAddonCatalog(
        AddonCatalog.extractCatalogJson(await file.readAsBytes()),
      );

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
    },
    skip: Platform.environment['FCL_REAL_CATALOG'] != '1'
        ? 'Manual test: set FCL_REAL_CATALOG=1 to parse the real catalog zip'
        : null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
