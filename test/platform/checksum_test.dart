// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/checksum.dart';
import 'package:path/path.dart' as p;

void main() {
  const helloHash = '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';

  test('hashes bytes and files', () async {
    final bytes = utf8.encode('hello');

    expect(sha256OfBytes(bytes), helloHash);

    final directory = Directory.systemTemp.createTempSync('fcl_checksum_test');
    try {
      final file = File(p.join(directory.path, 'hello.txt'))..writeAsBytesSync(bytes);
      expect(await sha256File(file.path), helloHash);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('reports hashing progress and still matches the digest', () async {
    final directory = Directory.systemTemp.createTempSync('fcl_checksum_progress');
    try {
      final bytes = List<int>.generate(4096, (index) => index % 251);
      final file = File(p.join(directory.path, 'data.bin'))..writeAsBytesSync(bytes);
      final progress = <double>[];

      final digest = await sha256File(file.path, onProgress: progress.add);

      expect(digest, sha256OfBytes(bytes));
      expect(progress, isNotEmpty);
      expect(progress.last, 1.0);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  group('parseSha256Text', () {
    test('extracts the digest from common sidecar formats', () {
      final hash = List.filled(64, 'a').join();
      expect(parseSha256Text('$hash  FreeCAD.AppImage'), hash);
      expect(parseSha256Text('$hash *FreeCAD.AppImage'), hash);
      expect(parseSha256Text(hash), hash);
      expect(parseSha256Text(hash.toUpperCase()), hash);
    });

    test('returns null when no digest is present', () {
      expect(parseSha256Text('not a checksum'), isNull);
      expect(parseSha256Text(''), isNull);
    });
  });
}
