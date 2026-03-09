import 'package:flutter/widgets.dart';
import 'package:freecad_launcher/controller/addons.dart';
import 'package:freecad_launcher/controller/apps.dart';
import 'package:freecad_launcher/controller/profiles.dart';
import 'package:freecad_launcher/model/github_stats.dart';
import 'package:freecad_launcher/service/download.dart';
import 'package:freecad_launcher/model/addons.dart';
import 'package:freecad_launcher/service/database.dart';

export 'package:freecad_launcher/controller/addons.dart' show AddonDownloadController;
export 'package:freecad_launcher/controller/apps.dart' show AppController;
export 'package:freecad_launcher/controller/profiles.dart' show ProfileController;

class MainController {
  final Database db;
  final DownloadManager downloadManager = DownloadManager();

  late final AppController apps = AppController(db);
  late final ProfileController profiles = ProfileController(db);
  late final AddonDownloadController downloadedAddons = AddonDownloadController(db);
  late final Future<AddonCatalog> addonsCatalog = AddonCatalog.download(downloadManager);
  late final Future<AddonStatsCatalog> addonsStats = AddonStatsCatalog.download(downloadManager);

  MainController(this.db);

  static MainController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MainControllerScope>();
    assert(scope != null, 'No MainControllerScope found in context');
    return scope!.controller;
  }

  void dispose() {
    db.close();
    downloadManager.dispose();
  }
}

class MainControllerScope extends InheritedWidget {
  final MainController controller;

  const MainControllerScope({super.key, required this.controller, required super.child});

  @override
  bool updateShouldNotify(MainControllerScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
