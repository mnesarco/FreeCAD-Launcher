import 'package:freecad_launcher/service/database.dart';
import 'package:signals_flutter/signals_flutter.dart';

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
