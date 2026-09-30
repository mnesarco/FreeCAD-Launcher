// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';
import 'package:path/path.dart' as p;

void main() {
  final posix = p.Context(style: p.Style.posix);
  final windows = p.Context(style: p.Style.windows);

  group('ProfilePaths', () {
    test('builds the layout with posix separators', () {
      final paths = ProfilePaths('/data/profiles/p1', context: posix);

      expect(paths.root, '/data/profiles/p1');
      expect(paths.temp, '/data/profiles/p1/temp');
      expect(paths.mod, '/data/profiles/p1/Mod');
      expect(paths.additionalPythonPackages, '/data/profiles/p1/AdditionalPythonPackages');
      expect(paths.xdgConfig, '/data/profiles/p1/xdg/config');
      expect(paths.userCfg, '/data/profiles/p1/user.cfg');
      expect(paths.systemCfg, '/data/profiles/p1/system.cfg');
    });

    test('builds the layout with windows separators', () {
      final paths = ProfilePaths(r'C:\data\profiles\p1', context: windows);

      expect(paths.temp, r'C:\data\profiles\p1\temp');
      expect(paths.appDataRoaming, r'C:\data\profiles\p1\AppData\Roaming');
      expect(paths.appDataLocal, r'C:\data\profiles\p1\AppData\Local');
      expect(paths.mod, r'C:\data\profiles\p1\Mod');
    });

    test('directoriesFor returns exactly the platform layout', () {
      final paths = ProfilePaths('/p', context: posix);

      final linux = paths.directoriesFor(BuildPlatform.linux);
      expect(
        linux,
        containsAll([
          '/p',
          '/p/temp',
          '/p/Mod',
          '/p/AdditionalPythonPackages',
          '/p/backups',
          '/p/xdg/config',
          '/p/xdg/data',
          '/p/xdg/cache',
        ]),
      );
      expect(linux, isNot(contains('/p/home')));
      expect(linux, isNot(contains('/p/AppData/Roaming')));

      final windowsDirs = paths.directoriesFor(BuildPlatform.windows);
      expect(
        windowsDirs,
        containsAll(['/p', '/p/temp', '/p/Mod', '/p/AppData/Roaming', '/p/AppData/Local']),
      );
      expect(windowsDirs, isNot(contains('/p/xdg/config')));

      final macos = paths.directoriesFor(BuildPlatform.macos);
      expect(macos, containsAll(['/p', '/p/temp', '/p/Mod']));
      expect(macos, isNot(contains('/p/home')));
      expect(macos, isNot(contains('/p/AppData/Roaming')));
      expect(macos, isNot(contains('/p/xdg/config')));
    });
  });
}
