import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/profiles/profile_manifest.dart';

ProfileManifest sampleManifest() {
  return ProfileManifest(
    exportedAt: DateTime.utc(2026, 9, 20, 10, 30),
    source: const ManifestSource(os: 'linux', arch: 'x86_64'),
    profile: const ManifestProfileInfo(
      name: 'My Profile',
      build: '1.1.3',
      channel: 'stable',
      python: '3.11',
    ),
    addons: const [
      ManifestAddon(id: 'A2plus', gitRef: 'master', version: '0.4.60', pinned: true),
      ManifestAddon(id: 'Fasteners'),
    ],
    pythonPackages: const [
      ManifestPackage(name: 'numpy', version: '1.26.4', source: 'requirements'),
      ManifestPackage(name: 'six', source: 'manual'),
    ],
    bundles: const ['Mechanical'],
    macros: const ['MyMacro.FCMacro'],
    config: const {
      'user.cfg':
          '<FCParameters><FCText Name="MacroPath">/home/ana/Macros/</FCText></FCParameters>',
      'system.cfg': '<FCParameters/>',
    },
    configFiles: const ['user.cfg', 'system.cfg'],
  );
}

void main() {
  test('round-trips a manifest through the JSON codec', () {
    final encoded = encodeProfileManifest(sampleManifest());
    final decoded = decodeProfileManifest(encoded);

    expect(decoded.isOk, isTrue);
    final manifest = decoded.valueOrNull!;
    expect(manifest.exportedAt, DateTime.utc(2026, 9, 20, 10, 30));
    expect(manifest.source.os, 'linux');
    expect(manifest.source.arch, 'x86_64');
    expect(manifest.profile.name, 'My Profile');
    expect(manifest.profile.build, '1.1.3');
    expect(manifest.profile.channel, 'stable');
    expect(manifest.profile.python, '3.11');
    expect(manifest.addons.length, 2);
    expect(manifest.addons.first.id, 'A2plus');
    expect(manifest.addons.first.gitRef, 'master');
    expect(manifest.addons.first.pinned, isTrue);
    expect(manifest.addons.last.gitRef, isNull);
    expect(manifest.addons.last.pinned, isFalse);
    expect(manifest.pythonPackages.first.source, 'requirements');
    expect(manifest.pythonPackages.last.version, isNull);
    expect(manifest.bundles, ['Mechanical']);
    expect(manifest.macros, ['MyMacro.FCMacro']);
    expect(manifest.configFiles, ['user.cfg', 'system.cfg']);
    expect(manifest.config['user.cfg'], contains('/home/ana/Macros/'));
  });

  test('encoded JSON follows the documented schema', () {
    final data = jsonDecode(encodeProfileManifest(sampleManifest())) as Map<String, dynamic>;

    expect(data['schema'], profileManifestSchemaVersion);
    expect(data['config_files'], ['user.cfg', 'system.cfg']);
    expect((data['profile'] as Map)['build'], '1.1.3');
    expect((data['addons'] as List).first, {
      'id': 'A2plus',
      'git_ref': 'master',
      'version': '0.4.60',
      'pinned': true,
    });
  });

  test('rejects invalid payloads', () {
    expect(decodeProfileManifest('not json').isErr, isTrue);
    expect(decodeProfileManifest('[]').isErr, isTrue);
    expect(decodeProfileManifest('{"schema": 2}').isErr, isTrue);
    expect(decodeProfileManifest('{"schema": 1}').isErr, isTrue);
    expect(decodeProfileManifest('{"schema": 1, "profile": {}}').isErr, isTrue);
    expect(decodeProfileManifest('{"schema": 1, "profile": {"name": "  "}}').isErr, isTrue);
  });

  test('skips malformed entries and keeps only known config payloads', () {
    final decoded = decodeProfileManifest(
      jsonEncode({
        'schema': 1,
        'profile': {'name': 'Dev'},
        'addons': [
          {'id': 'A2plus'},
          {'id': '  '},
          'garbage',
          {'no_id': true},
        ],
        'python_packages': [
          {'name': 'numpy', 'version': ' 1.26.4 '},
          {'version': '1.0'},
        ],
        'bundles': ['A', 7, ''],
        'config_files': ['user.cfg', 'other.txt'],
        'config': {'user.cfg': '<xml/>', 'other.txt': 'x'},
      }),
    );

    expect(decoded.isOk, isTrue);
    final manifest = decoded.valueOrNull!;
    expect(manifest.profile.name, 'Dev');
    expect(manifest.profile.build, isNull);
    expect(manifest.addons.single.id, 'A2plus');
    expect(manifest.pythonPackages.single.version, '1.26.4');
    expect(manifest.bundles, ['A']);
    expect(manifest.config.keys, ['user.cfg']);
    expect(manifest.configFiles, ['user.cfg', 'other.txt']);
  });

  test('rejects an oversized config payload', () {
    final decoded = decodeProfileManifest(
      jsonEncode({
        'schema': 1,
        'profile': {'name': 'Dev'},
        'config': {'user.cfg': 'x' * (maxManifestConfigLength + 1)},
      }),
    );

    expect(decoded.isErr, isTrue);
    expect(decoded.errorOrNull!.message, contains('too large'));
  });

  test('finds absolute paths in POSIX, Windows and UNC values', () {
    final config = {
      'user.cfg':
          '<FCParameters><Preferences>'
          '<FCText Name="MacroPath">/home/ana/Macros/</FCText>'
          '<FCText Name="Relative">Macros/</FCText>'
          '<FCText Name="Win">C:\\Tools\\FreeCAD</FCText>'
          '<FCText Name="Unc">\\\\server\\share\\tools</FCText>'
          '<FCText Name="Dup">/home/ana/Macros/</FCText>'
          '<FCText Name="Url">https://example.org/a</FCText>'
          '</Preferences></FCParameters>',
      'system.cfg': '<FCParameters><FCText Name="Root">/</FCText></FCParameters>',
    };

    final paths = findConfigAbsolutePaths(config);

    expect(paths, [
      const ManifestAbsolutePath(file: 'user.cfg', path: '/home/ana/Macros/'),
      const ManifestAbsolutePath(file: 'user.cfg', path: 'C:\\Tools\\FreeCAD'),
      const ManifestAbsolutePath(file: 'user.cfg', path: '\\\\server\\share\\tools'),
    ]);
  });

  test('scans unparsable config text line by line', () {
    final paths = findConfigAbsolutePaths({'system.cfg': '/opt/freecad\nrelative/path\nD:/work'});

    expect(paths, [
      const ManifestAbsolutePath(file: 'system.cfg', path: '/opt/freecad'),
      const ManifestAbsolutePath(file: 'system.cfg', path: 'D:/work'),
    ]);
  });
}
