// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/cancellation.dart';
import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/asset_classifier.dart';
import 'package:freecad_launcher/domain/builds/build_label_rules.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/platform/build_installer.dart';
import 'package:freecad_launcher/platform/checksum.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/python_probe.dart';
import 'package:freecad_launcher/state/jobs_controller.dart';

class CustomImportException implements Exception {
  const CustomImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum InstallStage { hashing, downloading, installing, detectingPython }

class InstallProgress {
  const InstallProgress({
    required this.stage,
    this.fraction,
    this.receivedBytes,
    this.totalBytes,
    this.bytesPerSecond,
  });

  final InstallStage stage;
  final double? fraction;
  final int? receivedBytes;
  final int? totalBytes;
  final int? bytesPerSecond;
}

class BuildsController {
  static const int weeklyBuildLimit = 52;

  BuildsController({
    required AppDatabase database,
    required ReleasesCatalog catalog,
    required Downloader downloader,
    required BuildInstaller installer,
    required AppPaths paths,
    required BuildPlatform platform,
    required String arch,
    PythonProbe? pythonProbe,
    JobsController? jobs,
    DateTime Function()? clock,
  }) : _database = database,
       _catalog = catalog,
       _downloader = downloader,
       _installer = installer,
       _paths = paths,
       _platform = platform,
       _arch = arch,
       _pythonProbe = pythonProbe,
       _jobs = jobs,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final ReleasesCatalog _catalog;
  final Downloader _downloader;
  final BuildInstaller _installer;
  final AppPaths _paths;
  final BuildPlatform _platform;
  final String _arch;
  final PythonProbe? _pythonProbe;
  final JobsController? _jobs;
  final DateTime Function() _clock;

  final installedBuilds = signal<List<Build>>([]);
  final availableBuilds = signal<List<BuildCandidate>>([]);
  final weeklyBuilds = signal<List<BuildCandidate>>([]);
  final catalogFreshness = signal<CatalogFreshness?>(null);
  final catalogError = signal<AppError?>(null);
  final loadingCatalog = signal(false);
  final installProgress = signal<Map<String, InstallProgress>>({});
  final installErrors = signal<Map<String, AppError>>({});

  final Map<String, CancellationToken> _tokens = {};
  final Map<String, DateTime> _downloadStartedAt = {};
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
    final stopwatch = Stopwatch()..start();
    loadingCatalog.value = true;
    catalogError.value = null;
    try {
      final result = await _catalog.load(forceRefresh: forceRefresh);
      final stableCandidates = <BuildCandidate>[];
      final weeklyCandidates = <BuildCandidate>[];
      final seen = <String>{};
      for (final release in result.releases) {
        final classified = AssetClassifier.classify(release);
        if (classified.isEmpty) {
          continue;
        }
        final candidate = AssetClassifier.selectFor(
          classified,
          platform: _platform,
          arch: _arch,
        );
        if (candidate == null || !seen.add(candidate.id)) {
          continue;
        }
        switch (candidate.channel) {
          case BuildChannel.stable:
            stableCandidates.add(candidate);
          case BuildChannel.weekly:
            if (candidate.weekly != null) {
              weeklyCandidates.add(candidate);
            }
          case BuildChannel.legacy:
          case BuildChannel.custom:
            break;
        }
      }
      stableCandidates.sort((a, b) {
        final versionA = a.version;
        final versionB = b.version;
        if (versionA != null && versionB != null) {
          return versionB.compareTo(versionA);
        }
        return b.versionLabel.compareTo(a.versionLabel);
      });
      weeklyCandidates.sort((a, b) => b.weekly!.compareTo(a.weekly!));
      availableBuilds.value = stableCandidates;
      weeklyBuilds.value = weeklyCandidates.take(weeklyBuildLimit).toList();
      catalogFreshness.value = result.freshness;
      appLogger.info(
        'releases catalog: ${result.releases.length} releases, '
        '${stableCandidates.length} stable + ${weeklyCandidates.length} weekly '
        'candidates in ${stopwatch.elapsedMilliseconds} ms',
        tag: 'perf',
      );
    } on Object catch (error, stackTrace) {
      appLogger.error(
        'releases catalog load failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'catalog',
      );
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
    final jobs = _jobs;
    if (jobs == null) {
      return _installLocked(candidate, null);
    }
    final result = await jobs.run<Result<Build>>(
      kind: JobKind.install,
      label: 'Install FreeCAD ${candidate.versionLabel}',
      onRetry: () async {
        await install(candidate);
      },
      task: (context) => _installLocked(candidate, context),
    );
    return result ?? const Err(AppError(message: 'Install cancelled'));
  }

