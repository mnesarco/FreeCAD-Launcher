// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/tables/profiles.dart';

part 'profiles_dao.g.dart';

@DriftAccessor(tables: [Profiles])
class ProfilesDao extends DatabaseAccessor<AppDatabase> with _$ProfilesDaoMixin {
  ProfilesDao(super.db);

  Stream<List<Profile>> watchAll() =>
      (select(profiles)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<List<Profile>> getAll() =>
      (select(profiles)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<Profile?> getById(String id) =>
      (select(profiles)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Profile?> getByName(String name) =>
      (select(profiles)..where((t) => t.name.lower().equals(name.toLowerCase()))).getSingleOrNull();

  Future<void> save(Profile profile) => into(profiles).insertOnConflictUpdate(profile);

  Future<int> deleteById(String id) => (delete(profiles)..where((t) => t.id.equals(id))).go();

  Future<int> touchLastUsed(String id, DateTime at) =>
      (update(profiles)..where((t) => t.id.equals(id))).write(
        ProfilesCompanion(lastUsedAt: Value(at)),
      );

  Future<int> countByBuild(String buildId) async {
    final count = countAll();
    final query = selectOnly(profiles)
      ..addColumns([count])
      ..where(profiles.buildId.equals(buildId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }
}
