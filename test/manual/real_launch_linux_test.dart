// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/launch_command.dart';
import 'package:freecad_launcher/platform/diagnostics.dart';
import 'package:freecad_launcher/platform/launch.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/state/profiles_controller.dart';

void main() {
  final binary = Platform.environment['FCL_LAUNCH_BINARY'] ??
      '/home/mnesarco/devel/toolkits/freecad/'
          'FreeCAD_1.0.2-conda-Linux-x86_64-py311.AppImage';

  test(
    'launches a real AppImage inside an isolated profile',
    () async {
      final root = Directory('/tmp/opencode/fcl_launch_smoke');
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      final paths = AppPaths(dataRoot: root.path);
      await paths.ensureBaseDirectories();
      final db = AppDatabase.inMemory();
      final now = DateTime.now().toUtc();
      await db.buildsDao.save(
        Build(
          id: 'smoke',
          kind: BuildKind.appimage,
          version: 'smoke',
          channel: BuildChannel.custom,
          platform: BuildPlatform.linux,
          arch: BuildArch.x86_64,
          localPath: binary,
          pythonVersion: '3.11',
          status: BuildStatus.installed,
          verified: false,
          installedAt: now,
          updatedAt: now,
        ),
      );

      final repository = ProfilesRepository(
        database: db,
        paths: paths,
        platform: BuildPlatform.linux,
      );
      final runner = ProcessRunner();
      final runtime = FreeCadRuntime(
        processRunner: runner,
        diagnostics: DiagnosticsService(
          paths: paths,
          platform: BuildPlatform.linux,
          processRunner: runner,
        ),
        platform: BuildPlatform.linux,
      );
      final controller = ProfilesController(
        database: db,
        repository: repository,
        paths: paths,
        platform: BuildPlatform.linux,
        runtime: runtime,
      );

      final created = await repository.create(name: 'Smoke', buildId: 'smoke');
      final profile = created.valueOrNull!;

      final result = await controller.launch(
        profileId: profile.id,
        userArguments: const ['--version'],
      );
      expect(result.isStarted, isTrue);
      expect(controller.isRunning(profile.id), isTrue);

      final exitCode = await result.launch!.exitCode.timeout(const Duration(minutes: 2));
      // ignore: avoid_print
      print('binary=$binary exit=$exitCode log=${result.launch!.logPath}');
      expect(exitCode, 0);
      expect(controller.isRunning(profile.id), isFalse);
      expect(controller.lastExitCodes.value[profile.id], 0);
      expect(File(result.launch!.logPath).readAsStringSync(), contains(binary));
      expect((await repository.getById(profile.id))!.lastUsedAt, isNotNull);

      final planResult = await controller.planFor(profile.id);
      final command = LaunchCommand.fromPlan(
        planResult.valueOrNull!,
        inheritedEnvironment: runtime.inheritedEnvironment,
      );
      final shellCommand = command.toShellCommand(platform: BuildPlatform.linux);
      // ignore: avoid_print
      print('copied-command: $shellCommand');
      final shellRun = await Process.run(
        '/bin/sh',
        ['-c', shellCommand],
      ).timeout(const Duration(minutes: 2));
      // ignore: avoid_print
      print('copied-command exit=${shellRun.exitCode}');
      expect(shellRun.exitCode, 0);

      controller.dispose();
      await db.close();
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    },
    skip: Platform.environment['FCL_REAL_LAUNCH'] != '1'
        ? 'Manual test: set FCL_REAL_LAUNCH=1 to launch a real AppImage'
        : null,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
