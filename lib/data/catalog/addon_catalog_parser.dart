// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/package_xml.dart';

List<Addon> parseAddonCatalog(String jsonText, {String downloadBaseUrl = defaultDownloadBaseUrl}) {
  final decoded = jsonDecode(jsonText);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Addon catalog root must be a JSON object');
  }

  final addons = <Addon>[];
  decoded.forEach((key, value) {
    if (key.startsWith('_') || key.startsWith(r'$')) {
      return;
    }
    if (value is! List) {
      return;
    }
    final branches = <AddonBranch>[];
    for (final entry in value) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final branch = _parseBranch(entry, key, downloadBaseUrl);
      if (branch != null) {
        branches.add(branch);
      }
    }
    if (branches.isNotEmpty) {
      addons.add(Addon(id: key, branches: branches));
    }
  });

  addons.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  return addons;
}

const String defaultDownloadBaseUrl = 'https://addons.freecad.org/';

AddonBranch? _parseBranch(Map<String, dynamic> raw, String addonId, String downloadBaseUrl) {
  final gitRef = _string(raw['git_ref']);
  if (gitRef == null) {
    return null;
  }
  final relativeCachePath = _string(raw['relative_cache_path']);
  final zipUrl =
      _string(raw['zip_url']) ??
      (relativeCachePath == null
          ? null
          : Uri.parse(downloadBaseUrl).resolve(relativeCachePath).toString());
  if (zipUrl == null) {
    return null;
  }

  return AddonBranch(
    gitRef: gitRef,
    displayName: _string(raw['branch_display_name']) ?? gitRef,
    repositoryUrl: _string(raw['repository']) ?? '',
    zipUrl: zipUrl,
    curated: raw['curated'] == true,
    sparseCache: raw['sparse_cache'] == true,
    relativeCachePath: relativeCachePath,
    freecadMin: _parseVersion(raw['freecad_min']),
    freecadMax: _parseVersion(raw['freecad_max']),
    lastUpdateTime: _parseDate(_string(raw['last_update_time'])),
    note: _string(raw['note']),
    metadata: _parseMetadata(raw['metadata'], addonId),
  );
}

String? _parseVersion(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is Map<String, dynamic>) {
    final list = value['version_as_list'];
    if (list is List) {
      final parts = list
          .map((part) => part?.toString().trim() ?? '')
          .where((part) => part.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join('.');
    }
  }
  return null;
}

DateTime? _parseDate(String? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value);
}

AddonMetadata? _parseMetadata(Object? value, String addonId) {
  if (value is! Map<String, dynamic>) {
    return null;
  }
  final packageXml = _string(value['package_xml']);
  if (packageXml == null) {
    return null;
  }
  final info = parsePackageXml(packageXml);
  if (info == null) {
    return null;
  }

  return AddonMetadata(
    name: info.name.isEmpty ? addonId : info.name,
    description: info.description,
    version: info.version,
    license: info.license,
    minPython: info.minPython,
    tags: info.tags,
    people: info.people,
    content: info.content,
    requirements: _string(value['requirements_txt']) ?? '',
    iconBase64: _string(value['icon_data']),
  );
}

String? _string(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}
