import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/cancellation.dart';
import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/asset_classifier.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/build_installer.dart';
import 'package:freecad_launcher/platform/checksum.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';

class CustomImportException implements Exception {
  const CustomImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum InstallStage { downloading, verifying, installing }

class InstallProgress {
  const InstallProgress({required this.stage, this.fraction});

  final InstallStage stage;
  final double? fraction;
}

class BuildsController {
  BuildsController({
    required AppDatabase database,
    required ReleasesCatalog catalog,
    required Downloader downloader,
    required BuildInstaller installer,
    required AppPaths paths,
    required BuildPlatform platform,
    required String arch,
    DateTime Function()? clock,
  }) : _database = database,
       _catalog = catalog,
       _downloader = downloader,
       _installer = installer,
       _paths = paths,
       _platform = platform,
       _arch = arch,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final ReleasesCatalog _catalog;
  final Downloader _downloader;
  final BuildInstaller _installer;
  final AppPaths _paths;
  final BuildPlatform _platform;
  final String _arch;
  final DateTime Function() _clock;

  final installedBuilds = signal<List<Build>>([]);
  final availableBuilds = signal<List<BuildCandidate>>([]);
  final catalogFreshness = signal<CatalogFreshness?>(null);
  final catalogError = signal<AppError?>(null);
  final loadingCatalog = signal(false);
  final installProgress = signal<Map<String, InstallProgress>>({});
  final installErrors = signal<Map<String, AppError>>({});

  final Map<String, CancellationToken> _tokens = {};
  StreamSubscription<List<Build>>? _buildsSubscription;

  BuildPlatform get platform => _platform;

  String get arch => _arch;

  void start() {
    _buildsSubscription ??= _database.buildsDao.watchAll().listen(
      (builds) => installedBuilds.value = builds,
    );
    unawaited(reconcile());
  }

  Future<void> reconcile() async {
    final builds = await _database.buildsDao.getAll();
    for (final build in builds) {
      final status = _statusFor(build);
      if (status != build.status) {
        await _database.buildsDao.updateStatus(build.id, status);
      }
    }
  }

  BuildStatus _statusFor(Build build) {
    final executable = File(build.localPath);
    if (build.kind == BuildKind.custom) {
      return executable.existsSync() ? BuildStatus.installed : BuildStatus.missing;
    }
    final directory = Directory(_paths.buildDir(build.id));
    if (!directory.existsSync()) {
      return BuildStatus.missing;
    }
    if (!executable.existsSync()) {
      return BuildStatus.broken;
    }
    return BuildStatus.installed;
  }

  Future<Result<BuildStatus>> verify(String buildId) async {
    final build = await _database.buildsDao.getById(buildId);
    if (build == null) {
      return const Err(AppError(message: 'Build not found'));
    }

    var status = _statusFor(build);
    var verified = build.verified;
    final expected = build.sha256;
    if (status == BuildStatus.installed && expected != null && build.kind == BuildKind.appimage) {
      final actual = await sha256File(build.localPath);
      verified = actual == expected;
      if (!verified) {
        status = BuildStatus.broken;
      }
    }

    await _database.buildsDao.save(
      build.copyWith(status: status, verified: verified, updatedAt: _clock()),
    );
    return Ok(status);
  }

  Future<void> loadCatalog({bool forceRefresh = false}) async {
    loadingCatalog.value = true;
    catalogError.value = null;
    try {
      final result = await _catalog.load(forceRefresh: forceRefresh);
      final candidates = <BuildCandidate>[];
      final seen = <String>{};
      for (final release in result.releases) {
        for (final candidate in AssetClassifier.classify(release)) {
          if (candidate.channel != BuildChannel.stable ||
              candidate.platform != _platform ||
              candidate.arch != _arch) {
            continue;
          }
          if (seen.add(candidate.id)) {
            candidates.add(candidate);
          }
        }
      }
      candidates.sort((a, b) {
        final versionA = a.version;
        final versionB = b.version;
        if (versionA != null && versionB != null) {
          return versionB.compareTo(versionA);
        }
        return b.versionLabel.compareTo(a.versionLabel);
      });
      availableBuilds.value = candidates;
      catalogFreshness.value = result.freshness;
    } on Object catch (error) {
      catalogError.value = AppError.from(error, retryable: true);
      catalogFreshness.value = null;
    } finally {
      loadingCatalog.value = false;
    }
  }

