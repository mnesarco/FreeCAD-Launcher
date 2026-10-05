// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;
  late AppPaths paths;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_paths_test');
    paths = AppPaths(dataRoot: p.join(tempDirectory.path, 'org.freecad.ext.launcher'));
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('exposes the app data layout', () {
    expect(paths.databaseFile, p.join(paths.dataRoot, 'config.db'));
    expect(paths.buildDir('build-1'), p.join(paths.buildsDir, 'build-1'));
    expect(paths.profilePaths('profile-1').root, p.join(paths.profilesDir, 'profile-1'));
    expect(paths.addonsCacheDir, p.join(paths.cacheDir, 'addons'));
  });

  test('build directories use portable segments', () {
    expect(
      paths.buildDir('stable:1.1.3:windows:x86_64'),
      p.join(paths.buildsDir, 'stable_1.1.3_windows_x86_64'),
    );
  });

  test('build directories are portable with a Windows path context', () {
    final windows = AppPaths(
      dataRoot: r'C:\data',
      context: p.Context(style: p.Style.windows),
    );
    expect(
      windows.buildDir('stable:1.1.3:windows:x86_64'),
      r'C:\data\builds\stable_1.1.3_windows_x86_64',
    );
  });

  test('existingBuildDir resolves legacy unsanitized directories', () {
    if (Platform.isWindows) {
      return;
    }
    const id = 'stable:1.1.3:linux:x86_64';
    final legacy = Directory(p.join(paths.buildsDir, id))..createSync(recursive: true);
    expect(paths.existingBuildDir(id), legacy.path);

    final sanitized = Directory(paths.buildDir(id))..createSync(recursive: true);
    expect(paths.existingBuildDir(id), sanitized.path);
    expect(paths.buildDirCandidates(id), [sanitized.path, legacy.path]);
  });

  test('ensureBaseDirectories creates every base directory', () async {
    await paths.ensureBaseDirectories();

    for (final path in paths.baseDirectories) {
      expect(Directory(path).existsSync(), isTrue, reason: path);
    }
  });

  test('ensureProfileDirectories creates the platform layout', () async {
    await paths.ensureProfileDirectories('profile-1', BuildPlatform.linux);

    final profile = paths.profilePaths('profile-1');
    for (final path in profile.directoriesFor(BuildPlatform.linux)) {
      expect(Directory(path).existsSync(), isTrue, reason: path);
    }
    expect(File(profile.userCfg).existsSync(), isFalse);
  });

  group('Windows data root', () {
    late Directory appData;
    late String pinnedRoot;
    late String legacyRoot;

    setUp(() {
      appData = Directory(p.join(tempDirectory.path, 'AppData', 'Roaming'))
        ..createSync(recursive: true);
      pinnedRoot = p.join(appData.path, 'org.freecad.ext.launcher');
      legacyRoot = p.join(appData.path, 'FreeCAD Launcher contributors', 'FreeCAD Launcher');
    });

    Future<AppPaths> resolveWindows({Map<String, String>? environment}) => AppPaths.resolve(
      windows: true,
      environment: environment ?? {'APPDATA': appData.path},
      supportDirectory: () async => appData,
    );

    test('fresh installs use the pinned application-id root', () async {
      final resolved = await resolveWindows();
      expect(resolved.dataRoot, pinnedRoot);
      expect(resolved.legacyRoot, legacyRoot);
    });

    test('an existing legacy install keeps using its root', () async {
      File(p.join(legacyRoot, 'config.db')).createSync(recursive: true);

      final resolved = await resolveWindows();

      expect(resolved.dataRoot, legacyRoot);
      expect(resolved.legacyRoot, isNull);
      expect(Directory(legacyRoot).existsSync(), isTrue);
    });

    test('a pinned database wins over a legacy database', () async {
      File(p.join(legacyRoot, 'config.db')).createSync(recursive: true);
      File(p.join(pinnedRoot, 'config.db')).createSync(recursive: true);

      final resolved = await resolveWindows();

      expect(resolved.dataRoot, pinnedRoot);
      expect(resolved.legacyRoot, legacyRoot);
    });

    test('a legacy directory without a database is ignored', () async {
      Directory(legacyRoot).createSync(recursive: true);

      final resolved = await resolveWindows();

      expect(resolved.dataRoot, pinnedRoot);
    });

    test('a missing APPDATA falls back to the support directory', () async {
      final support = Directory(p.join(tempDirectory.path, 'support'))..createSync();
      final resolved = await AppPaths.resolve(
        windows: true,
        environment: const {},
        supportDirectory: () async => support,
      );
      expect(resolved.dataRoot, support.path);
      expect(resolved.legacyRoot, isNull);
    });
  });

  test('non-Windows resolves the support directory', () async {
    final support = Directory(p.join(tempDirectory.path, 'support'))..createSync();
    final resolved = await AppPaths.resolve(
      windows: false,
      supportDirectory: () async => support,
    );
    expect(resolved.dataRoot, support.path);
    expect(resolved.legacyRoot, isNull);
  });
}
