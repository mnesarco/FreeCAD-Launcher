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
}
