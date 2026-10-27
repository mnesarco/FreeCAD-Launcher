// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:freecad_launcher/platform/checksum.dart';
import 'package:http/http.dart' as http;

/// Reads the SHA-256 GitHub computed for a release asset. FreeCAD stopped publishing
/// `<asset>-SHA256.txt` sidecars in FreeCAD/FreeCAD#33318 (2026-10-14).
Future<String?> fetchReleaseAssetSha256({
  required String tag,
  required String asset,
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient.get(
      Uri.https('api.github.com', '/repos/FreeCAD/FreeCAD/releases/tags/$tag'),
      headers: const {'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode != 200) {
      return null;
    }
    final assets = (jsonDecode(response.body) as Map<String, dynamic>)['assets'] as List<dynamic>;
    for (final entry in assets.cast<Map<String, dynamic>>()) {
      if (entry['name'] == asset) {
        return parseSha256Text(entry['digest'] as String? ?? '');
      }
    }
    return null;
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}
