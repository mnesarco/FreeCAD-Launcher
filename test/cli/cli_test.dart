import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/cli/cli.dart';
import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/state/app_services.dart';

import '../data/test_fixtures.dart';
import '../helpers/fake_process.dart';
import '../helpers/test_database.dart';

void main() {
  late Directory tempDirectory;
  late AppPaths paths;
  late AppDatabase db;
  late FakeProcessLauncher launcher;
  late AppServices services;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_cli_test');
    paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    db = createTestDatabase();
    launcher = FakeProcessLauncher();
    services = AppServices(
      paths: paths,
      database: db,
      processRunner: ProcessRunner(launcher: launcher),
    );
  });

  tearDown(() async {
    await services.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> seedProfile({String name = 'Dev'}) async {
    await db.buildsDao.save(sampleBuild());
    await services.profilesRepository.create(name: name, buildId: 'build-1');
  }

  test('prints help and version', () async {
    final out = StringBuffer();
    final err = StringBuffer();

    expect(await runCli(['--help'], services: services, out: out, err: err), cliOk);
    expect(out.toString(), contains('Usage:'));
    expect(err.toString(), isEmpty);

    out.clear();
    expect(await runCli(['--version'], services: services, out: out, err: err), cliOk);
    expect(out.toString().trim(), '$appName $appVersion');
  });

  test('lists profiles with build details', () async {
    await seedProfile();
    final out = StringBuffer();

    expect(await runCli(['list'], services: services, out: out, err: StringBuffer()), cliOk);

    expect(out.toString(), contains('Dev'));
    expect(out.toString(), contains('1.1.3'));
    expect(out.toString(), contains('py3.11'));
  });

  test('lists nothing when there are no profiles', () async {
    final out = StringBuffer();

    expect(await runCli(['list'], services: services, out: out, err: StringBuffer()), cliOk);
    expect(out.toString(), isEmpty);
  });

  test('rejects unknown commands and bad usage', () async {
    final err = StringBuffer();

    expect(
      await runCli(['frobnicate'], services: services, out: StringBuffer(), err: err),
      cliUsage,
    );
    expect(err.toString(), contains('Unknown command'));

    err.clear();
    expect(await runCli(['run'], services: services, out: StringBuffer(), err: err), cliUsage);
    expect(err.toString(), contains('run <profile>'));

    err.clear();
    expect(
      await runCli(['run', 'Dev', '--version'], services: services, out: StringBuffer(), err: err),
      cliUsage,
    );
    expect(err.toString(), contains('after --'));

    err.clear();
    expect(
      await runCli(['run', 'Nope'], services: services, out: StringBuffer(), err: err),
      cliUsage,
    );
    expect(err.toString(), contains('Profile not found'));
  });

  test('runs a profile, passes arguments and returns the exit code', () async {
    await seedProfile();
    final profile = (await services.profilesRepository.getByName('Dev'))!;
    final out = StringBuffer();
    final err = StringBuffer();

    final future = runCli(
      ['run', 'Dev', '--', '--version', 'file.FCStd'],
      services: services,
      out: out,
      err: err,
    );
    await pumpEventQueue();

    final userCfg = paths.profilePaths(profile.id).userCfg;
    final systemCfg = paths.profilePaths(profile.id).systemCfg;
    expect(launcher.specs.single.arguments, [
      '--console',
      '--version',
      'file.FCStd',
      '-u',
      userCfg,
      '-s',
      systemCfg,
    ]);
    expect(services.profiles.isRunning(profile.id), isTrue);

    launcher.handles.single.exit(7);

    expect(await future, 7);
    expect(err.toString(), isEmpty);
  });

  test('fails when the build is not installed', () async {
    await seedProfile();
    await db.buildsDao.updateStatus('build-1', BuildStatus.missing);
    final err = StringBuffer();

    final code = await runCli(['run', 'Dev'], services: services, out: StringBuffer(), err: err);

    expect(code, cliFailure);
    expect(err.toString(), contains('missing'));
    expect(launcher.specs, isEmpty);
  });
}