  bool isInstalled(BuildCandidate candidate) {
    return installedBuilds.value.any((build) => build.id == candidate.id);
  }

  bool isInstalling(BuildCandidate candidate) {
    return installProgress.value.containsKey(candidate.id);
  }

  Future<Result<Build>> install(BuildCandidate candidate) async {
    final buildId = candidate.id;
    final token = CancellationToken();
    _tokens[buildId] = token;
    _setProgress(buildId, const InstallProgress(stage: InstallStage.downloading, fraction: 0));

    try {
      final expected = await _fetchExpectedChecksum(candidate, token);

      final download = await _downloader.download(
        uri: Uri.parse(candidate.downloadUrl),
        fileName: candidate.assetName,
        expectedSha256: expected,
        cancellationToken: token,
        onProgress: (progress) => _setProgress(
          buildId,
          InstallProgress(stage: InstallStage.downloading, fraction: progress.fraction),
        ),
      );

      _setProgress(buildId, const InstallProgress(stage: InstallStage.installing));
      final installed = await _installer.install(
        InstallRequest(
          buildId: buildId,
          kind: candidate.kind,
          archivePath: download.path,
          assetName: candidate.assetName,
          pythonVersionHint: candidate.pythonVersion,
        ),
      );

      final now = _clock();
      final build = Build(
        id: buildId,
        kind: candidate.kind,
        version: candidate.versionLabel,
        channel: candidate.channel,
        platform: candidate.platform,
        arch: candidate.arch,
        sourceUrl: candidate.downloadUrl,
        assetName: candidate.assetName,
        localPath: installed.executablePath,
        sha256: download.sha256,
        verified: expected != null,
        pythonVersion: installed.pythonVersion,
        sizeBytes: installed.sizeBytes,
        status: BuildStatus.installed,
        releaseNotesUrl: candidate.releaseNotesUrl,
        installedAt: now,
        updatedAt: now,
      );
      await _database.buildsDao.save(build);
      return Ok(build);
    } on Object catch (error) {
      final appError = error is AppError ? error : AppError.from(error, retryable: true);
      installErrors.value = {...installErrors.value, buildId: appError};
      return Err(appError);
    } finally {
      _tokens.remove(buildId);
      installProgress.value = {...installProgress.value}..remove(buildId);
    }
  }

  void cancelInstall(BuildCandidate candidate) {
    _tokens[candidate.id]?.cancel();
  }

  Future<Result<void>> remove(String buildId) async {
    final build = await _database.buildsDao.getById(buildId);
    if (build == null) {
      return const Err(AppError(message: 'Build not found'));
    }

    final profileCount = await _database.profilesDao.countByBuild(buildId);
    if (profileCount > 0) {
      return Err(
        AppError(
          message: 'This build is used by $profileCount profile(s)',
          detail: 'Remove or reassign those profiles first.',
        ),
      );
    }

    await _database.buildsDao.deleteById(buildId);
    if (build.kind != BuildKind.custom) {
      final buildDirectory = Directory(_paths.buildDir(buildId));
      if (buildDirectory.existsSync()) {
        buildDirectory.deleteSync(recursive: true);
      }
    }
    return const Ok(null);
  }

  Future<Result<Build>> importCustom({
    required String source,
    String? versionLabel,
    String? sha256,
    String? fileName,
    BuildKind? kind,
  }) async {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return const Err(AppError(message: 'Enter a file path or URL'));
    }

    final isUrl = trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final resolvedKind = kind ?? kindFromName(fileName ?? trimmed);
    final buildId = 'custom:${const Uuid().v4()}';
    final token = CancellationToken();
    _tokens[buildId] = token;
    _setProgress(buildId, const InstallProgress(stage: InstallStage.downloading, fraction: 0));

