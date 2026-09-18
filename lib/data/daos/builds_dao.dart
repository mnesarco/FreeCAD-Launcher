import 'package:drift/drift.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/tables/builds.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';

part 'builds_dao.g.dart';

@DriftAccessor(tables: [Builds])
class BuildsDao extends DatabaseAccessor<AppDatabase> with _$BuildsDaoMixin {
  BuildsDao(super.db);

  Stream<List<Build>> watchAll() =>
      (select(builds)..orderBy([(t) => OrderingTerm.desc(t.installedAt)])).watch();

  Future<List<Build>> getAll() =>
      (select(builds)..orderBy([(t) => OrderingTerm.desc(t.installedAt)])).get();

  Future<Build?> getById(String id) =>
      (select(builds)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> save(Build build) => into(builds).insertOnConflictUpdate(build);

  Future<int> deleteById(String id) => (delete(builds)..where((t) => t.id.equals(id))).go();

  Future<int> updateStatus(String id, BuildStatus status) =>
      (update(builds)..where((t) => t.id.equals(id))).write(
        BuildsCompanion(status: Value(status), updatedAt: Value(DateTime.now())),
      );
}
