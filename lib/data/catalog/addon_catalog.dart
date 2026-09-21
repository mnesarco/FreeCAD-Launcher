import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'package:freecad_launcher/data/catalog/addon_catalog_parser.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/daos/catalog_cache_dao.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:freecad_launcher/platform/downloader.dart';

class AddonCatalogResult {
  const AddonCatalogResult({
    required this.addons,
    required this.freshness,
    this.fetchedAt,
    this.error,
  });

  final List<Addon> addons;
  final CatalogFreshness freshness;
  final DateTime? fetchedAt;
  final Object? error;

  bool get isStale => freshness == CatalogFreshness.stale;
}

class AddonCatalogUnavailableException implements Exception {
  const AddonCatalogUnavailableException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AddonCatalogUnavailableException: $message';
}

class AddonCatalog {
  AddonCatalog({
    required Downloader downloader,
    required CatalogCacheDao dao,
    required String cacheDirectory,
    Uri? sourceUrl,
    this.ttl = const Duration(hours: 6),
    DateTime Function()? clock,
  }) : _downloader = downloader,
       _dao = dao,
       _cacheDirectory = cacheDirectory,
       _sourceUrl = sourceUrl ?? defaultSourceUrl,
       _clock = clock ?? DateTime.now;

  static const String cacheKey = 'addons:catalog';
  static const String payloadFileName = 'addon_catalog_cache.zip';
  static const String jsonEntryName = 'addon_catalog_cache.json';
  static final Uri defaultSourceUrl = Uri.parse(
    'https://addons.freecad.org/addon_catalog_cache.zip',
  );

  final Downloader _downloader;
  final CatalogCacheDao _dao;
  final String _cacheDirectory;
  final Uri _sourceUrl;
  final DateTime Function() _clock;
  final Duration ttl;

  String get payloadPath => p.join(_cacheDirectory, payloadFileName);

  bool get hasCachedPayload => File(payloadPath).existsSync();

  Future<AddonCatalogResult> load({bool forceRefresh = false}) async {
    final now = _clock();
    final entry = await _dao.get(cacheKey);
    final isFresh =
        !forceRefresh &&
        entry != null &&
        entry.status == CacheStatus.ok &&
        hasCachedPayload &&
        now.difference(entry.fetchedAt) < ttl;

    if (isFresh) {
      return AddonCatalogResult(
        addons: await _parseCachedPayload(),
        freshness: CatalogFreshness.fresh,
        fetchedAt: entry.fetchedAt,
      );
    }

    try {
      await _downloader.download(
        uri: _sourceUrl,
        fileName: payloadFileName,
        directory: _cacheDirectory,
      );
      final addons = await _parseCachedPayload();
      await _dao.put(
        CatalogCacheEntry(
          key: cacheKey,
          payloadPath: payloadPath,
          fetchedAt: now,
          status: CacheStatus.ok,
        ),
      );
      return AddonCatalogResult(
        addons: addons,
        freshness: CatalogFreshness.refreshed,
        fetchedAt: now,
      );
    } on Object catch (error) {
      if (entry != null && hasCachedPayload) {
        await _dao.put(
          CatalogCacheEntry(
            key: cacheKey,
            etag: entry.etag,
            lastModified: entry.lastModified,
            payloadPath: payloadPath,
            fetchedAt: entry.fetchedAt,
            status: CacheStatus.stale,
          ),
        );
        return AddonCatalogResult(
          addons: await _parseCachedPayload(),
          freshness: CatalogFreshness.stale,
          fetchedAt: entry.fetchedAt,
          error: error,
        );
      }
      throw AddonCatalogUnavailableException(
        'Could not load the addon catalog',
        cause: error,
      );
    }
  }

  Future<List<Addon>?> cachedAddons() async {
    if (!hasCachedPayload) {
      return null;
    }
    try {
      return await _parseCachedPayload();
    } on Object {
      return null;
    }
  }

  Future<List<Addon>> _parseCachedPayload() async {
    final file = File(payloadPath);
    if (!file.existsSync()) {
      throw AddonCatalogUnavailableException('Cached catalog payload is missing');
    }
    final bytes = await file.readAsBytes();
    return Isolate.run(() => parseAddonCatalog(extractCatalogJson(bytes)));
  }

  static String extractCatalogJson(List<int> zipBytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } on Object catch (error) {
      throw FormatException('Addon catalog zip is not readable: $error');
    }

    ArchiveFile? entry;
    for (final file in archive.files) {
      if (file.name == jsonEntryName || file.name.endsWith('.json')) {
        entry = file;
        break;
      }
    }
    if (entry == null || !entry.isFile) {
      throw const FormatException('Addon catalog zip contains no JSON entry');
    }
    return utf8.decode(entry.content);
  }
}