    try {
      var effectiveSha = sha256?.trim().toLowerCase();
      if (effectiveSha != null && effectiveSha.isEmpty) {
        effectiveSha = null;
      }

      final String executablePath;
      final int sizeBytes;
      String? pythonVersion;
      final String assetName = fileName ??
          (isUrl ? Uri.parse(trimmed).path.split('/').last : p.basename(trimmed));

      if (resolvedKind == BuildKind.custom) {
        if (isUrl) {
          throw const CustomImportException(
            'A custom executable must be a local file, not a URL',
          );
        }
        final file = File(trimmed);
        if (!file.existsSync()) {
          throw CustomImportException('File not found: $trimmed');
        }
        if (effectiveSha != null && await sha256File(file.path) != effectiveSha) {
          throw const ChecksumMismatchException(
            expected: 'the provided checksum',
            actual: 'the file content',
          );
        }
        executablePath = file.path;
        sizeBytes = await file.length();
      } else {
        String archivePath;
        if (isUrl) {
          final download = await _downloader.download(
            uri: Uri.parse(trimmed),
            fileName: fileName ?? Uri.parse(trimmed).path.split('/').last,
            expectedSha256: effectiveSha,
            cancellationToken: token,
          );
          archivePath = download.path;
          effectiveSha = download.sha256;
        } else {
          final file = File(trimmed);
          if (!file.existsSync()) {
            throw CustomImportException('File not found: $trimmed');
          }
          archivePath = file.path;
          final actual = await sha256File(file.path);
          if (effectiveSha != null && actual != effectiveSha) {
            throw ChecksumMismatchException(expected: effectiveSha, actual: actual);
          }
          effectiveSha ??= actual;
        }

        _setProgress(buildId, const InstallProgress(stage: InstallStage.installing));
        final installed = await _installer.install(
          InstallRequest(
            buildId: buildId,
            kind: resolvedKind,
            archivePath: archivePath,
            assetName: assetName,
            pythonVersionHint: null,
          ),
        );
        executablePath = installed.executablePath;
        sizeBytes = installed.sizeBytes;
        pythonVersion = installed.pythonVersion;
      }

      final label = (versionLabel != null && versionLabel.trim().isNotEmpty)
          ? versionLabel.trim()
          : assetName.split('.').first;
      final now = _clock();
      final build = Build(
        id: buildId,
        kind: resolvedKind,
        version: label,
        channel: BuildChannel.custom,
        platform: _platform,
        arch: _arch,
        sourceUrl: isUrl ? trimmed : null,
        assetName: assetName,
        localPath: executablePath,
        sha256: effectiveSha,
        verified: effectiveSha != null,
        pythonVersion: pythonVersion,
        sizeBytes: sizeBytes,
        status: BuildStatus.installed,
        releaseNotesUrl: null,
        installedAt: now,
        updatedAt: now,
      );
      await _database.buildsDao.save(build);
      return Ok(build);
    } on Object catch (error) {
      final appError = error is AppError ? error : AppError.from(error, retryable: true);
      installErrors.value = {...installErrors.value, buildId: appError};
      return Err(appError);
    } finally {
      _tokens.remove(buildId);
      installProgress.value = {...installProgress.value}..remove(buildId);
    }
  }

  static BuildKind kindFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.appimage')) {
      return BuildKind.appimage;
    }
    if (lower.endsWith('.dmg')) {
      return BuildKind.dmg;
    }
    if (lower.endsWith('.7z') ||
        lower.endsWith('.zip') ||
        lower.endsWith('.tar.gz') ||
        lower.endsWith('.tgz') ||
        lower.endsWith('.tar')) {
      return BuildKind.archive;
    }
    return BuildKind.custom;
  }

  void clearInstallError(String buildId) {
    installErrors.value = {...installErrors.value}..remove(buildId);
  }

  Future<String?> _fetchExpectedChecksum(BuildCandidate candidate, CancellationToken token) async {
    final checksumUrl = candidate.checksumUrl;
    if (checksumUrl == null) {
      return null;
    }
    try {
      final sidecar = await _downloader.download(
        uri: Uri.parse(checksumUrl),
        fileName: '${candidate.assetName}-SHA256.txt',
        cancellationToken: token,
      );
      return parseSha256Text(await File(sidecar.path).readAsString());
    } on Object {
      return null;
    }
  }

  void _setProgress(String buildId, InstallProgress progress) {
    installProgress.value = {...installProgress.value, buildId: progress};
  }

  void dispose() {
    _buildsSubscription?.cancel();
    _buildsSubscription = null;
  }
}
