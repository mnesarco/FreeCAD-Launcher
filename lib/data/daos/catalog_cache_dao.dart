import 'package:drift/drift.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/tables/cache.dart';

part 'catalog_cache_dao.g.dart';

@DriftAccessor(tables: [CatalogCache])
class CatalogCacheDao extends DatabaseAccessor<AppDatabase> with _$CatalogCacheDaoMixin {
  CatalogCacheDao(super.db);

  Future<CatalogCacheEntry?> get(String key) =>
      (select(catalogCache)..where((t) => t.key.equals(key))).getSingleOrNull();

  Future<List<CatalogCacheEntry>> getAll() => select(catalogCache).get();

  Future<void> put(CatalogCacheEntry entry) =>
      into(catalogCache).insertOnConflictUpdate(entry);

  Future<int> remove(String key) =>
      (delete(catalogCache)..where((t) => t.key.equals(key))).go();
}
