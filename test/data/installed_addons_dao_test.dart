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

  test('saves and reads an addon for a profile', () async {
    await db.installedAddonsDao.save(sampleAddon());

    final addon = await db.installedAddonsDao.getByAddon('profile-1', 'A2plus');

    expect(addon, isNotNull);
    expect(addon!.displayName, 'A2plus');
    expect(addon.gitRef, 'master');
  });

  test('upserts by profile and addon id', () async {
    await db.installedAddonsDao.save(sampleAddon());
    await db.installedAddonsDao.save(sampleAddon(id: 'addon-2', displayName: 'A2plus v2'));

    final addons = await db.installedAddonsDao.getByProfile('profile-1');

    expect(addons, hasLength(1));
    expect(addons.single.displayName, 'A2plus v2');
  });

  test('deleteAddon removes only the matching row', () async {
    await db.installedAddonsDao.save(sampleAddon());
    await db.installedAddonsDao.save(
      sampleAddon(id: 'addon-2', addonId: 'Fasteners', displayName: 'Fasteners'),
    );

    await db.installedAddonsDao.deleteAddon('profile-1', 'A2plus');

    final addons = await db.installedAddonsDao.getByProfile('profile-1');
    expect(addons, hasLength(1));
    expect(addons.single.addonId, 'Fasteners');
  });

  test('deleteByProfile removes all addons of a profile', () async {
    await db.installedAddonsDao.save(sampleAddon());
    await db.installedAddonsDao.save(
      sampleAddon(id: 'addon-2', addonId: 'Fasteners', displayName: 'Fasteners'),
    );

    await db.installedAddonsDao.deleteByProfile('profile-1');

    expect(await db.installedAddonsDao.getByProfile('profile-1'), isEmpty);
  });
}
