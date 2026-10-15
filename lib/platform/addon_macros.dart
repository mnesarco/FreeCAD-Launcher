// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/core/log.dart';

/// Copies `.FCMacro` files embedded in an addon into the profile macro
/// directory and maintains the AddonManager-compatible installation digest
/// (`AM_INSTALLATION_DIGEST.txt`) used on removal (D-126).
class AddonMacroInstaller {
  const AddonMacroInstaller();

  static const String digestFileName = 'AM_INSTALLATION_DIGEST.txt';

  /// Copies every `.fcmacro` file (case-insensitive, recursive) found under
  /// [addonDirectory] into [macroDirectory] by base name; returns the
  /// absolute paths of the copied files in deterministic order.
  List<String> copyMacros({
    required String addonDirectory,
    required String macroDirectory,
  }) {
    final source = Directory(addonDirectory);
    if (!source.existsSync()) {
      return const [];
    }
    final macros = <String>[];
    for (final entity in source.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      if (!p.basename(entity.path).toLowerCase().endsWith('.fcmacro')) {
        continue;
      }
      macros.add(entity.path);
    }
    if (macros.isEmpty) {
      return const [];
    }
    macros.sort();
    Directory(macroDirectory).createSync(recursive: true);
    final copied = <String>[];
    for (final path in macros) {
      final destination = p.join(macroDirectory, p.basename(path));
      File(path).copySync(destination);
      copied.add(p.normalize(destination));
    }
    return copied;
  }

  /// Writes the digest inside [addonDirectory] listing [files], in the format
  /// FreeCAD's AddonManager reads and writes.
  void writeDigest({
    required String addonDirectory,
    required List<String> files,
    required DateTime now,
  }) {
    final digest = StringBuffer()
      ..writeln(
        '# The following files were created outside this installation path '
        'during the installation of this addon on ${_timestamp(now)}:',
      );
    for (final file in files) {
      digest.writeln(file);
    }
    File(
      p.join(addonDirectory, digestFileName),
    ).writeAsStringSync(digest.toString());
  }

  /// Reads the digest of [addonDirectory]; comment and blank lines are
  /// skipped. Returns an empty list when the digest does not exist.
  List<String> readDigest(String addonDirectory) {
    final file = File(p.join(addonDirectory, digestFileName));
    if (!file.existsSync()) {
      return const [];
    }
    final entries = <String>[];
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      entries.add(trimmed);
    }
    return entries;
  }

  /// Deletes [files] that resolve inside [macroDirectory] and returns the
  /// removed paths. Paths outside the macro directory are ignored so a
  /// tampered digest can never delete arbitrary files (D-126).
  List<String> removeCopiedMacros({
    required String macroDirectory,
    required Iterable<String> files,
  }) {
    final normalizedMacros = p.normalize(p.absolute(macroDirectory));
    final removed = <String>[];
    for (final raw in files) {
      final candidate = raw.trim();
      if (candidate.isEmpty) {
        continue;
      }
      final normalized = p.normalize(p.absolute(candidate));
      if (normalized == normalizedMacros || !p.isWithin(normalizedMacros, normalized)) {
        continue;
      }
      final type = FileSystemEntity.typeSync(normalized, followLinks: false);
      if (type != FileSystemEntityType.file && type != FileSystemEntityType.link) {
        continue;
      }
      try {
        File(normalized).deleteSync();
        removed.add(normalized);
      } on FileSystemException catch (error) {
        appLogger.warn(
          'Could not remove addon macro $normalized: ${error.message}',
          error: error,
          tag: 'addons',
        );
      }
    }
    return removed;
  }

  String _timestamp(DateTime now) =>
      now.toUtc().toIso8601String().replaceFirst('T', ' ').replaceFirst('Z', '+00:00');
}
