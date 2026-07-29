import 'package:freecad_launcher/service/applications.dart';
import 'package:freecad_launcher/service/database.dart';
import 'package:freecad_launcher/util/path.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AppController {
  final Database db;

  final searchFilter = signal('');

  late final items = streamSignal(() {
    return db.watchApps(searchFilter.value);
  });

  AppController(this.db);

  void add(String name, String kind, String command, String args, String cwd) {
    db.addApp(AppsCompanion.insert(name: name, kind: kind, command: command, args: args, cwd: cwd));
  }

  Future<void> importInstalledApps() async {
    // -- Flatpak
    {
      FlatpakService flatpak = FlatpakService();
      final result = await flatpak.find();
      switch (result) {
        case Success(:final data):
          final cwd = await Path.home();
          for (final app in data) {
            try {
              final target = FlatpakTarget.fromString(app);
              final name = 'Flatpak ${target.install} ${target.version}';
              if (await db.findAppByName(name) == null) {
                add(name, 'Flatpak', app, '', cwd.str);
              }
            } catch (ex) {
              // Already imported
            }
          }
        case _:
        // No flatpaks
      }
    }

    // -- Snap
    {
      SnapService snap = SnapService();
      final result = await snap.find();
      switch (result) {
        case Success(:final data):
          final cwd = await Path.home();
          for (final app in data) {
            switch (await snap.getVersion(app)) {
              case Success(:final data):
                try {
                  final name = 'Snap $data';
                  if (await db.findAppByName(name) == null) {
                    add('Snap $data', 'Snap', app, '', cwd.str);
                  }
                } catch (ex) {
                  // Already imported
                }
              case _:
              // Version not found
            }
          }
        case _:
        // No snaps
      }
    }
  }
}
