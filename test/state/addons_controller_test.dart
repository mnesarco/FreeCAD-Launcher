// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/addon_dependencies.dart';
import 'package:freecad_launcher/domain/addons/package_xml.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/pip_runner.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_env.dart';
import 'package:freecad_launcher/platform/python_package_probe.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/jobs_controller.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_addon_catalog.dart';
import '../helpers/fake_pip.dart';
import '../helpers/fake_download.dart';
import '../helpers/fake_process.dart';
import '../helpers/test_database.dart';

Addon addon(
  String id, {
  String? name,
  String description = '',
  List<String> tags = const [],
  Set<AddonContentType> content = const {AddonContentType.workbench},
  String? freecadMin,
  String? freecadMax,
  String version = '',
  String requirements = '',
  List<AddonDependency> dependencies = const [],
}) {
  return Addon(
    id: id,
    branches: [
      AddonBranch(
        gitRef: 'master',
        displayName: 'master',
        repositoryUrl: 'https://example.invalid/$id',
        zipUrl: 'https://example.invalid/$id.zip',
        curated: true,
        sparseCache: false,
        freecadMin: freecadMin,
        freecadMax: freecadMax,
        metadata: AddonMetadata(
          name: name ?? id,
          description: description,
          version: version,
          license: 'MIT',
          minPython: '3.10',
          tags: tags,
          people: const [],
          content: content,
          requirements: requirements,
          dependencies: dependencies,
        ),
      ),
    ],
  );
}

