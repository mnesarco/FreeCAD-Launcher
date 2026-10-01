// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/core/path_segments.dart';

class MacroCatalogEntry {
  const MacroCatalogEntry({
    required this.name,
    required this.code,
    this.comment = '',
    this.description = '',
    this.author = '',
    this.date = '',
    this.version = '',
    this.license = '',
    this.wiki = '',
    this.url = '',
    this.onGit = false,
    this.onWiki = false,
    this.srcFilename = '',
    this.filenameFromUrl = '',
    this.iconName = '',
    this.iconBase64,
    this.iconExtension = '',
    this.xpm = '',
    this.otherFiles = const [],
    this.otherFilesData = const {},
  });

  final String name;
  final String code;
  final String comment;
  final String description;
  final String author;
  final String date;
  final String version;
  final String license;
  final String wiki;
  final String url;
  final bool onGit;
  final bool onWiki;
  final String srcFilename;
  final String filenameFromUrl;
  final String iconName;
  final String? iconBase64;
  final String iconExtension;
  final String xpm;
  final List<String> otherFiles;
  final Map<String, String> otherFilesData;

  bool get hasLicense => license.trim().isNotEmpty;

  String get fileName {
    if (onGit && srcFilename.isNotEmpty) {
      return p.basename(srcFilename.replaceAll('\\', '/'));
    }
    if (filenameFromUrl.isNotEmpty) {
      return filenameFromUrl;
    }
    return '${safePathSegment(name)}.FCMacro';
  }

  String? get category {
    final parts = srcFilename.replaceAll('\\', '/').split('/');
    if (parts.length >= 3) {
      return parts[parts.length - 2];
    }
    return null;
  }

  String? get iconFileName {
    if (xpm.trim().isNotEmpty) {
      return '${safePathSegment(name)}_icon.xpm';
    }
    if (iconName.trim().isNotEmpty) {
      return p.basename(iconName.replaceAll('\\', '/'));
    }
    return null;
  }
}

List<MacroCatalogEntry> parseMacroCatalog(String jsonText) {
  final Object? decoded;
  try {
    decoded = jsonDecode(jsonText);
  } on FormatException catch (error) {
    throw FormatException('Macro catalog is not valid JSON: ${error.message}');
  }
  if (decoded is! Map) {
    throw const FormatException('Macro catalog is not a JSON object');
  }

  final entries = <MacroCatalogEntry>[];
  for (final value in decoded.values) {
    if (value is! Map) {
      continue;
    }
    final name = _string(value['name']).trim();
    final code = _string(value['code']);
    if (name.isEmpty || code.trim().isEmpty) {
      continue;
    }
    entries.add(
      MacroCatalogEntry(
        name: name,
        code: code,
        comment: _string(value['comment']).trim(),
        description: _string(value['desc']).trim(),
        author: _string(value['author']).trim(),
        date: _string(value['date']).trim(),
        version: _string(value['version']).trim(),
        license: _string(value['license']).trim(),
        wiki: _string(value['wiki']).trim(),
        url: _string(value['url']).trim(),
        onGit: value['on_git'] == true,
        onWiki: value['on_wiki'] == true,
        srcFilename: _string(value['src_filename']).trim(),
        filenameFromUrl: _string(value['filename_from_url']).trim(),
        iconName: _string(value['icon']).trim(),
        iconBase64: _nullableString(value['icon_data']),
        iconExtension: _string(value['icon_extension']).trim(),
        xpm: _string(value['xpm']),
        otherFiles: _parseOtherFiles(value['other_files']),
        otherFilesData: _parseOtherFilesData(value['other_files_data']),
      ),
    );
  }
  entries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return entries;
}

String _string(Object? value) => value is String ? value : '';

String? _nullableString(Object? value) {
  final text = _string(value).trim();
  return text.isEmpty ? null : text;
}

List<String> _parseOtherFiles(Object? value) {
  if (value is List) {
    return [
      for (final entry in value)
        if (entry is String && entry.trim().isNotEmpty) entry.trim(),
    ];
  }
  if (value is String) {
    final matches = RegExp("'([^']*)'|\"([^\"]*)\"").allMatches(value);
    return [
      for (final match in matches)
        if ((match.group(1) ?? match.group(2) ?? '').trim().isNotEmpty)
          (match.group(1) ?? match.group(2) ?? '').trim(),
    ];
  }
  return const [];
}

Map<String, String> _parseOtherFilesData(Object? value) {
  if (value is! Map) {
    return const {};
  }
  final result = <String, String>{};
  for (final entry in value.entries) {
    final key = entry.key;
    final data = entry.value;
    if (key is String && key.trim().isNotEmpty && data is String && data.isNotEmpty) {
      result[key] = data;
    }
  }
  return result;
}
