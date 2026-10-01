// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class ArchiveExtractionException implements Exception {
  const ArchiveExtractionException(this.message);

  final String message;

  @override
  String toString() => 'ArchiveExtractionException: $message';
}

class ExtractionLimits {
  const ExtractionLimits({
    this.maxUncompressedBytes = 4 << 30,
    this.maxEntries = 200000,
  });

  final int maxUncompressedBytes;
  final int maxEntries;
}

abstract interface class ArchiveExtractor {
  Future<void> extract(String archivePath, String destination);
}

class SafeArchiveExtractor implements ArchiveExtractor {
  const SafeArchiveExtractor({this.limits = const ExtractionLimits()});

  final ExtractionLimits limits;

  @override
  Future<void> extract(String archivePath, String destination) async {
    final name = archivePath.toLowerCase();
    if (name.endsWith('.zip')) {
      await _extractZip(archivePath, destination);
      return;
    }
    if (name.endsWith('.tar.gz') || name.endsWith('.tgz') || name.endsWith('.tar')) {
      await _extractTar(archivePath, destination, gzipped: !name.endsWith('.tar'));
      return;
    }
    throw ArchiveExtractionException('Unsupported archive type: $archivePath');
  }

  Future<void> _extractZip(String archivePath, String destination) async {
    final bytes = await File(archivePath).readAsBytes();
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object catch (error) {
      throw ArchiveExtractionException('Invalid ZIP archive: $error');
    }
    await extractEntries(archive.files, destination);
  }

  Future<void> _extractTar(
    String archivePath,
    String destination, {
    required bool gzipped,
  }) async {
    var bytes = await File(archivePath).readAsBytes();
    if (gzipped) {
      try {
        bytes = GZipDecoder().decodeBytes(bytes);
      } on Object catch (error) {
        throw ArchiveExtractionException('Invalid gzip stream: $error');
      }
    }
    final Archive archive;
    try {
      archive = TarDecoder().decodeBytes(bytes);
    } on Object catch (error) {
      throw ArchiveExtractionException('Invalid TAR archive: $error');
    }
    await extractEntries(archive.files, destination);
  }

  Future<void> extractEntries(List<ArchiveFile> files, String destination) async {
    await Directory(destination).create(recursive: true);

    var entries = 0;
    var totalBytes = 0;

    for (final file in files) {
      entries++;
      if (entries > limits.maxEntries) {
        throw ArchiveExtractionException(
          'Archive contains more than ${limits.maxEntries} entries',
        );
      }

      final relative = normalizeEntryPath(file.name);
      final targetPath = p.join(destination, relative);

      if (file.isDirectory) {
        await Directory(targetPath).create(recursive: true);
        continue;
      }
      if (file.isSymbolicLink) {
        throw ArchiveExtractionException('Symlink entries are not allowed: ${file.name}');
      }

      totalBytes += file.size;
      if (totalBytes > limits.maxUncompressedBytes) {
        throw ArchiveExtractionException(
          'Archive expands beyond ${limits.maxUncompressedBytes} bytes',
        );
      }

      await Directory(p.dirname(targetPath)).create(recursive: true);
      await File(targetPath).writeAsBytes(file.content, flush: true);
    }
  }

  static String normalizeEntryPath(String name) {
    final normalized = p.posix.normalize(name.replaceAll('\\', '/'));
    if (normalized.isEmpty || normalized == '.') {
      return '.';
    }
    if (p.posix.isAbsolute(normalized)) {
      throw ArchiveExtractionException('Absolute paths are not allowed: $name');
    }
    if (normalized == '..' || normalized.startsWith('../')) {
      throw ArchiveExtractionException('Path escapes the destination: $name');
    }
    if (RegExp(r'^[a-zA-Z]:').hasMatch(normalized)) {
      throw ArchiveExtractionException('Drive-letter paths are not allowed: $name');
    }
    return normalized;
  }
}
