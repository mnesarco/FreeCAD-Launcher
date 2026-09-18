import 'package:http/http.dart' as http;

import 'package:freecad_launcher/core/constants.dart';

class GitHubRateLimit {
  const GitHubRateLimit({this.limit, this.remaining, this.resetAt});

  final int? limit;
  final int? remaining;
  final DateTime? resetAt;

  bool get isExhausted => remaining != null && remaining! <= 0;
}

class ReleasesResponse {
  const ReleasesResponse({
    required this.statusCode,
    this.body,
    this.etag,
    this.lastModified,
    this.rateLimit = const GitHubRateLimit(),
  });

  final int statusCode;
  final String? body;
  final String? etag;
  final String? lastModified;
  final GitHubRateLimit rateLimit;

  bool get isOk => statusCode == 200;

  bool get isNotModified => statusCode == 304;

  bool get isRateLimited => statusCode == 403 || statusCode == 429;
}

class GitHubReleasesClient {
  GitHubReleasesClient({
    required http.Client client,
    this.repository = 'FreeCAD/FreeCAD',
    this.tokenProvider,
  }) : _client = client;

  final http.Client _client;
  final String repository;
  final String? Function()? tokenProvider;

  Future<ReleasesResponse> fetchReleases({
    int page = 1,
    int perPage = 100,
    String? etag,
    String? lastModified,
  }) async {
    final uri = Uri.https('api.github.com', '/repos/$repository/releases', {
      'per_page': '$perPage',
      'page': '$page',
    });

    final headers = <String, String>{
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': '$appName/$appVersion',
    };

    final token = tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (etag != null) {
      headers['If-None-Match'] = etag;
    }
    if (lastModified != null) {
      headers['If-Modified-Since'] = lastModified;
    }

    final response = await _client.get(uri, headers: headers);

    return ReleasesResponse(
      statusCode: response.statusCode,
      body: response.statusCode == 304 ? null : response.body,
      etag: response.headers['etag'],
      lastModified: response.headers['last-modified'],
      rateLimit: _parseRateLimit(response.headers),
    );
  }

  GitHubRateLimit _parseRateLimit(Map<String, String> headers) {
    final reset = int.tryParse(headers['x-ratelimit-reset'] ?? '');
    return GitHubRateLimit(
      limit: int.tryParse(headers['x-ratelimit-limit'] ?? ''),
      remaining: int.tryParse(headers['x-ratelimit-remaining'] ?? ''),
      resetAt: reset == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(reset * 1000, isUtc: true),
    );
  }
}