void main() {
  late Directory tempDirectory;
  late AppDatabase db;
  late FakeAddonCatalog catalog;
  late FakeDownloadSource downloadSource;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_addons_controller');
    db = createTestDatabase();
    downloadSource = FakeDownloadSource();
    catalog = FakeAddonCatalog(
      downloader: Downloader(
        source: downloadSource,
        cacheDirectory: p.join(tempDirectory.path, 'addons'),
      ),
      dao: db.catalogCacheDao,
      cacheDirectory: p.join(tempDirectory.path, 'addons'),
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  AddonsController controller({
    PipRunner? pipRunner,
    PythonEnvResolver? pythonResolver,
    PythonPackageProbe? packageProbe,
    Future<bool> Function()? fuseAvailable,
    JobsController? jobs,
    AddonInstaller? installer,
  }) {
    return AddonsController(
      database: db,
      catalog: catalog,
      pipRunner: pipRunner,
      pythonResolver: pythonResolver,
      packageProbe: packageProbe,
      fuseAvailable: fuseAvailable,
      jobs: jobs,
      installer:
          installer ??
          AddonInstaller(
            downloader: Downloader(
              source: downloadSource,
              cacheDirectory: p.join(tempDirectory.path, 'downloads'),
            ),
          ),
      paths: AppPaths(dataRoot: tempDirectory.path),
      clock: () => DateTime.utc(2026, 9, 19, 16),
    );
  }

  test('loads the catalog and reports errors', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus', name: 'A2plus')],
      freshness: CatalogFreshness.refreshed,
      fetchedAt: DateTime.utc(2026, 9, 19),
    );
    final subject = controller();

    await subject.load();

    expect(subject.loaded.value, isTrue);
    expect(subject.addons.value.single.id, 'A2plus');
    expect(subject.freshness.value, CatalogFreshness.refreshed);

    catalog.error = const AddonCatalogUnavailableException('offline');
    await subject.load(forceRefresh: true);

    expect(subject.error.value, isNotNull);
    subject.dispose();
  });

  test('ensureCachedCatalog populates addons from cache without loading', () async {
    catalog.cached = [addon('A2plus', name: 'A2plus')];
    final subject = controller();

    await subject.ensureCachedCatalog();

    expect(subject.loaded.value, isFalse);
    expect(subject.addons.value.single.id, 'A2plus');
    expect(catalog.loads, 0);
    subject.dispose();
  });

  test('ensureCachedCatalog skips when the catalog is already loaded', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('Loaded')],
      freshness: CatalogFreshness.fresh,
    );
    catalog.cached = [addon('A2plus')];
    final subject = controller();
    await subject.load();

    await subject.ensureCachedCatalog();

    expect(subject.addons.value.single.id, 'Loaded');
    expect(catalog.cachedLoads, 0);
    subject.dispose();
  });

  test('filters by text, tag, content and installed state', () async {
    catalog.result = AddonCatalogResult(
      addons: [
        addon('A2plus', description: 'Assembly workbench', tags: ['assembly']),
        addon('MacroTool', content: {AddonContentType.macro}, tags: ['utility']),
      ],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    await db.installedAddonsDao.save(sampleAddon(addonId: 'MacroTool'));
    final subject = controller();
    await subject.load();
    subject.start();
    await pumpEventQueue();

    expect(subject.filteredAddons.value, hasLength(2));

    subject.query.value = 'assembly';
    expect(subject.filteredAddons.value.single.id, 'A2plus');

    subject.query.value = '#utility';
    expect(subject.filteredAddons.value.single.id, 'MacroTool');

    subject.query.value = '';
    subject.toggleContentFilter(AddonContentType.macro);
    expect(subject.filteredAddons.value.single.id, 'MacroTool');

    subject.toggleContentFilter(AddonContentType.workbench);
    expect(subject.filteredAddons.value.map((item) => item.id).toSet(), {'A2plus', 'MacroTool'});
    subject.toggleContentFilter(AddonContentType.workbench);

    subject.toggleContentFilter(AddonContentType.macro);
    subject.toggleInstalledFilter(AddonInstalledFilter.installed);
    expect(subject.filteredAddons.value.single.id, 'MacroTool');

    subject.toggleInstalledFilter(AddonInstalledFilter.installed);
    subject.toggleInstalledFilter(AddonInstalledFilter.notInstalled);
    expect(subject.filteredAddons.value.single.id, 'A2plus');

    subject.toggleInstalledFilter(AddonInstalledFilter.installed);
    expect(subject.filteredAddons.value, hasLength(2));

    expect(subject.activeFilterCount, 2);
    subject.clearFilters();
    expect(subject.activeFilterCount, 0);
    expect(subject.filteredAddons.value, hasLength(2));
    subject.dispose();
  });

  test('filters by installed build versions', () async {
    catalog.result = AddonCatalogResult(
      addons: [
        addon('Old', freecadMin: '0.19', freecadMax: '0.21'),
        addon('New', freecadMin: '1.0'),
        addon('Free'),
      ],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild(version: '1.1.3'));
    final subject = controller();
    await subject.load();
    subject.start();

    subject.setFreecadFilter('1.1.3');
    final ids = subject.filteredAddons.value.map((item) => item.id).toSet();
    expect(ids, {'New', 'Free'});
    expect(subject.isCompatibleWith(subject.addons.value.first, '1.1.3'), isFalse);
    subject.dispose();
  });

  test('selects branches per addon', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus')],
      freshness: CatalogFreshness.fresh,
    );
    final subject = controller();
    await subject.load();

    expect(subject.branchRefFor(subject.addons.value.single), 'master');
    subject.selectBranch('A2plus', 'dev');
    expect(subject.branchRefFor(subject.addons.value.single), 'dev');
    subject.dispose();
  });

  test('installs an addon into Mod and records it', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus', name: 'A2plus', version: '0.4.68')],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    downloadSource.streamFactory = () => Stream.fromIterable([
      catalogZip({
        'A2plus-master/InitGui.py': 'gui',
        'A2plus-master/package.xml': '<package><name>A2plus</name></package>',
      }),
    ]);
    final subject = controller();
    await subject.load();
    subject.start();
    await pumpEventQueue();

    final result = await subject.install(
      addonId: 'A2plus',
      branchRef: 'master',
      profileId: 'profile-1',
    );

    expect(result.isOk, isTrue);
    final modDirectory = p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'A2plus');
    expect(File(p.join(modDirectory, 'InitGui.py')).existsSync(), isTrue);
    expect(File(p.join(modDirectory, 'package.xml')).existsSync(), isTrue);
    final row = await db.installedAddonsDao.getByAddon('profile-1', 'A2plus');
    expect(row, isNotNull);
    expect(row!.gitRef, 'master');
    expect(row.version, '0.4.68');
    expect(row.hasRequirements, isFalse);
    expect(subject.installing.value, isEmpty);
    await pumpEventQueue();
    expect(subject.isInstalledIn('profile-1', 'A2plus'), isTrue);
    subject.dispose();
  });

  test('cancelling an addon install job removes the partial download', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus', name: 'A2plus')],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    final chunks = StreamController<List<int>>();
    downloadSource.streamFactory = () => chunks.stream;
    final jobs = JobsController();
    final subject = controller(jobs: jobs);
    await subject.load();

    final installFuture = subject.install(
      addonId: 'A2plus',
      branchRef: 'master',
      profileId: 'profile-1',
    );
    await pumpEventQueue();
    chunks.add(List<int>.filled(4096, 1));
    await pumpEventQueue();

    jobs.cancel(jobs.jobs.value.single.id);
    chunks.add(List<int>.filled(4096, 2));
    await chunks.close();

    final result = await installFuture;
    expect(result.isErr, isTrue);
    expect(jobs.jobs.value.single.state, JobState.cancelled);
    final downloads = Directory(p.join(tempDirectory.path, 'downloads'));
    final leftovers = downloads.existsSync()
        ? downloads.listSync().whereType<File>().toList()
        : <File>[];
    expect(leftovers, isEmpty);
    expect(
      Directory(p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'A2plus')).existsSync(),
      isFalse,
    );
    expect(await db.installedAddonsDao.getByAddon('profile-1', 'A2plus'), isNull);
    subject.dispose();
    jobs.dispose();
  });

  test('install failure reports the error and records nothing', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('Broken')],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    downloadSource.streamFactory = () => Stream.fromIterable([utf8.encode('not a zip')]);
    final subject = controller();
    await subject.load();

    final result = await subject.install(
      addonId: 'Broken',
      branchRef: 'master',
      profileId: 'profile-1',
    );

    expect(result.isErr, isTrue);
    expect(subject.installErrors.value['Broken'], isNotNull);
    expect(await db.installedAddonsDao.getByAddon('profile-1', 'Broken'), isNull);
    expect(
      Directory(p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'Broken')).existsSync(),
      isFalse,
    );
    subject.dispose();
  });

  test('install requires an existing profile', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus')],
      freshness: CatalogFreshness.fresh,
    );
    final subject = controller();
    await subject.load();

    final result = await subject.install(addonId: 'A2plus', branchRef: 'master', profileId: 'nope');

    expect(result.isErr, isTrue);
    expect(result.errorOrNull!.message, contains('Profile not found'));
    subject.dispose();
  });

  test('detects updates by catalog timestamp and version', () async {
    final catalogAddon = addon('A2plus', name: 'A2plus', version: '0.4.68');
    catalog.result = AddonCatalogResult(addons: [catalogAddon], freshness: CatalogFreshness.fresh);
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    final subject = controller();
    await subject.load();
    subject.start();
    await pumpEventQueue();

    await db.installedAddonsDao.save(
      sampleAddon(
        profileId: 'profile-1',
        addonId: 'A2plus',
        version: '0.4.60',
        catalogLastUpdate: DateTime.utc(2026, 1, 1),
      ),
    );
    await pumpEventQueue();
    expect(subject.isUpdateAvailable('profile-1', 'A2plus'), isTrue);

    await db.installedAddonsDao.save(
      sampleAddon(
        profileId: 'profile-1',
        addonId: 'A2plus',
        version: '0.4.68',
        catalogLastUpdate: DateTime.utc(2026, 12, 1),
      ),
    );
    await pumpEventQueue();
    expect(subject.isUpdateAvailable('profile-1', 'A2plus'), isFalse);
    subject.dispose();
  });

  test('update backs up the current addon and reinstalls it', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus', name: 'A2plus', version: '0.4.68')],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    final modDirectory = p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'A2plus');
    File(p.join(modDirectory, 'old.txt')).createSync(recursive: true);
    await db.installedAddonsDao.save(
      sampleAddon(profileId: 'profile-1', addonId: 'A2plus', version: '0.4.60'),
    );
    downloadSource.streamFactory = () => Stream.fromIterable([
      catalogZip({'A2plus-master/new.txt': 'new'}),
    ]);
    final subject = controller();
    await subject.load();
    subject.start();
    await pumpEventQueue();

    final result = await subject.update(
      addonId: 'A2plus',
      branchRef: 'master',
      profileId: 'profile-1',
    );

    expect(result.isOk, isTrue);
    final backupDirectory = p.join(
      tempDirectory.path,
      'profiles',
      'profile-1',
      'backups',
      'addon-A2plus-2026-09-19T16-00-00-000Z',
    );
    expect(File(p.join(backupDirectory, 'old.txt')).existsSync(), isTrue);
    expect(File(p.join(modDirectory, 'new.txt')).existsSync(), isTrue);
    expect(File(p.join(modDirectory, 'old.txt')).existsSync(), isFalse);
    final row = await db.installedAddonsDao.getByAddon('profile-1', 'A2plus');
    expect(row!.version, '0.4.68');
    subject.dispose();
  });

  test('update requires an installed addon', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus')],
      freshness: CatalogFreshness.fresh,
    );
    final subject = controller();
    await subject.load();

    final result = await subject.update(
      addonId: 'A2plus',
      branchRef: 'master',
      profileId: 'profile-1',
    );

    expect(result.isErr, isTrue);
    subject.dispose();
  });

  test('pins and unpins an installed addon, blocking updates while pinned', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus')],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    await db.installedAddonsDao.save(sampleAddon(addonId: 'A2plus'));
    final subject = controller();
    await subject.load();
    subject.start();
    await pumpEventQueue();

    expect(subject.isPinned('profile-1', 'A2plus'), isFalse);
    expect((await subject.pin(addonId: 'A2plus', profileId: 'profile-1')).isOk, isTrue);
    await pumpEventQueue();
    expect(subject.isPinned('profile-1', 'A2plus'), isTrue);
    expect(
      (await db.installedAddonsDao.getByAddon('profile-1', 'A2plus'))!.pinnedAt,
      DateTime.utc(2026, 9, 19, 16),
    );

    final update = await subject.update(
      addonId: 'A2plus',
      branchRef: 'master',
      profileId: 'profile-1',
    );
    expect(update.isErr, isTrue);
    expect('${update.errorOrNull}', contains('pinned'));

    expect((await subject.unpin(addonId: 'A2plus', profileId: 'profile-1')).isOk, isTrue);
    await pumpEventQueue();
    expect(subject.isPinned('profile-1', 'A2plus'), isFalse);
    expect((await db.installedAddonsDao.getByAddon('profile-1', 'A2plus'))!.pinnedAt, isNull);

    expect((await subject.pin(addonId: 'Nope', profileId: 'profile-1')).isErr, isTrue);
    subject.dispose();
  });

  test('installs declared requirements with pip and records the packages', () async {
    catalog.result = AddonCatalogResult(
      addons: [
        addon(
          'WithReqs',
          name: 'WithReqs',
          version: '1.0.0',
          requirements: 'numpy>=1.26\n# comment\nsix',
        ),
      ],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    downloadSource.streamFactory = () => Stream.fromIterable([
      catalogZip({'WithReqs-master/InitGui.py': 'gui'}),
    ]);
    final pip = FakePipRunner();
    final subject = controller(
      pipRunner: pip,
      pythonResolver: FakePythonEnvResolver('/opt/freecad/bin/python'),
    );
    await subject.load();

    final result = await subject.install(
      addonId: 'WithReqs',
      branchRef: 'master',
      profileId: 'profile-1',
      selection: AddonDependencySelection.requiredOnly,
    );

    expect(result.isOk, isTrue);
    expect(pip.calls.single.pythonPath, '/opt/freecad/bin/python');
    expect(pip.calls.single.packages, ['numpy>=1.26', 'six']);
    expect(
      pip.calls.single.targetDirectory,
      p.join(tempDirectory.path, 'profiles', 'profile-1', 'AdditionalPythonPackages', 'py311'),
    );
    final packages = await db.pythonPackagesDao.getByProfile('profile-1');
    expect(packages.map((package) => package.name).toSet(), {'numpy', 'six'});
    expect(packages.every((package) => package.source == 'addon:WithReqs'), isTrue);
    expect(subject.requirementsErrors.value, isEmpty);
    subject.dispose();
  });

  test('requirements failures are reported without failing the addon install', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('WithReqs', requirements: 'numpy>=1.26')],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    downloadSource.streamFactory = () => Stream.fromIterable([
      catalogZip({'WithReqs-master/InitGui.py': 'gui'}),
    ]);
    final pip = FakePipRunner()..success = false;
    final subject = controller(
      pipRunner: pip,
      pythonResolver: FakePythonEnvResolver('/opt/freecad/bin/python'),
    );
    await subject.load();

    final result = await subject.install(
      addonId: 'WithReqs',
      branchRef: 'master',
      profileId: 'profile-1',
      selection: AddonDependencySelection.requiredOnly,
    );

    expect(result.isOk, isTrue);
    expect(subject.requirementsErrors.value['WithReqs'], isNotNull);
    expect(await db.pythonPackagesDao.getByProfile('profile-1'), isEmpty);
    subject.dispose();
  });

  test('skips pip when the addon declares no requirements', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus')],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    downloadSource.streamFactory = () => Stream.fromIterable([
      catalogZip({'A2plus-master/InitGui.py': 'gui'}),
    ]);
    final pip = FakePipRunner();
    final subject = controller(
      pipRunner: pip,
      pythonResolver: FakePythonEnvResolver('/opt/freecad/bin/python'),
    );
    await subject.load();

    final result = await subject.install(
      addonId: 'A2plus',
      branchRef: 'master',
      profileId: 'profile-1',
      selection: AddonDependencySelection.requiredOnly,
    );

    expect(result.isOk, isTrue);
    expect(pip.calls, isEmpty);
    subject.dispose();
  });

  test('remove deletes the addon files and the DB row', () async {
    catalog.result = AddonCatalogResult(
      addons: [addon('A2plus')],
      freshness: CatalogFreshness.fresh,
    );
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    final modDirectory = p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'A2plus');
    File(p.join(modDirectory, 'InitGui.py')).createSync(recursive: true);
    await db.installedAddonsDao.save(sampleAddon(profileId: 'profile-1', addonId: 'A2plus'));
    final subject = controller();
    await subject.load();
    subject.start();
    await pumpEventQueue();

    final result = await subject.remove(addonId: 'A2plus', profileId: 'profile-1');

    expect(result.isOk, isTrue);
    expect(Directory(modDirectory).existsSync(), isFalse);
    expect(await db.installedAddonsDao.getByAddon('profile-1', 'A2plus'), isNull);
    expect((await subject.remove(addonId: 'A2plus', profileId: 'profile-1')).isErr, isTrue);
    subject.dispose();
  });
  group('custom installs', () {
    setUp(() async {
      await db.buildsDao.save(sampleBuild());
      await db.profilesDao.save(sampleProfile());
    });

    test('installs from a repository URL and records provenance', () async {
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({
          'MyAddon-main/package.xml': _packageXml('MyAddon', '1.2.3'),
          'MyAddon-main/InitGui.py': 'gui',
        }),
      ]);
      final subject = controller();

      final result = await subject.installFromRepository(
        repositoryUrl: 'https://github.com/owner/MyAddon',
        gitRef: 'main',
        profileId: 'profile-1',
      );

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      final modDirectory = p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'MyAddon');
      expect(File(p.join(modDirectory, 'InitGui.py')).existsSync(), isTrue);
      final row = await db.installedAddonsDao.getByAddon('profile-1', 'MyAddon');
      expect(row, isNotNull);
      expect(row!.source, 'repo');
      expect(row.sourceUrl, 'https://github.com/owner/MyAddon');
      expect(row.gitRef, 'main');
      expect(row.version, '1.2.3');
      expect(row.catalogLastUpdate, isNull);
      expect(
        downloadSource.requests.single.toString(),
        'https://github.com/owner/MyAddon/archive/main.zip',
      );
      subject.dispose();
    });

    test('rejects a repository archive without package.xml', () async {
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({'MyAddon-main/InitGui.py': 'gui'}),
      ]);
      final subject = controller();

      final result = await subject.installFromRepository(
        repositoryUrl: 'https://github.com/owner/MyAddon',
        gitRef: 'main',
        profileId: 'profile-1',
      );

      expect(result.isErr, isTrue);
      expect('${result.errorOrNull}', contains('package.xml'));
      expect(
        Directory(
          p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'MyAddon'),
        ).existsSync(),
        isFalse,
      );
      expect(await db.installedAddonsDao.getByAddon('profile-1', 'MyAddon'), isNull);
      subject.dispose();
    });

    test('blocks a custom install when the addon id already exists', () async {
      await db.installedAddonsDao.save(sampleAddon(addonId: 'MyAddon'));
      final subject = controller();

      final result = await subject.installFromRepository(
        repositoryUrl: 'https://github.com/owner/MyAddon',
        gitRef: 'main',
        profileId: 'profile-1',
      );

      expect(result.isErr, isTrue);
      expect('${result.errorOrNull}', contains('remove it first'));
      expect(downloadSource.requests, isEmpty);
      subject.dispose();
    });

    test('updates a repository addon after backing up the old files', () async {
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({
          'MyAddon-main/package.xml': _packageXml('MyAddon', '1.0.0'),
          'MyAddon-main/InitGui.py': 'gui',
        }),
      ]);
      final subject = controller();
      await subject.installFromRepository(
        repositoryUrl: 'https://github.com/owner/MyAddon',
        gitRef: 'main',
        profileId: 'profile-1',
      );

      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({
          'MyAddon-main/package.xml': _packageXml('MyAddon', '2.0.0'),
          'MyAddon-main/InitGui.py': 'gui-v2',
        }),
      ]);
      final result = await subject.updateFromRepository(addonId: 'MyAddon', profileId: 'profile-1');

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      final row = await db.installedAddonsDao.getByAddon('profile-1', 'MyAddon');
      expect(row!.version, '2.0.0');
      expect(row.source, 'repo');
      final backups = Directory(p.join(tempDirectory.path, 'profiles', 'profile-1', 'backups'));
      expect(
        backups.listSync().whereType<Directory>().map((d) => p.basename(d.path)).toList(),
        contains(startsWith('addon-MyAddon-')),
      );
      subject.dispose();
    });

    test('blocks repository updates while pinned', () async {
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({'MyAddon-main/package.xml': _packageXml('MyAddon', '1.0.0')}),
      ]);
      final subject = controller();
      await subject.installFromRepository(
        repositoryUrl: 'https://github.com/owner/MyAddon',
        gitRef: 'main',
        profileId: 'profile-1',
      );
      await subject.pin(addonId: 'MyAddon', profileId: 'profile-1');

      final result = await subject.updateFromRepository(addonId: 'MyAddon', profileId: 'profile-1');

      expect(result.isErr, isTrue);
      expect('${result.errorOrNull}', contains('pinned'));
      subject.dispose();
    });

    test('installs from a local archive and records the path', () async {
      final archivePath = p.join(tempDirectory.path, 'LocalAddon.zip');
      File(archivePath).writeAsBytesSync(
        catalogZip({
          'LocalAddon/package.xml': _packageXml('LocalAddon', '0.9.0'),
          'LocalAddon/InitGui.py': 'gui',
        }),
      );
      final subject = controller();

      final result = await subject.installFromArchive(
        archivePath: archivePath,
        profileId: 'profile-1',
      );

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      final row = await db.installedAddonsDao.getByAddon('profile-1', 'LocalAddon');
      expect(row, isNotNull);
      expect(row!.source, 'zip');
      expect(row.sourcePath, File(archivePath).absolute.path);
      expect(row.version, '0.9.0');
      expect(downloadSource.requests, isEmpty);
      subject.dispose();
    });

    test('reinstalls a zip addon from a new file', () async {
      final first = p.join(tempDirectory.path, 'LocalAddon.zip');
      File(first).writeAsBytesSync(
        catalogZip({'LocalAddon/package.xml': _packageXml('LocalAddon', '0.9.0')}),
      );
      final subject = controller();
      await subject.installFromArchive(archivePath: first, profileId: 'profile-1');

      final second = p.join(tempDirectory.path, 'LocalAddon-v2.zip');
      File(second).writeAsBytesSync(
        catalogZip({
          'LocalAddon/package.xml': _packageXml('LocalAddon', '1.0.0'),
          'LocalAddon/InitGui.py': 'gui',
        }),
      );
      final result = await subject.reinstallFromArchive(
        addonId: 'LocalAddon',
        profileId: 'profile-1',
        archivePath: second,
      );

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      final row = await db.installedAddonsDao.getByAddon('profile-1', 'LocalAddon');
      expect(row!.version, '1.0.0');
      expect(
        File(
          p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'LocalAddon', 'InitGui.py'),
        ).existsSync(),
        isTrue,
      );
      subject.dispose();
    });

    test('asks for requirements consent before placing files', () async {
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({
          'MyAddon-main/package.xml': _packageXml('MyAddon', '1.0.0'),
          'MyAddon-main/requirements.txt': 'six>=1.0',
        }),
      ]);
      final subject = controller();
      var asked = false;

      final result = await subject.installFromRepository(
        repositoryUrl: 'https://github.com/owner/MyAddon',
        gitRef: 'main',
        profileId: 'profile-1',
        onDependencies: (plan) async {
          asked = true;
          expect(plan.requiredPython.single.requirement.name, 'six');
          return null;
        },
      );

      expect(asked, isTrue);
      expect(result.isErr, isTrue);
      expect(
        Directory(
          p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'MyAddon'),
        ).existsSync(),
        isFalse,
      );
      expect(
        Directory(
          p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'MyAddon.part'),
        ).existsSync(),
        isFalse,
      );
      expect(await db.installedAddonsDao.getByAddon('profile-1', 'MyAddon'), isNull);
      expect(subject.installErrors.value, isEmpty);
      subject.dispose();
    });

    test('installs accepted requirements into the profile', () async {
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({
          'MyAddon-main/package.xml': _packageXml('MyAddon', '1.0.0'),
          'MyAddon-main/requirements.txt': 'six>=1.0',
        }),
      ]);
      final pip = FakePipRunner();
      final subject = controller(
        pipRunner: pip,
        pythonResolver: FakePythonEnvResolver('/opt/freecad/bin/python'),
      );

      final result = await subject.installFromRepository(
        repositoryUrl: 'https://github.com/owner/MyAddon',
        gitRef: 'main',
        profileId: 'profile-1',
        onDependencies: (_) async => AddonDependencySelection.requiredOnly,
      );

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      expect(pip.calls.single.packages, ['six>=1.0']);
      final row = await db.installedAddonsDao.getByAddon('profile-1', 'MyAddon');
      expect(row!.hasRequirements, isTrue);
      final packages = await db.pythonPackagesDao.getByProfile('profile-1');
      expect(packages.single.name, 'six');
      expect(packages.single.source, 'addon:MyAddon');
      subject.dispose();
    });

    test('links a development directory and remove keeps the source', () async {
      final sourceDirectory = p.join(tempDirectory.path, 'dev', 'DevAddon');
      Directory(sourceDirectory).createSync(recursive: true);
      File(
        p.join(sourceDirectory, 'package.xml'),
      ).writeAsStringSync(_packageXml('DevAddon', '0.1.0'));
      File(p.join(sourceDirectory, 'InitGui.py')).writeAsStringSync('live');
      final subject = controller();

      final result = await subject.installFromDirectory(
        sourcePath: sourceDirectory,
        profileId: 'profile-1',
      );

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      expect(result.errorOrNull, isNull);
      final modDirectory = p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'DevAddon');
      expect(isAddonLink(modDirectory), isTrue);
      final row = await db.installedAddonsDao.getByAddon('profile-1', 'DevAddon');
      expect(row!.source, 'symlink');
      expect(row.sourcePath, p.normalize(sourceDirectory));
      expect(subject.isUpdateAvailable('profile-1', 'DevAddon'), isFalse);

      expect((await subject.remove(addonId: 'DevAddon', profileId: 'profile-1')).isOk, isTrue);
      expect(File(p.join(sourceDirectory, 'InitGui.py')).existsSync(), isTrue);
      expect(
        FileSystemEntity.typeSync(modDirectory, followLinks: false),
        FileSystemEntityType.notFound,
      );
      subject.dispose();
    }, skip: Platform.isWindows);

    test('rejects linking the profile Mod directory', () async {
      final modRoot = p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod');
      Directory(modRoot).createSync(recursive: true);
      final subject = controller();

      final result = await subject.installFromDirectory(
        sourcePath: modRoot,
        profileId: 'profile-1',
      );

      expect(result.isErr, isTrue);
      subject.dispose();
    }, skip: Platform.isWindows);

    test('installs a repository addon into another profile', () async {
      await db.profilesDao.save(sampleProfile(id: 'profile-2', name: 'Other'));
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({
          'MyAddon-main/package.xml': _packageXml('MyAddon', '1.0.0'),
          'MyAddon-main/InitGui.py': 'gui',
        }),
      ]);
      final subject = controller();
      await subject.installFromRepository(
        repositoryUrl: 'https://github.com/owner/MyAddon',
        gitRef: 'main',
        profileId: 'profile-1',
      );
      final row = (await db.installedAddonsDao.getByAddon('profile-1', 'MyAddon'))!;

      final result = await subject.installCustomInProfile(addon: row, profileId: 'profile-2');

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      final copied = await db.installedAddonsDao.getByAddon('profile-2', 'MyAddon');
      expect(copied, isNotNull);
      expect(copied!.source, 'repo');
      expect(copied.sourceUrl, 'https://github.com/owner/MyAddon');
      expect(copied.gitRef, 'main');
      expect(
        File(
          p.join(tempDirectory.path, 'profiles', 'profile-2', 'Mod', 'MyAddon', 'InitGui.py'),
        ).existsSync(),
        isTrue,
      );
      subject.dispose();
    });

    test('installs an archive addon into another profile keeping the id', () async {
      await db.profilesDao.save(sampleProfile(id: 'profile-2', name: 'Other'));
      final archivePath = p.join(tempDirectory.path, 'LocalAddon.zip');
      File(archivePath).writeAsBytesSync(
        catalogZip({'LocalAddon/package.xml': _packageXml('LocalAddon', '0.9.0')}),
      );
      final subject = controller();
      await subject.installFromArchive(archivePath: archivePath, profileId: 'profile-1');
      final row = (await db.installedAddonsDao.getByAddon('profile-1', 'LocalAddon'))!;

      final renamed = p.join(tempDirectory.path, 'renamed.zip');
      File(renamed).writeAsBytesSync(
        catalogZip({'LocalAddon/package.xml': _packageXml('LocalAddon', '0.9.0')}),
      );
      final result = await subject.installCustomInProfile(
        addon: row,
        profileId: 'profile-2',
        archivePath: renamed,
      );

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      final copied = await db.installedAddonsDao.getByAddon('profile-2', 'LocalAddon');
      expect(copied, isNotNull);
      expect(copied!.source, 'zip');
      expect(copied.sourcePath, File(renamed).absolute.path);
      subject.dispose();
    });

    test('links a development directory into another profile', () async {
      await db.profilesDao.save(sampleProfile(id: 'profile-2', name: 'Other'));
      final sourceDirectory = p.join(tempDirectory.path, 'dev2', 'DevAddon');
      Directory(sourceDirectory).createSync(recursive: true);
      File(
        p.join(sourceDirectory, 'package.xml'),
      ).writeAsStringSync(_packageXml('DevAddon', '0.1.0'));
      final subject = controller();
      await subject.installFromDirectory(sourcePath: sourceDirectory, profileId: 'profile-1');
      final row = (await db.installedAddonsDao.getByAddon('profile-1', 'DevAddon'))!;

      final result = await subject.installCustomInProfile(addon: row, profileId: 'profile-2');

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      final linkPath = p.join(tempDirectory.path, 'profiles', 'profile-2', 'Mod', 'DevAddon');
      expect(isAddonLink(linkPath), isTrue);
      final copied = await db.installedAddonsDao.getByAddon('profile-2', 'DevAddon');
      expect(copied!.source, 'symlink');
      expect(copied.sourcePath, p.normalize(sourceDirectory));
      subject.dispose();
    }, skip: Platform.isWindows);

    test('blocks installing a custom addon twice into the same profile', () async {
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({'MyAddon-main/package.xml': _packageXml('MyAddon', '1.0.0')}),
      ]);
      final subject = controller();
      await subject.installFromRepository(
        repositoryUrl: 'https://github.com/owner/MyAddon',
        gitRef: 'main',
        profileId: 'profile-1',
      );
      final row = (await db.installedAddonsDao.getByAddon('profile-1', 'MyAddon'))!;

      final result = await subject.installCustomInProfile(addon: row, profileId: 'profile-1');

      expect(result.isErr, isTrue);
      expect('${result.errorOrNull}', contains('remove it first'));
      subject.dispose();
    });

    test('refuses to copy catalog addons with the custom action', () async {
      final subject = controller();

      final result = await subject.installCustomInProfile(
        addon: sampleAddon(addonId: 'A2plus'),
        profileId: 'profile-1',
      );

      expect(result.isErr, isTrue);
      expect('${result.errorOrNull}', contains('custom addons'));
      subject.dispose();
    });

    test('reports a missing archive when copying a zip addon', () async {
      await db.profilesDao.save(sampleProfile(id: 'profile-2', name: 'Other'));
      final archivePath = p.join(tempDirectory.path, 'LocalAddon.zip');
      File(archivePath).writeAsBytesSync(
        catalogZip({'LocalAddon/package.xml': _packageXml('LocalAddon', '0.9.0')}),
      );
      final subject = controller();
      await subject.installFromArchive(archivePath: archivePath, profileId: 'profile-1');
      final row = (await db.installedAddonsDao.getByAddon('profile-1', 'LocalAddon'))!;
      File(archivePath).deleteSync();

      final result = await subject.installCustomInProfile(addon: row, profileId: 'profile-2');

      expect(result.isErr, isTrue);
      expect('${result.errorOrNull}', contains('Archive not found'));
      subject.dispose();
    });
  });

  group('addon disabled state', () {
    setUp(() async {
      await db.buildsDao.save(sampleBuild());
      await db.profilesDao.save(sampleProfile());
    });

    String modDirectory() => p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'A2plus');

    test('disables and enables an installed addon with the marker file', () async {
      Directory(modDirectory()).createSync(recursive: true);
      await db.installedAddonsDao.save(sampleAddon(addonId: 'A2plus'));
      final subject = controller();
      subject.start();
      await pumpEventQueue();

      final marker = File(p.join(modDirectory(), 'ADDON_DISABLED'));
      expect(subject.isAddonDisabled('profile-1', 'A2plus'), isFalse);

      final disabled = await subject.setAddonDisabled(
        addonId: 'A2plus',
        profileId: 'profile-1',
        disabled: true,
      );
      expect(disabled.isOk, isTrue);
      expect(marker.existsSync(), isTrue);
      expect(subject.isAddonDisabled('profile-1', 'A2plus'), isTrue);

      final enabled = await subject.setAddonDisabled(
        addonId: 'A2plus',
        profileId: 'profile-1',
        disabled: false,
      );
      expect(enabled.isOk, isTrue);
      expect(marker.existsSync(), isFalse);
      expect(subject.isAddonDisabled('profile-1', 'A2plus'), isFalse);
      subject.dispose();
    });

    test('detects a marker created outside the app on refresh', () async {
      Directory(modDirectory()).createSync(recursive: true);
      await db.installedAddonsDao.save(sampleAddon(addonId: 'A2plus'));
      final subject = controller();
      subject.start();
      await pumpEventQueue();

      File(p.join(modDirectory(), 'ADDON_DISABLED')).writeAsStringSync('');
      await subject.refreshDisabledState();

      expect(subject.isAddonDisabled('profile-1', 'A2plus'), isTrue);
      subject.dispose();
    });

    test('reports when the addon files are missing', () async {
      await db.installedAddonsDao.save(sampleAddon(addonId: 'A2plus'));
      final subject = controller();

      final result = await subject.setAddonDisabled(
        addonId: 'A2plus',
        profileId: 'profile-1',
        disabled: true,
      );

      expect(result.isErr, isTrue);
      expect('${result.errorOrNull}', contains('files not found'));
      subject.dispose();
    });
  });

  group('dependency installs', () {
    setUp(() async {
      await db.buildsDao.save(sampleBuild());
      await db.profilesDao.save(sampleProfile());
    });

    test('installs dependent addons and Python packages before the addon', () async {
      catalog.result = AddonCatalogResult(
        addons: [
          addon(
            'Root',
            dependencies: const [
              AddonDependency(name: 'Curves'),
              AddonDependency(name: 'numpy'),
            ],
          ),
          addon('Curves', dependencies: const [AddonDependency(name: 'tzlocal')]),
        ],
        freshness: CatalogFreshness.fresh,
      );
      final downloader = FakeDownloadSourceWithResponses((uri) async {
        final bytes = uri.path.contains('Curves')
            ? catalogZip({
                'Curves-master/package.xml': _packageXml('Curves', '1.0.0'),
                'Curves-master/InitGui.py': 'gui',
              })
            : catalogZip({'Root-master/InitGui.py': 'gui'});
        return DownloadStream(bytes: bytesStream(bytes), contentLength: null);
      });
      final pip = FakePipRunner();
      final subject = controller(
        pipRunner: pip,
        pythonResolver: FakePythonEnvResolver('/opt/freecad/bin/python'),
        installer: AddonInstaller(
          downloader: Downloader(
            source: downloader,
            cacheDirectory: p.join(tempDirectory.path, 'dep-downloads'),
          ),
        ),
      );
      await subject.load();

      final result = await subject.install(
        addonId: 'Root',
        branchRef: 'master',
        profileId: 'profile-1',
        selection: AddonDependencySelection.requiredOnly,
      );

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      expect(pip.calls.single.packages, unorderedEquals(['tzlocal', 'numpy']));
      expect(await db.installedAddonsDao.getByAddon('profile-1', 'Curves'), isNotNull);
      final rootRow = await db.installedAddonsDao.getByAddon('profile-1', 'Root');
      expect(rootRow, isNotNull);
      expect(rootRow!.hasRequirements, isTrue);
      final packages = await db.pythonPackagesDao.getByProfile('profile-1');
      expect(packages.map((package) => package.name).toSet(), {'numpy', 'tzlocal'});
      expect(packages.firstWhere((package) => package.name == 'numpy').source, 'addon:Root');
      expect(packages.firstWhere((package) => package.name == 'tzlocal').source, 'addon:Curves');
      final mod = p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod');
      expect(Directory(p.join(mod, 'Root')).existsSync(), isTrue);
      expect(Directory(p.join(mod, 'Curves')).existsSync(), isTrue);
      subject.dispose();
    });

    test('runs pip inside the AppImage when FUSE is available', () async {
      catalog.result = AddonCatalogResult(
        addons: [
          addon('Root', dependencies: const [AddonDependency(name: 'tzlocal')]),
        ],
        freshness: CatalogFreshness.fresh,
      );
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({'Root-master/InitGui.py': 'gui'}),
      ]);
      final pip = FakePipRunner();
      final subject = controller(
        pipRunner: pip,
        pythonResolver: FakePythonEnvResolver('/opt/freecad/bin/python'),
        packageProbe: FakePackageProbe(const {}),
        fuseAvailable: () async => true,
      );
      await subject.load();

      final result = await subject.install(
        addonId: 'Root',
        branchRef: 'master',
        profileId: 'profile-1',
        selection: AddonDependencySelection.requiredOnly,
      );

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      expect(pip.calls.single.appImagePath, '/data/builds/build-1');
      expect(pip.calls.single.pythonPath, isNull);
      subject.dispose();
    });

    test('records skipped archive entries as install warnings', () async {
      catalog.result = AddonCatalogResult(
        addons: [addon('Root')],
        freshness: CatalogFreshness.fresh,
      );
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({'Root-master/InitGui.py': 'gui'}),
      ]);
      final installer = AddonInstaller(
        downloader: Downloader(
          source: downloadSource,
          cacheDirectory: p.join(tempDirectory.path, 'warning-downloads'),
        ),
        extractor: const SkippedLinkExtractor(),
      );
      final subject = controller(installer: installer);
      await subject.load();

      final result = await subject.install(
        addonId: 'Root',
        branchRef: 'master',
        profileId: 'profile-1',
        selection: AddonDependencySelection.none,
      );

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      expect(subject.installWarnings.value['Root'], ['docs/link -> ../x']);
      subject.dispose();
    });

    test('a cheap preparation does not cache fallback availability', () async {
      catalog.result = AddonCatalogResult(
        addons: [
          addon(
            'Root',
            dependencies: const [
              AddonDependency(name: 'requests'),
              AddonDependency(name: 'tzlocal'),
            ],
          ),
        ],
        freshness: CatalogFreshness.fresh,
      );
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({'Root-master/InitGui.py': 'gui'}),
      ]);
      final pip = FakePipRunner();
      final resolver = LazyPythonEnvResolver();
      final subject = controller(
        pipRunner: pip,
        pythonResolver: resolver,
        packageProbe: FakePackageProbe({'requests'}),
      );
      await subject.load();

      // No interpreter without extraction: the dialog phase lists every
      // candidate and must not cache them as unavailable.
      final plan = await subject.prepareDependencies(
        addonId: 'Root',
        branchRef: 'master',
        profileId: 'profile-1',
      );
      expect(
        plan.requiredPython.map((entry) => entry.requirement.name),
        containsAll(['requests', 'tzlocal']),
      );
      expect(resolver.extractionAllowed, isFalse);

      // The install phase may extract, probes for real and filters `requests`.
      final result = await subject.install(
        addonId: 'Root',
        branchRef: 'master',
        profileId: 'profile-1',
        selection: AddonDependencySelection.requiredOnly,
      );
      expect(result.isOk, isTrue);
      expect(resolver.extractionAllowed, isTrue);
      expect(pip.calls.single.packages, ['tzlocal']);
      subject.dispose();
    });

    test('filters Python packages already available through the probe', () async {
      catalog.result = AddonCatalogResult(
        addons: [
          addon(
            'Root',
            dependencies: const [
              AddonDependency(name: 'requests'),
              AddonDependency(name: 'tzlocal'),
            ],
          ),
        ],
        freshness: CatalogFreshness.fresh,
      );
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({'Root-master/InitGui.py': 'gui'}),
      ]);
      final pip = FakePipRunner();
      final subject = controller(
        pipRunner: pip,
        pythonResolver: FakePythonEnvResolver('/opt/freecad/bin/python'),
        packageProbe: FakePackageProbe({'requests'}),
      );
      await subject.load();

      final plan = await subject.prepareDependencies(
        addonId: 'Root',
        branchRef: 'master',
        profileId: 'profile-1',
      );
      expect(plan.requiredPython.map((entry) => entry.requirement.name), ['tzlocal']);

      final result = await subject.install(
        addonId: 'Root',
        branchRef: 'master',
        profileId: 'profile-1',
        selection: AddonDependencySelection.requiredOnly,
      );

      expect(result.isOk, isTrue);
      expect(pip.calls.single.packages, ['tzlocal']);
      final packages = await db.pythonPackagesDao.getByProfile('profile-1');
      expect(packages.single.name, 'tzlocal');
      subject.dispose();
    });

    test('keeps installing the addon when a dependent addon fails', () async {
      catalog.result = AddonCatalogResult(
        addons: [
          addon('Root', dependencies: const [AddonDependency(name: 'Broken')]),
          addon('Broken'),
        ],
        freshness: CatalogFreshness.fresh,
      );
      final downloader = FakeDownloadSourceWithResponses((uri) async {
        if (uri.path.contains('Broken')) {
          throw StateError('no network');
        }
        return DownloadStream(
          bytes: bytesStream(catalogZip({'Root-master/InitGui.py': 'gui'})),
          contentLength: null,
        );
      });
      final subject = controller(
        installer: AddonInstaller(
          downloader: Downloader(
            source: downloader,
            cacheDirectory: p.join(tempDirectory.path, 'dep-downloads'),
          ),
        ),
      );
      await subject.load();

      final result = await subject.install(
        addonId: 'Root',
        branchRef: 'master',
        profileId: 'profile-1',
        selection: AddonDependencySelection.requiredOnly,
      );

      expect(result.isOk, isTrue);
      expect(await db.installedAddonsDao.getByAddon('profile-1', 'Root'), isNotNull);
      expect(await db.installedAddonsDao.getByAddon('profile-1', 'Broken'), isNull);
      expect(subject.installErrors.value['Broken'], isNotNull);
      subject.dispose();
    });

    test('cancelling the dependency dialog aborts the install', () async {
      catalog.result = AddonCatalogResult(
        addons: [
          addon('Root', dependencies: const [AddonDependency(name: 'numpy')]),
        ],
        freshness: CatalogFreshness.fresh,
      );
      downloadSource.streamFactory = () => Stream.fromIterable([
        catalogZip({'Root-master/InitGui.py': 'gui'}),
      ]);
      final subject = controller();
      await subject.load();

      final result = await subject.install(
        addonId: 'Root',
        branchRef: 'master',
        profileId: 'profile-1',
        onDependencies: (_) async => null,
      );

      expect(result.isErr, isTrue);
      expect('${result.errorOrNull}', contains('cancelled'));
      expect(
        Directory(p.join(tempDirectory.path, 'profiles', 'profile-1', 'Mod', 'Root')).existsSync(),
        isFalse,
      );
      expect(await db.installedAddonsDao.getByAddon('profile-1', 'Root'), isNull);
      expect(subject.installErrors.value, isEmpty);
      subject.dispose();
    });

    test('reports dependents for removal warnings', () async {
      catalog.result = AddonCatalogResult(
        addons: [
          addon('A', dependencies: const [AddonDependency(name: 'B')]),
          addon('B'),
        ],
        freshness: CatalogFreshness.fresh,
      );
      await db.installedAddonsDao.save(
        sampleAddon(id: 'row-a', profileId: 'profile-1', addonId: 'A', displayName: 'A'),
      );
      await db.installedAddonsDao.save(
        sampleAddon(id: 'row-b', profileId: 'profile-1', addonId: 'B', displayName: 'B'),
      );
      final subject = controller();
      await subject.load();
      subject.start();
      await pumpEventQueue();

      expect(subject.dependentsOf('profile-1', 'B'), ['A']);
      expect(subject.dependentsOf('profile-1', 'A'), isEmpty);
      subject.dispose();
    });

    test('resolves package.xml depend tags from custom installs', () async {
      catalog.result = AddonCatalogResult(
        addons: [addon('Curves')],
        freshness: CatalogFreshness.fresh,
      );
      final downloader = FakeDownloadSourceWithResponses((uri) async {
        final bytes = uri.path.contains('Curves')
            ? catalogZip({'Curves-master/InitGui.py': 'gui'})
            : catalogZip({
                'MyAddon-main/package.xml': '''
<package format="1">
  <name>MyAddon</name>
  <version>1.0.0</version>
  <content>
    <workbench>
      <depend>Curves</depend>
      <depend type="python">tzlocal</depend>
    </workbench>
  </content>
</package>
''',
                'MyAddon-main/InitGui.py': 'gui',
              });
        return DownloadStream(bytes: bytesStream(bytes), contentLength: null);
      });
      final pip = FakePipRunner();
      final subject = controller(
        pipRunner: pip,
        pythonResolver: FakePythonEnvResolver('/opt/freecad/bin/python'),
        installer: AddonInstaller(
          downloader: Downloader(
            source: downloader,
            cacheDirectory: p.join(tempDirectory.path, 'dep-downloads'),
          ),
        ),
      );
      await subject.load();
      AddonDependencyPlan? seen;

      final result = await subject.installFromRepository(
        repositoryUrl: 'https://github.com/owner/MyAddon',
        gitRef: 'main',
        profileId: 'profile-1',
        onDependencies: (plan) async {
          seen = plan;
          return AddonDependencySelection.requiredOnly;
        },
      );

      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      expect(seen!.requiredAddons.single.addon!.id, 'Curves');
      expect(seen!.requiredPython.single.requirement.name, 'tzlocal');
      expect(pip.calls.single.packages, ['tzlocal']);
      expect(await db.installedAddonsDao.getByAddon('profile-1', 'Curves'), isNotNull);
      final row = await db.installedAddonsDao.getByAddon('profile-1', 'MyAddon');
      expect(row!.hasRequirements, isTrue);
      subject.dispose();
    });
  });
}

