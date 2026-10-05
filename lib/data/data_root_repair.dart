// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:freecad_launcher/data/database.dart';

/// Rewrites stored absolute paths after the Windows data root changed (D-117).
///
/// The database is an index over the filesystem and stores absolute paths
/// (`builds.localPath`, `builds.pythonPath`, `catalog_cache.payloadPath`,
/// `installed_addons.sourcePath`, `python_packages.targetDir`). Moving the data
/// root leaves them pointing at the old location; only values whose mapped
/// target exists are rewritten, so nothing is changed blindly.
class DataRootRepair {
  DataRootRepair(this._database);

  final AppDatabase _database;

  /// Rewrites paths under [from] to [to]; returns the number of fields updated.
  Future<int> rewritePathPrefix({required String from, required String to}) async {
    if (from == to) {
      return 0;
    }
    var repaired = 0;
    for (final build in await _database.buildsDao.getAll()) {
      final localPath = _map(build.localPath, from, to);
      final pythonPath = _map(build.pythonPath, from, to);
      if (localPath != null || pythonPath != null) {
        await _database.buildsDao.save(
          build.copyWith(
            localPath: localPath ?? build.localPath,
            pythonPath: pythonPath == null ? const Value.absent() : Value(pythonPath),
          ),
        );
        repaired++;
      }
    }
    for (final entry in await _database.catalogCacheDao.getAll()) {
      final payloadPath = _map(entry.payloadPath, from, to);
      if (payloadPath != null) {
        await _database.catalogCacheDao.put(entry.copyWith(payloadPath: payloadPath));
        repaired++;
      }
    }
    for (final addon in await _database.installedAddonsDao.getAll()) {
      final sourcePath = _map(addon.sourcePath, from, to);
      if (sourcePath != null) {
        await _database.installedAddonsDao.save(addon.copyWith(sourcePath: Value(sourcePath)));
        repaired++;
      }
    }
    for (final package in await _database.pythonPackagesDao.getAll()) {
      final targetDir = _map(package.targetDir, from, to);
      if (targetDir != null) {
        await _database.pythonPackagesDao.save(package.copyWith(targetDir: targetDir));
        repaired++;
      }
    }
    return repaired;
  }

  String? _map(String? value, String from, String to) {
    if (value == null || value.length < from.length) {
      return null;
    }
    if (value.substring(0, from.length).toLowerCase() != from.toLowerCase()) {
      return null;
    }
    final mapped = '$to${value.substring(from.length)}';
    if (File(mapped).existsSync() || Directory(mapped).existsSync()) {
      return mapped;
    }
    return null;
  }
}
