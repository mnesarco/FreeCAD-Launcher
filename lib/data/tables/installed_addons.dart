import 'package:drift/drift.dart';

import 'package:freecad_launcher/data/tables/profiles.dart';

@DataClassName('InstalledAddon')
class InstalledAddons extends Table {
  TextColumn get id => text()();

  TextColumn get profileId => text().references(Profiles, #id, onDelete: KeyAction.cascade)();

  TextColumn get addonId => text()();

  TextColumn get displayName => text()();

  TextColumn get gitRef => text().nullable()();

  TextColumn get version => text().nullable()();

  DateTimeColumn get installedAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get catalogLastUpdate => dateTime().nullable()();

  TextColumn get sourceUrl => text().nullable()();

  BoolColumn get hasRequirements => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, addonId},
  ];
}
