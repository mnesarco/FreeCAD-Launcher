import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/asset_classifier.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/builds/release_info.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/build_installer.dart';
import 'package:freecad_launcher/platform/checksum.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/builds_controller.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_download.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

class FakeReleasesCatalog implements ReleasesCatalog {
  ReleasesCatalogResult? nextResult;
  Object? error;
  int loads = 0;

  @override
  Duration get ttl => const Duration(hours: 6);

  @override
  int get maxPages => 5;

  @override
  Future<ReleasesCatalogResult> load({bool forceRefresh = false}) async {
    loads++;
    if (error != null) {
      throw error!;
    }
    return nextResult ??
        const ReleasesCatalogResult(releases: [], freshness: CatalogFreshness.fresh);
  }
}

class FakeInstaller implements BuildInstaller {
  final List<InstallRequest> requests = [];
  InstalledBuild result = const InstalledBuild(
    directory: '/data/builds/x',
    executablePath: '/data/builds/x/FreeCAD',
    sizeBytes: 100,
    pythonVersion: '3.11',
  );
  Object? error;

  @override
  Future<InstalledBuild> install(InstallRequest request) async {
    if (error != null) {
      throw error!;
    }
    requests.add(request);
    return result;
  }
}

void main() {
  late Directory tempDirectory;
  late AppPaths paths;
  late AppDatabase database;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_builds_controller_test');
    paths = AppPaths(dataRoot: tempDirectory.path);
    database = createTestDatabase();
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  BuildCandidate candidate({String? checksumUrl, String version = '1.1.3'}) {
    return BuildCandidate(
      versionLabel: version,
      channel: BuildChannel.stable,
      platform: BuildPlatform.linux,
      arch: BuildArch.x86_64,
      kind: BuildKind.appimage,
      assetName: 'FreeCAD_$version-Linux-x86_64-py311.AppImage',
      downloadUrl: 'https://example.invalid/$version.AppImage',
      sizeBytes: 1000,
      pythonVersion: '3.11',
      checksumUrl: checksumUrl,
      releaseNotesUrl: 'https://example.invalid/notes',
    );
  }

  BuildsController buildController({
    FakeDownloadSourceWithResponses? source,
    FakeInstaller? installer,
    FakeReleasesCatalog? catalog,
  }) {
    final downloader = Downloader(
      source: source ??
          FakeDownloadSourceWithResponses(
            (uri) async => DownloadStream(
              bytes: bytesStream(utf8.encode('data')),
              contentLength: 4,
            ),
          ),
      cacheDirectory: paths.downloadsCacheDir,
    );
    return BuildsController(
      database: database,
      catalog: catalog ?? FakeReleasesCatalog(),
      downloader: downloader,
      installer: installer ?? FakeInstaller(),
      paths: paths,
      platform: BuildPlatform.linux,
      arch: BuildArch.x86_64,
      clock: () => DateTime.utc(2026, 9, 18),
    );
  }

  List<ReleaseInfo> fixtureReleases(List<String> fixtures) {
    return [
      for (final fixture in fixtures)
        ...parseReleasesJson(loadFixture(fixture)),
    ];
  }

  test('start mirrors installed builds from the database', () async {
    final controller = buildController();
    controller.start();

    await database.buildsDao.save(sampleBuild());
    await Future<void>.delayed(Duration.zero);

    expect(controller.installedBuilds.value, hasLength(1));
    expect(controller.installedBuilds.value.single.id, 'build-1');
    controller.dispose();
  });

  test('loadCatalog keeps stable candidates for host platform and arch', () async {
    final catalog = FakeReleasesCatalog()
      ..nextResult = ReleasesCatalogResult(
        releases: fixtureReleases([
          'github_releases_1.1.3.json',
          'github_releases_1.0.2.json',
          'github_releases_weekly.json',
        ]),
        freshness: CatalogFreshness.refreshed,
      );
    final controller = buildController(catalog: catalog);

    await controller.loadCatalog();

    final candidates = controller.availableBuilds.value;
    expect(candidates, hasLength(1));
    expect(candidates.single.versionLabel, '1.1.3');
    expect(candidates.single.platform, BuildPlatform.linux);
    expect(candidates.single.arch, BuildArch.x86_64);
    expect(controller.catalogFreshness.value, CatalogFreshness.refreshed);
  });

  test('loadCatalog surfaces stale catalogs', () async {
    final catalog = FakeReleasesCatalog()
      ..nextResult = ReleasesCatalogResult(
        releases: fixtureReleases(['github_releases_1.1.3.json']),
        freshness: CatalogFreshness.stale,
        error: const SocketException('offline'),
      );
    final controller = buildController(catalog: catalog);

    await controller.loadCatalog();

    expect(controller.catalogFreshness.value, CatalogFreshness.stale);
    expect(controller.catalogError.value, isNull);
    expect(controller.availableBuilds.value, isNotEmpty);
  });

  test('loadCatalog records errors', () async {
    final catalog = FakeReleasesCatalog()..error = const CatalogUnavailableException('offline');
    final controller = buildController(catalog: catalog);

    await controller.loadCatalog();

    expect(controller.catalogError.value, isNotNull);
    expect(controller.loadingCatalog.value, isFalse);
    expect(controller.availableBuilds.value, isEmpty);
  });

  test('install downloads, installs and stores the build', () async {
    final installer = FakeInstaller();
    final controller = buildController(installer: installer);
    final buildCandidate = candidate();

    final result = await controller.install(buildCandidate);

    expect(result, isA<Ok<Build>>());
    expect(installer.requests, hasLength(1));
    expect(installer.requests.single.kind, BuildKind.appimage);
    expect(installer.requests.single.pythonVersionHint, '3.11');

    final stored = await database.buildsDao.getById(buildCandidate.id);
    expect(stored, isNotNull);
    expect(stored!.version, '1.1.3');
    expect(stored.localPath, '/data/builds/x/FreeCAD');
    expect(stored.pythonVersion, '3.11');
    expect(stored.verified, isFalse);
    expect(stored.installedAt, DateTime.utc(2026, 9, 18));
    expect(controller.installProgress.value, isEmpty);
    expect(controller.installErrors.value, isEmpty);
  });

  test('install verifies the checksum sidecar when present', () async {
    final data = utf8.encode('data');
    final expected = sha256OfBytes(data);
    final source = FakeDownloadSourceWithResponses((uri) async {
      if (uri.path.endsWith('-SHA256.txt')) {
        return DownloadStream(
          bytes: bytesStream(utf8.encode('$expected  FreeCAD.AppImage\n')),
          contentLength: expected.length,
        );
      }
      return DownloadStream(bytes: bytesStream(data), contentLength: data.length);
    });
    final installer = FakeInstaller();
    final controller = buildController(source: source, installer: installer);

    final result = await controller.install(
      candidate(checksumUrl: 'https://example.invalid/FreeCAD.AppImage-SHA256.txt'),
    );

    expect(result, isA<Ok<Build>>());
    final stored = await database.buildsDao.getById(candidate().id);
    expect(stored!.verified, isTrue);
    expect(stored.sha256, expected);
  });

  test('install records failures without storing anything', () async {
    final installer = FakeInstaller()..error = const ArchiveExtractionException('boom');
    final controller = buildController(installer: installer);
    final buildCandidate = candidate();

    final result = await controller.install(buildCandidate);

    expect(result, isA<Err<Build>>());
    expect(controller.installErrors.value.containsKey(buildCandidate.id), isTrue);
    expect(controller.installProgress.value, isEmpty);
    expect(await database.buildsDao.getById(buildCandidate.id), isNull);
  });

  test('remove deletes the database row and the build directory', () async {
    final buildDirectory = Directory(paths.buildDir('build-1'))..createSync(recursive: true);
    File(p.join(buildDirectory.path, 'FreeCAD.AppImage')).writeAsStringSync('');
    await database.buildsDao.save(sampleBuild(id: 'build-1'));
    final controller = buildController();

    await controller.remove('build-1');

    expect(await database.buildsDao.getById('build-1'), isNull);
    expect(buildDirectory.existsSync(), isFalse);
  });
}
