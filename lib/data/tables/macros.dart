import 'package:drift/drift.dart';
import 'package:freecad_launcher/domain/macros/macro_types.dart';

import 'package:freecad_launcher/data/tables/profiles.dart';

@DataClassName('Macro')
class Macros extends Table {
  TextColumn get id => text()();

  TextColumn get profileId => text().references(Profiles, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text()();

  TextColumn get fileName => text()();

  TextColumn get source => textEnum<MacroSource>()();

  DateTimeColumn get installedAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get catalogCommit => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, fileName},
  ];
}
