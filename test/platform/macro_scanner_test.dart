// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/macro_scanner.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;
  const scanner = MacroScanner();

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_macro_scanner');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('scans .FCMacro files in the macro directory', () async {
    File(p.join(tempDirectory.path, 'Foto.FCMacro')).createSync(recursive: true);
    File(p.join(tempDirectory.path, 'readme.txt')).createSync(recursive: true);
    Directory(p.join(tempDirectory.path, 'Mod')).createSync(recursive: true);

    final macros = await scanner.scan(tempDirectory.path);

    expect(macros.map((macro) => macro.fileName).toSet(), {'Foto.FCMacro'});
    expect(macros.single.name, 'Foto');
    expect(macros.single.sizeBytes, 0);
    expect(macros.single.modifiedAt.isBefore(DateTime.now()), isTrue);
  });

  test('matches the .FCMacro extension case-insensitively', () async {
    File(p.join(tempDirectory.path, 'lower.fcmacro')).createSync(recursive: true);

    final macros = await scanner.scan(tempDirectory.path);
    expect(macros.single.fileName, 'lower.fcmacro');
  });

  test('returns an empty list for a missing directory', () async {
    expect(await scanner.scan(p.join(tempDirectory.path, 'missing')), isEmpty);
  });
}
