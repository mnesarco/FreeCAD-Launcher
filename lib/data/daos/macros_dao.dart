// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/tables/macros.dart';

part 'macros_dao.g.dart';

@DriftAccessor(tables: [Macros])
class MacrosDao extends DatabaseAccessor<AppDatabase> with _$MacrosDaoMixin {
  MacrosDao(super.db);

  Stream<List<Macro>> watchAll() =>
      (select(macros)
            ..orderBy([
              (t) => OrderingTerm.asc(t.profileId),
              (t) => OrderingTerm.asc(t.name),
            ]))
          .watch();

  Stream<List<Macro>> watchByProfile(String profileId) =>
      (select(macros)
            ..where((t) => t.profileId.equals(profileId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<List<Macro>> getByProfile(String profileId) =>
      (select(macros)
            ..where((t) => t.profileId.equals(profileId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<Macro?> getByFileName(String profileId, String fileName) =>
      (select(macros)
            ..where((t) => t.profileId.equals(profileId) & t.fileName.equals(fileName)))
          .getSingleOrNull();

  Future<void> save(Macro macro) => into(macros).insert(
    macro,
    onConflict: DoUpdate(
      (_) => macro,
      target: [macros.profileId, macros.fileName],
    ),
  );

  Future<int> deleteByFileName(String profileId, String fileName) =>
      (delete(macros)
            ..where((t) => t.profileId.equals(profileId) & t.fileName.equals(fileName)))
          .go();

  Future<int> deleteByProfile(String profileId) =>
      (delete(macros)..where((t) => t.profileId.equals(profileId))).go();
}
