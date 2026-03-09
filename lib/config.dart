import 'package:intl/intl.dart';

class MainConfig {
  final String addonsCatalogUrl = 'https://addons.freecad.org/addon_catalog_cache.zip';
  final int addonsCatalogTTL = 3600 * 6;
  final String addonsServerStatus = 'https://addons.freecad.org/status';
  final String addonsStatsUrl = 'https://www.freecad.org/addon_stats.json';
  final String addonsDownloadBaseUrl = 'https://addons.freecad.org/';
  final bool showCuratedIcon = true;
  final bool showGithubStats = true;
  final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
}

final mainConfig = MainConfig();
