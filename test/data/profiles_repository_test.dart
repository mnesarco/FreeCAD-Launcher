import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';

import '../helpers/test_database.dart';
import 'test_fixtures.dart';

void main() {
  late AppDatabase db;
  late ProfilesRepository repository;

  setUp(() async {
    db = createTestDatabase();
    await db.buildsDao.save(sampleBuild());
    repository = ProfilesRepository(
      database: db,
      clock: () => DateTime.utc(2026, 9, 19, 12),
    );
  });

  tearDown(() => db.close());

  test('creates a profile with a trimmed name and the build Python version', () async {
    final result = await repository.create(name: '  Dev  ', buildId: 'build-1');

    expect(result.isOk, isTrue);
    final profile = result.valueOrNull!;
    expect(profile.name, 'Dev');
    expect(profile.description, isNull);
    expect(profile.buildId, 'build-1');
    expect(profile.pythonVersion, '3.11');
    expect(profile.createdAt, DateTime.utc(2026, 9, 19, 12));
  });

  test('rejects duplicate names case-insensitively', () async {
    await repository.create(name: 'Dev', buildId: 'build-1');

    final result = await repository.create(name: ' dev ', buildId: 'build-1');

    expect(result.isErr, isTrue);
    expect(result.errorOrNull!.message, contains('already exists'));
  });

  test('rejects invalid names', () async {
    final empty = await repository.create(name: '   ', buildId: 'build-1');
    expect(empty.errorOrNull!.message, contains('Enter a profile name'));

    final tooLong = await repository.create(
      name: 'a' * 65,
      buildId: 'build-1',
    );
    expect(tooLong.errorOrNull!.message, contains('limited to 64'));

    final control = await repository.create(name: 'bad\u0000name', buildId: 'build-1');
    expect(control.errorOrNull!.message, contains('control characters'));
  });

  test('rejects a missing build', () async {
    final result = await repository.create(name: 'Dev', buildId: 'nope');

    expect(result.isErr, isTrue);
    expect(result.errorOrNull!.message, contains('no longer exists'));
  });

  test('rejects a build that is not installed', () async {
    await db.buildsDao.save(
      sampleBuild(id: 'build-missing', version: '1.0.9', status: BuildStatus.missing),
    );

    final result = await repository.create(name: 'Dev', buildId: 'build-missing');

    expect(result.isErr, isTrue);
    expect(result.errorOrNull!.message, contains('not installed'));
  });

  test('rejects a build without a detected Python version', () async {
    await db.buildsDao.save(
      sampleBuild(id: 'build-nopy', version: '1.0.8', pythonVersion: null),
    );

    final result = await repository.create(name: 'Dev', buildId: 'build-nopy');

    expect(result.isErr, isTrue);
    expect(result.errorOrNull!.message, contains('no detected Python'));
  });

  test('renames a profile and enforces uniqueness', () async {
    final created = await repository.create(name: 'Dev', buildId: 'build-1');
    final profile = created.valueOrNull!;

    final renamed = await repository.rename(profileId: profile.id, name: ' Work ');
    expect(renamed.valueOrNull!.name, 'Work');
    expect(renamed.valueOrNull!.updatedAt, DateTime.utc(2026, 9, 19, 12));

    await repository.create(name: 'Second', buildId: 'build-1');
    final clash = await repository.rename(profileId: profile.id, name: 'second');
    expect(clash.isErr, isTrue);
    expect(clash.errorOrNull!.message, contains('already exists'));

    final same = await repository.rename(profileId: profile.id, name: 'Work');
    expect(same.isOk, isTrue);
  });

  test('setBuild updates the binding and reports Python changes', () async {
    await db.buildsDao.save(
      sampleBuild(id: 'build-2', version: '1.0.2', pythonVersion: '3.10'),
    );
    await db.buildsDao.save(
      sampleBuild(id: 'build-3', version: '1.1.2', pythonVersion: '3.10'),
    );
    final created = await repository.create(name: 'Dev', buildId: 'build-1');
    final profile = created.valueOrNull!;

    final changed = await repository.setBuild(profileId: profile.id, buildId: 'build-2');

    expect(changed.isOk, isTrue);
    expect(changed.valueOrNull!.pythonChanged, isTrue);
    expect(changed.valueOrNull!.profile.buildId, 'build-2');
    expect(changed.valueOrNull!.profile.pythonVersion, '3.10');

    final samePython = await repository.setBuild(profileId: profile.id, buildId: 'build-3');

    expect(samePython.valueOrNull!.pythonChanged, isFalse);
    expect(samePython.valueOrNull!.profile.buildId, 'build-3');
  });

  test('setBuild rejects unhealthy builds and unknown profiles', () async {
    await db.buildsDao.save(
      sampleBuild(id: 'build-broken', version: '1.0.7', status: BuildStatus.broken),
    );
    await db.buildsDao.save(
      sampleBuild(id: 'build-nopy', version: '1.0.8', pythonVersion: null),
    );
    final created = await repository.create(name: 'Dev', buildId: 'build-1');
    final profile = created.valueOrNull!;

    expect(
      (await repository.setBuild(profileId: profile.id, buildId: 'build-broken')).isErr,
      isTrue,
    );
    expect(
      (await repository.setBuild(profileId: profile.id, buildId: 'build-nopy')).isErr,
      isTrue,
    );
    expect((await repository.setBuild(profileId: 'nope', buildId: 'build-1')).isErr, isTrue);
  });

  test('delete removes the profile and reports unknown ids', () async {
    final created = await repository.create(name: 'Dev', buildId: 'build-1');

    expect((await repository.delete(created.valueOrNull!.id)).isOk, isTrue);
    expect(await repository.getById(created.valueOrNull!.id), isNull);
    expect((await repository.delete('nope')).isErr, isTrue);
  });
}
