// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/addon_macros.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;
  const installer = AddonMacroInstaller();

  setUp(() {
    temp = Directory.systemTemp.createTempSync('fcl_addon_macros');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  test('copies every .fcmacro recursively by base name', () {
    final addon = Directory(p.join(temp.path, 'addon'))..createSync(recursive: true);
    Directory(p.join(addon.path, 'macro')).createSync();
    Directory(p.join(addon.path, 'docs')).createSync();
    File(p.join(addon.path, 'macro', 'Tool.FCMacro')).writeAsStringSync('tool');
    File(p.join(addon.path, 'docs', 'example.fcmacro')).writeAsStringSync('example');
    File(p.join(addon.path, 'macro', 'README.md')).writeAsStringSync('no');
    final macros = p.join(temp.path, 'Macros');

    final copied = installer.copyMacros(addonDirectory: addon.path, macroDirectory: macros);

    expect(copied, [
      p.normalize(p.join(macros, 'example.fcmacro')),
      p.normalize(p.join(macros, 'Tool.FCMacro')),
    ]);
    expect(File(p.join(macros, 'Tool.FCMacro')).readAsStringSync(), 'tool');
    expect(File(p.join(macros, 'example.fcmacro')).readAsStringSync(), 'example');
    expect(File(p.join(macros, 'README.md')).existsSync(), isFalse);
  });

  test('overwrites an existing macro with the same name', () {
    final addon = Directory(p.join(temp.path, 'addon'))..createSync(recursive: true);
    File(p.join(addon.path, 'Tool.FCMacro')).writeAsStringSync('new');
    final macros = Directory(p.join(temp.path, 'Macros'))..createSync();
    File(p.join(macros.path, 'Tool.FCMacro')).writeAsStringSync('old');

    installer.copyMacros(addonDirectory: addon.path, macroDirectory: macros.path);

    expect(File(p.join(macros.path, 'Tool.FCMacro')).readAsStringSync(), 'new');
  });

  test('returns an empty list when there are no macros', () {
    final addon = Directory(p.join(temp.path, 'addon'))..createSync(recursive: true);
    File(p.join(addon.path, 'InitGui.py')).writeAsStringSync('gui');

    final copied = installer.copyMacros(
      addonDirectory: addon.path,
      macroDirectory: p.join(temp.path, 'Macros'),
    );

    expect(copied, isEmpty);
    expect(Directory(p.join(temp.path, 'Macros')).existsSync(), isFalse);
  });

  test('writes and reads the installation digest', () {
    final addon = Directory(p.join(temp.path, 'addon'))..createSync(recursive: true);
    final files = [p.join(temp.path, 'Macros', 'Tool.FCMacro')];

    installer.writeDigest(
      addonDirectory: addon.path,
      files: files,
      now: DateTime.utc(2026, 10, 15, 11, 51, 48, 625, 731),
    );

    final digest = File(p.join(addon.path, AddonMacroInstaller.digestFileName));
    expect(digest.existsSync(), isTrue);
    expect(
      digest.readAsLinesSync().first,
      contains('created outside this installation path'),
    );
    expect(installer.readDigest(addon.path), files);
    expect(installer.readDigest(p.join(temp.path, 'missing')), isEmpty);
  });

  test('removal only touches files inside the macro directory', () {
    final macros = Directory(p.join(temp.path, 'Macros'))..createSync();
    final inside = File(p.join(macros.path, 'Tool.FCMacro'))..writeAsStringSync('tool');
    final outside = File(p.join(temp.path, 'important.txt'))..writeAsStringSync('keep');
    final directory = Directory(p.join(macros.path, 'somedir'))..createSync();

    final removed = installer.removeCopiedMacros(
      macroDirectory: macros.path,
      files: [inside.path, outside.path, directory.path, p.join(macros.path, 'gone.FCMacro')],
    );

    expect(removed, [p.normalize(inside.path)]);
    expect(inside.existsSync(), isFalse);
    expect(outside.existsSync(), isTrue);
    expect(directory.existsSync(), isTrue);
  });
}
