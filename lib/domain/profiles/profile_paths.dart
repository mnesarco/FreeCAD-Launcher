import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/builds/build_types.dart';

class ProfilePaths {
  ProfilePaths(this.root, {p.Context? context}) : _p = context ?? p.context;

  final String root;
  final p.Context _p;

  String get home => _p.join(root, 'home');

  String get temp => _p.join(root, 'temp');

  String get xdgConfig => _p.join(root, 'xdg', 'config');

  String get xdgData => _p.join(root, 'xdg', 'data');

  String get xdgCache => _p.join(root, 'xdg', 'cache');

  String get appDataRoaming => _p.join(root, 'AppData', 'Roaming');

  String get appDataLocal => _p.join(root, 'AppData', 'Local');

  String get mod => _p.join(root, 'Mod');

  String get macros => _p.join(root, 'Macros');

  String get additionalPythonPackages => _p.join(root, 'AdditionalPythonPackages');

  String get backups => _p.join(root, 'backups');

  String get userCfg => _p.join(root, 'user.cfg');

  String get systemCfg => _p.join(root, 'system.cfg');

  List<String> directoriesFor(BuildPlatform platform) {
    final common = [root, temp, mod, macros, additionalPythonPackages, backups];
    return switch (platform) {
      BuildPlatform.linux => [...common, home, xdgConfig, xdgData, xdgCache],
      BuildPlatform.windows => [...common, appDataRoaming, appDataLocal],
      BuildPlatform.macos => [...common, home],
    };
  }
}
