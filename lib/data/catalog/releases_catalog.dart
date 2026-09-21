import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/data/catalog/github_releases_client.dart';
import 'package:freecad_launcher/data/daos/catalog_cache_dao.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/release_info.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';

enum CatalogFreshness { fresh, refreshed, stale }

class ReleasesCatalogResult {
  const ReleasesCatalogResult({
    required this.releases,
    required this.freshness,
    this.fetchedAt,
    this.rateLimit = const GitHubRateLimit(),
    this.error,
  });

  final List<ReleaseInfo> releases;
  final CatalogFreshness freshness;
  final DateTime? fetchedAt;
  final GitHubRateLimit rateLimit;
  final Object? error;

  bool get isStale => freshness == CatalogFreshness.stale;
}

class CatalogUnavailableException implements Exception {
  const CatalogUnavailableException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'CatalogUnavailableException: $message';
}

class ReleasesHttpException implements Exception {
  const ReleasesHttpException(this.statusCode, this.body);

  final int statusCode;
  final String? body;

  @override
  String toString() => 'GitHub releases request failed with HTTP $statusCode';
}

class ReleasesCatalog {
  ReleasesCatalog({
    required GitHubReleasesClient client,
    required CatalogCacheDao dao,
    required String cacheDirectory,
    this.ttl = const Duration(hours: 6),
    this.maxPages = 5,
    DateTime Function()? clock,
  }) : _client = client,
       _dao = dao,
       _cacheDirectory = cacheDirectory,
       _clock = clock ?? DateTime.now;

  static const String cacheKey = 'github:releases:freecad';
  static const String payloadFileName = 'releases_freecad.json';

  final GitHubReleasesClient _client;
  final CatalogCacheDao _dao;
  final String _cacheDirectory;
  final DateTime Function() _clock;
  final Duration ttl;
  final int maxPages;

  String get _payloadPath => p.join(_cacheDirectory, payloadFileName);

  Future<ReleasesCatalogResult> load({bool forceRefresh = false}) async {
    final now = _clock();
    final entry = await _dao.get(cacheKey);
    final cachedPayload = await _readPayload(entry);

    final isFresh =
        !forceRefresh &&
        entry != null &&
        entry.status == CacheStatus.ok &&
        cachedPayload != null &&
        now.difference(entry.fetchedAt) < ttl;

    if (isFresh) {
      return ReleasesCatalogResult(
        releases: await _parseReleasesJson(cachedPayload),
        freshness: CatalogFreshness.fresh,
        fetchedAt: entry.fetchedAt,
      );
    }

    try {
      final outcome = await _fetchAll(entry);
      if (outcome.notModified) {
        final payload = cachedPayload;
        if (payload == null) {
          throw const CatalogUnavailableException('Server returned 304 but no cached payload exists');
        }
        await _dao.put(
          CatalogCacheEntry(
            key: cacheKey,
            etag: entry?.etag,
            lastModified: entry?.lastModified,
            payloadPath: _payloadPath,
            fetchedAt: now,
            status: CacheStatus.ok,
          ),
        );
        return ReleasesCatalogResult(
          releases: await _parseReleasesJson(payload),
          freshness: CatalogFreshness.refreshed,
          fetchedAt: now,
          rateLimit: outcome.rateLimit,
        );
      }

      final body = outcome.body!;
      await _writePayload(body);
      await _dao.put(
        CatalogCacheEntry(
          key: cacheKey,
          etag: outcome.etag,
          lastModified: outcome.lastModified,
          payloadPath: _payloadPath,
          fetchedAt: now,
          status: CacheStatus.ok,
        ),
      );
      return ReleasesCatalogResult(
        releases: await _parseReleasesJson(body),
        freshness: CatalogFreshness.refreshed,
        fetchedAt: now,
        rateLimit: outcome.rateLimit,
      );
    } on CatalogUnavailableException {
      rethrow;
    } on Object catch (error) {
      if (cachedPayload != null && entry != null) {
        await _dao.put(
          CatalogCacheEntry(
            key: cacheKey,
            etag: entry.etag,
            lastModified: entry.lastModified,
            payloadPath: _payloadPath,
            fetchedAt: entry.fetchedAt,
            status: CacheStatus.stale,
          ),
        );
        return ReleasesCatalogResult(
          releases: await _parseReleasesJson(cachedPayload),
          freshness: CatalogFreshness.stale,
          fetchedAt: entry.fetchedAt,
          error: error,
        );
      }
      throw CatalogUnavailableException('Could not load the FreeCAD release catalog', cause: error);
    }
  }

  Future<List<ReleaseInfo>> _parseReleasesJson(String json) {
    return Isolate.run(() => parseReleasesJson(json));
  }

  Future<_FetchOutcome> _fetchAll(CatalogCacheEntry? entry) async {
    final all = <dynamic>[];
    String? etag;
    String? lastModified;
    var rateLimit = const GitHubRateLimit();
    var page = 1;

    while (page <= maxPages) {
      final response = await _client.fetchReleases(
        page: page,
        etag: page == 1 ? entry?.etag : null,
        lastModified: page == 1 ? entry?.lastModified : null,
      );
      rateLimit = response.rateLimit;

      if (page == 1 && response.isNotModified) {
        return _FetchOutcome.notModified(rateLimit: rateLimit);
      }
      if (!response.isOk) {
        throw ReleasesHttpException(response.statusCode, response.body);
      }

      etag ??= response.etag;
      lastModified ??= response.lastModified;
      all.addAll(jsonDecode(response.body!) as List<dynamic>);

      final next = ReleasesResponse.nextPageFromLink(response.link);
      if (next == null || next <= page) {
        break;
      }
      page = next;
    }

    return _FetchOutcome.body(
      jsonEncode(all),
      etag: etag,
      lastModified: lastModified,
      rateLimit: rateLimit,
    );
  }

  Future<String?> _readPayload(CatalogCacheEntry? entry) async {
    if (entry == null) {
      return null;
    }
    final file = File(_payloadPath);
    if (!file.existsSync()) {
      return null;
    }
    return file.readAsString();
  }

  Future<void> _writePayload(String body) async {
    await Directory(_cacheDirectory).create(recursive: true);
    final part = File('$_payloadPath.part');
    await part.writeAsString(body, flush: true);
    await part.rename(_payloadPath);
  }
}

class _FetchOutcome {
  const _FetchOutcome._({this.body, this.etag, this.lastModified, required this.rateLimit, this.notModified = false});

  factory _FetchOutcome.body(
    String body, {
    String? etag,
    String? lastModified,
    required GitHubRateLimit rateLimit,
  }) {
    return _FetchOutcome._(body: body, etag: etag, lastModified: lastModified, rateLimit: rateLimit);
  }

  factory _FetchOutcome.notModified({required GitHubRateLimit rateLimit}) {
    return _FetchOutcome._(rateLimit: rateLimit, notModified: true);
  }

  final String? body;
  final String? etag;
  final String? lastModified;
  final GitHubRateLimit rateLimit;
  final bool notModified;
}
