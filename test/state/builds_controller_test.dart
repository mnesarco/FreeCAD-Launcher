import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/asset_classifier.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/builds/release_info.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/build_installer.dart';
import 'package:freecad_launcher/platform/checksum.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/python_probe.dart';
import 'package:freecad_launcher/state/builds_controller.dart';
import 'package:freecad_launcher/state/jobs_controller.dart';
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
    pythonPath: '/data/builds/x/bin/python3.11',
  );
  Object? error;

  @override
  Future<InstalledBuild> install(InstallRequest request) async {
    if (error != null) {
      throw error!;
    }
    requests.add(request);
    request.onDetectingPython?.call();
    return result;
  }
}

class FakePythonProbe implements PythonProbe {
  final List<String> freeCadCalls = [];
  final List<String> interpreterCalls = [];
  PythonDetection fromFreeCadResult = const PythonDetection(reason: 'not detected');
  PythonDetection interpreterResult = const PythonDetection(reason: 'not detected');

  @override
  Future<PythonDetection> detect({
    required BuildKind kind,
    required String installDirectory,
    required String executablePath,
    String? knownVersion,
  }) async {
    return const PythonDetection(reason: 'unused');
  }

  @override
  Future<PythonDetection> detectFromFreeCad({required String executablePath}) async {
    freeCadCalls.add(executablePath);
    return fromFreeCadResult;
  }

