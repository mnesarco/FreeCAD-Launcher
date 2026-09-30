// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/tables/python_packages.dart';

part 'python_packages_dao.g.dart';

@DriftAccessor(tables: [PythonPackages])
class PythonPackagesDao extends DatabaseAccessor<AppDatabase> with _$PythonPackagesDaoMixin {
  PythonPackagesDao(super.db);

  Stream<List<PythonPackage>> watchAll() =>
      (select(pythonPackages)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Stream<List<PythonPackage>> watchByProfile(String profileId) =>
      (select(pythonPackages)
            ..where((t) => t.profileId.equals(profileId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<List<PythonPackage>> getByProfile(String profileId) =>
      (select(pythonPackages)
            ..where((t) => t.profileId.equals(profileId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<PythonPackage?> getByName(String profileId, String name) =>
      (select(pythonPackages)
            ..where((t) => t.profileId.equals(profileId) & t.name.equals(name)))
          .getSingleOrNull();

  Future<void> save(PythonPackage package) => into(pythonPackages).insert(
    package,
    onConflict: DoUpdate(
      (_) => package,
      target: [pythonPackages.profileId, pythonPackages.name],
    ),
  );

  Future<int> deletePackage(String profileId, String name) =>
      (delete(pythonPackages)
            ..where((t) => t.profileId.equals(profileId) & t.name.equals(name)))
          .go();

  Future<int> deleteByProfile(String profileId) =>
      (delete(pythonPackages)..where((t) => t.profileId.equals(profileId))).go();
}
