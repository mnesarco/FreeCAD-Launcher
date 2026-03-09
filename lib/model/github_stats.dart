import 'dart:convert';
import 'dart:io';

import 'package:freecad_launcher/config.dart';
import 'package:freecad_launcher/service/download.dart';

/// GitHub repository statistics for a single addon.
class GitHubStats {
  final DateTime? pushedAt;
  final int stargazersCount;
  final int forksCount;
  final int openIssuesCount;
  final int networkCount;
  final int subscribersCount;
  final DateTime? createdAt;
  final String? license;
  final String starsDisplay;

  const GitHubStats({
    this.pushedAt,
    this.stargazersCount = 0,
    this.forksCount = 0,
    this.openIssuesCount = 0,
    this.networkCount = 0,
    this.subscribersCount = 0,
    this.createdAt,
    this.license,
  }) : starsDisplay = stargazersCount == 1 ? '$stargazersCount star' : '$stargazersCount stars';

  factory GitHubStats.fromJson(Map<String, dynamic> json) {
    return GitHubStats(
      pushedAt: _parseDateTime(json['pushed_at']),
      stargazersCount: json['stargazers_count'] as int? ?? 0,
      forksCount: json['forks_count'] as int? ?? 0,
      openIssuesCount: json['open_issues_count'] as int? ?? 0,
      networkCount: json['network_count'] as int? ?? 0,
      subscribersCount: json['subscribers_count'] as int? ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      license: json['license'] as String?,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

/// Collection of GitHub stats for all addons, keyed by repository URL.
class AddonStatsCatalog {
  final Map<String, GitHubStats> stats;

  const AddonStatsCatalog(this.stats);

  /// Look up stats for a given repository URL. Returns null if not found.
  GitHubStats? operator [](String repositoryUrl) => stats[repositoryUrl];

  static Future<AddonStatsCatalog> download(DownloadManager downloadManager) async {
    final cache = await downloadManager.download(
      mainConfig.addonsStatsUrl,
      'addon_stats.json',
      mainConfig.addonsCatalogTTL,
    );
    final raw = await File(cache).readAsString();
    return _parse(raw);
  }

  static AddonStatsCatalog _parse(String raw) {
    final Map<String, dynamic> json = jsonDecode(raw);
    final Map<String, GitHubStats> result = {};
    for (final entry in json.entries) {
      if (entry.value is Map<String, dynamic>) {
        final map = entry.value as Map<String, dynamic>;
        if (map.isNotEmpty) {
          result[entry.key] = GitHubStats.fromJson(map);
        }
      }
    }
    return AddonStatsCatalog(result);
  }
}