  Future<Result<Build>> _installLocked(
    BuildCandidate candidate,
    JobContext? context,
  ) async {
    final buildId = candidate.id;
    final token = CancellationToken();
    _tokens[buildId] = token;
    context?.token.addListener(token.cancel);
    _startDownloadTracking(buildId);
    _setProgress(buildId, const InstallProgress(stage: InstallStage.downloading, fraction: 0), context: context);

    try {
      final expected = await _fetchExpectedChecksum(candidate, token);

      final download = await _downloader.download(
        uri: Uri.parse(candidate.downloadUrl),
        fileName: candidate.assetName,
        expectedSha256: expected,
        cancellationToken: token,
        onProgress: (progress) => _onDownloadProgress(buildId, progress, context: context),
      );

      _setProgress(buildId, const InstallProgress(stage: InstallStage.installing), context: context);
      final installed = await _installer.install(
        InstallRequest(
          buildId: buildId,
          kind: candidate.kind,
          archivePath: download.path,
          assetName: candidate.assetName,
          pythonVersionHint: candidate.pythonVersion,
          onDetectingPython: () => _setProgress(
            buildId,
            const InstallProgress(stage: InstallStage.detectingPython),
            context: context,
          ),
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
        pythonPath: installed.pythonPath,
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
      context?.fail(appError.message);
      return Err(appError);
    } finally {
      _tokens.remove(buildId);
      _downloadStartedAt.remove(buildId);
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
    final assetName = fileName ??
        (isUrl ? Uri.parse(trimmed).path.split('/').last : p.basename(trimmed));
    final label = (versionLabel != null && versionLabel.trim().isNotEmpty)
        ? versionLabel.trim()
        : assetName.split('.').first;
    final existing = await _database.buildsDao.findByKey(
      platform: _platform,
      arch: _arch,
      channel: BuildChannel.custom,
      version: label,
      assetName: assetName,
    );
    final buildId = existing?.id ?? 'custom:${const Uuid().v4()}';
    final token = CancellationToken();
    _tokens[buildId] = token;
    if (isUrl) {
      _startDownloadTracking(buildId);
      _setProgress(buildId, const InstallProgress(stage: InstallStage.downloading, fraction: 0));
    }

    try {
      var effectiveSha = sha256?.trim().toLowerCase();
      if (effectiveSha != null && effectiveSha.isEmpty) {
        effectiveSha = null;
      }

      final String executablePath;
      final int sizeBytes;
      String? pythonVersion;
      String? pythonPath;

      if (resolvedKind == BuildKind.custom) {
        if (isUrl) {
          throw const CustomImportException(
            'A custom executable must be a local file, not a URL',
          );
        }
        final file = _validatedExecutable(trimmed);
        if (effectiveSha != null) {
          final actual = await _hashWithProgress(buildId, file.path);
          if (actual != effectiveSha) {
            throw ChecksumMismatchException(expected: effectiveSha, actual: actual);
          }
        }
        executablePath = file.path;
        sizeBytes = await file.length();
        if (_pythonProbe != null) {
          _setProgress(buildId, const InstallProgress(stage: InstallStage.detectingPython));
        }
        final detection = await _pythonProbe?.detectFromFreeCad(
          executablePath: file.path,
        );
        pythonVersion = detection?.detectedVersion;
        pythonPath = detection?.python?.executablePath;
      } else {
        var referenceInPlace = false;
        String archivePath;
        if (isUrl) {
          final download = await _downloader.download(
            uri: Uri.parse(trimmed),
            fileName: fileName ?? Uri.parse(trimmed).path.split('/').last,
            expectedSha256: effectiveSha,
            cancellationToken: token,
            onProgress: (progress) => _onDownloadProgress(buildId, progress),
          );
          archivePath = download.path;
          effectiveSha = download.sha256;
        } else {
          final type = FileSystemEntity.typeSync(trimmed);
          if (type == FileSystemEntityType.notFound) {
            throw CustomImportException('File not found: $trimmed');
          }
          if (resolvedKind == BuildKind.appimage) {
            referenceInPlace = true;
            archivePath = _validatedExecutable(trimmed).path;
          } else {
            archivePath = File(trimmed).path;
          }
          if (effectiveSha != null) {
            final actual = await _hashWithProgress(buildId, archivePath);
            if (actual != effectiveSha) {
              throw ChecksumMismatchException(expected: effectiveSha, actual: actual);
            }
          }
        }

        _setProgress(buildId, const InstallProgress(stage: InstallStage.installing));
        final installed = await _installer.install(
          InstallRequest(
            buildId: buildId,
            kind: resolvedKind,
            archivePath: archivePath,
            assetName: assetName,
            pythonVersionHint: null,
            referenceInPlace: referenceInPlace,
            onDetectingPython: () => _setProgress(
              buildId,
              const InstallProgress(stage: InstallStage.detectingPython),
            ),
          ),
        );
        executablePath = installed.executablePath;
        sizeBytes = installed.sizeBytes;
        pythonVersion = installed.pythonVersion;
        pythonPath = installed.pythonPath;
      }

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
        pythonPath: pythonPath,
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
      _downloadStartedAt.remove(buildId);
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

  Future<Result<Build>> setCustomPython({
    required String buildId,
    required String pythonExecutable,
  }) async {
    final build = await _database.buildsDao.getById(buildId);
    if (build == null) {
      return const Err(AppError(message: 'Build not found'));
    }

    final probe = _pythonProbe;
    if (probe == null) {
      return const Err(AppError(message: 'Python detection is unavailable'));
    }

    final trimmed = pythonExecutable.trim();
    if (trimmed.isEmpty) {
      return const Err(AppError(message: 'Select a Python executable'));
    }
    final type = FileSystemEntity.typeSync(trimmed);
    if (type == FileSystemEntityType.notFound) {
      return Err(AppError(message: 'File not found: $trimmed'));
    }
    if (type != FileSystemEntityType.file) {
      return Err(AppError(message: 'Not a file: $trimmed'));
    }

    final detection = await probe.detectInterpreter(executablePath: trimmed);
    final python = detection.python;
    if (python == null) {
      return Err(AppError(message: detection.reason ?? 'Not a Python interpreter: $trimmed'));
    }

    final updated = build.copyWith(
      pythonVersion: Value(python.version),
      pythonPath: Value(python.executablePath),
      updatedAt: _clock(),
    );
    await _database.buildsDao.save(updated);
    return Ok(updated);
  }

  Future<Result<Build>> relabel(String buildId, String? label) async {
    final build = await _database.buildsDao.getById(buildId);
    if (build == null) {
      return const Err(AppError(message: 'Build not found'));
    }

    final issue = validateBuildLabel(label);
    if (issue != null) {
      return Err(
        AppError(
          message: switch (issue) {
            BuildLabelIssue.tooLong =>
              'Label must be $maxBuildLabelLength characters or fewer',
            BuildLabelIssue.controlCharacters => 'Label contains invalid characters',
          },
        ),
      );
    }

    final normalized = normalizeBuildLabel(label);
    final now = _clock();
    await _database.buildsDao.updateLabel(buildId, normalized, now);
    return Ok(build.copyWith(label: Value(normalized), updatedAt: now));
  }

  File _validatedExecutable(String path) {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.notFound) {
      throw CustomImportException('File not found: $path');
    }
    if (type != FileSystemEntityType.file) {
      throw CustomImportException('Not an executable file: $path');
    }

    final file = File(path);
    if (_platform != BuildPlatform.windows && !_hasExecutableBit(file)) {
      throw CustomImportException('File is not executable: $path');
    }
    return file;
  }

  static const int _executableBits = 0x49;

  bool _hasExecutableBit(File file) {
    try {
      return file.statSync().mode & _executableBits != 0;
    } on FileSystemException {
      return false;
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

  void _startDownloadTracking(String buildId) {
    _downloadStartedAt[buildId] = _clock();
  }

  void _onDownloadProgress(
    String buildId,
    DownloadProgress progress, {
    JobContext? context,
  }) {
    int? bytesPerSecond;
    final started = _downloadStartedAt[buildId];
    if (started != null) {
      final seconds = _clock().difference(started).inMilliseconds / 1000;
      if (seconds > 0.5) {
        bytesPerSecond = (progress.receivedBytes / seconds).round();
      }
    }
    final value = InstallProgress(
      stage: InstallStage.downloading,
      fraction: progress.fraction,
      receivedBytes: progress.receivedBytes,
      totalBytes: progress.totalBytes,
      bytesPerSecond: bytesPerSecond,
    );
    _setProgress(buildId, value, context: context);
  }

  Future<String> _hashWithProgress(String buildId, String path) {
    _setProgress(buildId, const InstallProgress(stage: InstallStage.hashing));
    var lastPercent = -1;
    return sha256File(
      path,
      onProgress: (fraction) {
        final percent = (fraction * 100).floor();
        if (percent == lastPercent) {
          return;
        }
        lastPercent = percent;
        _setProgress(
          buildId,
          InstallProgress(stage: InstallStage.hashing, fraction: fraction),
        );
      },
    );
  }

  void _setProgress(
    String buildId,
    InstallProgress progress, {
    JobContext? context,
  }) {
    installProgress.value = {...installProgress.value, buildId: progress};
    if (context != null) {
      context.report(
        fraction: progress.fraction,
        detail: _stageDetail(progress.stage),
        receivedBytes: progress.receivedBytes,
        totalBytes: progress.totalBytes,
        bytesPerSecond: progress.bytesPerSecond,
      );
    }
  }

  String _stageDetail(InstallStage stage) {
    return switch (stage) {
      InstallStage.hashing => 'Hashing',
      InstallStage.downloading => 'Downloading',
      InstallStage.installing => 'Installing',
      InstallStage.detectingPython => 'Detecting Python',
    };
  }

  void dispose() {
    _buildsSubscription?.cancel();
    _buildsSubscription = null;
  }
}
