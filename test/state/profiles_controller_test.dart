// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/diagnostics.dart';
import 'package:freecad_launcher/platform/launch.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/state/profiles_controller.dart';

import '../data/test_fixtures.dart';
import '../helpers/fake_process.dart';
import '../helpers/test_database.dart';

class FakeQuarantineGuard implements QuarantineGuard {
  bool quarantined = false;
  final List<String> cleared = [];

  @override
  Future<bool> isQuarantined(String appPath) async => quarantined;

  @override
  Future<void> clear(String appPath) async {
    cleared.add(appPath);
  }
}

void main() {
  late Directory tempDirectory;
  late AppPaths paths;
  late AppDatabase db;
  late ProfilesRepository repository;
  late FakeProcessLauncher launcher;
  late FakeQuarantineGuard quarantine;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_profiles_controller');
    paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    db = createTestDatabase();
    await db.buildsDao.save(sampleBuild());
    repository = ProfilesRepository(
      database: db,
      paths: paths,
      platform: BuildPlatform.linux,
      clock: () => DateTime.utc(2026, 9, 19, 15),
    );
    launcher = FakeProcessLauncher();
    quarantine = FakeQuarantineGuard();
  });

  tearDown(() async {
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  ProfilesController buildController({
    BuildPlatform platform = BuildPlatform.linux,
    bool fuseAvailable = true,
  }) {
    if (fuseAvailable) {
      File('${tempDirectory.path}/fusermount').createSync();
    }
    final runner = ProcessRunner(launcher: launcher);
    return ProfilesController(
      database: db,
      repository: repository,
      paths: paths,
      platform: platform,
      runtime: FreeCadRuntime(
        processRunner: runner,
        diagnostics: DiagnosticsService(
          paths: paths,
          platform: platform,
          processRunner: runner,
          environment: {'PATH': fuseAvailable ? tempDirectory.path : ''},
          fuseDeviceExists: () => fuseAvailable,
        ),
        platform: platform,
        quarantineGuard: quarantine,
        environment: const {},
      ),
    );
  }

  Future<void> waitForProfiles(ProfilesController controller) async {
    for (var attempt = 0; attempt < 250 && controller.profiles.value.isEmpty; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  test('start mirrors profiles from the database', () async {
    final controller = buildController();
    controller.start();
    await repository.create(name: 'Dev', buildId: 'build-1');

    await waitForProfiles(controller);

    expect(controller.profiles.value.single.name, 'Dev');
    controller.dispose();
  });

  test('planFor returns the isolated plan and blocks unhealthy builds', () async {
    final created = await repository.create(name: 'Dev', buildId: 'build-1');
    final profileId = created.valueOrNull!.id;
    final controller = buildController();

    final result = await controller.planFor(profileId);

    expect(result.isOk, isTrue);
    final plan = result.valueOrNull!;
    expect(plan.executable, '/data/builds/build-1');
    expect(plan.arguments, [
      '-u',
      paths.profilePaths(profileId).userCfg,
      '-s',
      paths.profilePaths(profileId).systemCfg,
    ]);
    expect(plan.environment['FREECAD_USER_HOME'], paths.profilePaths(profileId).root);

    await db.buildsDao.updateStatus('build-1', BuildStatus.missing);
    expect((await controller.planFor(profileId)).isErr, isTrue);
    expect((await controller.planFor('nope')).isErr, isTrue);
    controller.dispose();
  });

  test('launch blocks profiles whose build is not installed', () async {
    final created = await repository.create(name: 'Dev', buildId: 'build-1');
    await db.buildsDao.updateStatus('build-1', BuildStatus.missing);
    final controller = buildController();

    final result = await controller.launch(profileId: created.valueOrNull!.id);

    expect(result.isFailure, isTrue);
    expect(result.error!.message, contains('missing'));
    controller.dispose();
  });

  test('launch fails for unknown profiles', () async {
    final controller = buildController();

    final result = await controller.launch(profileId: 'nope');

    expect(result.isFailure, isTrue);
    expect(result.error!.message, contains('Profile not found'));
    controller.dispose();
  });

  test('launch recreates the profile directories and records last use', () async {
    final created = await repository.create(name: 'Dev', buildId: 'build-1');
    final profile = created.valueOrNull!;
    final home = paths.profilePaths(profile.id).home;
    Directory(home).deleteSync(recursive: true);
    final controller = buildController();

    final result = await controller.launch(
      profileId: profile.id,
      userArguments: const ['--version'],
    );

    expect(result.isStarted, isTrue);
    expect(Directory(home).existsSync(), isTrue);
    expect(launcher.specs.single.arguments.take(2), ['--console', '--version']);
    expect(launcher.specs.single.executable, '/data/builds/build-1');
    expect(
      (await repository.getById(profile.id))!.lastUsedAt,
      DateTime.utc(2026, 9, 19, 15),
    );
    launcher.handles.single.exit(0);
    await result.launch!.exitCode;
    controller.dispose();
  });

  test('tracks the running profile and streams output to the log', () async {
    final created = await repository.create(name: 'Dev', buildId: 'build-1');
    final profile = created.valueOrNull!;
    final controller = buildController();

    final result = await controller.launch(profileId: profile.id);

    expect(controller.isRunning(profile.id), isTrue);
    expect(controller.launchLogs.value[profile.id], result.launch!.logPath);

    launcher.handles.single
      ..emitStdout('hello\n')
      ..emitStderr('warn\n')
      ..exit(0);

    expect(await result.launch!.exitCode, 0);
    for (var attempt = 0;
        attempt < 250 && controller.isRunning(profile.id);
        attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    expect(controller.isRunning(profile.id), isFalse);
    expect(controller.lastExitCodes.value[profile.id], 0);

    final log = File(result.launch!.logPath);
    for (var attempt = 0;
        attempt < 250 && !log.readAsStringSync().contains('warn');
        attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    final content = log.readAsStringSync();
    expect(content, contains('hello'));
    expect(content, contains('warn'));
    controller.dispose();
  });

  test('keeps the profile running until all launches exit', () async {
    final created = await repository.create(name: 'Dev', buildId: 'build-1');
    final profile = created.valueOrNull!;
    final controller = buildController();

    final first = await controller.launch(profileId: profile.id);
    final second = await controller.launch(profileId: profile.id);

    expect(controller.isRunning(profile.id), isTrue);
    launcher.handles[0].exit(0);
    await first.launch!.exitCode;
    expect(controller.isRunning(profile.id), isTrue);

    launcher.handles[1].exit(0);
    await second.launch!.exitCode;
    expect(controller.isRunning(profile.id), isFalse);
    controller.dispose();
  });

  test('launch enables the AppImage fallback when FUSE is missing', () async {
    final created = await repository.create(name: 'Dev', buildId: 'build-1');
    final controller = buildController(fuseAvailable: false);

    final result = await controller.launch(profileId: created.valueOrNull!.id);

    expect(result.isStarted, isTrue);
    expect(launcher.specs.single.environment['APPIMAGE_EXTRACT_AND_RUN'], '1');
    launcher.handles.single.exit(0);
    await result.launch!.exitCode;
    controller.dispose();
  });

  test('macOS quarantine requires consent before clearing and launching', () async {
    final created = await repository.create(name: 'Dev', buildId: 'build-1');
    final profileId = created.valueOrNull!.id;
    quarantine.quarantined = true;
    final controller = buildController(platform: BuildPlatform.macos);

    final blocked = await controller.launch(profileId: profileId);

    expect(blocked.isQuarantineRequired, isTrue);
    expect(blocked.quarantineAppPath, '/data/builds/build-1');
    expect(quarantine.cleared, isEmpty);
    expect(launcher.specs, isEmpty);

    final started = await controller.launch(profileId: profileId, quarantineConsent: true);

    expect(quarantine.cleared, ['/data/builds/build-1']);
    expect(started.isStarted, isTrue);
    launcher.handles.single.exit(0);
    await started.launch!.exitCode;
    controller.dispose();
  });
}
