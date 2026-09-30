// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;

class PythonUninstallException implements Exception {
  const PythonUninstallException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PythonUninstaller {
  const PythonUninstaller();

  Future<int> uninstall({
    required String targetDirectory,
    required String packageName,
  }) async {
    final target = Directory(targetDirectory);
    if (!target.existsSync()) {
      throw PythonUninstallException('Target directory does not exist: $targetDirectory');
    }

    final normalized = _normalizeName(packageName);
    final distInfos = target
        .listSync(followLinks: false)
        .whereType<Directory>()
        .where((directory) {
          final raw = p.basename(directory.path).toLowerCase();
          if (!raw.endsWith('.dist-info')) {
            return false;
          }
          return _normalizeName(raw).startsWith('$normalized-');
        })
        .toList();
    if (distInfos.isEmpty) {
      throw PythonUninstallException(
        'No installed distribution found for "$packageName"',
      );
    }

    var removed = 0;
    final parents = <Directory>{};
    for (final distInfo in distInfos) {
      final record = File(p.join(distInfo.path, 'RECORD'));
      if (!record.existsSync()) {
        continue;
      }
      for (final line in await record.readAsLines()) {
        final relative = _firstCsvField(line);
        if (relative.isEmpty) {
          continue;
        }
        final resolved = p.normalize(p.join(target.path, relative));
        if (!p.isWithin(target.path, resolved)) {
          throw PythonUninstallException('Unsafe RECORD path: $relative');
        }
        final file = File(resolved);
        if (file.existsSync()) {
          await file.delete();
          removed++;
          parents.add(Directory(p.dirname(resolved)));
        }
      }
    }

    final sortedParents = parents.toList()
      ..sort((a, b) => p.split(b.path).length.compareTo(p.split(a.path).length));
    for (final directory in sortedParents) {
      if (directory.existsSync() &&
          p.isWithin(target.path, directory.path) &&
          directory.listSync(followLinks: false).isEmpty) {
        await directory.delete();
      }
    }

    for (final distInfo in distInfos) {
      if (distInfo.existsSync()) {
        await distInfo.delete(recursive: true);
      }
    }
    return removed;
  }

  static String _normalizeName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[-_.]+'), '-');
  }

  static String _firstCsvField(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (!trimmed.startsWith('"')) {
      final comma = trimmed.indexOf(',');
      return (comma < 0 ? trimmed : trimmed.substring(0, comma)).trim();
    }
    final buffer = StringBuffer();
    var index = 1;
    while (index < trimmed.length) {
      final char = trimmed[index];
      if (char == '"') {
        if (index + 1 < trimmed.length && trimmed[index + 1] == '"') {
          buffer.write('"');
          index += 2;
          continue;
        }
        break;
      }
      buffer.write(char);
      index++;
    }
    return buffer.toString();
  }
}
