// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/github_releases_client.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/catalog/news_feed.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/data_root_repair.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/addons/addon_dependencies.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/build_installer.dart';
import 'package:freecad_launcher/platform/cache_service.dart';
import 'package:freecad_launcher/platform/cli_wrapper.dart';
import 'package:freecad_launcher/platform/debug_bundle.dart';
import 'package:freecad_launcher/platform/diagnostics.dart';
import 'package:freecad_launcher/platform/dmg_extractor.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/host.dart';
import 'package:freecad_launcher/platform/launch.dart';
import 'package:freecad_launcher/platform/macro_icon_cache.dart';
import 'package:freecad_launcher/platform/network_probe.dart';
import 'package:freecad_launcher/platform/config_snapshots.dart';
import 'package:freecad_launcher/platform/file_actions.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/pip_runner.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_env.dart';
import 'package:freecad_launcher/platform/python_package_probe.dart';
import 'package:freecad_launcher/platform/python_probe.dart';
import 'package:freecad_launcher/platform/seven_zip_extractor.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/builds_controller.dart';
import 'package:freecad_launcher/state/cache_controller.dart';
import 'package:freecad_launcher/state/debug_bundle_controller.dart';
import 'package:freecad_launcher/state/bundle_apply_controller.dart';
import 'package:freecad_launcher/state/bundles_controller.dart';
import 'package:freecad_launcher/state/jobs_controller.dart';
import 'package:freecad_launcher/state/macros_controller.dart';
import 'package:freecad_launcher/state/news_controller.dart';
import 'package:freecad_launcher/state/profile_manifest_controller.dart';
import 'package:freecad_launcher/state/profiles_controller.dart';
import 'package:freecad_launcher/state/python_controller.dart';
import 'package:freecad_launcher/state/settings_controller.dart';
import 'package:freecad_launcher/state/shell_controller.dart';
import 'package:freecad_launcher/state/updates_controller.dart';

class AppServices {
  AppServices({
    required this.paths,
    required this.database,
    this.startupWarning,
    ProcessRunner? processRunner,
    http.Client? httpClient,
    BuildsController? buildsController,
    AddonsController? addonsController,
    MacrosController? macrosController,
    ProfileManifestController? manifestsController,
    UpdatesController? updatesController,
    NewsController? newsController,
  }) : processRunner = processRunner ?? ProcessRunner(),
       _httpClient = httpClient,
       _buildsControllerOverride = buildsController,
       _addonsControllerOverride = addonsController,
       _macrosControllerOverride = macrosController,
       _manifestsControllerOverride = manifestsController,
       _updatesControllerOverride = updatesController,
       _newsControllerOverride = newsController;

  final AppPaths paths;
  final AppDatabase database;
  final ProcessRunner processRunner;

  /// Warning recorded during bootstrap and logged once the logger is set up.
  final String? startupWarning;

  final http.Client? _httpClient;
  final BuildsController? _buildsControllerOverride;
  final AddonsController? _addonsControllerOverride;
  final MacrosController? _macrosControllerOverride;
  final ProfileManifestController? _manifestsControllerOverride;
  final UpdatesController? _updatesControllerOverride;
  final NewsController? _newsControllerOverride;

  late final http.Client _client = _httpClient ?? http.Client();

  late final JobsController jobs = JobsController();

  late final DiagnosticsService diagnostics = DiagnosticsService(
    paths: paths,
    platform: hostPlatform,
    processRunner: processRunner,
    networkProbe: probeUri,
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

  late final AddonCatalog addonCatalog = AddonCatalog(
    downloader: downloader,
    dao: database.catalogCacheDao,
    cacheDirectory: paths.addonsCacheDir,
  );

  late final MacroCatalog macroCatalog = MacroCatalog(
    downloader: downloader,
    dao: database.catalogCacheDao,
    cacheDirectory: paths.macrosCacheDir,
  );

  late final MacroIconCache macroIcons = MacroIconCache(directory: paths.macroIconsCacheDir);

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
    configSnapshots: configSnapshots,
  );

  late final AddonInstaller addonInstaller = AddonInstaller(downloader: downloader);

  late final PipRunner pipRunner = PipRunner(processRunner: processRunner, paths: paths);

  late final PythonEnvResolver pythonEnvResolver = PythonEnvResolver(processRunner: processRunner);

  late final PythonPackageProbe pythonPackageProbe = PythonPackageProbe(
    processRunner: processRunner,
  );

