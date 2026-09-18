import 'package:drift/drift.dart';

@DataClassName('Bundle')
class Bundles extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().unique()();

  TextColumn get description => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BundleItem')
class BundleItems extends Table {
  TextColumn get bundleId => text().references(Bundles, #id, onDelete: KeyAction.cascade)();

  TextColumn get addonId => text()();

  TextColumn get gitRef => text().nullable()();

  @override
  Set<Column> get primaryKey => {bundleId, addonId};
}
