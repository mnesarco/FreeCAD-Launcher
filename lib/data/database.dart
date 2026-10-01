// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:freecad_launcher/data/daos/builds_dao.dart';
import 'package:freecad_launcher/data/daos/bundles_dao.dart';
import 'package:freecad_launcher/data/daos/catalog_cache_dao.dart';
import 'package:freecad_launcher/data/daos/installed_addons_dao.dart';
import 'package:freecad_launcher/data/daos/macros_dao.dart';
import 'package:freecad_launcher/data/daos/profiles_dao.dart';
import 'package:freecad_launcher/data/daos/python_packages_dao.dart';
import 'package:freecad_launcher/data/daos/settings_dao.dart';
import 'package:freecad_launcher/data/tables/builds.dart';
import 'package:freecad_launcher/data/tables/bundles.dart';
import 'package:freecad_launcher/data/tables/cache.dart';
import 'package:freecad_launcher/data/tables/installed_addons.dart';
import 'package:freecad_launcher/data/tables/macros.dart';
import 'package:freecad_launcher/data/tables/profiles.dart';
import 'package:freecad_launcher/data/tables/python_packages.dart';
import 'package:freecad_launcher/data/tables/settings.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:freecad_launcher/domain/macros/macro_types.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Builds,
    Profiles,
    InstalledAddons,
    PythonPackages,
    Bundles,
    BundleItems,
    Macros,
    CatalogCache,
    Settings,
  ],
  daos: [
    BuildsDao,
    ProfilesDao,
    InstalledAddonsDao,
    PythonPackagesDao,
    BundlesDao,
    MacrosDao,
    CatalogCacheDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(builds, builds.pythonPath);
      }
      if (from < 3) {
        await m.addColumn(macros, macros.license);
        await m.addColumn(macros, macros.sizeBytes);
      }
      if (from < 4) {
        await m.addColumn(installedAddons, installedAddons.pinnedAt);
      }
      if (from < 5) {
        await m.addColumn(builds, builds.label);
      }
      if (from < 6) {
        await m.addColumn(installedAddons, installedAddons.source);
        await m.addColumn(installedAddons, installedAddons.sourcePath);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

extension BuildDisplayLabel on Build {
  String get displayLabel => label ?? version;
}
