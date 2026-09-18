// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$CatalogCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $CatalogCacheTable get catalogCache => attachedDatabase.catalogCache;
  CatalogCacheDaoManager get managers => CatalogCacheDaoManager(this);
}

class CatalogCacheDaoManager {
  final _$CatalogCacheDaoMixin _db;
  CatalogCacheDaoManager(this._db);
  $$CatalogCacheTableTableManager get catalogCache =>
      $$CatalogCacheTableTableManager(_db.attachedDatabase, _db.catalogCache);
}
