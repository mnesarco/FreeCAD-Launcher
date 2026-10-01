// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/launch_environment.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';
import 'package:path/path.dart' as p;

void main() {
  final posix = p.Context(style: p.Style.posix);
  final windows = p.Context(style: p.Style.windows);
  final posixPaths = ProfilePaths('/data/profiles/p1', context: posix);
  final windowsPaths = ProfilePaths(r'C:\data\profiles\p1', context: windows);

  Map<String, String> inherited() => {
    'PATH': '/usr/bin',
    'LANG': 'en_US.UTF-8',
    'HOME': '/real/home',
    'PYTHONPATH': '/system/python',
    'PYTHONHOME': '/system/python',
    'VIRTUAL_ENV': '/venv',
    'PYTHONUSERBASE': '/user',
  };

  test('linux isolates user dirs and strips python variables', () {
    final env = LaunchEnvironment.build(
      platform: BuildPlatform.linux,
      paths: posixPaths,
      inherited: inherited(),
    );

    expect(env['FREECAD_USER_HOME'], '/data/profiles/p1');
    expect(env['FREECAD_USER_TEMP'], '/data/profiles/p1/temp');
    expect(env['HOME'], '/real/home');
    expect(env['XDG_CONFIG_HOME'], '/data/profiles/p1/xdg/config');
    expect(env['XDG_DATA_HOME'], '/data/profiles/p1/xdg/data');
    expect(env['XDG_CACHE_HOME'], '/data/profiles/p1/xdg/cache');
    expect(env['TMPDIR'], '/data/profiles/p1/temp');
    expect(env.containsKey('PYTHONPATH'), isFalse);
    expect(env.containsKey('PYTHONHOME'), isFalse);
    expect(env.containsKey('VIRTUAL_ENV'), isFalse);
    expect(env.containsKey('PYTHONUSERBASE'), isFalse);
    expect(env['PATH'], '/usr/bin');
    expect(env['LANG'], 'en_US.UTF-8');
    expect(env.containsKey('APPDATA'), isFalse);
  });

  test('windows isolates app data and temp without HOME or XDG', () {
    final env = LaunchEnvironment.build(
      platform: BuildPlatform.windows,
      paths: windowsPaths,
      inherited: inherited(),
    );

    expect(env['FREECAD_USER_HOME'], r'C:\data\profiles\p1');
    expect(env['FREECAD_USER_TEMP'], r'C:\data\profiles\p1\temp');
    expect(env['APPDATA'], r'C:\data\profiles\p1\AppData\Roaming');
    expect(env['LOCALAPPDATA'], r'C:\data\profiles\p1\AppData\Local');
    expect(env['TEMP'], r'C:\data\profiles\p1\temp');
    expect(env['TMP'], r'C:\data\profiles\p1\temp');
    expect(env['HOME'], '/real/home');
    expect(env.containsKey('XDG_CONFIG_HOME'), isFalse);
    expect(env.containsKey('TMPDIR'), isFalse);
  });

  test('macos leaves HOME inherited and isolates temp', () {
    final env = LaunchEnvironment.build(
      platform: BuildPlatform.macos,
      paths: posixPaths,
      inherited: inherited(),
    );

    expect(env['HOME'], '/real/home');
    expect(env['TMPDIR'], '/data/profiles/p1/temp');
    expect(env.containsKey('XDG_CONFIG_HOME'), isFalse);
    expect(env.containsKey('APPDATA'), isFalse);
  });

  test('passes through HOME even when it points at a profile directory', () {
    final env = LaunchEnvironment.build(
      platform: BuildPlatform.linux,
      paths: posixPaths,
      inherited: const {'HOME': '/data/profiles/p1'},
    );

    expect(env['HOME'], '/data/profiles/p1');
  });

  test('overrides inherited FREECAD values', () {
    final env = LaunchEnvironment.build(
      platform: BuildPlatform.linux,
      paths: posixPaths,
      inherited: {'FREECAD_USER_HOME': '/wrong', 'FREECAD_USER_TEMP': '/wrong'},
    );

    expect(env['FREECAD_USER_HOME'], '/data/profiles/p1');
    expect(env['FREECAD_USER_TEMP'], '/data/profiles/p1/temp');
  });

  test('strips sanitized keys case-insensitively', () {
    final env = LaunchEnvironment.build(
      platform: BuildPlatform.windows,
      paths: windowsPaths,
      inherited: {'PythonPath': r'C:\system', 'Virtual_Env': r'C:\venv'},
    );

    expect(env.containsKey('PythonPath'), isFalse);
    expect(env.containsKey('Virtual_Env'), isFalse);
  });

  test('enables AppImage extract-and-run only on linux when requested', () {
    final linux = LaunchEnvironment.build(
      platform: BuildPlatform.linux,
      paths: posixPaths,
      inherited: const {},
      appImageExtractAndRun: true,
    );
    expect(linux['APPIMAGE_EXTRACT_AND_RUN'], '1');

    final macos = LaunchEnvironment.build(
      platform: BuildPlatform.macos,
      paths: posixPaths,
      inherited: const {},
      appImageExtractAndRun: true,
    );
    expect(macos.containsKey('APPIMAGE_EXTRACT_AND_RUN'), isFalse);

    final linuxWithout = LaunchEnvironment.build(
      platform: BuildPlatform.linux,
      paths: posixPaths,
      inherited: const {},
    );
    expect(linuxWithout.containsKey('APPIMAGE_EXTRACT_AND_RUN'), isFalse);
  });
}
