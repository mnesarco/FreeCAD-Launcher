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

  test('saves and finds a macro by file name', () async {
    await db.macrosDao.save(sampleMacro());

    final macro = await db.macrosDao.getByFileName('profile-1', 'MyMacro.FCMacro');

    expect(macro, isNotNull);
    expect(macro!.name, 'MyMacro');
  });

  test('upserts by profile and file name', () async {
    await db.macrosDao.save(sampleMacro());
    await db.macrosDao.save(sampleMacro(id: 'macro-2', name: 'Renamed'));

    final macros = await db.macrosDao.getByProfile('profile-1');

    expect(macros, hasLength(1));
    expect(macros.single.name, 'Renamed');
  });

  test('deleteByFileName removes only that macro', () async {
    await db.macrosDao.save(sampleMacro());
    await db.macrosDao.save(
      sampleMacro(id: 'macro-2', name: 'Other', fileName: 'Other.FCMacro'),
    );

    await db.macrosDao.deleteByFileName('profile-1', 'MyMacro.FCMacro');

    final macros = await db.macrosDao.getByProfile('profile-1');
    expect(macros, hasLength(1));
    expect(macros.single.fileName, 'Other.FCMacro');
  });
}
