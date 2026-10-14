// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:sqlite3/sqlite3.dart';

import 'test_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.inMemory();
    await db.buildsDao.save(sampleBuild());
  });
  tearDown(() => db.close());

  test('saves and finds a profile by name case-insensitively', () async {
    await db.profilesDao.save(sampleProfile(name: 'Default'));

    expect((await db.profilesDao.getByName('default'))?.id, 'profile-1');
  });

  test('counts profiles per build', () async {
    await db.profilesDao.save(sampleProfile());
    await db.profilesDao.save(sampleProfile(id: 'profile-2', name: 'Second'));

    expect(await db.profilesDao.countByBuild('build-1'), 2);
  });

  test('orders profiles by manual sort order, then name', () async {
    await db.profilesDao.save(sampleProfile(id: 'p-c', name: 'Charlie', sortOrder: 1));
    await db.profilesDao.save(sampleProfile(id: 'p-a', name: 'Alpha', sortOrder: 2));
    await db.profilesDao.save(sampleProfile(id: 'p-b', name: 'Bravo', sortOrder: 0));

    final profiles = await db.profilesDao.getAll();

    expect([for (final profile in profiles) profile.name], ['Bravo', 'Charlie', 'Alpha']);
  });

  test('saveOrder renumbers profiles in the given order', () async {
    await db.profilesDao.save(sampleProfile(id: 'p-a', name: 'Alpha', sortOrder: 0));
    await db.profilesDao.save(sampleProfile(id: 'p-b', name: 'Bravo', sortOrder: 1));

    await db.profilesDao.saveOrder(['p-b', 'p-a']);

    final profiles = await db.profilesDao.getAll();
    expect([for (final profile in profiles) profile.id], ['p-b', 'p-a']);
    expect([for (final profile in profiles) profile.sortOrder], [0, 1]);
  });

  test('nextSortOrder appends after the last profile', () async {
    expect(await db.profilesDao.nextSortOrder(), 0);

    await db.profilesDao.save(sampleProfile(id: 'p-a', name: 'Alpha', sortOrder: 4));

    expect(await db.profilesDao.nextSortOrder(), 5);
  });

  test('blocks deleting a build referenced by a profile', () async {
    await db.profilesDao.save(sampleProfile());

    expect(db.buildsDao.deleteById('build-1'), throwsA(isA<SqliteException>()));
  });

  test('deleting a profile cascades to addons, packages and macros', () async {
    await db.profilesDao.save(sampleProfile());
    await db.installedAddonsDao.save(sampleAddon());
    await db.pythonPackagesDao.save(samplePackage());
    await db.macrosDao.save(sampleMacro());

    await db.profilesDao.deleteById('profile-1');

    expect(await db.installedAddonsDao.getByProfile('profile-1'), isEmpty);
    expect(await db.pythonPackagesDao.getByProfile('profile-1'), isEmpty);
    expect(await db.macrosDao.getByProfile('profile-1'), isEmpty);
  });

  test('touchLastUsed updates only the timestamp', () async {
    await db.profilesDao.save(sampleProfile());
    final at = DateTime.utc(2026, 9, 19);

    await db.profilesDao.touchLastUsed('profile-1', at);

    expect((await db.profilesDao.getById('profile-1'))!.lastUsedAt, at);
  });
}
