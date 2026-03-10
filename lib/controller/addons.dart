import 'package:drift/drift.dart';
import 'package:freecad_launcher/model/addons.dart';
import 'package:freecad_launcher/service/database.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AddonUpdate {
  final Addon addon;
  final AddonEntry entry;
  final DownloadedAddon downloaded;
  AddonUpdate({required this.addon, required this.entry, required this.downloaded});
}

class AddonUpdateCheckController {
  final Database db;
  final Future<AddonCatalog> catalog;
  final FlutterSignal<Future<Map<String, AddonUpdate>>> updated;
  static final FlutterSignal<bool> checkingUpdates = signal(false);

  FlutterSignal<bool> get isChecking => checkingUpdates;

  AddonUpdateCheckController({required this.db, required this.catalog})
    : updated = signal(_findUpdates(catalog, db));

  Future<void> check() async {
    if (checkingUpdates.value) {
      return;
    }
    await _findUpdates(catalog, db);
  }

  static Future<Map<String, AddonUpdate>> _findUpdates(
    Future<AddonCatalog> catalogFuture,
    Database db,
  ) async {
    try {
      AddonCatalog catalog = await catalogFuture;
      checkingUpdates.value = true;
      final Map<String, AddonUpdate> updated = {};
      for (final addon in catalog.addons) {
        for (final entry in addon.entries) {
          final old = await db.findLatestDownloadedAddon(addon.id, entry.gitRef);
          if (old != null &&
              entry.lastUpdateTime != null &&
              entry.lastUpdateTime!.isAfter(old.updatedAt)) {
            updated[entry.sha1] = AddonUpdate(addon: addon, entry: entry, downloaded: old);
          }
        }
      }
      return updated;
    } finally {
      checkingUpdates.value = false;
    }
  }
}

class AddonDownloadController {
  final Database db;
  late final findBranch = db.findLatestDownloadedAddon;

  AddonDownloadController(this.db);

  Future<DownloadedAddon> add(
    String name,
    String repoUrl,
    String zipUrl,
    String branch,
    String version,
    DateTime updatedAt,
    String fileName,
    DateTime downloadedAt,
  ) async {
    final value = DownloadedAddon(
      name: name,
      updatedAt: updatedAt,
      downloadedAt: downloadedAt,
      downloadedName: fileName,
      repoUrl: repoUrl,
      zipUrl: zipUrl,
      branch: branch,
      version: version,
    );
    await db.addAddonDownload(value.toCompanion(true));
    return value;
  }
}
