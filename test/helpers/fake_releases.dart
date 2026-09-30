// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/platform/build_installer.dart';

class FakeReleasesCatalog implements ReleasesCatalog {
  FakeReleasesCatalog({this.error});

  Object? error;

  @override
  Duration get ttl => const Duration(hours: 6);

  @override
  int get maxPages => 5;

  @override
  Future<ReleasesCatalogResult> load({bool forceRefresh = false}) async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return const ReleasesCatalogResult(releases: [], freshness: CatalogFreshness.fresh);
  }
}

class FakeBuildInstaller implements BuildInstaller {
  @override
  Future<InstalledBuild> install(InstallRequest request) async {
    return const InstalledBuild(
      directory: '/data/builds/x',
      executablePath: '/data/builds/x/FreeCAD',
      sizeBytes: 100,
      pythonVersion: '3.11',
      pythonPath: '/data/builds/x/bin/python3.11',
    );
  }
}
