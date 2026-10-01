// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/addon_manifest_reader.dart';
import 'package:path/path.dart' as p;

List<int> _zip(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return ZipEncoder().encode(archive);
}

List<int> _tarGz(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return GZipEncoder().encode(TarEncoder().encode(archive));
}

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_addon_manifest');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  const packageXml = '''
<package format="1" xmlns="https://wiki.freecad.org/Package_Metadata">
  <name>A2plus</name>
  <description>Assembly workbench</description>
  <version>0.4.68</version>
  <license>LGPL-2.1</license>
  <pythonmin>3.10</pythonmin>
  <author email="a@example.com">Alice</author>
  <tag>assembly</tag>
  <content><workbench/></content>
</package>
''';

  group('readPackageXmlInfo', () {
    test('parses a valid package.xml', () {
      final directory = p.join(tempDirectory.path, 'A2plus');
      Directory(directory).createSync();
      File(p.join(directory, 'package.xml')).writeAsStringSync(packageXml);

      final info = readPackageXmlInfo(directory);

      expect(info.name, 'A2plus');
      expect(info.description, 'Assembly workbench');
      expect(info.version, '0.4.68');
      expect(info.license, 'LGPL-2.1');
      expect(info.tags, ['assembly']);
      expect(info.people.single.name, 'Alice');
      expect(info.people.single.contact, 'a@example.com');
    });

    test('throws when package.xml is missing', () {
      final directory = p.join(tempDirectory.path, 'NoManifest');
      Directory(directory).createSync();

      expect(() => readPackageXmlInfo(directory), throwsA(isA<AddonInstallException>()));
    });

    test('throws when package.xml is invalid', () {
      final directory = p.join(tempDirectory.path, 'Broken');
      Directory(directory).createSync();
      File(p.join(directory, 'package.xml')).writeAsStringSync('<package><name>');

      expect(() => readPackageXmlInfo(directory), throwsA(isA<AddonInstallException>()));
    });
  });

  group('requirements', () {
    test('reads requirements from a directory', () {
      final directory = p.join(tempDirectory.path, 'A2plus');
      Directory(directory).createSync();
      File(p.join(directory, 'requirements.txt')).writeAsStringSync('six>=1.0\n');

      expect(readRequirementsFromDirectory(directory), 'six>=1.0\n');
    });

    test('ignores an empty requirements file', () {
      final directory = p.join(tempDirectory.path, 'A2plus');
      Directory(directory).createSync();
      File(p.join(directory, 'requirements.txt')).writeAsStringSync('  \n');

      expect(readRequirementsFromDirectory(directory), isNull);
    });

    test('reads requirements from the archive root', () {
      final archive = p.join(tempDirectory.path, 'flat.zip');
      File(archive).writeAsBytesSync(_zip({'requirements.txt': 'six\n'}));

      expect(readRequirementsFromArchive(archive), 'six\n');
    });

    test('reads requirements from the single archive root directory', () {
      final archive = p.join(tempDirectory.path, 'rooted.zip');
      File(archive).writeAsBytesSync(_zip({'A2plus-main/requirements.txt': 'six\n'}));

      expect(readRequirementsFromArchive(archive), 'six\n');
    });

    test('reads requirements from a tar.gz archive', () {
      final archive = p.join(tempDirectory.path, 'rooted.tar.gz');
      File(archive).writeAsBytesSync(_tarGz({'A2plus-main/requirements.txt': 'six\n'}));

      expect(readRequirementsFromArchive(archive), 'six\n');
    });

    test('returns null when the archive has no requirements', () {
      final archive = p.join(tempDirectory.path, 'none.zip');
      File(archive).writeAsBytesSync(_zip({'A2plus-main/InitGui.py': 'gui'}));

      expect(readRequirementsFromArchive(archive), isNull);
    });
  });
}
