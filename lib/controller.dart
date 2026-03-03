import 'package:signals_flutter/signals_flutter.dart';
import 'database.dart';

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
}

class ProfileController {
  final Database db;

  final searchFilter = signal('');

  late final items = streamSignal(() {
    return db.watchProfiles(searchFilter.value);
  });

  ProfileController(this.db);

  void add(String name, String kind, String command, String args, String cwd) {
    db.addProfile(ProfilesCompanion.insert(name: name, args: args, cwd: cwd));
  }
}

class MainController {
  final Database db;
  final AppController apps;
  final ProfileController profiles;

  MainController(this.db) : apps = AppController(db), profiles = ProfileController(db);
}
