// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'python_packages_dao.dart';

// ignore_for_file: type=lint
mixin _$PythonPackagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BuildsTable get builds => attachedDatabase.builds;
  $ProfilesTable get profiles => attachedDatabase.profiles;
  $PythonPackagesTable get pythonPackages => attachedDatabase.pythonPackages;
  PythonPackagesDaoManager get managers => PythonPackagesDaoManager(this);
}

class PythonPackagesDaoManager {
  final _$PythonPackagesDaoMixin _db;
  PythonPackagesDaoManager(this._db);
  $$BuildsTableTableManager get builds =>
      $$BuildsTableTableManager(_db.attachedDatabase, _db.builds);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db.attachedDatabase, _db.profiles);
  $$PythonPackagesTableTableManager get pythonPackages =>
      $$PythonPackagesTableTableManager(
        _db.attachedDatabase,
        _db.pythonPackages,
      );
}
