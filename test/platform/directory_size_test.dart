// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/directory_size.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_directory_size_test');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('sums nested file sizes', () async {
    File(p.join(tempDirectory.path, 'a.txt')).writeAsStringSync('aaa');
    final nested = Directory(p.join(tempDirectory.path, 'nested', 'deep'))
      ..createSync(recursive: true);
    File(p.join(nested.path, 'b.txt')).writeAsStringSync('bbbbb');

    expect(await directorySize(tempDirectory.path), 8);
  });

  test('returns 0 for a missing directory', () async {
    expect(await directorySize(p.join(tempDirectory.path, 'missing')), 0);
  });

  test('skips unreadable subdirectories', () async {
    if (Platform.isWindows) {
      return;
    }
    File(p.join(tempDirectory.path, 'ok.txt')).writeAsStringSync('ok');
    final locked = Directory(p.join(tempDirectory.path, 'locked'))..createSync();
    File(p.join(locked.path, 'hidden.txt')).writeAsStringSync('hidden');
    final chmod = await Process.run('chmod', ['000', locked.path]);
    expect(chmod.exitCode, 0);
    addTearDown(() => Process.run('chmod', ['755', locked.path]));

    expect(await directorySize(tempDirectory.path), 2);
  });
}
