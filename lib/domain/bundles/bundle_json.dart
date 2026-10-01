// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';

const int bundleSchemaVersion = 1;

class BundleJsonItem {
  const BundleJsonItem({required this.addonId, this.gitRef});

  final String addonId;
  final String? gitRef;
}

class BundleJson {
  const BundleJson({required this.name, this.description, required this.items});

  final String name;
  final String? description;
  final List<BundleJsonItem> items;
}

String encodeBundleJson(BundleJson bundle) {
  final data = <String, Object?>{
    'schema': bundleSchemaVersion,
    'name': bundle.name,
    if ((bundle.description ?? '').isNotEmpty) 'description': bundle.description,
    'addons': [
      for (final item in bundle.items) {'id': item.addonId, 'git_ref': item.gitRef},
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}

Result<BundleJson> decodeBundleJson(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (error) {
    return Err(AppError(message: 'Invalid JSON: ${error.message}'));
  }
  if (decoded is! Map<String, dynamic>) {
    return const Err(AppError(message: 'The file is not a bundle JSON object'));
  }
  if (decoded['schema'] != bundleSchemaVersion) {
    return Err(
      AppError(
        message: 'Unsupported bundle schema',
        detail: 'Expected $bundleSchemaVersion, found ${decoded['schema']}',
      ),
    );
  }
  final name = (decoded['name'] as String?)?.trim() ?? '';
  if (name.isEmpty) {
    return const Err(AppError(message: 'The bundle has no name'));
  }
  final description = (decoded['description'] as String?)?.trim();
  final addons = decoded['addons'];
  if (addons is! List) {
    return const Err(AppError(message: 'The bundle has no addon list'));
  }

  final items = <BundleJsonItem>[];
  for (final entry in addons) {
    if (entry is! Map) {
      continue;
    }
    final id = entry['id'];
    if (id is! String || id.trim().isEmpty) {
      continue;
    }
    final gitRef = entry['git_ref'];
    items.add(
      BundleJsonItem(
        addonId: id.trim(),
        gitRef: gitRef is String && gitRef.trim().isNotEmpty ? gitRef.trim() : null,
      ),
    );
  }
  return Ok(
    BundleJson(
      name: name,
      description: description != null && description.isNotEmpty ? description : null,
      items: items,
    ),
  );
}
