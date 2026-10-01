// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;
  late Directory destination;
  const extractor = SafeArchiveExtractor();

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_archive_test');
    destination = Directory(p.join(tempDirectory.path, 'out'));
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<File> writeZip(String name, Archive archive) async {
    final file = File(p.join(tempDirectory.path, name));
    await file.writeAsBytes(ZipEncoder().encode(archive));
    return file;
  }

  Future<File> writeTarGz(String name, Archive archive) async {
    final file = File(p.join(tempDirectory.path, name));
    final tar = TarEncoder().encode(archive);
    await file.writeAsBytes(GZipEncoder().encode(tar));
    return file;
  }

  test('extracts a zip with nested directories', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('pkg/data/hello.txt', 5, utf8.encode('hello')))
      ..addFile(ArchiveFile('pkg/empty', 0, []));
    final file = await writeZip('test.zip', archive);

    await extractor.extract(file.path, destination.path);

    expect(File(p.join(destination.path, 'pkg/data/hello.txt')).readAsStringSync(), 'hello');
    expect(File(p.join(destination.path, 'pkg/empty')).existsSync(), isTrue);
  });

  test('extracts a tar.gz archive', () async {
    final archive = Archive()..addFile(ArchiveFile('pkg/hello.txt', 5, utf8.encode('hello')));
    final file = await writeTarGz('test.tar.gz', archive);

    await extractor.extract(file.path, destination.path);

    expect(File(p.join(destination.path, 'pkg/hello.txt')).readAsStringSync(), 'hello');
  });

  test('rejects zip-slip entries and writes nothing outside', () async {
    final archive = Archive()..addFile(ArchiveFile('../evil.txt', 4, utf8.encode('evil')));
    final file = await writeZip('slip.zip', archive);

    await expectLater(
      extractor.extract(file.path, destination.path),
      throwsA(isA<ArchiveExtractionException>()),
    );

    expect(File(p.join(tempDirectory.path, 'evil.txt')).existsSync(), isFalse);
  });

  test('rejects absolute paths', () async {
    final archive = Archive()..addFile(ArchiveFile('/tmp/evil.txt', 4, utf8.encode('evil')));
    final file = await writeZip('absolute.zip', archive);

    await expectLater(
      extractor.extract(file.path, destination.path),
      throwsA(isA<ArchiveExtractionException>()),
    );
  });

  test('rejects symlink entries', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('link', 0, [])..symbolicLink = '/etc/passwd');

    await expectLater(
      extractor.extractEntries(archive.files, destination.path),
      throwsA(isA<ArchiveExtractionException>()),
    );
  });

  test('enforces the entry count limit', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('a.txt', 1, [65]))
      ..addFile(ArchiveFile('b.txt', 1, [66]))
      ..addFile(ArchiveFile('c.txt', 1, [67]));
    final file = await writeZip('many.zip', archive);
    const limited = SafeArchiveExtractor(limits: ExtractionLimits(maxEntries: 2));

    await expectLater(
      limited.extract(file.path, destination.path),
      throwsA(isA<ArchiveExtractionException>()),
    );
  });

  test('enforces the uncompressed size limit', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('big.txt', 20, List.filled(20, 65)));
    final file = await writeZip('big.zip', archive);
    const limited = SafeArchiveExtractor(
      limits: ExtractionLimits(maxUncompressedBytes: 10),
    );

    await expectLater(
      limited.extract(file.path, destination.path),
      throwsA(isA<ArchiveExtractionException>()),
    );
  });

  test('rejects unsupported archive types', () async {
    final file = File(p.join(tempDirectory.path, 'archive.7z'))..writeAsBytesSync([1, 2, 3]);

    await expectLater(
      extractor.extract(file.path, destination.path),
      throwsA(isA<ArchiveExtractionException>()),
    );
  });

  group('normalizeEntryPath', () {
    test('normalizes separators and dot segments', () {
      expect(SafeArchiveExtractor.normalizeEntryPath('pkg\\data\\file.txt'), 'pkg/data/file.txt');
      expect(SafeArchiveExtractor.normalizeEntryPath('./pkg/file.txt'), 'pkg/file.txt');
    });

    test('rejects escapes and absolute paths', () {
      expect(
        () => SafeArchiveExtractor.normalizeEntryPath('../evil'),
        throwsA(isA<ArchiveExtractionException>()),
      );
      expect(
        () => SafeArchiveExtractor.normalizeEntryPath('/etc/passwd'),
        throwsA(isA<ArchiveExtractionException>()),
      );
      expect(
        () => SafeArchiveExtractor.normalizeEntryPath(r'C:\Windows\evil'),
        throwsA(isA<ArchiveExtractionException>()),
      );
    });
  });
}
