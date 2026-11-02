// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';

const Set<String> sanitizedEnvironmentKeys = {
  'PYTHONPATH',
  'PYTHONHOME',
  'VIRTUAL_ENV',
  'PYTHONUSERBASE',
};

const Set<String> appImageEnvironmentKeys = {
  'APPIMAGE',
  'APPDIR',
  'OWD',
  'ARGV0',
  'LD_LIBRARY_PATH',
  'LD_PRELOAD',
  'APPIMAGE_EXTRACT_AND_RUN',
};

/// Removes every sanitized Python variable from [environment] in place.
///
/// Matching is case-insensitive because Windows environment variable names are
/// case-insensitive (a `PythonPath` inherited from the system must not leak
/// into pip or the package probe).
void removeSanitizedEnvironmentKeys(Map<String, String> environment) {
  final keys = [
    for (final key in environment.keys)
      if (sanitizedEnvironmentKeys.contains(key.toUpperCase())) key,
  ];
  for (final key in keys) {
    environment.remove(key);
  }
}

/// Removes the launcher AppImage runtime from [environment] in place.
///
/// The launcher AppImage bundles system libraries older than the ones its
/// children expect; leaking `LD_LIBRARY_PATH` shadows theirs (system `gio`
/// hits undefined symbols, FreeCAD's `pyexpat` loads the wrong `libexpat`).
/// Children run their own AppImage, so none of these variables apply (D-098).
void removeAppImageEnvironmentKeys(Map<String, String> environment) {
  final appDir = environment['APPDIR'];
  final isAppImage = (appDir != null && appDir.isNotEmpty) || environment.containsKey('APPIMAGE');
  if (!isAppImage) {
    return;
  }
  final keys = [
    for (final key in environment.keys)
      if (appImageEnvironmentKeys.contains(key.toUpperCase())) key,
  ];
  for (final key in keys) {
    environment.remove(key);
  }
  if (appDir == null || appDir.isEmpty) {
    return;
  }
  final dataDirs = (environment['XDG_DATA_DIRS'] ?? '')
      .split(':')
      .where((entry) => entry.isNotEmpty && !entry.startsWith(appDir))
      .toList(growable: false);
  environment['XDG_DATA_DIRS'] = dataDirs.isEmpty
      ? '/usr/local/share:/usr/share'
      : dataDirs.join(':');
}

abstract final class LaunchEnvironment {
  static Map<String, String> build({
    required BuildPlatform platform,
    required ProfilePaths paths,
    required Map<String, String> inherited,
    bool appImageExtractAndRun = false,
  }) {
    final env = <String, String>{};
    for (final entry in inherited.entries) {
      if (!sanitizedEnvironmentKeys.contains(entry.key.toUpperCase())) {
        env[entry.key] = entry.value;
      }
    }
    removeAppImageEnvironmentKeys(env);

    env['FREECAD_USER_HOME'] = paths.root;
    env['FREECAD_USER_TEMP'] = paths.temp;

    if (platform == BuildPlatform.linux && appImageExtractAndRun) {
      env['APPIMAGE_EXTRACT_AND_RUN'] = '1';
    }

    switch (platform) {
      case BuildPlatform.linux:
        env['XDG_CONFIG_HOME'] = paths.xdgConfig;
        env['XDG_DATA_HOME'] = paths.xdgData;
        env['XDG_CACHE_HOME'] = paths.xdgCache;
        env['TMPDIR'] = paths.temp;
      case BuildPlatform.windows:
        env['APPDATA'] = paths.appDataRoaming;
        env['LOCALAPPDATA'] = paths.appDataLocal;
        env['TEMP'] = paths.temp;
        env['TMP'] = paths.temp;
      case BuildPlatform.macos:
        env['TMPDIR'] = paths.temp;
    }

    return env;
  }
}
