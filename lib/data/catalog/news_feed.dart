// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/daos/catalog_cache_dao.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:freecad_launcher/domain/news/news_item.dart';
import 'package:freecad_launcher/platform/downloader.dart';

class NewsFeedResult {
  const NewsFeedResult({
    required this.items,
    required this.freshness,
    this.fetchedAt,
    this.error,
  });

  final List<NewsItem> items;
  final CatalogFreshness freshness;
  final DateTime? fetchedAt;
  final Object? error;

  bool get isStale => freshness == CatalogFreshness.stale;
}

class NewsFeedException implements Exception {
  const NewsFeedException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'NewsFeedException: $message';
}

class NewsFeed {
  NewsFeed({
    required Downloader downloader,
    required CatalogCacheDao dao,
    required String cacheDirectory,
    this.ttl = const Duration(hours: 6),
    DateTime Function()? clock,
  }) : _downloader = downloader,
       _dao = dao,
       _cacheDirectory = cacheDirectory,
       _clock = clock ?? DateTime.now;

  static const String cacheKey = 'news:feed';
  static const String payloadFileName = 'news_feed.xml';

  final Downloader _downloader;
  final CatalogCacheDao _dao;
  final String _cacheDirectory;
  final DateTime Function() _clock;
  final Duration ttl;

  String get payloadPath => p.join(_cacheDirectory, payloadFileName);

  bool get hasCachedPayload => File(payloadPath).existsSync();

  Future<NewsFeedResult> load({
    required String sourceUrl,
    bool forceRefresh = false,
  }) async {
    final uri = Uri.tryParse(sourceUrl.trim());
    if (uri == null || !uri.hasScheme || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw NewsFeedException('Invalid news feed URL: "$sourceUrl"');
    }

    final now = _clock();
    final entry = await _dao.get(cacheKey);
    final urlMatches = entry?.etag == uri.toString();
    final isFresh =
        !forceRefresh &&
        entry != null &&
        entry.status == CacheStatus.ok &&
        urlMatches &&
        hasCachedPayload &&
        now.difference(entry.fetchedAt) < ttl;

    if (isFresh) {
      return NewsFeedResult(
        items: await _parseCachedPayload(),
        freshness: CatalogFreshness.fresh,
        fetchedAt: entry.fetchedAt,
      );
    }

    try {
      await _downloader.download(
        uri: uri,
        fileName: payloadFileName,
        directory: _cacheDirectory,
      );
      final items = await _parseCachedPayload();
      await _dao.put(
        CatalogCacheEntry(
          key: cacheKey,
          etag: uri.toString(),
          payloadPath: payloadPath,
          fetchedAt: now,
          status: CacheStatus.ok,
        ),
      );
      return NewsFeedResult(
        items: items,
        freshness: CatalogFreshness.refreshed,
        fetchedAt: now,
      );
    } on Object catch (error) {
      if (entry != null && urlMatches && hasCachedPayload) {
        await _dao.put(
          CatalogCacheEntry(
            key: cacheKey,
            etag: entry.etag,
            payloadPath: payloadPath,
            fetchedAt: entry.fetchedAt,
            status: CacheStatus.stale,
          ),
        );
        return NewsFeedResult(
          items: await _parseCachedPayload(),
          freshness: CatalogFreshness.stale,
          fetchedAt: entry.fetchedAt,
          error: error,
        );
      }
      throw NewsFeedException('Could not load the news feed', cause: error);
    }
  }

  Future<List<NewsItem>> _parseCachedPayload() async {
    final file = File(payloadPath);
    if (!file.existsSync()) {
      throw const NewsFeedException('Cached news feed payload is missing');
    }
    return parseNewsFeed(await file.readAsString());
  }
}

