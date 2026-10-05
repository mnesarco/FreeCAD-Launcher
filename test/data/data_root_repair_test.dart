// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/data_root_repair.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:path/path.dart' as p;

import '../helpers/test_database.dart';
import 'test_fixtures.dart';

void main() {
  late Directory tempDirectory;
  late String oldRoot;
  late String newRoot;
  late AppDatabase db;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_root_repair');
    oldRoot = p.join(tempDirectory.path, 'old');
    newRoot = p.join(tempDirectory.path, 'new');
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> seed() async {
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
  }

  String createFile(String path) {
    File(path).createSync(recursive: true);
    return path;
  }

  test('rewrites stale paths whose mapped target exists', () async {
    await seed();
    final local = createFile(p.join(newRoot, 'builds', 'build-1', 'FreeCAD.exe'));
    final python = createFile(p.join(newRoot, 'builds', 'build-1', 'bin', 'python.exe'));
    final payload = createFile(p.join(newRoot, 'cache', 'releases.json'));
    final source = createFile(p.join(newRoot, 'downloads', 'addon.zip'));
    final target = Directory(
      p.join(newRoot, 'profiles', 'profile-1', 'AdditionalPythonPackages', 'py311'),
    )..createSync(recursive: true);

    await db.buildsDao.save(
      sampleBuild().copyWith(
        localPath: p.join(oldRoot, 'builds', 'build-1', 'FreeCAD.exe'),
        pythonPath: Value(p.join(oldRoot, 'builds', 'build-1', 'bin', 'python.exe')),
      ),
    );
    await db.catalogCacheDao.put(
      sampleCacheEntry(payloadPath: p.join(oldRoot, 'cache', 'releases.json')),
    );
    await db.installedAddonsDao.save(
      sampleAddon(
        source: 'zip',
        sourcePath: p.join(oldRoot, 'downloads', 'addon.zip'),
      ),
    );
    await db.pythonPackagesDao.save(
      samplePackage(
        targetDir: p.join(
          oldRoot,
          'profiles',
          'profile-1',
          'AdditionalPythonPackages',
          'py311',
        ),
      ),
    );

    final repaired = await DataRootRepair(db).rewritePathPrefix(from: oldRoot, to: newRoot);

    expect(repaired, 4);
    final build = await db.buildsDao.getById('build-1');
    expect(build!.localPath, local);
    expect(build.pythonPath, python);
    final cache = await db.catalogCacheDao.get('github:releases:stable');
    expect(cache!.payloadPath, payload);
    final addon = await db.installedAddonsDao.getByAddon('profile-1', 'A2plus');
    expect(addon!.sourcePath, source);
    final package = await db.pythonPackagesDao.getByName('profile-1', 'numpy');
    expect(package!.targetDir, target.path);
  });

  test('keeps paths whose mapped target is missing', () async {
    await seed();
    final stale = p.join(oldRoot, 'builds', 'build-1', 'FreeCAD.exe');
    await db.buildsDao.save(sampleBuild().copyWith(localPath: stale));

    final repaired = await DataRootRepair(db).rewritePathPrefix(from: oldRoot, to: newRoot);

    expect(repaired, 0);
    final build = await db.buildsDao.getById('build-1');
    expect(build!.localPath, stale);
  });

  test('ignores unrelated paths and identical roots', () async {
    await seed();
    final external = createFile(p.join(tempDirectory.path, 'external', 'FreeCAD.exe'));
    await db.buildsDao.save(sampleBuild().copyWith(localPath: external));

    final repaired = await DataRootRepair(db).rewritePathPrefix(from: oldRoot, to: newRoot);
    final identical = await DataRootRepair(db).rewritePathPrefix(from: newRoot, to: newRoot);

    expect(repaired, 0);
    expect(identical, 0);
    final build = await db.buildsDao.getById('build-1');
    expect(build!.localPath, external);
  });

  test('matches the prefix case-insensitively', () async {
    await seed();
    final local = createFile(p.join(newRoot, 'builds', 'build-1', 'FreeCAD.exe'));
    await db.buildsDao.save(
      sampleBuild().copyWith(
        localPath: p.join(oldRoot.toUpperCase(), 'builds', 'build-1', 'FreeCAD.exe'),
      ),
    );

    final repaired = await DataRootRepair(db).rewritePathPrefix(from: oldRoot, to: newRoot);

    expect(repaired, 1);
    final build = await db.buildsDao.getById('build-1');
    expect(build!.localPath, local);
  });
}
