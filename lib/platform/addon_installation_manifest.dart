// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';

/// The FreeCAD version recorded by AddonManager installations as three
/// strings (e.g. `["1","1","3"]`); empty when the version cannot be parsed.
List<String> manifestFreeCadVersion(String? version) {
  final parsed = version == null ? null : FreeCadVersion.tryParse(version);
  if (parsed == null) {
    return const [];
  }
  return ['${parsed.major}', '${parsed.minor}', '${parsed.patch}'];
}

/// Maintains the AddonManager installation manifest (`Mod/manifest.json`) so
/// addons installed by the launcher are known to FreeCAD's AddonManager and
/// their copied macros can be cleaned up on removal (D-126).
class AddonInstallationManifest {
  const AddonInstallationManifest({required this.modDirectory});

  static const String fileName = 'manifest.json';

  final String modDirectory;

  String get manifestPath => p.join(modDirectory, fileName);

  /// The `extra_files` recorded for [addonId] (empty when absent).
  List<String> extraFilesOf(String addonId) {
    final entry = _read()[addonId];
    if (entry is! Map) {
      return const [];
    }
    final files = entry['extra_files'];
    if (files is! List) {
      return const [];
    }
    return [
      for (final file in files)
        if (file is String) file,
    ];
  }

  /// Creates or updates the entry for [addonId]; existing entries keep their
  /// `first_installed`/`migrated` values and merge `extra_files`.
  void recordInstallation({
    required String addonId,
    required String branchDisplayName,
    required List<String> extraFiles,
    required List<String> freecadVersion,
    required DateTime now,
  }) {
    final manifest = _read();
    final stamp = _timestamp(now);
    final existing = manifest[addonId];
    if (existing is Map) {
      final entry = Map<String, dynamic>.from(existing);
      entry['last_updated'] = stamp;
      entry['branch_display_name'] = branchDisplayName;
      entry['freecad_version'] = freecadVersion;
      entry['extra_files'] = <String>{...extraFilesOf(addonId), ...extraFiles}.toList();
      manifest[addonId] = entry;
    } else {
      manifest[addonId] = <String, dynamic>{
        'addon_id': addonId,
        'migrated': false,
        'first_installed': stamp,
        'last_updated': stamp,
        'branch_display_name': branchDisplayName,
        'extra_files': List<String>.from(extraFiles),
        'freecad_version': freecadVersion,
      };
    }
    _write(manifest);
  }

  /// Drops the entry for [addonId] (uninstall); no-op when it is absent.
  void removeAddon(String addonId) {
    final manifest = _read();
    if (manifest.remove(addonId) == null) {
      return;
    }
    _write(manifest);
  }

  Map<String, dynamic> _read() {
    final file = File(manifestPath);
    if (!file.existsSync()) {
      return {};
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
    } on FormatException {
      appLogger.warn('Ignoring invalid addon installation manifest $manifestPath', tag: 'addons');
    }
    return {};
  }

  void _write(Map<String, dynamic> manifest) {
    Directory(modDirectory).createSync(recursive: true);
    File(manifestPath).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
  }

  String _timestamp(DateTime now) =>
      now.toUtc().toIso8601String().replaceFirst('Z', '+00:00');
}
