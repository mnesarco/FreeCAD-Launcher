// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/platform/paths.dart';

class DebugBundleResult {
  const DebugBundleResult({
    required this.path,
    required this.bytes,
    required this.logFiles,
  });

  final String path;
  final int bytes;
  final int logFiles;
}

class DebugBundleService {
  DebugBundleService({required AppPaths paths}) : _paths = paths;

  final AppPaths _paths;

  static String suggestedFileName(DateTime now) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'freecad-launcher-debug-${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}.zip';
  }

  Future<DebugBundleResult> create({
    required String outputPath,
    required String systemInfo,
    required String diagnostics,
  }) async {
    final archive = Archive()
      ..addFile(_textFile('system.txt', systemInfo))
      ..addFile(_textFile('diagnostics.txt', diagnostics));

    final logDirectory = Directory(_paths.logsDir);
    var logFiles = 0;
    if (logDirectory.existsSync()) {
      final files = logDirectory.listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in files) {
        try {
          final content = utf8.decode(
            file.readAsBytesSync(),
            allowMalformed: true,
          );
          final redacted = content
              .split('\n')
              .map(redactSensitive)
              .join('\n');
          archive.addFile(
            _textFile('logs/${p.basename(file.path)}', redacted),
          );
          logFiles++;
        } on FileSystemException {
          continue;
        }
      }
    }

    final bytes = ZipEncoder().encode(archive);
    final target = File(outputPath);
    await target.parent.create(recursive: true);
    final part = File('$outputPath.part');
    await part.writeAsBytes(bytes, flush: true);
    if (target.existsSync()) {
      await target.delete();
    }
    final result = await part.rename(outputPath);
    return DebugBundleResult(
      path: result.path,
      bytes: bytes.length,
      logFiles: logFiles,
    );
  }

  ArchiveFile _textFile(String name, String content) {
    final data = utf8.encode(content);
    return ArchiveFile(name, data.length, data);
  }
}
