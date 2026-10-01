// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';

import 'test_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.inMemory();
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
  });
  tearDown(() => db.close());

  test('saves and finds a package by name', () async {
    await db.pythonPackagesDao.save(samplePackage());

    final package = await db.pythonPackagesDao.getByName('profile-1', 'numpy');

    expect(package, isNotNull);
    expect(package!.version, '1.26.4');
    expect(package.source, 'manual');
  });

  test('upserts by profile and package name', () async {
    await db.pythonPackagesDao.save(samplePackage());
    await db.pythonPackagesDao.save(samplePackage(id: 'package-2', version: '2.0.0'));

    final packages = await db.pythonPackagesDao.getByProfile('profile-1');

    expect(packages, hasLength(1));
    expect(packages.single.version, '2.0.0');
  });

  test('deletePackage removes only that package', () async {
    await db.pythonPackagesDao.save(samplePackage());
    await db.pythonPackagesDao.save(
      samplePackage(id: 'package-2', name: 'scipy', version: '1.13.0'),
    );

    await db.pythonPackagesDao.deletePackage('profile-1', 'numpy');

    final packages = await db.pythonPackagesDao.getByProfile('profile-1');
    expect(packages, hasLength(1));
    expect(packages.single.name, 'scipy');
  });

  test('deleteByProfile removes all packages of a profile', () async {
    await db.pythonPackagesDao.save(samplePackage());
    await db.pythonPackagesDao.save(samplePackage(id: 'package-2', name: 'scipy'));

    await db.pythonPackagesDao.deleteByProfile('profile-1');

    expect(await db.pythonPackagesDao.getByProfile('profile-1'), isEmpty);
  });
}
