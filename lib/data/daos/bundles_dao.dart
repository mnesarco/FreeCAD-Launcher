// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/tables/bundles.dart';

part 'bundles_dao.g.dart';

@DriftAccessor(tables: [Bundles, BundleItems])
class BundlesDao extends DatabaseAccessor<AppDatabase> with _$BundlesDaoMixin {
  BundlesDao(super.db);

  Stream<List<Bundle>> watchAll() =>
      (select(bundles)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<List<Bundle>> getAll() =>
      (select(bundles)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<Bundle?> getById(String id) =>
      (select(bundles)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> save(Bundle bundle) =>
      into(bundles).insertOnConflictUpdate(bundle.toCompanion(false));

  Future<int> deleteById(String id) => (delete(bundles)..where((t) => t.id.equals(id))).go();

  Stream<List<BundleItem>> watchItems(String bundleId) =>
      (select(bundleItems)
            ..where((t) => t.bundleId.equals(bundleId))
            ..orderBy([(t) => OrderingTerm.asc(t.addonId)]))
          .watch();

  Stream<List<BundleItem>> watchAllItems() =>
      (select(bundleItems)
            ..orderBy([
              (t) => OrderingTerm.asc(t.bundleId),
              (t) => OrderingTerm.asc(t.addonId),
            ]))
          .watch();

  Future<List<BundleItem>> getItems(String bundleId) =>
      (select(bundleItems)
            ..where((t) => t.bundleId.equals(bundleId))
            ..orderBy([(t) => OrderingTerm.asc(t.addonId)]))
          .get();

  Future<void> addItem(BundleItem item) => into(bundleItems).insertOnConflictUpdate(item);

  Future<int> removeItem(String bundleId, String addonId) =>
      (delete(bundleItems)
            ..where((t) => t.bundleId.equals(bundleId) & t.addonId.equals(addonId)))
          .go();

  Future<void> replaceItems(String bundleId, List<BundleItem> items) {
    return transaction(() async {
      await (delete(bundleItems)..where((t) => t.bundleId.equals(bundleId))).go();
      await batch((batch) => batch.insertAll(bundleItems, items));
    });
  }
}
