// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/app_services.dart';

void main() {
  test('exposes the paths and database and closes the database', () async {
    final database = AppDatabase.inMemory();
    final services = AppServices(paths: AppPaths(dataRoot: '/data'), database: database);

    expect(services.paths.dataRoot, '/data');
    expect(services.database, same(database));

    await services.close();
  });
}
