// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;

class ScannedMacro {
  const ScannedMacro({
    required this.name,
    required this.fileName,
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String name;
  final String fileName;
  final String path;
  final int sizeBytes;
  final DateTime modifiedAt;
}

class MacroScanner {
  const MacroScanner();

  Future<List<ScannedMacro>> scan(String macroDirectory) async {
    final byName = <String, ScannedMacro>{};
    final dir = Directory(macroDirectory);
    if (!dir.existsSync()) {
      return const [];
    }
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final fileName = p.basename(entity.path);
      if (!fileName.toLowerCase().endsWith('.fcmacro')) {
        continue;
      }
      final stat = await entity.stat();
      byName.putIfAbsent(
        fileName.toLowerCase(),
        () => ScannedMacro(
          name: p.basenameWithoutExtension(fileName),
          fileName: fileName,
          path: entity.path,
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
        ),
      );
    }
    final macros = byName.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return macros;
  }
}
