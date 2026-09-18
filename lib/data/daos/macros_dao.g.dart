// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'macros_dao.dart';

// ignore_for_file: type=lint
mixin _$MacrosDaoMixin on DatabaseAccessor<AppDatabase> {
  $BuildsTable get builds => attachedDatabase.builds;
  $ProfilesTable get profiles => attachedDatabase.profiles;
  $MacrosTable get macros => attachedDatabase.macros;
  MacrosDaoManager get managers => MacrosDaoManager(this);
}

class MacrosDaoManager {
  final _$MacrosDaoMixin _db;
  MacrosDaoManager(this._db);
  $$BuildsTableTableManager get builds =>
      $$BuildsTableTableManager(_db.attachedDatabase, _db.builds);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db.attachedDatabase, _db.profiles);
  $$MacrosTableTableManager get macros =>
      $$MacrosTableTableManager(_db.attachedDatabase, _db.macros);
}
