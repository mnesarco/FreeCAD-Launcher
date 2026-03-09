import 'package:drift/drift.dart';
import 'package:freecad_launcher/service/database.dart';

class AddonDownloadController {
  final Database db;

  AddonDownloadController(this.db);

  void add(
    String name,
    String repoUrl,
    String zipUrl,
    String branch,
    String version,
    DateTime updatedAt,
    String fileName,
    DateTime downloadedAt,
  ) {
    db.addAddonDownload(
      DownloadedAddonsCompanion.insert(
        name: name,
        repoUrl: Value.absentIfNull(repoUrl),
        zipUrl: Value.absentIfNull(zipUrl),
        branch: Value.absentIfNull(branch),
        version: Value.absentIfNull(version),
        updatedAt: updatedAt,
        downloadedAt: downloadedAt,
        downloadedName: fileName,
      ),
    );
  }
}
