// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';
import 'package:freecad_launcher/platform/diagnostics.dart';
import 'package:freecad_launcher/platform/launch.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_process.dart';

class FakeQuarantineGuard implements QuarantineGuard {
  bool quarantined = false;
  final List<String> checked = [];
  final List<String> cleared = [];

  @override
  Future<bool> isQuarantined(String appPath) async {
    checked.add(appPath);
    return quarantined;
  }

  @override
  Future<void> clear(String appPath) async {
    cleared.add(appPath);
  }
}

void main() {
  late Directory tempDirectory;
  late FakeProcessLauncher launcher;
  late ProcessRunner runner;
  late FakeQuarantineGuard quarantine;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_launch_test');
    launcher = FakeProcessLauncher();
    runner = ProcessRunner(launcher: launcher);
    quarantine = FakeQuarantineGuard();
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  DiagnosticsService diagnostics({
    required BuildPlatform platform,
    required bool fuseAvailable,
  }) {
    if (fuseAvailable) {
      File(p.join(tempDirectory.path, 'fusermount')).createSync();
    }
    return DiagnosticsService(
      paths: AppPaths(dataRoot: tempDirectory.path),
      platform: platform,
      processRunner: runner,
      environment: {'PATH': fuseAvailable ? tempDirectory.path : ''},
      fuseDeviceExists: () => fuseAvailable,
    );
  }

  FreeCadRuntime runtime(BuildPlatform platform, {required bool fuseAvailable}) {
    return FreeCadRuntime(
      processRunner: runner,
      diagnostics: diagnostics(platform: platform, fuseAvailable: fuseAvailable),
      platform: platform,
      quarantineGuard: quarantine,
      environment: const {'PATH': '/usr/bin'},
    );
  }

  final posixPaths = ProfilePaths('/data/profiles/p1');

  test('keeps FUSE for AppImages when it is available', () async {
    final plan = await runtime(BuildPlatform.linux, fuseAvailable: true).planFor(
      kind: BuildKind.appimage,
      executablePath: '/data/builds/b1/FreeCAD.AppImage',
      paths: posixPaths,
    );

    expect(plan.environment.containsKey('APPIMAGE_EXTRACT_AND_RUN'), isFalse);
  });

  test('sets APPIMAGE_EXTRACT_AND_RUN when FUSE is missing', () async {
    final plan = await runtime(BuildPlatform.linux, fuseAvailable: false).planFor(
      kind: BuildKind.appimage,
      executablePath: '/data/builds/b1/FreeCAD.AppImage',
      paths: posixPaths,
    );

    expect(plan.environment['APPIMAGE_EXTRACT_AND_RUN'], '1');
  });

  test('never sets the AppImage fallback for other kinds', () async {
    final plan = await runtime(BuildPlatform.linux, fuseAvailable: false).planFor(
      kind: BuildKind.archive,
      executablePath: '/data/builds/b1/FreeCAD',
      paths: posixPaths,
    );

    expect(plan.environment.containsKey('APPIMAGE_EXTRACT_AND_RUN'), isFalse);
  });

  test('starts the plan through the process runner', () async {
    final plan = await runtime(BuildPlatform.linux, fuseAvailable: true).planFor(
      kind: BuildKind.custom,
      executablePath: '/data/builds/b1/FreeCAD',
      paths: posixPaths,
      userArguments: const ['--version'],
    );

    final handle = await runtime(BuildPlatform.linux, fuseAvailable: true).start(plan);

    expect(handle, isNotNull);
    expect(launcher.specs.single.executable, '/data/builds/b1/FreeCAD');
    expect(launcher.specs.single.arguments, [
      '--console',
      '--version',
      '-u',
      posixPaths.userCfg,
      '-s',
      posixPaths.systemCfg,
    ]);
  });

  test('finds the app bundle for quarantine checks', () {
    expect(
      macAppBundlePath('/data/builds/b1/FreeCAD.app/Contents/MacOS/FreeCAD'),
      '/data/builds/b1/FreeCAD.app',
    );
    expect(macAppBundlePath('/usr/local/bin/freecad'), isNull);
  });

  test('reports quarantine only on macOS with a quarantined bundle', () async {
    quarantine.quarantined = true;
    final macos = runtime(BuildPlatform.macos, fuseAvailable: false);

    final appPath = await macos.quarantineAppPath(
      '/data/builds/b1/FreeCAD.app/Contents/MacOS/FreeCAD',
    );

    expect(appPath, '/data/builds/b1/FreeCAD.app');
    expect(quarantine.checked, ['/data/builds/b1/FreeCAD.app']);

    expect(await macos.quarantineAppPath('/data/builds/b1/FreeCADCmd'), '/data/builds/b1/FreeCADCmd');

    final linux = runtime(BuildPlatform.linux, fuseAvailable: true);
    expect(await linux.quarantineAppPath('/data/builds/b1/FreeCAD.AppImage'), isNull);
    expect(quarantine.checked, hasLength(2));
  });

  test('clears quarantine on request', () async {
    await runtime(BuildPlatform.macos, fuseAvailable: false).clearQuarantine(
      '/data/builds/b1/FreeCAD.app',
    );

    expect(quarantine.cleared, ['/data/builds/b1/FreeCAD.app']);
  });
}
