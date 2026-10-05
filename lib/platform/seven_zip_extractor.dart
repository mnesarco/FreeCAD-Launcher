// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/process.dart';

class SevenZipExtractor implements ArchiveExtractor {
  SevenZipExtractor({required ProcessRunner processRunner, required String executablePath})
    : _processRunner = processRunner,
      _executablePath = executablePath;

  factory SevenZipExtractor.bundled(ProcessRunner processRunner) {
    final executableDirectory = File(Platform.resolvedExecutable).parent.path;
    return SevenZipExtractor(
      processRunner: processRunner,
      executablePath: p.join(executableDirectory, '7zr.exe'),
    );
  }

  final ProcessRunner _processRunner;
  final String _executablePath;

  String get executablePath => _executablePath;

  @override
  Future<void> extract(
    String archivePath,
    String destination, {
    ArchiveWarningCallback? onWarning,
  }) async {
    if (!File(_executablePath).existsSync()) {
      throw ArchiveExtractionException('7-Zip helper not found at $_executablePath');
    }
    await Directory(destination).create(recursive: true);

    final result = await _processRunner.run(
      ProcessSpec(
        executable: _executablePath,
        arguments: ['x', '-y', '-bso0', '-bsp0', '-o$destination', archivePath],
      ),
    );

    if (!result.isSuccess) {
      final details = result.stderr.trim().isEmpty ? result.stdout.trim() : result.stderr.trim();
      throw ArchiveExtractionException(
        '7-Zip failed with exit code ${result.exitCode}${details.isEmpty ? '' : ': $details'}',
      );
    }
  }
}
