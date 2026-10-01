// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';

import 'test_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.inMemory());
  tearDown(() => db.close());

  test('saves and reads a build', () async {
    await db.buildsDao.save(sampleBuild());

    final build = await db.buildsDao.getById('build-1');

    expect(build, isNotNull);
    expect(build!.version, '1.1.3');
    expect(build.kind, BuildKind.appimage);
    expect(build.channel, BuildChannel.stable);
    expect(build.platform, BuildPlatform.linux);
    expect(build.status, BuildStatus.installed);
    expect(build.verified, isTrue);
  });

  test('upserts a build with the same id', () async {
    await db.buildsDao.save(sampleBuild());
    await db.buildsDao.save(sampleBuild(version: '1.1.4'));

    final builds = await db.buildsDao.getAll();

    expect(builds, hasLength(1));
    expect(builds.single.version, '1.1.4');
  });

  test('updateStatus persists the new status', () async {
    await db.buildsDao.save(sampleBuild());

    await db.buildsDao.updateStatus('build-1', BuildStatus.broken);

    expect((await db.buildsDao.getById('build-1'))!.status, BuildStatus.broken);
  });

  test('deleteById removes the build', () async {
    await db.buildsDao.save(sampleBuild());

    await db.buildsDao.deleteById('build-1');

    expect(await db.buildsDao.getById('build-1'), isNull);
  });

  test('watchAll emits initial and updated values', () async {
    final stream = db.buildsDao.watchAll();

    expect(await stream.first, isEmpty);

    final next = expectLater(stream, emitsInOrder([isEmpty, hasLength(1)]));
    await db.buildsDao.save(sampleBuild());
    await next;
  });
}
