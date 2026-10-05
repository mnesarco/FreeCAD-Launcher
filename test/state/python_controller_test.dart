// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/python_controller.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_pip.dart';
import '../helpers/test_database.dart';

void main() {
  late Directory tempDirectory;
  late AppPaths paths;
  late AppDatabase db;
  late FakePipRunner pip;
  late FakePythonEnvResolver resolver;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_python_controller');
    paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    db = createTestDatabase();
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    pip = FakePipRunner();
    resolver = FakePythonEnvResolver('/opt/freecad/bin/python');
  });

  tearDown(() async {
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  PythonController controller() {
    return PythonController(
      database: db,
      paths: paths,
      pipRunner: pip,
      pythonResolver: resolver,
      clock: () => DateTime.utc(2026, 9, 19, 17),
    );
  }

  test('runs pip inside the AppImage when FUSE is available', () async {
    final subject = PythonController(
      database: db,
      paths: paths,
      pipRunner: pip,
      pythonResolver: resolver,
      fuseAvailable: () async => true,
      clock: () => DateTime.utc(2026, 9, 19, 17),
    );

    final result = await subject.install(profileId: 'profile-1', specText: 'six');

    expect(result.isOk, isTrue);
    expect(pip.calls.single.appImagePath, '/data/builds/build-1');
    expect(pip.calls.single.pythonPath, isNull);
  });

  test('installs packages with pip and records them', () async {
    final subject = controller();

    final result = await subject.install(
      profileId: 'profile-1',
      specText: 'numpy==1.26.4\n# comment\nsix',
    );

    expect(result.isOk, isTrue);
    expect(pip.calls.single.packages, ['numpy==1.26.4', 'six']);
    expect(
      pip.calls.single.targetDirectory,
      p.join(tempDirectory.path, 'profiles', 'profile-1', 'AdditionalPythonPackages', 'py311'),
    );
    final packages = await db.pythonPackagesDao.getByProfile('profile-1');
    expect(packages.map((package) => package.name).toSet(), {'numpy', 'six'});
    expect(packages.every((package) => package.source == 'manual'), isTrue);
    subject.dispose();
  });

  test('reports pip failures without recording packages', () async {
    pip.success = false;
    final subject = controller();

    final result = await subject.install(profileId: 'profile-1', specText: 'numpy');

    expect(result.isErr, isTrue);
    expect(subject.errors.value['profile-1'], isNotNull);
    expect(await db.pythonPackagesDao.getByProfile('profile-1'), isEmpty);
    subject.dispose();
  });

  test('rejects empty or unparsable specs', () async {
    final subject = controller();

    expect((await subject.install(profileId: 'profile-1', specText: '')).isErr, isTrue);
    expect((await subject.install(profileId: 'profile-1', specText: '-e git+x')).isErr, isTrue);
    expect(pip.calls, isEmpty);
    subject.dispose();
  });

  test('uninstalls RECORD-listed files and deletes the row', () async {
    final target = p.join(
      tempDirectory.path,
      'profiles',
      'profile-1',
      'AdditionalPythonPackages',
      'py311',
    );
    File(p.join(target, 'numpy', '__init__.py')).createSync(recursive: true);
    File(p.join(target, 'numpy-1.26.4.dist-info', 'RECORD'))
      ..createSync(recursive: true)
      ..writeAsStringSync('numpy/__init__.py,,\n');
    await db.pythonPackagesDao.save(
      samplePackage(profileId: 'profile-1', name: 'numpy', targetDir: target),
    );
    final subject = controller();
    subject.start();
    await pumpEventQueue();

    final result = await subject.uninstall(profileId: 'profile-1', packageName: 'numpy');

    expect(result.isOk, isTrue);
    expect(Directory(p.join(target, 'numpy')).existsSync(), isFalse);
    expect(await db.pythonPackagesDao.getByName('profile-1', 'numpy'), isNull);
    subject.dispose();
  });

  test('uninstall reports unknown packages', () async {
    final subject = controller();
    subject.start();

    final result = await subject.uninstall(profileId: 'profile-1', packageName: 'nope');

    expect(result.isErr, isTrue);
    subject.dispose();
  });
}
