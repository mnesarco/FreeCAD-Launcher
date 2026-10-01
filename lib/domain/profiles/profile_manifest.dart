// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';

const int profileManifestSchemaVersion = 1;

const List<String> manifestConfigFileNames = ['user.cfg', 'system.cfg'];

const int maxManifestConfigLength = 4 * 1024 * 1024;

class ManifestSource {
  const ManifestSource({this.os, this.arch});

  final String? os;
  final String? arch;
}

class ManifestProfileInfo {
  const ManifestProfileInfo({required this.name, this.build, this.channel, this.python});

  final String name;
  final String? build;
  final String? channel;
  final String? python;
}

class ManifestAddon {
  const ManifestAddon({required this.id, this.gitRef, this.version, this.pinned = false});

  final String id;
  final String? gitRef;
  final String? version;
  final bool pinned;
}

class ManifestPackage {
  const ManifestPackage({required this.name, this.version, this.source});

  final String name;
  final String? version;
  final String? source;
}

class ProfileManifest {
  const ProfileManifest({
    this.exportedAt,
    this.source = const ManifestSource(),
    required this.profile,
    this.addons = const [],
    this.pythonPackages = const [],
    this.bundles = const [],
    this.macros = const [],
    this.config = const {},
    this.configFiles = const [],
  });

  final DateTime? exportedAt;
  final ManifestSource source;
  final ManifestProfileInfo profile;
  final List<ManifestAddon> addons;
  final List<ManifestPackage> pythonPackages;
  final List<String> bundles;
  final List<String> macros;
  final Map<String, String> config;
  final List<String> configFiles;
}

class ManifestAbsolutePath {
  const ManifestAbsolutePath({required this.file, required this.path});

  final String file;
  final String path;

  @override
  bool operator ==(Object other) {
    return other is ManifestAbsolutePath && other.file == file && other.path == path;
  }

  @override
  int get hashCode => Object.hash(file, path);

  @override
  String toString() => '$file: $path';
}

