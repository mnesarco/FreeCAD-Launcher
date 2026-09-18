// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_addons_dao.dart';

// ignore_for_file: type=lint
mixin _$InstalledAddonsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BuildsTable get builds => attachedDatabase.builds;
  $ProfilesTable get profiles => attachedDatabase.profiles;
  $InstalledAddonsTable get installedAddons => attachedDatabase.installedAddons;
  InstalledAddonsDaoManager get managers => InstalledAddonsDaoManager(this);
}

class InstalledAddonsDaoManager {
  final _$InstalledAddonsDaoMixin _db;
  InstalledAddonsDaoManager(this._db);
  $$BuildsTableTableManager get builds =>
      $$BuildsTableTableManager(_db.attachedDatabase, _db.builds);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db.attachedDatabase, _db.profiles);
  $$InstalledAddonsTableTableManager get installedAddons =>
      $$InstalledAddonsTableTableManager(
        _db.attachedDatabase,
        _db.installedAddons,
      );
}
