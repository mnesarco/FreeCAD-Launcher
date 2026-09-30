// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:path/path.dart' as p;

import '../helpers/test_database.dart';
import 'test_fixtures.dart';

void main() {
  late Directory tempDirectory;
  late AppPaths paths;
  late AppDatabase db;
  late ProfilesRepository repository;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_profiles_repo');
    paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    db = createTestDatabase();
    await db.buildsDao.save(sampleBuild());
    repository = ProfilesRepository(
      database: db,
      paths: paths,
      platform: BuildPlatform.linux,
      clock: () => DateTime.utc(2026, 9, 19, 12),
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  String rootOf(String profileId) => paths.profilePaths(profileId).root;

  bool hasStagingDirectory() {
    final directory = Directory(paths.profilesDir);
    if (!directory.existsSync()) {
      return false;
    }
    return directory.listSync().any((entry) => entry.path.endsWith('.part'));
  }

  test('creates a profile with a trimmed name and the build Python version', () async {
    final result = await repository.create(name: '  Dev  ', buildId: 'build-1');

    expect(result.isOk, isTrue);
    final profile = result.valueOrNull!;
    expect(profile.name, 'Dev');
    expect(profile.description, isNull);
    expect(profile.buildId, 'build-1');
    expect(profile.pythonVersion, '3.11');
    expect(profile.createdAt, DateTime.utc(2026, 9, 19, 12));

    for (final path in ProfilePaths(rootOf(profile.id)).directoriesFor(BuildPlatform.linux)) {
      expect(Directory(path).existsSync(), isTrue, reason: path);
    }
    expect(hasStagingDirectory(), isFalse);
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

  test('leaves no partial state when the layout cannot be created', () async {
    final blockedRoot = Directory.systemTemp.createTempSync('fcl_blocked');
    File(p.join(blockedRoot.path, 'profiles')).writeAsStringSync('blocked');
    final blocked = ProfilesRepository(
      database: db,
      paths: AppPaths(dataRoot: blockedRoot.path),
      platform: BuildPlatform.linux,
      clock: () => DateTime.utc(2026, 9, 19, 12),
    );

    final result = await blocked.create(name: 'Blocked', buildId: 'build-1');

    expect(result.isErr, isTrue);
    expect(await db.profilesDao.getAll(), isEmpty);
    blockedRoot.deleteSync(recursive: true);
  });

  test('duplicate copies config files only by default', () async {
    final created = await repository.create(name: 'Source', buildId: 'build-1');
    final source = created.valueOrNull!;
    final sourceRoot = rootOf(source.id);
    File(p.join(sourceRoot, 'user.cfg')).writeAsStringSync('cfg');
    File(p.join(sourceRoot, 'system.cfg')).writeAsStringSync('sys');
    File(p.join(sourceRoot, 'Mod', 'A2plus', 'init.py')).createSync(recursive: true);
    File(
      p.join(sourceRoot, 'AdditionalPythonPackages', 'py311', 'numpy.py'),
    ).createSync(recursive: true);
    File(p.join(sourceRoot, 'MyMacro.FCMacro')).writeAsStringSync('macro');
    await db.installedAddonsDao.save(sampleAddon(profileId: source.id));
    await db.pythonPackagesDao.save(
      samplePackage(
        profileId: source.id,
        targetDir: p.join(sourceRoot, 'AdditionalPythonPackages', 'py311'),
      ),
    );
    await db.macrosDao.save(sampleMacro(profileId: source.id));

    final result = await repository.duplicate(profileId: source.id, name: 'Copy');

    expect(result.isOk, isTrue);
    final copy = result.valueOrNull!;
    final copyRoot = rootOf(copy.id);
    expect(File(p.join(copyRoot, 'user.cfg')).readAsStringSync(), 'cfg');
    expect(File(p.join(copyRoot, 'system.cfg')).readAsStringSync(), 'sys');
    expect(Directory(p.join(copyRoot, 'Mod')).listSync(), isEmpty);
    expect(
      Directory(p.join(copyRoot, 'AdditionalPythonPackages')).listSync(),
      isEmpty,
    );
    expect(File(p.join(copyRoot, 'Mod', 'A2plus', 'init.py')).existsSync(), isFalse);
    expect(File(p.join(copyRoot, 'MyMacro.FCMacro')).existsSync(), isFalse);
    expect(await db.installedAddonsDao.getByProfile(copy.id), isEmpty);
    expect(await db.pythonPackagesDao.getByProfile(copy.id), isEmpty);
    expect(await db.macrosDao.getByProfile(copy.id), isEmpty);
  });

  test('duplicate copies the full payload when requested', () async {
    final created = await repository.create(name: 'Source', buildId: 'build-1');
    final source = created.valueOrNull!;
    final sourceRoot = rootOf(source.id);
    File(p.join(sourceRoot, 'user.cfg')).writeAsStringSync('cfg');
    File(p.join(sourceRoot, 'Mod', 'A2plus', 'init.py')).createSync(recursive: true);
    File(
      p.join(sourceRoot, 'AdditionalPythonPackages', 'py311', 'numpy.py'),
    ).createSync(recursive: true);
    File(p.join(sourceRoot, 'MyMacro.FCMacro')).writeAsStringSync('macro');
    await db.installedAddonsDao.save(sampleAddon(profileId: source.id));
    await db.pythonPackagesDao.save(
      samplePackage(
        profileId: source.id,
        targetDir: p.join(sourceRoot, 'AdditionalPythonPackages', 'py311'),
      ),
    );
    await db.macrosDao.save(sampleMacro(profileId: source.id));

    final result = await repository.duplicate(
      profileId: source.id,
      name: 'Full',
      copyPayload: true,
    );

    expect(result.isOk, isTrue);
    final copy = result.valueOrNull!;
    final copyRoot = rootOf(copy.id);
    expect(File(p.join(copyRoot, 'Mod', 'A2plus', 'init.py')).existsSync(), isTrue);
    expect(
      File(p.join(copyRoot, 'AdditionalPythonPackages', 'py311', 'numpy.py')).existsSync(),
      isTrue,
    );
    expect(File(p.join(copyRoot, 'MyMacro.FCMacro')).existsSync(), isTrue);

    final addons = await db.installedAddonsDao.getByProfile(copy.id);
    expect(addons.single.addonId, 'A2plus');
    final packages = await db.pythonPackagesDao.getByProfile(copy.id);
    expect(
      packages.single.targetDir,
      p.join(copyRoot, 'AdditionalPythonPackages', 'py311'),
    );
    expect((await db.macrosDao.getByProfile(copy.id)).single.fileName, 'MyMacro.FCMacro');
  });

  test('duplicate is atomic when copying fails', () async {
    final created = await repository.create(name: 'Source', buildId: 'build-1');
    final source = created.valueOrNull!;
    Directory(p.join(rootOf(source.id), 'user.cfg')).createSync(recursive: true);

    final result = await repository.duplicate(profileId: source.id, name: 'Copy');

    expect(result.isErr, isTrue);
    expect(await db.profilesDao.getAll(), hasLength(1));
    expect(hasStagingDirectory(), isFalse);
    expect(Directory(paths.profilesDir).listSync(), hasLength(1));
  });

  test('duplicate allows an unhealthy source build', () async {
    final created = await repository.create(name: 'Source', buildId: 'build-1');
    await db.buildsDao.updateStatus('build-1', BuildStatus.missing);

    final result = await repository.duplicate(profileId: created.valueOrNull!.id, name: 'Copy');

    expect(result.isOk, isTrue);
    expect(result.valueOrNull!.buildId, 'build-1');
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

  test('delete removes the directory and cascades DB rows', () async {
    final created = await repository.create(name: 'Dev', buildId: 'build-1');
    final profile = created.valueOrNull!;
    final root = rootOf(profile.id);
    File(p.join(root, 'user.cfg')).writeAsStringSync('cfg');
    await db.installedAddonsDao.save(sampleAddon(profileId: profile.id));
    await db.pythonPackagesDao.save(samplePackage(profileId: profile.id));
    await db.macrosDao.save(sampleMacro(profileId: profile.id));

    final result = await repository.delete(profile.id);

    expect(result.isOk, isTrue);
    expect(Directory(root).existsSync(), isFalse);
    expect(await repository.getById(profile.id), isNull);
    expect(await db.installedAddonsDao.getByProfile(profile.id), isEmpty);
    expect(await db.pythonPackagesDao.getByProfile(profile.id), isEmpty);
    expect(await db.macrosDao.getByProfile(profile.id), isEmpty);
    expect((await repository.delete('nope')).isErr, isTrue);
  });
}