String encodeProfileManifest(ProfileManifest manifest) {
  final data = <String, Object?>{
    'schema': profileManifestSchemaVersion,
    if (manifest.exportedAt != null) 'exported_at': manifest.exportedAt!.toUtc().toIso8601String(),
    'source': {
      if (manifest.source.os != null) 'os': manifest.source.os,
      if (manifest.source.arch != null) 'arch': manifest.source.arch,
    },
    'profile': {
      'name': manifest.profile.name,
      if (manifest.profile.build != null) 'build': manifest.profile.build,
      if (manifest.profile.channel != null) 'channel': manifest.profile.channel,
      if (manifest.profile.python != null) 'python': manifest.profile.python,
    },
    'addons': [
      for (final addon in manifest.addons)
        {
          'id': addon.id,
          if (addon.gitRef != null) 'git_ref': addon.gitRef,
          'version': addon.version,
          if (addon.pinned) 'pinned': true,
        },
    ],
    'python_packages': [
      for (final package in manifest.pythonPackages)
        {
          'name': package.name,
          if (package.version != null) 'version': package.version,
          if (package.source != null) 'source': package.source,
        },
    ],
    'bundles': manifest.bundles,
    'config_files': manifest.configFiles,
    if (manifest.config.isNotEmpty) 'config': manifest.config,
    'macros': manifest.macros,
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}

Result<ProfileManifest> decodeProfileManifest(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (error) {
    return Err(AppError(message: 'Invalid JSON: ${error.message}'));
  }
  if (decoded is! Map<String, dynamic>) {
    return const Err(AppError(message: 'The file is not a profile manifest JSON object'));
  }
  if (decoded['schema'] != profileManifestSchemaVersion) {
    return Err(
      AppError(
        message: 'Unsupported manifest schema',
        detail: 'Expected $profileManifestSchemaVersion, found ${decoded['schema']}',
      ),
    );
  }

  final profileJson = decoded['profile'];
  if (profileJson is! Map) {
    return const Err(AppError(message: 'The manifest has no profile section'));
  }
  final name = _trimmedString(profileJson['name']);
  if (name == null) {
    return const Err(AppError(message: 'The manifest profile has no name'));
  }
  final profile = ManifestProfileInfo(
    name: name,
    build: _trimmedString(profileJson['build']),
    channel: _trimmedString(profileJson['channel']),
    python: _trimmedString(profileJson['python']),
  );

  final configJson = decoded['config'];
  final config = <String, String>{};
  if (configJson is Map) {
    var total = 0;
    for (final entry in configJson.entries) {
      final fileName = entry.key;
      final content = entry.value;
      if (fileName is! String || !manifestConfigFileNames.contains(fileName)) {
        continue;
      }
      if (content is! String) {
        continue;
      }
      total += content.length;
      if (total > maxManifestConfigLength) {
        return const Err(AppError(message: 'The manifest config payload is too large'));
      }
      config[fileName] = content;
    }
  }

  final configFiles = <String>[];
  final configFilesJson = decoded['config_files'];
  if (configFilesJson is List) {
    for (final entry in configFilesJson) {
      final value = _trimmedString(entry);
      if (value != null && !configFiles.contains(value)) {
        configFiles.add(value);
      }
    }
  }
  for (final fileName in config.keys) {
    if (!configFiles.contains(fileName)) {
      configFiles.add(fileName);
    }
  }

  final addons = <ManifestAddon>[];
  final addonsJson = decoded['addons'];
  if (addonsJson is List) {
    for (final entry in addonsJson) {
      if (entry is! Map) {
        continue;
      }
      final id = _trimmedString(entry['id']);
      if (id == null) {
        continue;
      }
      addons.add(
        ManifestAddon(
          id: id,
          gitRef: _trimmedString(entry['git_ref']),
          version: _trimmedString(entry['version']),
          pinned: entry['pinned'] == true,
        ),
      );
    }
  }

  final packages = <ManifestPackage>[];
  final packagesJson = decoded['python_packages'];
  if (packagesJson is List) {
    for (final entry in packagesJson) {
      if (entry is! Map) {
        continue;
      }
      final packageName = _trimmedString(entry['name']);
      if (packageName == null) {
        continue;
      }
      packages.add(
        ManifestPackage(
          name: packageName,
          version: _trimmedString(entry['version']),
          source: _trimmedString(entry['source']),
        ),
      );
    }
  }

  final exportedAt = DateTime.tryParse(_trimmedString(decoded['exported_at']) ?? '');
  final sourceJson = decoded['source'];

  return Ok(
    ProfileManifest(
      exportedAt: exportedAt,
      source: sourceJson is Map
          ? ManifestSource(
              os: _trimmedString(sourceJson['os']),
              arch: _trimmedString(sourceJson['arch']),
            )
          : const ManifestSource(),
      profile: profile,
      addons: addons,
      pythonPackages: packages,
      bundles: _stringList(decoded['bundles']),
      macros: _stringList(decoded['macros']),
      config: config,
      configFiles: configFiles,
    ),
  );
}

List<ManifestAbsolutePath> findConfigAbsolutePaths(Map<String, String> config) {
  final results = <ManifestAbsolutePath>[];
  final seen = <String>{};
  for (final entry in config.entries) {
    for (final value in _configValues(entry.value)) {
      final trimmed = value.trim();
      if (!_isAbsolutePath(trimmed)) {
        continue;
      }
      if (!seen.add('${entry.key}\u0000$trimmed')) {
        continue;
      }
      results.add(ManifestAbsolutePath(file: entry.key, path: trimmed));
    }
  }
  return results;
}

Iterable<String> _configValues(String text) sync* {
  for (final match in _elementText.allMatches(text)) {
    yield match.group(1)!;
  }
  for (final match in _doubleQuotedValue.allMatches(text)) {
    yield match.group(1)!;
  }
  for (final match in _singleQuotedValue.allMatches(text)) {
    yield match.group(1)!;
  }
  yield* text.split('\n');
}

final RegExp _elementText = RegExp(r'>([^<>]*)<');
final RegExp _doubleQuotedValue = RegExp(r'="([^"]*)"');
final RegExp _singleQuotedValue = RegExp(r"='([^']*)'");
final RegExp _windowsAbsolute = RegExp(r'^[A-Za-z]:[\\/]');

bool _isAbsolutePath(String value) {
  if (value.length <= 1) {
    return false;
  }
  if (value.startsWith('/') || value.startsWith(r'\\')) {
    return true;
  }
  return _windowsAbsolute.hasMatch(value);
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  final result = <String>[];
  for (final entry in value) {
    final trimmed = _trimmedString(entry);
    if (trimmed != null && !result.contains(trimmed)) {
      result.add(trimmed);
    }
  }
  return result;
}

String? _trimmedString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
