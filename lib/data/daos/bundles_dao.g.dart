// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bundles_dao.dart';

// ignore_for_file: type=lint
mixin _$BundlesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BundlesTable get bundles => attachedDatabase.bundles;
  $BundleItemsTable get bundleItems => attachedDatabase.bundleItems;
  BundlesDaoManager get managers => BundlesDaoManager(this);
}

class BundlesDaoManager {
  final _$BundlesDaoMixin _db;
  BundlesDaoManager(this._db);
  $$BundlesTableTableManager get bundles =>
      $$BundlesTableTableManager(_db.attachedDatabase, _db.bundles);
  $$BundleItemsTableTableManager get bundleItems =>
      $$BundleItemsTableTableManager(_db.attachedDatabase, _db.bundleItems);
}
