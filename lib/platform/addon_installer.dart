// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
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

class PreparedAddonInstall {
  const PreparedAddonInstall({
    required this.contentRoot,
    required this.stagingDirectory,
    required this.destinationDirectory,
    this.skippedEntries = const [],
  });

  final String contentRoot;
  final String stagingDirectory;
  final String destinationDirectory;
  final List<SkippedArchiveEntry> skippedEntries;
}

bool isAddonLink(String path) =>
    FileSystemEntity.typeSync(path, followLinks: false) == FileSystemEntityType.link;

void deleteAddonEntry(String path) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    return;
  }
  if (type == FileSystemEntityType.link) {
    Link(path).deleteSync();
    return;
  }
  Directory(path).deleteSync(recursive: true);
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

  Future<String> downloadArchive({
    required Uri uri,
    required String directory,
    String? assetName,
    CancellationToken? cancellationToken,
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final fileName = assetName ?? p.basename(uri.path);
    final download = await _downloader.download(
      uri: uri,
      fileName: fileName,
      directory: directory,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
    if (cancellationToken?.isCancelled ?? false) {
      throw const AddonInstallException('Addon installation cancelled');
    }
    return download.path;
  }

  Future<AddonInstallResult> install({
    required Uri zipUri,
    required String destinationDirectory,
    required String downloadDirectory,
    String? assetName,
    CancellationToken? cancellationToken,
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final archivePath = await downloadArchive(
      uri: zipUri,
      directory: downloadDirectory,
      assetName: assetName,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
    return installFromArchive(
      archivePath: archivePath,
      destinationDirectory: destinationDirectory,
      cancellationToken: cancellationToken,
    );
  }

  Future<PreparedAddonInstall> prepareFromArchive({
    required String archivePath,
    required String destinationDirectory,
    CancellationToken? cancellationToken,
  }) async {
    if (cancellationToken?.isCancelled ?? false) {
      throw const AddonInstallException('Addon installation cancelled');
    }
    final staging = '$destinationDirectory.part';
    Directory(p.dirname(destinationDirectory)).createSync(recursive: true);
    deleteAddonEntry(staging);
    final skippedEntries = <SkippedArchiveEntry>[];
    try {
      await _extractor.extract(archivePath, staging, onWarning: skippedEntries.add);
      final root = _contentRoot(staging);
      if (await _countFiles(root) == 0) {
        throw const AddonInstallException('Archive contains no files');
      }
      if (cancellationToken?.isCancelled ?? false) {
        throw const AddonInstallException('Addon installation cancelled');
      }
      return PreparedAddonInstall(
        contentRoot: root,
        stagingDirectory: staging,
        destinationDirectory: destinationDirectory,
        skippedEntries: skippedEntries,
      );
    } on Object {
      deleteAddonEntry(staging);
      rethrow;
    }
  }

  Future<AddonInstallResult> commitPrepared(
    PreparedAddonInstall prepared, {
    CancellationToken? cancellationToken,
  }) async {
    if (cancellationToken?.isCancelled ?? false) {
      throw const AddonInstallException('Addon installation cancelled');
    }
    final destination = prepared.destinationDirectory;
    final backup = '$destination.old';
    deleteAddonEntry(backup);
    final hadDestination =
        FileSystemEntity.typeSync(destination, followLinks: false) != FileSystemEntityType.notFound;
    if (hadDestination) {
      _renameEntry(destination, backup);
    }
    try {
      await Directory(prepared.contentRoot).rename(destination);
    } on Object {
      if (hadDestination &&
          FileSystemEntity.typeSync(backup, followLinks: false) != FileSystemEntityType.notFound) {
        deleteAddonEntry(destination);
        _renameEntry(backup, destination);
      }
      rethrow;
    }
    deleteAddonEntry(backup);
    deleteAddonEntry(prepared.stagingDirectory);
    return AddonInstallResult(directory: destination, sizeBytes: await _directorySize(destination));
  }

  void discardPrepared(PreparedAddonInstall prepared) {
    deleteAddonEntry(prepared.stagingDirectory);
  }

  Future<AddonInstallResult> installFromArchive({
    required String archivePath,
    required String destinationDirectory,
    CancellationToken? cancellationToken,
  }) async {
    final prepared = await prepareFromArchive(
      archivePath: archivePath,
      destinationDirectory: destinationDirectory,
      cancellationToken: cancellationToken,
    );
    try {
      return await commitPrepared(prepared, cancellationToken: cancellationToken);
    } on Object catch (error) {
      discardPrepared(prepared);
      if (error is ArchiveExtractionException || error is AddonInstallException) {
        rethrow;
      }
      throw AddonInstallException('Addon installation failed: $error');
    }
  }

  Future<AddonInstallResult> linkDirectory({
    required String sourceDirectory,
    required String destinationDirectory,
  }) async {
    final source = Directory(sourceDirectory);
    if (!source.existsSync()) {
      throw const AddonInstallException('Source directory does not exist');
    }
    final staging = '$destinationDirectory.part';
    Directory(p.dirname(destinationDirectory)).createSync(recursive: true);
    deleteAddonEntry(staging);
    if (FileSystemEntity.typeSync(destinationDirectory, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw const AddonInstallException('Addon directory already exists');
    }
    try {
      Link(staging).createSync(source.absolute.path);
      await Link(staging).rename(destinationDirectory);
    } on Object catch (error) {
      deleteAddonEntry(staging);
      throw AddonInstallException('Could not create the development link: $error');
    }
    return AddonInstallResult(directory: destinationDirectory, sizeBytes: 0);
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
          (directory) => !_ignoredRootEntries.contains(p.basename(directory.path).toLowerCase()),
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

  void _renameEntry(String from, String to) {
    final type = FileSystemEntity.typeSync(from, followLinks: false);
    if (type == FileSystemEntityType.link) {
      Link(from).renameSync(to);
    } else {
      Directory(from).renameSync(to);
    }
  }
}
