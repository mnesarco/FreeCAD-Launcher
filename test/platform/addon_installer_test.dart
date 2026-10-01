// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_download.dart';

List<int> _zip(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return ZipEncoder().encode(archive);
}

void main() {
  late Directory tempDirectory;
  late String downloadDirectory;
  late String destination;
  late FakeDownloadSource source;
  late AddonInstaller installer;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_addon_installer');
    downloadDirectory = p.join(tempDirectory.path, 'downloads');
    destination = p.join(tempDirectory.path, 'Mod', 'A2plus');
    source = FakeDownloadSource();
    installer = AddonInstaller(
      downloader: Downloader(source: source, cacheDirectory: downloadDirectory),
    );
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<AddonInstallResult> install(List<int> bytes) {
    source.streamFactory = () => Stream.fromIterable([bytes]);
    return installer.install(
      zipUri: Uri.parse('https://example.invalid/A2plus.zip'),
      destinationDirectory: destination,
      downloadDirectory: downloadDirectory,
      assetName: 'A2plus-master.zip',
    );
  }

  test('strips the archive root and places files in the destination', () async {
    final result = await install(
      _zip({
        'A2plus-master/InitGui.py': 'gui',
        'A2plus-master/package.xml': '<package><name>A2plus</name></package>',
        'A2plus-master/resources/icon.svg': '<svg/>',
      }),
    );

    expect(result.directory, destination);
    expect(result.sizeBytes, greaterThan(0));
    expect(File(p.join(destination, 'InitGui.py')).readAsStringSync(), 'gui');
    expect(File(p.join(destination, 'resources', 'icon.svg')).existsSync(), isTrue);
    expect(Directory('$destination.part').existsSync(), isFalse);
    expect(Directory('$destination.old').existsSync(), isFalse);
  });

  test('keeps archives without a single root at the top level', () async {
    await install(_zip({'InitGui.py': 'gui', 'package.xml': '<package/>'}));

    expect(File(p.join(destination, 'InitGui.py')).existsSync(), isTrue);
    expect(File(p.join(destination, 'package.xml')).existsSync(), isTrue);
  });

  test('replaces an existing addon atomically', () async {
    Directory(p.join(destination)).createSync(recursive: true);
    File(p.join(destination, 'old.txt')).writeAsStringSync('old');

    await install(_zip({'A2plus-master/new.txt': 'new'}));

    expect(File(p.join(destination, 'new.txt')).existsSync(), isTrue);
    expect(File(p.join(destination, 'old.txt')).existsSync(), isFalse);
    expect(Directory('$destination.old').existsSync(), isFalse);
  });

  test('keeps the existing addon when extraction fails', () async {
    Directory(p.join(destination)).createSync(recursive: true);
    File(p.join(destination, 'keep.txt')).writeAsStringSync('keep');

    await expectLater(
      install(_zip({'../escape.txt': 'bad'})),
      throwsA(isA<ArchiveExtractionException>()),
    );

    expect(File(p.join(destination, 'keep.txt')).readAsStringSync(), 'keep');
    expect(Directory('$destination.part').existsSync(), isFalse);
    expect(Directory('$destination.old').existsSync(), isFalse);
  });

  test('rejects an archive that expands to no files', () async {
    await expectLater(install(_zip({})), throwsA(isA<AddonInstallException>()));

    expect(Directory(destination).existsSync(), isFalse);
    expect(Directory('$destination.part').existsSync(), isFalse);
  });

  test('installFromArchive installs a local file without downloading', () async {
    final archive = p.join(tempDirectory.path, 'A2plus.zip');
    File(archive).writeAsBytesSync(
      _zip({
        'A2plus-master/InitGui.py': 'gui',
        'A2plus-master/package.xml': '<package><name>A2plus</name></package>',
      }),
    );

    final result = await installer.installFromArchive(
      archivePath: archive,
      destinationDirectory: destination,
    );

    expect(result.directory, destination);
    expect(File(p.join(destination, 'InitGui.py')).existsSync(), isTrue);
    expect(Directory('$destination.part').existsSync(), isFalse);
    expect(source.requests, isEmpty);
  });

  test('prepareFromArchive can be discarded without touching the destination', () async {
    final archive = p.join(tempDirectory.path, 'A2plus.zip');
    File(archive).writeAsBytesSync(_zip({'A2plus-master/InitGui.py': 'gui'}));

    final prepared = await installer.prepareFromArchive(
      archivePath: archive,
      destinationDirectory: destination,
    );

    expect(Directory(prepared.contentRoot).existsSync(), isTrue);
    expect(File(p.join(prepared.contentRoot, 'InitGui.py')).existsSync(), isTrue);

    installer.discardPrepared(prepared);

    expect(Directory('$destination.part').existsSync(), isFalse);
    expect(Directory(destination).existsSync(), isFalse);
  });

  test('commitPrepared replaces an existing addon and cleans staging', () async {
    Directory(destination).createSync(recursive: true);
    File(p.join(destination, 'old.txt')).writeAsStringSync('old');
    final archive = p.join(tempDirectory.path, 'A2plus.zip');
    File(archive).writeAsBytesSync(_zip({'A2plus-master/new.txt': 'new'}));

    final prepared = await installer.prepareFromArchive(
      archivePath: archive,
      destinationDirectory: destination,
    );
    await installer.commitPrepared(prepared);

    expect(File(p.join(destination, 'new.txt')).readAsStringSync(), 'new');
    expect(File(p.join(destination, 'old.txt')).existsSync(), isFalse);
    expect(Directory('$destination.part').existsSync(), isFalse);
    expect(Directory('$destination.old').existsSync(), isFalse);
  });

  group('linkDirectory', () {
    test('creates a link and removing it keeps the source intact', () async {
      final sourceDirectory = p.join(tempDirectory.path, 'dev', 'MyAddon');
      Directory(sourceDirectory).createSync(recursive: true);
      File(p.join(sourceDirectory, 'InitGui.py')).writeAsStringSync('gui');

      final result = await installer.linkDirectory(
        sourceDirectory: sourceDirectory,
        destinationDirectory: destination,
      );

      expect(result.directory, destination);
      expect(isAddonLink(destination), isTrue);
      expect(File(p.join(destination, 'InitGui.py')).readAsStringSync(), 'gui');

      deleteAddonEntry(destination);

      expect(
        FileSystemEntity.typeSync(destination, followLinks: false),
        FileSystemEntityType.notFound,
      );
      expect(File(p.join(sourceDirectory, 'InitGui.py')).existsSync(), isTrue);
    });

    test('fails when the destination already exists', () async {
      final sourceDirectory = p.join(tempDirectory.path, 'dev', 'MyAddon');
      Directory(sourceDirectory).createSync(recursive: true);
      Directory(destination).createSync(recursive: true);

      await expectLater(
        installer.linkDirectory(
          sourceDirectory: sourceDirectory,
          destinationDirectory: destination,
        ),
        throwsA(isA<AddonInstallException>()),
      );
    });
  }, skip: Platform.isWindows);
}
