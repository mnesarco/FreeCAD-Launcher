import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:freecad_launcher/data/catalog/github_releases_client.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/build_installer.dart';
import 'package:freecad_launcher/platform/diagnostics.dart';
import 'package:freecad_launcher/platform/dmg_extractor.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/host.dart';
import 'package:freecad_launcher/platform/launch.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_probe.dart';
import 'package:freecad_launcher/platform/seven_zip_extractor.dart';
import 'package:freecad_launcher/state/builds_controller.dart';
import 'package:freecad_launcher/state/profiles_controller.dart';

class AppServices {
  AppServices({
    required this.paths,
    required this.database,
    ProcessRunner? processRunner,
    http.Client? httpClient,
    BuildsController? buildsController,
  }) : processRunner = processRunner ?? ProcessRunner(),
       _httpClient = httpClient,
       _buildsControllerOverride = buildsController;

  final AppPaths paths;
  final AppDatabase database;
  final ProcessRunner processRunner;

  final http.Client? _httpClient;
  final BuildsController? _buildsControllerOverride;

  late final http.Client _client = _httpClient ?? http.Client();

  late final DiagnosticsService diagnostics = DiagnosticsService(
    paths: paths,
    platform: hostPlatform,
    processRunner: processRunner,
  );

  late final GitHubReleasesClient releasesClient = GitHubReleasesClient(client: _client);

  late final ReleasesCatalog releasesCatalog = ReleasesCatalog(
    client: releasesClient,
    dao: database.catalogCacheDao,
    cacheDirectory: paths.githubCacheDir,
  );

  late final Downloader downloader = Downloader(
    source: HttpDownloadSource(_client),
    cacheDirectory: paths.downloadsCacheDir,
  );

  late final PythonProbe pythonProbe = ProcessPythonProbe(processRunner: processRunner);

  late final BuildInstaller buildInstaller = BuildInstaller(
    paths: paths,
    processRunner: processRunner,
    sevenZipExtractor: hostPlatform == BuildPlatform.windows
        ? SevenZipExtractor.bundled(processRunner)
        : null,
    dmgExtractor: hostPlatform == BuildPlatform.macos
        ? ProcessDmgExtractor(processRunner: processRunner)
        : null,
    pythonProbe: pythonProbe,
  );

  late final ProfilesRepository profilesRepository = ProfilesRepository(
    database: database,
    paths: paths,
    platform: hostPlatform,
  );

  late final FreeCadRuntime launchRuntime = FreeCadRuntime(
    processRunner: processRunner,
    diagnostics: diagnostics,
    platform: hostPlatform,
    quarantineGuard: XattrQuarantineGuard(processRunner),
  );

  late final ProfilesController profiles = ProfilesController(
    database: database,
    repository: profilesRepository,
    paths: paths,
    platform: hostPlatform,
    runtime: launchRuntime,
  );

  late final BuildsController builds =
      _buildsControllerOverride ??
      BuildsController(
        database: database,
        catalog: releasesCatalog,
        downloader: downloader,
        installer: buildInstaller,
        paths: paths,
        platform: hostPlatform,
        arch: hostArch,
        pythonProbe: pythonProbe,
      );

  static Future<AppServices> bootstrap() async {
    final paths = await AppPaths.resolve();
    await paths.ensureBaseDirectories();
    final database = AppDatabase(NativeDatabase(File(paths.databaseFile)));
    return AppServices(paths: paths, database: database);
  }

  Future<void> close() async {
    builds.dispose();
    profiles.dispose();
    await database.close();
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
