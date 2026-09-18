import 'dart:async';
import 'dart:io';

import 'package:signals_flutter/signals_flutter.dart';

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

  Future<void> remove(String buildId) async {
    await _database.buildsDao.deleteById(buildId);
    final buildDirectory = Directory(_paths.buildDir(buildId));
    if (buildDirectory.existsSync()) {
      buildDirectory.deleteSync(recursive: true);
    }
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
