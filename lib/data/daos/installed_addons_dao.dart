import 'package:drift/drift.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/tables/installed_addons.dart';

part 'installed_addons_dao.g.dart';

@DriftAccessor(tables: [InstalledAddons])
class InstalledAddonsDao extends DatabaseAccessor<AppDatabase> with _$InstalledAddonsDaoMixin {
  InstalledAddonsDao(super.db);

  Stream<List<InstalledAddon>> watchAll() =>
      (select(installedAddons)..orderBy([(t) => OrderingTerm.asc(t.displayName)])).watch();

  Future<List<InstalledAddon>> getAll() =>
      (select(installedAddons)..orderBy([(t) => OrderingTerm.asc(t.displayName)])).get();

  Stream<List<InstalledAddon>> watchByProfile(String profileId) =>
      (select(installedAddons)
            ..where((t) => t.profileId.equals(profileId))
            ..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
          .watch();

  Future<List<InstalledAddon>> getByProfile(String profileId) =>
      (select(installedAddons)
            ..where((t) => t.profileId.equals(profileId))
            ..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
          .get();

  Future<InstalledAddon?> getByAddon(String profileId, String addonId) =>
      (select(installedAddons)
            ..where((t) => t.profileId.equals(profileId) & t.addonId.equals(addonId)))
          .getSingleOrNull();

  Future<void> save(InstalledAddon addon) => into(installedAddons).insert(
    addon,
    onConflict: DoUpdate(
      (_) => addon,
      target: [installedAddons.profileId, installedAddons.addonId],
    ),
  );

  Future<int> deleteAddon(String profileId, String addonId) =>
      (delete(installedAddons)
            ..where((t) => t.profileId.equals(profileId) & t.addonId.equals(addonId)))
          .go();

  Future<int> setPinnedAt(String profileId, String addonId, DateTime? pinnedAt) =>
      (update(installedAddons)
            ..where((t) => t.profileId.equals(profileId) & t.addonId.equals(addonId)))
          .write(InstalledAddonsCompanion(pinnedAt: Value(pinnedAt)));

  Future<int> deleteByProfile(String profileId) =>
      (delete(installedAddons)..where((t) => t.profileId.equals(profileId))).go();
}
