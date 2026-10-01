// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/addons/package_xml.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';

PackageXmlInfo readPackageXmlInfo(String directory) {
  final file = File(p.join(directory, 'package.xml'));
  if (!file.existsSync()) {
    throw const AddonInstallException('package.xml not found at the addon root');
  }
  final info = parsePackageXml(file.readAsStringSync());
  if (info == null) {
    throw const AddonInstallException('package.xml is not valid XML');
  }
  return info;
}

String? readRequirementsFromDirectory(String directory) {
  return _readRequirementsFile(File(p.join(directory, 'requirements.txt')));
}

String? readRequirementsFromArchive(String archivePath) {
  final bytes = File(archivePath).readAsBytesSync();
  final lower = archivePath.toLowerCase();
  final Archive archive;
  try {
    if (lower.endsWith('.zip')) {
      archive = ZipDecoder().decodeBytes(bytes);
    } else if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz') || lower.endsWith('.tar')) {
      var data = bytes;
      if (!lower.endsWith('.tar')) {
        data = GZipDecoder().decodeBytes(data);
      }
      archive = TarDecoder().decodeBytes(data);
    } else {
      return null;
    }
  } on Object {
    return null;
  }

  ArchiveFile? best;
  var bestDepth = 0;
  for (final file in archive.files) {
    if (file.isDirectory || file.isSymbolicLink) {
      continue;
    }
    final normalized = SafeArchiveExtractor.normalizeEntryPath(file.name);
    if (p.posix.basename(normalized).toLowerCase() != 'requirements.txt') {
      continue;
    }
    final depth = normalized.split('/').length;
    if (depth > 2) {
      continue;
    }
    if (best == null || depth < bestDepth) {
      best = file;
      bestDepth = depth;
    }
  }
  if (best == null) {
    return null;
  }
  final text = utf8.decode(best.content, allowMalformed: true);
  return text.trim().isEmpty ? null : text;
}

String? _readRequirementsFile(File file) {
  if (!file.existsSync()) {
    return null;
  }
  final text = file.readAsStringSync();
  return text.trim().isEmpty ? null : text;
}
