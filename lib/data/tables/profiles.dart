import 'package:drift/drift.dart';

import 'package:freecad_launcher/data/tables/builds.dart';

@DataClassName('Profile')
class Profiles extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().unique()();

  TextColumn get description => text().nullable()();

  TextColumn get buildId => text().references(Builds, #id, onDelete: KeyAction.restrict)();

  TextColumn get pythonVersion => text()();

  IntColumn get iconColor => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
