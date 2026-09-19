import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;

class FakeAddonCatalog extends AddonCatalog {
  FakeAddonCatalog({
    required super.downloader,
    required super.dao,
    required super.cacheDirectory,
  });

  AddonCatalogResult? result;
  Object? error;
  int loads = 0;

  @override
  Future<AddonCatalogResult> load({bool forceRefresh = false}) async {
    loads++;
    if (error != null) {
      throw error!;
    }
    return result ??
        const AddonCatalogResult(addons: [], freshness: CatalogFreshness.fresh);
  }
}