List<int> catalogZip(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return ZipEncoder().encode(archive);
}

String _packageXml(String name, String version) =>
    '''
<package format="1">
  <name>$name</name>
  <description>Test addon</description>
  <version>$version</version>
  <license>MIT</license>
  <content><workbench/></content>
</package>
''';

class FakePackageProbe extends PythonPackageProbe {
  FakePackageProbe(this.available)
    : super(processRunner: ProcessRunner(launcher: FakeProcessLauncher()));

  final Set<String> available;

  @override
  Future<Set<String>?> availablePackages({
    required String pythonPath,
    required String targetDirectory,
    required Iterable<String> names,
    Duration timeout = const Duration(seconds: 60),
  }) async => available;

  @override
  Future<Set<String>?> availablePackagesInFreeCad({
    required String executablePath,
    required String targetDirectory,
    required Iterable<String> names,
    Duration timeout = const Duration(seconds: 60),
  }) async => available;
}

class LazyPythonEnvResolver extends PythonEnvResolver {
  LazyPythonEnvResolver() : super(processRunner: ProcessRunner(launcher: FakeProcessLauncher()));

  bool? extractionAllowed;

  @override
  Future<String?> resolve({
    required BuildKind kind,
    required String buildDirectory,
    required String executablePath,
    String? storedPythonPath,
    bool allowExtraction = true,
    void Function(String line)? onOutput,
  }) async {
    extractionAllowed = allowExtraction;
    return allowExtraction ? '/opt/freecad/bin/python' : null;
  }
}

class SkippedLinkExtractor implements ArchiveExtractor {
  const SkippedLinkExtractor();

  @override
  Future<void> extract(
    String archivePath,
    String destination, {
    ArchiveWarningCallback? onWarning,
  }) async {
    final root = Directory(p.join(destination, 'Root'))..createSync(recursive: true);
    File(p.join(root.path, 'InitGui.py')).writeAsStringSync('gui');
    onWarning?.call(const SkippedArchiveEntry(path: 'docs/link', symlinkTarget: '../x'));
  }
}
