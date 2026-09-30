// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog_parser.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';

void main() {
  const packageXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<package format="1" xmlns="https://wiki.freecad.org/Package_Metadata">
  <name>A2plus</name>
  <description>Assembly workbench</description>
  <version>0.4.68</version>
  <license file="LICENSE">LGPL-2.1-or-later</license>
  <maintainer email="kbwbe@gmx.de">kbwbe</maintainer>
  <author email="author@example.com">Author One</author>
  <content>
    <workbench>
      <classname>A2plusWorkbench</classname>
      <tag>Assembly</tag>
      <tag>  constraints  </tag>
    </workbench>
    <preferencepack>
      <name>Custom</name>
    </preferencepack>
  </content>
  <pythonmin>3.9</pythonmin>
</package>
''';

  final catalogJson = '''
{
  "_meta": {"schema": 2},
  "\$schema": "https://example.invalid/schema",
  "ignore_me": 42,
  "A2plus": [
    {
      "repository": "https://github.com/kbwbe/A2plus",
      "git_ref": "master",
      "branch_display_name": "master",
      "zip_url": "https://github.com/kbwbe/A2plus/archive/refs/heads/master.zip",
      "curated": true,
      "sparse_cache": false,
      "relative_cache_path": "./CatalogCache/A2plus/0-master.zip",
      "freecad_min": {"version_as_list": [0, 20, 1, ""]},
      "freecad_max": null,
      "last_update_time": "2026-02-15T17:12:54+01:00",
      "note": "note",
      "metadata": {
        "package_xml": "${_jsonString(packageXml)}",
        "requirements_txt": "numpy\\n",
        "metadata_txt": "",
        "icon_data": "PD94bWw="
      }
    },
    {
      "repository": "https://github.com/kbwbe/A2plus",
      "git_ref": "dev",
      "branch_display_name": "development",
      "zip_url": "https://github.com/kbwbe/A2plus/archive/refs/heads/dev.zip",
      "curated": false,
      "sparse_cache": true
    }
  ],
  "bundle_addon": [
    {
      "repository": "https://example.invalid/bundle",
      "git_ref": "main",
      "branch_display_name": "main",
      "zip_url": "https://example.invalid/main.zip",
      "curated": true,
      "sparse_cache": false,
      "freecad_min": "0.19"
    }
  ],
  "noMetadata": [
    {
      "repository": "https://example.invalid/x",
      "git_ref": "main",
      "branch_display_name": "main",
      "zip_url": "https://example.invalid/x.zip",
      "curated": true,
      "sparse_cache": false,
      "metadata": null
    }
  ]
}
''';

  test('parses branches, versions and metadata', () {
    final addons = parseAddonCatalog(catalogJson);
    expect(addons.map((addon) => addon.id), ['A2plus', 'bundle_addon', 'noMetadata']);

    final a2plus = addons.first;
    expect(a2plus.displayName, 'A2plus');
    expect(a2plus.description, 'Assembly workbench');
    expect(a2plus.version, '0.4.68');
    expect(a2plus.license, 'LGPL-2.1-or-later');
    expect(a2plus.hasRequirements, isTrue);
    expect(a2plus.tags, {'assembly', 'constraints'});
    expect(a2plus.content, {AddonContentType.workbench, AddonContentType.preferencePack});
    expect(a2plus.branches, hasLength(2));

    final master = a2plus.branches.first;
    expect(master.gitRef, 'master');
    expect(master.displayName, 'master');
    expect(master.repositoryUrl, 'https://github.com/kbwbe/A2plus');
    expect(master.freecadMin, '0.20.1');
    expect(master.freecadMax, isNull);
    expect(master.relativeCachePath, './CatalogCache/A2plus/0-master.zip');
    expect(master.curated, isTrue);
    expect(master.lastUpdateTime, isNotNull);
    expect(master.metadata!.minPython, '3.9');
    expect(master.metadata!.people, hasLength(2));
    expect(master.metadata!.people.first.roles, ['author']);
    expect(master.metadata!.iconBase64, 'PD94bWw=');

    final dev = a2plus.branches.last;
    expect(dev.gitRef, 'dev');
    expect(dev.displayName, 'development');
    expect(dev.curated, isFalse);
    expect(dev.sparseCache, isTrue);
    expect(dev.metadata, isNull);
    expect(dev.freecadMin, isNull);
  });

  test('normalizes string versions and skips meta keys', () {
    final addons = parseAddonCatalog(catalogJson);

    expect(addons.map((addon) => addon.id), isNot(contains('_meta')));
    expect(addons.map((addon) => addon.id), isNot(contains(r'$schema')));
    expect(addons.map((addon) => addon.id), isNot(contains('ignore_me')));

    final bundle = addons.firstWhere((addon) => addon.id == 'bundle_addon');
    expect(bundle.branches.single.freecadMin, '0.19');
    expect(bundle.primaryBranch.metadata, isNull);
    expect(bundle.displayName, 'bundle_addon');
    expect(bundle.description, isEmpty);
  });

  test('defaults Python and content when package.xml lacks them', () {
    final addons = parseAddonCatalog('''
{
  "plain": [
    {
      "repository": "https://example.invalid/plain",
      "git_ref": "main",
      "zip_url": "https://example.invalid/plain.zip",
      "curated": true,
      "sparse_cache": false,
      "metadata": {
        "package_xml": "<package><name>Plain</name></package>",
        "requirements_txt": "",
        "icon_data": null
      }
    }
  ]
}
''');

    final metadata = addons.single.primaryBranch.metadata!;
    expect(metadata.minPython, '3.10');
    expect(metadata.content, {AddonContentType.other});
    expect(metadata.hasRequirements, isFalse);
    expect(addons.single.hasRequirements, isFalse);
  });

  test('derives zip URLs from relative cache paths', () {
    final addons = parseAddonCatalog('''
{
  "relative": [
    {
      "repository": "https://example.invalid/r",
      "git_ref": "main",
      "branch_display_name": "main",
      "relative_cache_path": "./CatalogCache/relative/0-main.zip",
      "curated": true,
      "sparse_cache": false
    }
  ]
}
''');

    expect(
      addons.single.primaryBranch.zipUrl,
      'https://addons.freecad.org/CatalogCache/relative/0-main.zip',
    );
  });

  test('searches by text and #tag', () {
    final addons = parseAddonCatalog(catalogJson);
    final a2plus = addons.firstWhere((addon) => addon.id == 'A2plus');

    expect(a2plus.matchesQuery('assembly'), isTrue);
    expect(a2plus.matchesQuery('A2PLUS'), isTrue);
    expect(a2plus.matchesQuery('#constraints'), isTrue);
    expect(a2plus.matchesQuery('#missing'), isFalse);
    expect(a2plus.matchesQuery(''), isTrue);
  });
}

String _jsonString(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
}
