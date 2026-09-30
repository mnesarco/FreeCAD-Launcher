// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:freecad_launcher/domain/settings/app_settings.dart';
import 'package:freecad_launcher/platform/cache_service.dart';

class CacheController {
  CacheController({required CacheService service}) : _service = service;

  final CacheService _service;

  final sizes = signal<Map<CacheCategory, int>>({});
  final busy = signal(false);

  Future<void> refresh() async {
    sizes.value = await _service.sizes();
  }

  Future<int> clear(CacheCategory category) async {
    busy.value = true;
    try {
      final freed = await _service.clear(category);
      await refresh();
      return freed;
    } finally {
      busy.value = false;
    }
  }

  Future<int> prune(CacheRetention retention) async {
    final freed = await _service.pruneDownloads(retention);
    if (freed > 0) {
      await refresh();
    }
    return freed;
  }
}
