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

  test('scans the profile root and the legacy Macro directory', () async {
    File(p.join(tempDirectory.path, 'Foto.FCMacro')).createSync(recursive: true);
    File(p.join(tempDirectory.path, 'Macro', 'Legacy.FCMacro')).createSync(recursive: true);
    File(p.join(tempDirectory.path, 'Macro', 'readme.txt')).createSync(recursive: true);
    Directory(p.join(tempDirectory.path, 'Mod')).createSync(recursive: true);

    final macros = await scanner.scan(tempDirectory.path);

    expect(macros.map((macro) => macro.fileName).toSet(), {
      'Foto.FCMacro',
      'Legacy.FCMacro',
    });
    expect(macros.map((macro) => macro.name), ['Foto', 'Legacy']);
    expect(macros.every((macro) => macro.sizeBytes == 0), isTrue);
    expect(macros.every((macro) => macro.modifiedAt.isBefore(DateTime.now())), isTrue);
  });

  test('prefers the profile root over a duplicate in Macro/', () async {
    File(p.join(tempDirectory.path, 'Dup.FCMacro')).createSync(recursive: true);
    File(p.join(tempDirectory.path, 'Macro', 'Dup.FCMacro')).createSync(recursive: true);

    final macros = await scanner.scan(tempDirectory.path);

    expect(macros, hasLength(1));
    expect(macros.single.path, p.join(tempDirectory.path, 'Dup.FCMacro'));
  });

  test('matches the .FCMacro extension case-insensitively and handles a missing root', () async {
    File(p.join(tempDirectory.path, 'lower.fcmacro')).createSync(recursive: true);

    final macros = await scanner.scan(tempDirectory.path);
    expect(macros.single.fileName, 'lower.fcmacro');

    expect(await scanner.scan(p.join(tempDirectory.path, 'missing')), isEmpty);
  });
}