  @override
  Future<PythonDetection> detectInterpreter({required String executablePath}) async {
    interpreterCalls.add(executablePath);
    return interpreterResult;
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
    PythonProbe? pythonProbe,
    JobsController? jobs,
    BuildPlatform platform = BuildPlatform.linux,
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
      platform: platform,
      arch: BuildArch.x86_64,
      pythonProbe: pythonProbe,
      jobs: jobs,
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

  test('install runs as a job and stays retryable', () async {
    final jobs = JobsController();
    final installer = FakeInstaller();
    final controller = buildController(installer: installer, jobs: jobs);

    final result = await controller.install(candidate());

    expect(result, isA<Ok<Build>>());
    final job = jobs.jobs.value.single;
    expect(job.state, JobState.completed);
    expect(job.label, contains('1.1.3'));
    expect(job.fraction, 1);
    expect(jobs.canRetry(job.id), isTrue);
    expect(jobs.activeJobs, isEmpty);
    jobs.dispose();
    controller.dispose();
  });

  test('install failures mark the job as failed', () async {
    final jobs = JobsController();
    final installer = FakeInstaller()..error = StateError('disk full');
    final controller = buildController(installer: installer, jobs: jobs);

    final result = await controller.install(candidate());

    expect(result, isA<Err<Build>>());
    final job = jobs.jobs.value.single;
    expect(job.state, JobState.failed);
    expect(job.error, contains('disk full'));
    jobs.dispose();
    controller.dispose();
  });

  test('cancelling an install job aborts the download and cleans up', () async {
    final jobs = JobsController();
    final chunks = StreamController<List<int>>();
    final source = FakeDownloadSourceWithResponses(
      (uri) async => DownloadStream(bytes: chunks.stream, contentLength: 8192),
    );
    final controller = buildController(source: source, jobs: jobs);

    final installFuture = controller.install(candidate());
    await pumpEventQueue();
    chunks.add(List<int>.filled(4096, 1));
    await pumpEventQueue();

    jobs.cancel(jobs.jobs.value.single.id);
    chunks.add(List<int>.filled(4096, 2));
    await chunks.close();

    final result = await installFuture;
    expect(result, isA<Err<Build>>());
    expect(jobs.jobs.value.single.state, JobState.cancelled);
    final downloads = Directory(paths.downloadsCacheDir);
    final leftovers =
        downloads.existsSync() ? downloads.listSync().whereType<File>().toList() : <File>[];
    expect(leftovers, isEmpty);
    expect(await database.buildsDao.getById(candidate().id), isNull);
    jobs.dispose();
    controller.dispose();
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

  test('reports downloaded bytes and totals in install progress', () async {
    final data = utf8.encode('data');
    final source = FakeDownloadSourceWithResponses(
      (uri) async => DownloadStream(bytes: bytesStream(data), contentLength: data.length),
    );
    final controller = buildController(source: source);
    final buildId = candidate().id;
    final seen = <InstallProgress>[];
    final dispose = controller.installProgress.subscribe((progressByBuild) {
      final entry = progressByBuild[buildId];
      if (entry != null) {
        seen.add(entry);
      }
    });

    await controller.install(candidate());
    dispose();

    expect(
      seen.any(
        (progress) =>
            progress.receivedBytes == data.length && progress.totalBytes == data.length,
      ),
      isTrue,
    );
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

    final result = await controller.remove('build-1');

    expect(result.isOk, isTrue);
    expect(await database.buildsDao.getById('build-1'), isNull);
    expect(buildDirectory.existsSync(), isFalse);
  });

  test('remove is blocked while profiles use the build', () async {
    final buildDirectory = Directory(paths.buildDir('build-1'))..createSync(recursive: true);
    await database.buildsDao.save(sampleBuild(id: 'build-1'));
    await database.profilesDao.save(sampleProfile(buildId: 'build-1'));
    final controller = buildController();

    final result = await controller.remove('build-1');

    expect(result.isErr, isTrue);
    expect(result.errorOrNull!.message, contains('used by 1 profile'));
    expect(await database.buildsDao.getById('build-1'), isNotNull);
    expect(buildDirectory.existsSync(), isTrue);
  });

  test('verify confirms a matching AppImage hash', () async {
    final buildDirectory = Directory(paths.buildDir('build-1'))..createSync(recursive: true);
    final executable = File(p.join(buildDirectory.path, 'FreeCAD.AppImage'))
      ..writeAsStringSync('data');
    await database.buildsDao.save(
      sampleBuild(id: 'build-1').copyWith(
        localPath: executable.path,
        sha256: Value(sha256OfBytes(utf8.encode('data'))),
      ),
    );
    final controller = buildController();

    final result = await controller.verify('build-1');

    expect(result.valueOrNull, BuildStatus.installed);
    final stored = (await database.buildsDao.getById('build-1'))!;
    expect(stored.verified, isTrue);
    expect(stored.status, BuildStatus.installed);
  });

  test('verify marks a hash mismatch as broken', () async {
    final buildDirectory = Directory(paths.buildDir('build-1'))..createSync(recursive: true);
    final executable = File(p.join(buildDirectory.path, 'FreeCAD.AppImage'))
      ..writeAsStringSync('tampered');
    await database.buildsDao.save(
      sampleBuild(id: 'build-1').copyWith(
        localPath: executable.path,
        sha256: Value(sha256OfBytes(utf8.encode('data'))),
      ),
    );
    final controller = buildController();

    final result = await controller.verify('build-1');

    expect(result.valueOrNull, BuildStatus.broken);
    expect((await database.buildsDao.getById('build-1'))!.verified, isFalse);
  });

  test('verify marks missing files', () async {
    await database.buildsDao.save(sampleBuild(id: 'build-1'));
    final controller = buildController();

    final result = await controller.verify('build-1');

    expect(result.valueOrNull, BuildStatus.missing);
  });

  test('reconcile marks missing and broken builds', () async {
    final buildDirectory = Directory(paths.buildDir('build-1'))..createSync(recursive: true);
    final executable = File(p.join(buildDirectory.path, 'FreeCAD.AppImage'))
      ..writeAsStringSync('');
    await database.buildsDao.save(
      sampleBuild(id: 'build-1').copyWith(localPath: executable.path),
    );
    await database.buildsDao.save(
      sampleBuild(id: 'build-2', version: '1.1.4').copyWith(
        localPath: p.join(paths.buildDir('build-2'), 'FreeCAD.AppImage'),
      ),
    );
    final controller = buildController();

    await controller.reconcile();
    expect((await database.buildsDao.getById('build-1'))!.status, BuildStatus.installed);
    expect((await database.buildsDao.getById('build-2'))!.status, BuildStatus.missing);

    executable.deleteSync();
    await controller.reconcile();
    expect((await database.buildsDao.getById('build-1'))!.status, BuildStatus.broken);
  });

  test('imports a local AppImage without hashing when no checksum is given', () async {
    final sourceFile = File(p.join(tempDirectory.path, 'MyBuild.AppImage'))
      ..writeAsStringSync('data');
    if (!Platform.isWindows) {
      Process.runSync('chmod', ['755', sourceFile.path]);
    }
    final installer = FakeInstaller();
    final controller = buildController(
      installer: installer,
      platform: Platform.isWindows ? BuildPlatform.windows : BuildPlatform.linux,
    );

    final result = await controller.importCustom(
      source: sourceFile.path,
      versionLabel: 'My Build',
      kind: BuildKind.appimage,
    );

    expect(result.isOk, isTrue);
    final build = result.valueOrNull!;
    expect(build.channel, BuildChannel.custom);
    expect(build.version, 'My Build');
    expect(build.kind, BuildKind.appimage);
    expect(build.localPath, '/data/builds/x/FreeCAD');
    expect(build.sha256, isNull);
    expect(build.verified, isFalse);
    expect(installer.requests, hasLength(1));
    expect(installer.requests.single.referenceInPlace, isTrue);
    expect(await database.buildsDao.getById(build.id), isNotNull);
  });

  test('hashes and verifies a local AppImage only when a checksum is given', () async {
    final data = utf8.encode('data');
    final sourceFile = File(p.join(tempDirectory.path, 'MyBuild.AppImage'))
      ..writeAsStringSync('data');
    if (!Platform.isWindows) {
      Process.runSync('chmod', ['755', sourceFile.path]);
    }
    final controller = buildController(
      platform: Platform.isWindows ? BuildPlatform.windows : BuildPlatform.linux,
    );

    final result = await controller.importCustom(
      source: sourceFile.path,
      sha256: sha256OfBytes(data),
      kind: BuildKind.appimage,
    );

    expect(result.isOk, isTrue);
    expect(result.valueOrNull!.sha256, sha256OfBytes(data));
    expect(result.valueOrNull!.verified, isTrue);
  });

  test('rejects a local AppImage with a wrong checksum', () async {
    final sourceFile = File(p.join(tempDirectory.path, 'MyBuild.AppImage'))
      ..writeAsStringSync('data');
    if (!Platform.isWindows) {
      Process.runSync('chmod', ['755', sourceFile.path]);
    }
    final controller = buildController(
      platform: Platform.isWindows ? BuildPlatform.windows : BuildPlatform.linux,
    );

    final result = await controller.importCustom(
      source: sourceFile.path,
      sha256: sha256OfBytes(utf8.encode('other')),
    );

    expect(result.isErr, isTrue);
    expect(await database.buildsDao.getAll(), isEmpty);
  });

  test('reports hashing, installing and detecting stages for a local import', () async {
    final data = utf8.encode('data');
    final sourceFile = File(p.join(tempDirectory.path, 'MyBuild.AppImage'))
      ..writeAsStringSync('data');
    if (!Platform.isWindows) {
      Process.runSync('chmod', ['755', sourceFile.path]);
    }
    final probe = FakePythonProbe()
      ..fromFreeCadResult = const PythonDetection(
        python: BundledPython(executablePath: '/opt/python3.11', version: '3.11'),
      );
    final controller = buildController(
      installer: FakeInstaller(),
      pythonProbe: probe,
      platform: Platform.isWindows ? BuildPlatform.windows : BuildPlatform.linux,
    );
    final stages = <InstallStage>[];
    final dispose = controller.installProgress.subscribe((progressByBuild) {
      for (final entry in progressByBuild.entries) {
        if (entry.key.startsWith('custom:')) {
          if (stages.isEmpty || stages.last != entry.value.stage) {
            stages.add(entry.value.stage);
          }
        }
      }
    });

    await controller.importCustom(source: sourceFile.path, sha256: sha256OfBytes(data));
    dispose();

    expect(
      stages,
      containsAllInOrder([
        InstallStage.hashing,
        InstallStage.installing,
        InstallStage.detectingPython,
      ]),
    );
  });

  test('downloads a URL AppImage as a managed copy', () async {
    final installer = FakeInstaller();
    final controller = buildController(installer: installer);

    final result = await controller.importCustom(
      source: 'https://example.invalid/MyBuild.AppImage',
      fileName: 'MyBuild.AppImage',
      kind: BuildKind.appimage,
    );

    expect(result.isOk, isTrue);
    expect(installer.requests.single.referenceInPlace, isFalse);
  });

  test('rejects a non-executable local AppImage', () async {
    if (Platform.isWindows) {
      return;
    }
    final sourceFile = File(p.join(tempDirectory.path, 'MyBuild.AppImage'))
      ..writeAsStringSync('data');
    Process.runSync('chmod', ['644', sourceFile.path]);
    final controller = buildController();

    final result = await controller.importCustom(source: sourceFile.path);

    expect(result.isErr, isTrue);
    expect('${result.errorOrNull}', contains('not executable'));
    expect(await database.buildsDao.getAll(), isEmpty);
  });

  test('imports a URL archive with a checksum', () async {
    final data = utf8.encode('data');
    final expected = sha256OfBytes(data);
    final source = FakeDownloadSourceWithResponses(
      (uri) async => DownloadStream(bytes: bytesStream(data), contentLength: data.length),
    );
    final installer = FakeInstaller();
    final controller = buildController(source: source, installer: installer);

    final result = await controller.importCustom(
      source: 'https://example.invalid/FreeCAD.7z',
      fileName: 'FreeCAD.7z',
      sha256: expected,
      kind: BuildKind.archive,
    );

    expect(result.isOk, isTrue);
    expect(source.requests.single.toString(), 'https://example.invalid/FreeCAD.7z');
    expect(result.valueOrNull!.sourceUrl, 'https://example.invalid/FreeCAD.7z');
    expect(result.valueOrNull!.verified, isTrue);
    expect(installer.requests.single.archivePath, p.join(paths.downloadsCacheDir, 'FreeCAD.7z'));
  });

  test('registers a custom executable without installing', () async {
    final executable = File(p.join(tempDirectory.path, 'my-freecad'))..writeAsStringSync('bin');
    if (!Platform.isWindows) {
      Process.runSync('chmod', ['755', executable.path]);
    }
    final installer = FakeInstaller();
    final controller = buildController(
      installer: installer,
      platform: Platform.isWindows ? BuildPlatform.windows : BuildPlatform.linux,
    );

    final result = await controller.importCustom(source: executable.path);

    expect(result.isOk, isTrue);
    expect(result.valueOrNull!.kind, BuildKind.custom);
    expect(result.valueOrNull!.localPath, executable.path);
    expect(result.valueOrNull!.verified, isFalse);
    expect(installer.requests, isEmpty);
  });

  test('detects Python for a custom executable and references it in place', () async {
    final executable = File(p.join(tempDirectory.path, 'FreeCAD'))
      ..writeAsStringSync('bin');
    if (!Platform.isWindows) {
      Process.runSync('chmod', ['755', executable.path]);
    }
    final probe = FakePythonProbe()
      ..fromFreeCadResult = const PythonDetection(
        python: BundledPython(
          executablePath: '/opt/freecad/bin/python3.11',
          version: '3.11',
        ),
      );
    final controller = buildController(
      pythonProbe: probe,
      platform: Platform.isWindows ? BuildPlatform.windows : BuildPlatform.linux,
    );

    final result = await controller.importCustom(source: executable.path);

    expect(result.isOk, isTrue);
    final build = result.valueOrNull!;
    expect(build.localPath, executable.path);
    expect(build.pythonVersion, '3.11');
    expect(build.pythonPath, '/opt/freecad/bin/python3.11');
    expect(probe.freeCadCalls, [executable.path]);
    expect(Directory(p.join(paths.buildsDir, build.id)).existsSync(), isFalse);
  });

  test('rejects a custom executable without the executable bit', () async {
    if (Platform.isWindows) {
      return;
    }
    final executable = File(p.join(tempDirectory.path, 'not-executable'))
      ..writeAsStringSync('bin');
    Process.runSync('chmod', ['644', executable.path]);
    final controller = buildController();

    final result = await controller.importCustom(source: executable.path);

    expect(result.isErr, isTrue);
    expect('${result.errorOrNull}', contains('not executable'));
    expect(await database.buildsDao.getAll(), isEmpty);
  });

  test('rejects a directory as a custom executable', () async {
    final directory = Directory(p.join(tempDirectory.path, 'some-dir'))..createSync();
    final controller = buildController();

    final result = await controller.importCustom(source: directory.path);

    expect(result.isErr, isTrue);
    expect('${result.errorOrNull}', contains('Not an executable file'));
  });

  test('setCustomPython probes the interpreter and stores it', () async {
    final executable = File(p.join(tempDirectory.path, 'FreeCAD'))
      ..writeAsStringSync('bin');
    if (!Platform.isWindows) {
      Process.runSync('chmod', ['755', executable.path]);
    }
    final probe = FakePythonProbe();
    final controller = buildController(
      pythonProbe: probe,
      platform: Platform.isWindows ? BuildPlatform.windows : BuildPlatform.linux,
    );
    final imported = await controller.importCustom(source: executable.path);
    expect(imported.isOk, isTrue);
    final build = imported.valueOrNull!;
    expect(build.pythonVersion, isNull);

    final pythonFile = File(p.join(tempDirectory.path, 'python3'))..createSync();
    probe.interpreterResult = PythonDetection(
      python: BundledPython(executablePath: pythonFile.path, version: '3.11'),
    );
    final result = await controller.setCustomPython(
      buildId: build.id,
      pythonExecutable: pythonFile.path,
    );

    expect(result.isOk, isTrue);
    expect(result.valueOrNull!.pythonVersion, '3.11');
    expect(result.valueOrNull!.pythonPath, pythonFile.path);
    expect(probe.interpreterCalls, [pythonFile.path]);
    expect(
      (await database.buildsDao.getById(build.id))!.pythonPath,
      pythonFile.path,
    );
  });

  test('setCustomPython reports interpreter probe failures', () async {
    await database.buildsDao.save(sampleBuild(id: 'custom:1', kind: BuildKind.custom));
    final probe = FakePythonProbe()
      ..interpreterResult = const PythonDetection(reason: 'not a Python interpreter');
    final controller = buildController(pythonProbe: probe);

    final result = await controller.setCustomPython(
      buildId: 'custom:1',
      pythonExecutable: '/bin/false',
    );

    expect(result.isErr, isTrue);
    expect('${result.errorOrNull}', contains('not a Python interpreter'));
    controller.dispose();
  });

  test('import fails for a missing local file', () async {
    final controller = buildController();

    final result = await controller.importCustom(
      source: p.join(tempDirectory.path, 'missing.AppImage'),
    );

    expect(result.isErr, isTrue);
    expect(await database.buildsDao.getAll(), isEmpty);
  });
}