  late final AddonsController addons =
      _addonsControllerOverride ??
      AddonsController(
        database: database,
        catalog: addonCatalog,
        installer: addonInstaller,
        paths: paths,
        pipRunner: pipRunner,
        pythonResolver: pythonEnvResolver,
        packageProbe: pythonPackageProbe,
        fuseAvailable: diagnostics.fuseAvailable,
        jobs: jobs,
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
        jobs: jobs,
      );

  late final CliWrapperInstaller cliWrapper = CliWrapperInstaller(
    platform: hostPlatform,
    processRunner: processRunner,
  );

  late final SettingsController settings = SettingsController(
    cliWrapper: cliWrapper,
    settingsDao: database.settingsDao,
  );

  late final CacheService cacheService = CacheService(
    paths: paths,
    cacheDao: database.catalogCacheDao,
  );

  late final CacheController cache = CacheController(service: cacheService);

  late final ShellController shell = ShellController();

  late final NewsFeed newsFeed = NewsFeed(
    downloader: downloader,
    dao: database.catalogCacheDao,
    cacheDirectory: paths.newsCacheDir,
  );

  late final NewsController news = _newsControllerOverride ?? NewsController(feed: newsFeed);

  late final DebugBundleService debugBundleService = DebugBundleService(paths: paths);

  late final DebugBundleController debugBundle = DebugBundleController(
    service: debugBundleService,
    database: database,
    diagnostics: diagnostics,
    paths: paths,
  );

  late final FileActions fileActions = FileActions(
    processRunner: processRunner,
    platform: hostPlatform,
  );

  late final ConfigSnapshotService configSnapshots = const ConfigSnapshotService();

  late final BundlesController bundles = BundlesController(database: database);

  late final MacrosController macros =
      _macrosControllerOverride ??
      MacrosController(
        database: database,
        catalog: macroCatalog,
        paths: paths,
        iconCache: macroIcons,
        jobs: jobs,
      );

  late final BundleApplyController bundleApply = BundleApplyController(
    install:
        ({
          required String addonId,
          required String branchRef,
          required String profileId,
          AddonDependencySelection? selection,
        }) => addons.install(
          addonId: addonId,
          branchRef: branchRef,
          profileId: profileId,
          selection: selection,
        ),
    update: ({required String addonId, required String branchRef, required String profileId}) =>
        addons.update(addonId: addonId, branchRef: branchRef, profileId: profileId),
  );

  late final PythonController python = PythonController(
    database: database,
    paths: paths,
    pipRunner: pipRunner,
    pythonResolver: pythonEnvResolver,
    fuseAvailable: diagnostics.fuseAvailable,
    jobs: jobs,
  );

  late final UpdatesController updates =
      _updatesControllerOverride ??
      UpdatesController(addons: addons, builds: builds, settingsDao: database.settingsDao);

  late final ProfileManifestController manifests =
      _manifestsControllerOverride ??
      ProfileManifestController(
        database: database,
        repository: profilesRepository,
        paths: paths,
        platform: hostPlatform,
        installAddon:
            ({
              required String addonId,
              required String? branchRef,
              required String profileId,
              required AddonDependencySelection? selection,
            }) async {
              if (addons.addons.value.isEmpty) {
                await addons.load();
              }
              if (addons.byId(addonId) == null) {
                return Err(AppError(message: 'Addon "$addonId" is not in the catalog'));
              }
              return addons.install(
                addonId: addonId,
                branchRef: branchRef ?? '',
                profileId: profileId,
                selection: selection,
              );
            },
        installPackages:
            ({required String profileId, required String specText, required String source}) =>
                python.install(profileId: profileId, specText: specText, source: source),
      );

  static Future<AppServices> bootstrap() async {
    final paths = await AppPaths.resolve();
    await paths.ensureBaseDirectories();
    final database = AppDatabase(NativeDatabase(File(paths.databaseFile)));
    final startupWarning = await _repairMovedData(paths, database);
    final services = AppServices(
      paths: paths,
      database: database,
      startupWarning: startupWarning,
    );
    await services.settings.load();
    return services;
  }

  static Future<String?> _repairMovedData(AppPaths paths, AppDatabase database) async {
    final legacy = paths.legacyRoot;
    if (legacy == null || legacy == paths.dataRoot) {
      return null;
    }
    final repaired = await DataRootRepair(
      database,
    ).rewritePathPrefix(from: legacy, to: paths.dataRoot);
    if (repaired == 0) {
      return null;
    }
    return 'Repaired $repaired stored path(s) after the Windows data root changed (D-117).';
  }

  Future<void> close() async {
    builds.dispose();
    profiles.dispose();
    addons.dispose();
    python.dispose();
    bundles.dispose();
    macros.dispose();
    jobs.dispose();
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
