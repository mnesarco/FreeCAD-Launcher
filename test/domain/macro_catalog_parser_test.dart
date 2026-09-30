// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';

void main() {
  test('parses git and wiki macros with metadata', () {
    final macros = parseMacroCatalog('''
{
  "Foto": {
    "name": "Foto",
    "on_git": true,
    "on_wiki": false,
    "comment": "Creates a 300-dpi foto",
    "desc": "Long description",
    "author": "microelly",
    "date": "2015-01-01",
    "version": "0.1.0",
    "license": "",
    "wiki": "",
    "url": "",
    "code": "print('hi')",
    "src_filename": "FreeCAD-macros/Utility/Foto.FCMacro",
    "filename_from_url": "",
    "icon": "Foto.svg",
    "icon_data": "aWNvbg==",
    "icon_extension": "svg",
    "xpm": "",
    "other_files": "['Foto.svg', '']",
    "other_files_data": {"Foto.svg": "ICON"}
  },
  "WikiOnly": {
    "name": "Wiki Only",
    "on_git": false,
    "on_wiki": true,
    "comment": "From the wiki",
    "license": "LGPL-2.0-or-later",
    "code": "print('wiki')",
    "src_filename": "",
    "filename_from_url": "",
    "icon": "https://example.invalid/icons/wiki.png",
    "icon_data": null,
    "xpm": "",
    "other_files": [],
    "other_files_data": {}
  }
}
''');

    expect(macros, hasLength(2));
    final foto = macros.firstWhere((macro) => macro.name == 'Foto');
    expect(foto.onGit, isTrue);
    expect(foto.license, isEmpty);
    expect(foto.hasLicense, isFalse);
    expect(foto.fileName, 'Foto.FCMacro');
    expect(foto.category, 'Utility');
    expect(foto.iconFileName, 'Foto.svg');
    expect(foto.otherFiles, ['Foto.svg']);
    expect(foto.otherFilesData['Foto.svg'], 'ICON');

    final wiki = macros.firstWhere((macro) => macro.name == 'Wiki Only');
    expect(wiki.onWiki, isTrue);
    expect(wiki.hasLicense, isTrue);
    expect(wiki.fileName, 'Wiki_Only.FCMacro');
    expect(wiki.category, isNull);
    expect(wiki.iconFileName, 'wiki.png');
  });

  test('normalizes list-shaped other_files and skips entries without code', () {
    final macros = parseMacroCatalog('''
{
  "Broken": {"name": "Broken", "code": "", "other_files": []},
  "Valid": {
    "name": "Valid",
    "code": "x = 1",
    "other_files": ["a.py", "sub/b.txt"],
    "other_files_data": {"a.py": "YQ=="}
  }
}
''');

    expect(macros, hasLength(1));
    expect(macros.single.name, 'Valid');
    expect(macros.single.otherFiles, ['a.py', 'sub/b.txt']);
  });

  test('sorts by lowercase name and rejects invalid payloads', () {
    final macros = parseMacroCatalog('''
{"b": {"name": "beta", "code": "1"}, "A": {"name": "Alpha", "code": "2"}}
''');
    expect(macros.map((macro) => macro.name), ['Alpha', 'beta']);

    expect(() => parseMacroCatalog('not json'), throwsFormatException);
    expect(() => parseMacroCatalog('[]'), throwsFormatException);
  });
}
