import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/daos/catalog_cache_dao.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/platform/downloader.dart';

class MacroCatalogResult {
  const MacroCatalogResult({
    required this.macros,
    required this.freshness,
    this.fetchedAt,
    this.error,
  });

  final List<MacroCatalogEntry> macros;
  final CatalogFreshness freshness;
  final DateTime? fetchedAt;
  final Object? error;

  bool get isStale => freshness == CatalogFreshness.stale;
}

class MacroCatalogException implements Exception {
  const MacroCatalogException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'MacroCatalogException: $message';
}

class MacroCatalog {
  MacroCatalog({
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

  static const String cacheKey = 'macros:catalog';
  static const String payloadFileName = 'macro_cache.zip';
  static const String jsonEntryName = 'macro_cache.json';
  static const String hashFileName = 'macro_cache.zip.sha256';
  static final Uri defaultSourceUrl = Uri.parse(
    'https://addons.freecad.org/macro_cache.zip',
  );

  final Downloader _downloader;
  final CatalogCacheDao _dao;
  final String _cacheDirectory;
  final Uri _sourceUrl;
  final DateTime Function() _clock;
  final Duration ttl;

  String get payloadPath => p.join(_cacheDirectory, payloadFileName);

  bool get hasCachedPayload => File(payloadPath).existsSync();

  Future<MacroCatalogResult> load({bool forceRefresh = false}) async {
    final now = _clock();
    final entry = await _dao.get(cacheKey);
    final isFresh =
        !forceRefresh &&
        entry != null &&
        entry.status == CacheStatus.ok &&
        hasCachedPayload &&
        now.difference(entry.fetchedAt) < ttl;

    if (isFresh) {
      return MacroCatalogResult(
        macros: await _parseCachedPayload(),
        freshness: CatalogFreshness.fresh,
        fetchedAt: entry.fetchedAt,
      );
    }

    try {
      final hash = await _fetchHash();
      if (hash != null && entry != null && entry.etag == hash && hasCachedPayload) {
        await _dao.put(
          CatalogCacheEntry(
            key: cacheKey,
            etag: hash,
            payloadPath: payloadPath,
            fetchedAt: now,
            status: CacheStatus.ok,
          ),
        );
        return MacroCatalogResult(
          macros: await _parseCachedPayload(),
          freshness: CatalogFreshness.fresh,
          fetchedAt: now,
        );
      }
      await _downloader.download(
        uri: _sourceUrl,
        fileName: payloadFileName,
        directory: _cacheDirectory,
        expectedSha256: hash,
      );
      final macros = await _parseCachedPayload();
      await _dao.put(
        CatalogCacheEntry(
          key: cacheKey,
          etag: hash,
          payloadPath: payloadPath,
          fetchedAt: now,
          status: CacheStatus.ok,
        ),
      );
      return MacroCatalogResult(
        macros: macros,
        freshness: CatalogFreshness.refreshed,
        fetchedAt: now,
      );
    } on Object catch (error) {
      if (entry != null && hasCachedPayload) {
        await _dao.put(
          CatalogCacheEntry(
            key: cacheKey,
            etag: entry.etag,
            payloadPath: payloadPath,
            fetchedAt: entry.fetchedAt,
            status: CacheStatus.stale,
          ),
        );
        return MacroCatalogResult(
          macros: await _parseCachedPayload(),
          freshness: CatalogFreshness.stale,
          fetchedAt: entry.fetchedAt,
          error: error,
        );
      }
      throw MacroCatalogException('Could not load the macro catalog', cause: error);
    }
  }

  Future<String?> _fetchHash() async {
    try {
      await _downloader.download(
        uri: Uri.parse('$_sourceUrl.sha256'),
        fileName: hashFileName,
        directory: _cacheDirectory,
      );
      final file = File(p.join(_cacheDirectory, hashFileName));
      final text = (await file.readAsString()).trim().split(RegExp(r'\s+')).first;
      return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(text) ? text.toLowerCase() : null;
    } on Object {
      return null;
    }
  }

  Future<List<MacroCatalogEntry>> _parseCachedPayload() async {
    final file = File(payloadPath);
    if (!file.existsSync()) {
      throw const MacroCatalogException('Cached macro catalog payload is missing');
    }
    return parseMacroCatalog(extractMacroCatalogJson(await file.readAsBytes()));
  }

  static String extractMacroCatalogJson(List<int> zipBytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } on Object catch (error) {
      throw FormatException('Macro catalog zip is not readable: $error');
    }

    ArchiveFile? entry;
    for (final file in archive.files) {
      if (file.name == jsonEntryName || file.name.endsWith('.json')) {
        entry = file;
        break;
      }
    }
    if (entry == null || !entry.isFile) {
      throw const FormatException('Macro catalog zip contains no JSON entry');
    }
    return utf8.decode(entry.content);
  }
}
