// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/catalog/news_feed.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/daos/catalog_cache_dao.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:freecad_launcher/domain/settings/app_settings.dart';
import 'package:freecad_launcher/platform/paths.dart';

class CacheService {
  CacheService({
    required AppPaths paths,
    required CatalogCacheDao cacheDao,
    DateTime Function()? clock,
  }) : _paths = paths,
       _cacheDao = cacheDao,
       _clock = clock ?? DateTime.now;

  static const Map<CacheCategory, String> catalogKeys = {
    CacheCategory.github: ReleasesCatalog.cacheKey,
    CacheCategory.addons: AddonCatalog.cacheKey,
    CacheCategory.macros: MacroCatalog.cacheKey,
    CacheCategory.news: NewsFeed.cacheKey,
  };

  final AppPaths _paths;
  final CatalogCacheDao _cacheDao;
  final DateTime Function() _clock;

  String directoryFor(CacheCategory category) => switch (category) {
    CacheCategory.downloads => _paths.downloadsCacheDir,
    CacheCategory.github => _paths.githubCacheDir,
    CacheCategory.addons => _paths.addonsCacheDir,
    CacheCategory.macros => _paths.macrosCacheDir,
    CacheCategory.news => _paths.newsCacheDir,
  };

  Future<Map<CacheCategory, int>> sizes() async {
    return {
      for (final category in CacheCategory.values)
        category: _directorySize(directoryFor(category)),
    };
  }

  Future<int> clear(CacheCategory category) async {
    final directory = Directory(directoryFor(category));
    final freed = _directorySize(directory.path);
    if (directory.existsSync()) {
      for (final entity in directory.listSync()) {
        try {
          entity.deleteSync(recursive: true);
        } on FileSystemException {
          continue;
        }
      }
    }
    final key = catalogKeys[category];
    if (key != null) {
      await _cacheDao.remove(key);
    }
    return freed;
  }

  Future<int> pruneDownloads(CacheRetention retention) async {
    final days = retention.days;
    if (days == null) {
      return 0;
    }
    final directory = Directory(_paths.downloadsCacheDir);
    if (!directory.existsSync()) {
      return 0;
    }
    final cutoff = _clock().subtract(Duration(days: days));
    var freed = 0;
    for (final entity in directory.listSync()) {
      if (entity is! File) {
        continue;
      }
      try {
        if (entity.statSync().modified.isBefore(cutoff)) {
          freed += entity.lengthSync();
          entity.deleteSync();
        }
      } on FileSystemException {
        continue;
      }
    }
    return freed;
  }

  int _directorySize(String path) {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      return 0;
    }
    var total = 0;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      try {
        total += entity.lengthSync();
      } on FileSystemException {
        continue;
      }
    }
    return total;
  }
}