List<NewsItem> parseNewsFeed(String xmlText) {
  final document = XmlDocument.parse(xmlText);
  final root = document.rootElement.name.local.toLowerCase();
  final items = <NewsItem>[];

  if (root == 'rss' || root == 'rdf') {
    for (final element in document.findAllElements('item')) {
      final title = _cleanText(_childText(element, 'title'));
      final link = _childText(element, 'link') ?? _childText(element, 'guid');
      if (title == null || link == null || link.isEmpty) {
        continue;
      }
      items.add(
        NewsItem(
          title: title,
          link: link,
          publishedAt: _parseRssDate(_childText(element, 'pubDate')),
          summary: _cleanText(_childText(element, 'description')),
        ),
      );
    }
  } else if (root == 'feed') {
    for (final element in document.findAllElements('entry')) {
      final title = _cleanText(_childText(element, 'title'));
      final link = _atomLink(element);
      if (title == null || link == null || link.isEmpty) {
        continue;
      }
      items.add(
        NewsItem(
          title: title,
          link: link,
          publishedAt: _parseIsoDate(
            _childText(element, 'updated') ?? _childText(element, 'published'),
          ),
          summary: _cleanText(
            _childText(element, 'summary') ?? _childText(element, 'content'),
          ),
        ),
      );
    }
  }

  items.sort((a, b) {
    final left = a.publishedAt;
    final right = b.publishedAt;
    if (left == null && right == null) {
      return a.title.compareTo(b.title);
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }
    return right.compareTo(left);
  });
  return items;
}

String? _childText(XmlElement element, String name) {
  for (final child in element.childElements) {
    if (child.name.local.toLowerCase() == name.toLowerCase()) {
      final text = child.innerText.trim();
      return text.isEmpty ? null : text;
    }
  }
  return null;
}

String? _atomLink(XmlElement entry) {
  for (final link in entry.childElements) {
    if (link.name.local.toLowerCase() != 'link') {
      continue;
    }
    final rel = link.getAttribute('rel');
    if (rel == null || rel == 'alternate') {
      final href = link.getAttribute('href');
      if (href != null && href.isNotEmpty) {
        return href;
      }
    }
  }
  return _childText(entry, 'id');
}

DateTime? _parseRssDate(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  final match = RegExp(
    r'^(?:\w{3},\s*)?(\d{1,2})\s+(\w{3})\s+(\d{2,4})\s+'
    r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(.*)$',
  ).firstMatch(trimmed);
  if (match != null) {
    final day = int.tryParse(match.group(1)!);
    final month = _months[match.group(2)!.toLowerCase()];
    var year = int.tryParse(match.group(3)!);
    final hour = int.tryParse(match.group(4)!);
    final minute = int.tryParse(match.group(5)!);
    final second = int.tryParse(match.group(6) ?? '0') ?? 0;
    if (day != null &&
        month != null &&
        year != null &&
        hour != null &&
        minute != null) {
      if (year < 100) {
        year += year < 70 ? 2000 : 1900;
      }
      var parsed = DateTime.utc(year, month, day, hour, minute, second);
      final offset = _zoneOffset(match.group(7) ?? '');
      if (offset != null) {
        parsed = parsed.subtract(offset);
      }
      return parsed;
    }
  }
  return DateTime.tryParse(trimmed);
}

const Map<String, int> _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

Duration? _zoneOffset(String zone) {
  final upper = zone.trim().toUpperCase();
  if (upper.isEmpty || upper == 'GMT' || upper == 'UTC' || upper == 'Z') {
    return Duration.zero;
  }
  final match = RegExp(r'^([+-])(\d{2}):?(\d{2})$').firstMatch(upper);
  if (match == null) {
    return null;
  }
  final sign = match.group(1) == '-' ? -1 : 1;
  return Duration(
    hours: sign * int.parse(match.group(2)!),
    minutes: sign * int.parse(match.group(3)!),
  );
}

DateTime? _parseIsoDate(String? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value);
}

String? _cleanText(String? value) {
  if (value == null) {
    return null;
  }
  final withoutTags = value.replaceAll(RegExp(r'<[^>]*>'), ' ');
  final collapsed = withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  return collapsed.isEmpty ? null : collapsed;
}
