// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/debug_bundle.dart';
import 'package:freecad_launcher/platform/diagnostics.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/debug_bundle_controller.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/test_database.dart';

void main() {
  late Directory root;
  late AppPaths paths;
  late AppDatabase db;
  late DebugBundleController controller;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('fcl_debug_controller');
    paths = AppPaths(dataRoot: root.path);
    await paths.ensureBaseDirectories();
    db = createTestDatabase();
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    await db.installedAddonsDao.save(sampleAddon(addonId: 'A2plus'));
    await db.pythonPackagesDao.save(samplePackage(name: 'six', version: '1.17.0'));
    controller = DebugBundleController(
      service: DebugBundleService(paths: paths),
      database: db,
      diagnostics: DiagnosticsService(
        paths: paths,
        platform: BuildPlatform.linux,
        environment: const {},
        fuseDeviceExists: () => true,
      ),
      paths: paths,
      clock: () => DateTime(2026, 9, 20, 10, 30, 15),
    );
  });

  tearDown(() async {
    await db.close();
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('exports a bundle with the inventory and diagnostics', () async {
    final output = p.join(root.path, 'debug.zip');
    final result = await controller.export(output);

    expect(result.isOk, isTrue);
    expect(controller.exporting.value, isFalse);
    expect(controller.lastExportedPath.value, output);
    expect(File(output).existsSync(), isTrue);

    final archive = ZipDecoder().decodeBytes(File(output).readAsBytesSync());
    final system = utf8.decode(
      archive.files.firstWhere((file) => file.name == 'system.txt').content,
    );
    expect(system, contains('FreeCAD Launcher 0.1.0'));
    expect(system, contains('Builds (1):'));
    expect(system, contains('1.1.3'));
    expect(system, contains('stable'));
    expect(system, contains('Profiles (1):'));
    expect(system, contains('Default'));
    expect(system, contains('addons=1'));
    expect(system, contains('packages=1'));

    final diagnostics = utf8.decode(
      archive.files.firstWhere((file) => file.name == 'diagnostics.txt').content,
    );
    expect(diagnostics, contains('diagnostics'));
  });

  test('suggests a timestamped file name from the clock', () {
    expect(
      controller.suggestedFileName(),
      'freecad-launcher-debug-20260920-103015.zip',
    );
  });
}
