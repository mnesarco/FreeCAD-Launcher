// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/addon_installation_manifest.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;
  late Directory mod;
  late AddonInstallationManifest manifest;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('fcl_addon_manifest');
    mod = Directory(p.join(temp.path, 'Mod'));
    manifest = AddonInstallationManifest(modDirectory: mod.path);
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  test('records a new installation with the AddonManager schema', () {
    manifest.recordInstallation(
      addonId: 'LiveSectionAnalyzer',
      branchDisplayName: 'main',
      extraFiles: ['/data/profiles/p/Macros/LiveSectionAnalyzer.FCMacro'],
      freecadVersion: const ['27', '1', '0'],
      now: DateTime.utc(2026, 10, 15, 11, 51, 48),
    );

    final decoded =
        jsonDecode(File(p.join(mod.path, AddonInstallationManifest.fileName)).readAsStringSync())
            as Map<String, dynamic>;
    final entry = decoded['LiveSectionAnalyzer'] as Map<String, dynamic>;
    expect(entry['addon_id'], 'LiveSectionAnalyzer');
    expect(entry['migrated'], isFalse);
    expect(entry['branch_display_name'], 'main');
    expect(entry['first_installed'], '2026-10-15T11:51:48.000+00:00');
    expect(entry['last_updated'], '2026-10-15T11:51:48.000+00:00');
    expect(entry['freecad_version'], ['27', '1', '0']);
    expect(entry['extra_files'], ['/data/profiles/p/Macros/LiveSectionAnalyzer.FCMacro']);
    expect(
      manifest.extraFilesOf('LiveSectionAnalyzer'),
      ['/data/profiles/p/Macros/LiveSectionAnalyzer.FCMacro'],
    );
    expect(manifest.extraFilesOf('Nope'), isEmpty);
  });

  test('updates merge extra files and keep first_installed; other entries survive', () {
    manifest.recordInstallation(
      addonId: 'A',
      branchDisplayName: 'main',
      extraFiles: const ['/macros/Old.FCMacro'],
      freecadVersion: const ['1', '1', '3'],
      now: DateTime.utc(2026, 10, 1),
    );
    manifest.recordInstallation(
      addonId: 'B',
      branchDisplayName: 'main',
      extraFiles: const [],
      freecadVersion: const ['1', '1', '3'],
      now: DateTime.utc(2026, 10, 2),
    );

    manifest.recordInstallation(
      addonId: 'A',
      branchDisplayName: 'dev',
      extraFiles: const ['/macros/New.FCMacro', '/macros/Old.FCMacro'],
      freecadVersion: const ['1', '1', '4'],
      now: DateTime.utc(2026, 10, 15),
    );

    final decoded =
        jsonDecode(File(p.join(mod.path, AddonInstallationManifest.fileName)).readAsStringSync())
            as Map<String, dynamic>;
    final entry = decoded['A'] as Map<String, dynamic>;
    expect(entry['first_installed'], '2026-10-01T00:00:00.000+00:00');
    expect(entry['last_updated'], '2026-10-15T00:00:00.000+00:00');
    expect(entry['branch_display_name'], 'dev');
    expect(entry['freecad_version'], ['1', '1', '4']);
    expect(entry['extra_files'], ['/macros/Old.FCMacro', '/macros/New.FCMacro']);
    expect(decoded.containsKey('B'), isTrue);
  });

  test('removes the entry and keeps the rest of the manifest', () {
    manifest.recordInstallation(
      addonId: 'A',
      branchDisplayName: 'main',
      extraFiles: const [],
      freecadVersion: const [],
      now: DateTime.utc(2026, 10, 1),
    );
    manifest.recordInstallation(
      addonId: 'B',
      branchDisplayName: 'main',
      extraFiles: const [],
      freecadVersion: const [],
      now: DateTime.utc(2026, 10, 1),
    );

    manifest.removeAddon('A');
    manifest.removeAddon('Missing');

    final decoded =
        jsonDecode(File(p.join(mod.path, AddonInstallationManifest.fileName)).readAsStringSync())
            as Map<String, dynamic>;
    expect(decoded.keys, ['B']);
  });

  test('invalid manifest content is ignored instead of crashing', () {
    mod.createSync(recursive: true);
    File(
      p.join(mod.path, AddonInstallationManifest.fileName),
    ).writeAsStringSync('not json');

    expect(manifest.extraFilesOf('A'), isEmpty);
    manifest.recordInstallation(
      addonId: 'A',
      branchDisplayName: 'main',
      extraFiles: const [],
      freecadVersion: const [],
      now: DateTime.utc(2026, 10, 1),
    );
    expect(manifest.extraFilesOf('A'), isEmpty);
    expect(
      File(p.join(mod.path, AddonInstallationManifest.fileName)).readAsStringSync(),
      contains('"addon_id": "A"'),
    );
  });

  test('manifestFreeCadVersion records three strings or nothing', () {
    expect(manifestFreeCadVersion('1.1.3'), ['1', '1', '3']);
    expect(manifestFreeCadVersion('1.0'), ['1', '0', '0']);
    expect(manifestFreeCadVersion('26.3rc1'), ['26', '3', '0']);
    expect(manifestFreeCadVersion('weekly-2026.09.30'), isEmpty);
    expect(manifestFreeCadVersion(null), isEmpty);
  });
}
