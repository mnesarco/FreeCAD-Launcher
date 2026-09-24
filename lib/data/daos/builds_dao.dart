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

  Future<Build?> findByKey({
    required BuildPlatform platform,
    required String arch,
    required BuildChannel channel,
    required String version,
    required String assetName,
  }) async {
    final all = await getAll();
    for (final build in all) {
      if (build.platform == platform &&
          build.arch == arch &&
          build.channel == channel &&
          build.version == version &&
          build.assetName == assetName) {
        return build;
      }
    }
    return null;
  }

  Future<void> save(Build build) => into(builds).insertOnConflictUpdate(build);

  Future<int> deleteById(String id) => (delete(builds)..where((t) => t.id.equals(id))).go();

  Future<int> updateStatus(String id, BuildStatus status) =>
      (update(builds)..where((t) => t.id.equals(id))).write(
        BuildsCompanion(status: Value(status), updatedAt: Value(DateTime.now())),
      );

  Future<int> updateLabel(String id, String? label, DateTime updatedAt) =>
      (update(builds)..where((t) => t.id.equals(id))).write(
        BuildsCompanion(label: Value(label), updatedAt: Value(updatedAt)),
      );
}
