import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/platform/macro_installer.dart';
import 'package:path/path.dart' as p;

MacroCatalogEntry entry({
  String name = 'Foto',
  String code = "print('hi')",
  String fileName = 'Foto.FCMacro',
  List<String> otherFiles = const [],
  Map<String, String> otherFilesData = const {},
  String iconName = '',
  String? iconBase64,
  String xpm = '',
}) {
  return MacroCatalogEntry(
    name: name,
    code: code,
    onGit: true,
    srcFilename: 'FreeCAD-macros/Utility/$fileName',
    otherFiles: otherFiles,
    otherFilesData: otherFilesData,
    iconName: iconName,
    iconBase64: iconBase64,
    xpm: xpm,
  );
}

void main() {
  late Directory tempDirectory;
  late String macroDirectory;
  const installer = MacroInstaller();

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_macro_installer');
    macroDirectory = p.join(tempDirectory.path, 'profile');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('writes the macro, auxiliary files and icon', () async {
    final result = await installer.install(
      macro: entry(
        otherFiles: ['Foto.svg', 'lib/helper.py'],
        otherFilesData: {
          'Foto.svg': 'ICON',
          'lib/helper.py': base64Encode(utf8.encode('helper')),
          '': 'ignored',
        },
        iconName: 'Foto.svg',
        iconBase64: base64Encode(utf8.encode('<svg/>')),
      ),
      macroDirectory: macroDirectory,
    );

    expect(result.fileName, 'Foto.FCMacro');
    expect(File(p.join(macroDirectory, 'Foto.FCMacro')).readAsStringSync(), "print('hi')");
    expect(File(p.join(macroDirectory, 'lib', 'helper.py')).readAsStringSync(), 'helper');
    expect(File(p.join(macroDirectory, 'Foto.svg')).readAsStringSync(), '<svg/>');
    expect(result.files, hasLength(3));
    expect(
      Directory(macroDirectory).listSync().whereType<File>().where(
        (file) => file.path.endsWith('.part'),
      ),
      isEmpty,
    );
  });

  test('writes XPM icons as <name>_icon.xpm', () async {
    await installer.install(
      macro: entry(name: 'WithXpm', fileName: 'WithXpm.FCMacro', xpm: '/* XPM */'),
      macroDirectory: macroDirectory,
    );

    expect(
      File(p.join(macroDirectory, 'WithXpm_icon.xpm')).readAsStringSync(),
      '/* XPM */',
    );
  });

  test('skips unsafe auxiliary paths and overwrites existing macros', () async {
    await installer.install(macro: entry(code: 'old'), macroDirectory: macroDirectory);
    await installer.install(
      macro: entry(
        code: 'new',
        otherFilesData: {'../escape.py': base64Encode(utf8.encode('bad'))},
      ),
      macroDirectory: macroDirectory,
    );

    expect(File(p.join(macroDirectory, 'Foto.FCMacro')).readAsStringSync(), 'new');
    expect(File(p.join(tempDirectory.path, 'escape.py')).existsSync(), isFalse);
  });

  test('creates the profile directory when missing', () async {
    await installer.install(macro: entry(), macroDirectory: macroDirectory);
    expect(Directory(macroDirectory).existsSync(), isTrue);
  });
}
