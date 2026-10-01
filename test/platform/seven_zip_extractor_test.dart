// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/seven_zip_extractor.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_process.dart';

void main() {
  late Directory tempDirectory;
  late FakeProcessLauncher launcher;
  late ProcessRunner runner;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_7z_test');
    launcher = FakeProcessLauncher();
    runner = ProcessRunner(launcher: launcher);
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> waitForHandle(int index) async {
    for (var attempt = 0; attempt < 250 && launcher.handles.length <= index; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  test('rejects a missing 7-Zip helper before running anything', () async {
    final extractor = SevenZipExtractor(
      processRunner: runner,
      executablePath: p.join(tempDirectory.path, 'missing', '7zr.exe'),
    );

    await expectLater(
      extractor.extract(p.join(tempDirectory.path, 'a.7z'), tempDirectory.path),
      throwsA(isA<ArchiveExtractionException>()),
    );
    expect(launcher.specs, isEmpty);
  });

  test('invokes 7zr with an argument array and no shell', () async {
    final executable = File(p.join(tempDirectory.path, '7zr.exe'))..writeAsStringSync('');
    final archive = File(p.join(tempDirectory.path, 'FreeCAD.7z'))..writeAsStringSync('');
    final destination = p.join(tempDirectory.path, 'out');
    final extractor = SevenZipExtractor(
      processRunner: runner,
      executablePath: executable.path,
    );

    final future = extractor.extract(archive.path, destination);
    await waitForHandle(0);
    launcher.handles.first.exit(0);
    await future;

    expect(launcher.specs.single.executable, executable.path);
    expect(launcher.specs.single.arguments, [
      'x',
      '-y',
      '-bso0',
      '-bsp0',
      '-o$destination',
      archive.path,
    ]);
  });

  test('throws with stderr details when 7zr fails', () async {
    final executable = File(p.join(tempDirectory.path, '7zr.exe'))..writeAsStringSync('');
    final archive = File(p.join(tempDirectory.path, 'FreeCAD.7z'))..writeAsStringSync('');
    final extractor = SevenZipExtractor(
      processRunner: runner,
      executablePath: executable.path,
    );

    final future = extractor.extract(archive.path, p.join(tempDirectory.path, 'out'));
    await waitForHandle(0);
    launcher.handles.first
      ..emitStderr('ERROR: Data Error\n')
      ..exit(2);

    await expectLater(
      future,
      throwsA(
        isA<ArchiveExtractionException>().having(
          (error) => error.message,
          'message',
          contains('Data Error'),
        ),
      ),
    );
  });
}
