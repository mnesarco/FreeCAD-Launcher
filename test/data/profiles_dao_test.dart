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
