// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog_parser.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/addons/addon_dependencies.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/pip_runner.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_env.dart';
import 'package:freecad_launcher/platform/python_package_probe.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../helpers/fake_addon_catalog.dart';
import '../helpers/fake_download.dart';

void main() {
  test(
    'installs Ondsel-Lens and its <depend> Python packages with pip',
    () async {
      final catalogFile = File(
        Platform.environment['FCL_CATALOG_ZIP'] ??
            '${Platform.environment['HOME']}/.local/share/org.freecad.ext.launcher/'
                'cache/addons/addon_catalog_cache.zip',
      );
      expect(catalogFile.existsSync(), isTrue, reason: 'missing ${catalogFile.path}');
      final catalogAddons = parseAddonCatalog(
        AddonCatalog.extractCatalogJson(await catalogFile.readAsBytes()),
      );

      final root = Directory('/tmp/opencode/fcl_addon_deps_e2e');
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      final paths = AppPaths(dataRoot: root.path);
      await paths.ensureBaseDirectories();
      final db = AppDatabase.inMemory();
      final now = DateTime.now().toUtc();
      await db.buildsDao.save(
        Build(
          id: 'b1',
          kind: BuildKind.custom,
          version: '1.1.3',
          channel: BuildChannel.custom,
          platform: BuildPlatform.linux,
          arch: BuildArch.x86_64,
          localPath: '/usr/bin/python3',
          pythonPath: '/usr/bin/python3',
          pythonVersion: '3.12',
          status: BuildStatus.installed,
          verified: false,
          installedAt: now,
          updatedAt: now,
        ),
      );
      final repository = ProfilesRepository(
        database: db,
        paths: paths,
        platform: BuildPlatform.linux,
      );
      final profile = (await repository.create(name: 'DepsSmoke', buildId: 'b1')).valueOrNull!;

      final catalog = FakeAddonCatalog(
        downloader: Downloader(
          source: FakeDownloadSource(),
          cacheDirectory: p.join(root.path, 'catalog'),
        ),
        dao: db.catalogCacheDao,
        cacheDirectory: p.join(root.path, 'catalog'),
      )..result = AddonCatalogResult(addons: catalogAddons, freshness: CatalogFreshness.refreshed);

      final processRunner = ProcessRunner();
      final controller = AddonsController(
        database: db,
        catalog: catalog,
        installer: AddonInstaller(
          downloader: Downloader(
            source: HttpDownloadSource(http.Client()),
            cacheDirectory: paths.downloadsCacheDir,
          ),
        ),
        paths: paths,
        pipRunner: PipRunner(processRunner: processRunner, paths: paths),
        pythonResolver: PythonEnvResolver(processRunner: processRunner),
        packageProbe: PythonPackageProbe(processRunner: processRunner),
      );
      await controller.load();

      final ondsel = catalogAddons.firstWhere((addon) => addon.id == 'Ondsel-Lens');
      final plan = await controller.prepareDependencies(
        addonId: ondsel.id,
        branchRef: ondsel.primaryBranch.gitRef,
        profileId: profile.id,
      );
      // The system Python used by this smoke test ships `requests` and PyJWT
      // metadata, so the probe must filter them out while keeping tzlocal.
      final planNames = plan.requiredPython.map((entry) => entry.requirement.name).toSet();
      // ignore: avoid_print
      print('plan python=$planNames');
      expect(planNames, contains('tzlocal'));
      expect(planNames, isNot(contains('requests')));
      expect(planNames.every((name) => {'pyjwt', 'tzlocal'}.contains(name)), isTrue);

      final installed = await controller.install(
        addonId: ondsel.id,
        branchRef: ondsel.primaryBranch.gitRef,
        profileId: profile.id,
        selection: AddonDependencySelection.requiredOnly,
      );
      expect(installed.isOk, isTrue, reason: '${installed.errorOrNull}');
      final modDirectory = p.join(paths.profilePaths(profile.id).mod, ondsel.id);
      expect(File(p.join(modDirectory, 'package.xml')).existsSync(), isTrue);

      final packages = await db.pythonPackagesDao.getByProfile(profile.id);
      // ignore: avoid_print
      print('packages=${packages.map((row) => '${row.name} (${row.source})').toList()}');
      expect(packages.map((row) => row.name), contains('tzlocal'));
      expect(packages.every((row) => row.source == 'addon:Ondsel-Lens'), isTrue);

      final target = p.join(paths.profilePaths(profile.id).additionalPythonPackages, 'py312');
      final check = await Process.run(
        '/usr/bin/python3',
        ['-c', 'import jwt, tzlocal; print("import-ok")'],
        environment: {...Platform.environment, 'PYTHONPATH': target},
      );
      expect(check.exitCode, 0, reason: '${check.stderr}');
      expect(check.stdout, contains('import-ok'));

      controller.dispose();
      await db.close();
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    },
    skip: Platform.environment['FCL_REAL_DEPS'] != '1'
        ? 'Manual test: set FCL_REAL_DEPS=1 to install the real Ondsel-Lens and its dependencies'
        : null,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
