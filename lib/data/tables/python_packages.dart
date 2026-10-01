// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';

import 'package:freecad_launcher/data/tables/profiles.dart';

@DataClassName('PythonPackage')
class PythonPackages extends Table {
  TextColumn get id => text()();

  TextColumn get profileId => text().references(Profiles, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text()();

  TextColumn get version => text().nullable()();

  TextColumn get targetDir => text()();

  TextColumn get source => text()();

  DateTimeColumn get installedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, name},
  ];
}
