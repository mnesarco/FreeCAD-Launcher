// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/platform/macro_icon_cache.dart';
import 'package:path/path.dart' as p;

const _svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>';

MacroCatalogEntry _entry({String? base64, String extension = ''}) {
  return MacroCatalogEntry(
    name: 'Macro',
    code: 'print(1)',
    iconBase64: base64,
    iconExtension: extension,
  );
}

void main() {
  late Directory tempDirectory;
  late String iconsDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_macro_icons');
    iconsDirectory = p.join(tempDirectory.path, 'icons');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('decodes base64 and persists a content-addressed file', () {
    final cache = MacroIconCache(directory: iconsDirectory);
    final data = base64Encode(utf8.encode(_svg));
    final bytes = cache.resolve(_entry(base64: data, extension: 'svg'));

    expect(bytes, isNotNull);
    final files = Directory(iconsDirectory).listSync().whereType<File>().toList();
    expect(files, hasLength(1));
    expect(p.basename(files.single.path), '${MacroIconCache.keyFor(data)}.svg');
    expect(files.single.readAsBytesSync(), bytes);
  });

  test('a fresh instance serves the icon from disk without decoding again', () {
    final data = base64Encode(utf8.encode(_svg));
    MacroIconCache(directory: iconsDirectory).resolve(
      _entry(base64: data, extension: 'svg'),
    );

    final file = Directory(iconsDirectory).listSync().whereType<File>().single;
    file.writeAsBytesSync([1, 2, 3]);

    final fresh = MacroIconCache(directory: iconsDirectory);
    expect(fresh.resolve(_entry(base64: data, extension: 'svg')), [1, 2, 3]);
  });

  test('returns null for empty, invalid and xpm icons without writing', () {
    final cache = MacroIconCache(directory: iconsDirectory);

    expect(cache.resolve(_entry()), isNull);
    expect(cache.resolve(_entry(base64: 'not base64!!', extension: 'png')), isNull);
    expect(
      cache.resolve(_entry(base64: base64Encode(utf8.encode('/* XPM */')), extension: 'xpm')),
      isNull,
    );
    expect(Directory(iconsDirectory).existsSync(), isFalse);
  });

  test('prune deletes files that are not in the current catalog', () {
    final cache = MacroIconCache(directory: iconsDirectory);
    final keepData = base64Encode(utf8.encode(_svg));
    final dropData = base64Encode(utf8.encode('<svg xmlns="http://www.w3.org/2000/svg"/>'));

    cache.resolve(_entry(base64: keepData, extension: 'svg'));
    cache.resolve(_entry(base64: dropData, extension: 'svg'));
    expect(Directory(iconsDirectory).listSync().whereType<File>(), hasLength(2));

    cache.prune([MacroIconCache.keyFor(keepData)!]);

    final remaining = Directory(iconsDirectory).listSync().whereType<File>().toList();
    expect(remaining, hasLength(1));
    expect(cache.resolve(_entry(base64: dropData, extension: 'svg')), isNotNull);
  });
}
