// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/data/catalog/news_feed.dart';
import 'package:freecad_launcher/domain/news/news_item.dart';

class NewsController {
  NewsController({required NewsFeed feed}) : _feed = feed;

  final NewsFeed _feed;

  final items = signal<List<NewsItem>>([]);
  final loading = signal(false);
  final loaded = signal(false);
  final stale = signal(false);
  final error = signal<AppError?>(null);

  Future<void> load(String url, {bool forceRefresh = false}) async {
    loading.value = true;
    error.value = null;
    try {
      final result = await _feed.load(
        sourceUrl: url,
        forceRefresh: forceRefresh,
      );
      items.value = result.items;
      stale.value = result.isStale;
      loaded.value = true;
    } on Object catch (failure) {
      items.value = [];
      stale.value = false;
      loaded.value = true;
      final cause = failure is NewsFeedException
          ? failure.cause ?? failure
          : failure;
      error.value = AppError.from(cause, retryable: true);
    } finally {
      loading.value = false;
    }
  }

  Future<void> retry(String url) => load(url, forceRefresh: true);
}
