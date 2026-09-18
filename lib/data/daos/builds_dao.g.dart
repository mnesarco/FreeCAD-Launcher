// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'builds_dao.dart';

// ignore_for_file: type=lint
mixin _$BuildsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BuildsTable get builds => attachedDatabase.builds;
  BuildsDaoManager get managers => BuildsDaoManager(this);
}

class BuildsDaoManager {
  final _$BuildsDaoMixin _db;
  BuildsDaoManager(this._db);
  $$BuildsTableTableManager get builds =>
      $$BuildsTableTableManager(_db.attachedDatabase, _db.builds);
}
