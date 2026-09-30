// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';

const Set<String> sanitizedEnvironmentKeys = {
  'PYTHONPATH',
  'PYTHONHOME',
  'VIRTUAL_ENV',
  'PYTHONUSERBASE',
};

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

    env['FREECAD_USER_HOME'] = paths.root;
    env['FREECAD_USER_TEMP'] = paths.temp;

    if (platform == BuildPlatform.linux && appImageExtractAndRun) {
      env['APPIMAGE_EXTRACT_AND_RUN'] = '1';
    }

    switch (platform) {
      case BuildPlatform.linux:
        env['HOME'] = paths.home;
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
        env['HOME'] = paths.home;
        env['TMPDIR'] = paths.temp;
    }

    return env;
  }
}
