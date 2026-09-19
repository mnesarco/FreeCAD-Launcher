import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/core/cancellation.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/downloader.dart';

class AddonInstallException implements Exception {
  const AddonInstallException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AddonInstallResult {
  const AddonInstallResult({required this.directory, required this.sizeBytes});

  final String directory;
  final int sizeBytes;
}

class AddonInstaller {
  AddonInstaller({
    required Downloader downloader,
    ArchiveExtractor extractor = const SafeArchiveExtractor(),
  }) : _downloader = downloader,
       _extractor = extractor;

  static const List<String> _ignoredRootEntries = ['__macosx'];

  final Downloader _downloader;
  final ArchiveExtractor _extractor;

  Future<AddonInstallResult> install({
    required Uri zipUri,
    required String destinationDirectory,
    required String downloadDirectory,
    String? assetName,
    CancellationToken? cancellationToken,
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final fileName = assetName ?? p.basename(zipUri.path);
    final download = await _downloader.download(
      uri: zipUri,
      fileName: fileName,
      directory: downloadDirectory,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
    if (cancellationToken?.isCancelled ?? false) {
      throw const AddonInstallException('Addon installation cancelled');
    }

    final staging = '$destinationDirectory.part';
    final backup = '$destinationDirectory.old';
    Directory(p.dirname(destinationDirectory)).createSync(recursive: true);
    _deleteDirectory(staging);
    _deleteDirectory(backup);

    try {
      await _extractor.extract(download.path, staging);
      final root = _contentRoot(staging);
      if (await _countFiles(root) == 0) {
        throw const AddonInstallException('Archive contains no files');
      }

      final hadDestination = Directory(destinationDirectory).existsSync();
      if (hadDestination) {
        Directory(destinationDirectory).renameSync(backup);
      }
      try {
        await Directory(root).rename(destinationDirectory);
      } on Object {
        if (hadDestination && Directory(backup).existsSync()) {
          _deleteDirectory(destinationDirectory);
          await Directory(backup).rename(destinationDirectory);
        }
        rethrow;
      }
      _deleteDirectory(backup);

      return AddonInstallResult(
        directory: destinationDirectory,
        sizeBytes: await _directorySize(destinationDirectory),
      );
    } on Object catch (error) {
      if (error is ArchiveExtractionException || error is AddonInstallException) {
        rethrow;
      }
      throw AddonInstallException('Addon installation failed: $error');
    } finally {
      _deleteDirectory(staging);
    }
  }

  String _contentRoot(String staging) {
    final entries = Directory(staging).listSync(followLinks: false);
    final directories = entries.whereType<Directory>().toList();
    final files = entries.whereType<File>().toList();

    if (directories.length == 1 && files.isEmpty) {
      return directories.single.path;
    }
    final roots = directories
        .where(
          (directory) =>
              !_ignoredRootEntries.contains(p.basename(directory.path).toLowerCase()),
        )
        .toList();
    if (roots.length == 1 && directories.length <= 2 && files.isEmpty) {
      return roots.single.path;
    }
    return staging;
  }

  Future<int> _countFiles(String root) async {
    var count = 0;
    await for (final entity in Directory(root).list(recursive: true, followLinks: false)) {
      if (entity is File) {
        count++;
      }
    }
    return count;
  }

  Future<int> _directorySize(String root) async {
    var total = 0;
    await for (final entity in Directory(root).list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  void _deleteDirectory(String path) {
    final directory = Directory(path);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }
}
