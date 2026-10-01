// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

class ReleaseAsset {
  const ReleaseAsset({required this.name, required this.downloadUrl, this.size = 0});

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String,
      downloadUrl: json['browser_download_url'] as String,
      size: json['size'] as int? ?? 0,
    );
  }

  final String name;
  final String downloadUrl;
  final int size;
}

class ReleaseInfo {
  const ReleaseInfo({
    required this.tagName,
    required this.prerelease,
    required this.htmlUrl,
    required this.assets,
    this.publishedAt,
    this.body = '',
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    return ReleaseInfo(
      tagName: json['tag_name'] as String,
      prerelease: json['prerelease'] as bool? ?? false,
      htmlUrl: json['html_url'] as String? ?? '',
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      body: json['body'] as String? ?? '',
      assets: [
        for (final asset in json['assets'] as List<dynamic>? ?? const [])
          ReleaseAsset.fromJson(asset as Map<String, dynamic>),
      ],
    );
  }

  final String tagName;
  final bool prerelease;
  final String htmlUrl;
  final DateTime? publishedAt;
  final String body;
  final List<ReleaseAsset> assets;
}

List<ReleaseInfo> parseReleasesJson(String body) {
  final decoded = jsonDecode(body) as List<dynamic>;
  return [
    for (final release in decoded) ReleaseInfo.fromJson(release as Map<String, dynamic>),
  ];
}
