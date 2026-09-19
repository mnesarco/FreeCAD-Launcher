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
import 'package:path/path.dart' as p;

void main() {
  final binary = Platform.environment['FCL_LAUNCH_BINARY'] ??
      '/home/mnesarco/devel/toolkits/freecad/'
          'FreeCAD_1.0.2-conda-Linux-x86_64-py311.AppImage';

  String markerScript(String marker) {
    return '''
import os
import pathlib
import sys

root = pathlib.Path(os.environ['FREECAD_USER_HOME'])
(root / 'marker.txt').write_text('$marker')
(root / 'Mod' / 'marker.txt').write_text('$marker')
pathlib.Path(os.environ['HOME']).joinpath('home_marker.txt').write_text('$marker')
pathlib.Path(os.environ['TMPDIR']).joinpath('tmp_marker.txt').write_text('$marker')
sys.exit(0)
''';
  }

  test(
    'two profiles on one build keep config, Mod, home and temp isolated',
    () async {
      final root = Directory('/tmp/opencode/fcl_isolation_e2e');
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      final paths = AppPaths(dataRoot: root.path);
      await paths.ensureBaseDirectories();
      final db = AppDatabase.inMemory();
      final now = DateTime.now().toUtc();
      await db.buildsDao.save(
        Build(
          id: 'shared',
          kind: BuildKind.appimage,
          version: 'isolation',
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

      final runner = ProcessRunner();
      final repository = ProfilesRepository(
        database: db,
        paths: paths,
        platform: BuildPlatform.linux,
      );
      final controller = ProfilesController(
        database: db,
        repository: repository,
        paths: paths,
        platform: BuildPlatform.linux,
        runtime: FreeCadRuntime(
          processRunner: runner,
          diagnostics: DiagnosticsService(
            paths: paths,
            platform: BuildPlatform.linux,
            processRunner: runner,
          ),
          platform: BuildPlatform.linux,
        ),
      );

      final scriptDirectory = Directory(p.join(root.path, 'scripts'))..createSync();
      final profileA = (await repository.create(name: 'Alpha', buildId: 'shared')).valueOrNull!;
      final profileB = (await repository.create(name: 'Beta', buildId: 'shared')).valueOrNull!;
      final scriptA = File(p.join(scriptDirectory.path, 'marker_a.py'))
        ..writeAsStringSync(markerScript('A'));
      final scriptB = File(p.join(scriptDirectory.path, 'marker_b.py'))
        ..writeAsStringSync(markerScript('B'));

      for (final launch in [
        (profile: profileA, script: scriptA),
        (profile: profileB, script: scriptB),
      ]) {
        final result = await controller.launch(
          profileId: launch.profile.id,
          userArguments: ['--console', launch.script.path],
        );
        expect(result.isStarted, isTrue, reason: 'launch ${launch.profile.name}');
        final code = await result.launch!.exitCode.timeout(const Duration(minutes: 2));
        expect(code, 0, reason: 'exit ${launch.profile.name}');
      }

      final pathsA = paths.profilePaths(profileA.id);
      final pathsB = paths.profilePaths(profileB.id);

      expect(File(p.join(pathsA.root, 'marker.txt')).readAsStringSync(), 'A');
      expect(File(p.join(pathsB.root, 'marker.txt')).readAsStringSync(), 'B');
      expect(File(p.join(pathsA.mod, 'marker.txt')).readAsStringSync(), 'A');
      expect(File(p.join(pathsB.mod, 'marker.txt')).readAsStringSync(), 'B');
      expect(File(p.join(pathsA.home, 'home_marker.txt')).readAsStringSync(), 'A');
      expect(File(p.join(pathsB.home, 'home_marker.txt')).readAsStringSync(), 'B');
      expect(File(p.join(pathsA.temp, 'tmp_marker.txt')).readAsStringSync(), 'A');
      expect(File(p.join(pathsB.temp, 'tmp_marker.txt')).readAsStringSync(), 'B');
      expect(File(p.join(pathsA.mod, 'marker.txt')).existsSync(), isTrue);
      expect(File(p.join(pathsA.root, 'home_marker.txt')).existsSync(), isFalse);

      // ignore: avoid_print
      print(
        'isolation ok: A=${pathsA.root} B=${pathsB.root} '
        'launchA=${controller.launchLogs.value[profileA.id]}',
      );

      final removed = await controller.delete(profileA.id);
      expect(removed.isOk, isTrue);
      expect(Directory(pathsA.root).existsSync(), isFalse);
      expect(File(p.join(pathsB.root, 'marker.txt')).readAsStringSync(), 'B');

      controller.dispose();
      await db.close();
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    },
    skip: Platform.environment['FCL_REAL_ISOLATION'] != '1'
        ? 'Manual test: set FCL_REAL_ISOLATION=1 and run with a real FreeCAD binary'
        : null,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
