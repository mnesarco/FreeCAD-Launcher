import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/domain/macros/macro_types.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/macros_controller.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_download.dart';
import '../helpers/test_database.dart';

MacroCatalogEntry entry({
  String name = 'Foto',
  String code = "print('hi')",
  String comment = 'Creates a foto',
}) {
  return MacroCatalogEntry(
    name: name,
    code: code,
    comment: comment,
    onGit: true,
    srcFilename: 'FreeCAD-macros/Utility/$name.FCMacro',
  );
}

void main() {
  late Directory tempDirectory;
  late AppPaths paths;
  late AppDatabase db;
  late MacrosController controller;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_macros_controller');
    paths = AppPaths(dataRoot: tempDirectory.path);
    db = createTestDatabase();
    controller = MacrosController(
      database: db,
      catalog: MacroCatalog(
        downloader: Downloader(
          source: FakeDownloadSource(),
          cacheDirectory: paths.macrosCacheDir,
        ),
        dao: db.catalogCacheDao,
        cacheDirectory: paths.macrosCacheDir,
      ),
      paths: paths,
      clock: () => DateTime.utc(2026, 9, 19, 16),
    );
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('installs a macro into the profile root and records it', () async {
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    controller.loaded.value = true;
    controller.macros.value = [entry()];
    controller.start();
    await pumpEventQueue();

    final result = await controller.install(name: 'Foto', profileId: 'profile-1');
    await pumpEventQueue();

    expect(result.isOk, isTrue);
    final macroFile = File(p.join(paths.profilePaths('profile-1').root, 'Foto.FCMacro'));
    expect(macroFile.existsSync(), isTrue);
    expect(macroFile.readAsStringSync(), "print('hi')");
    final row = await db.macrosDao.getByFileName('profile-1', 'Foto.FCMacro');
    expect(row, isNotNull);
    expect(row!.source, MacroSource.catalog);
    expect(row.installedAt, DateTime.utc(2026, 9, 19, 16));
    expect(controller.installing.value, isEmpty);
    expect(controller.installErrors.value, isEmpty);
    expect(controller.isInstalled('profile-1', controller.macros.value.single), isTrue);
    expect(controller.isInstalled('profile-2', controller.macros.value.single), isFalse);
  });

  test('reinstalling updates the existing row', () async {
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    controller.loaded.value = true;
    controller.macros.value = [entry()];
    controller.start();
    await pumpEventQueue();

    await controller.install(name: 'Foto', profileId: 'profile-1');
    await pumpEventQueue();
    final first = await db.macrosDao.getByFileName('profile-1', 'Foto.FCMacro');

    controller.macros.value = [entry(code: 'print(2)')];
    final result = await controller.install(name: 'Foto', profileId: 'profile-1');
    await pumpEventQueue();

    expect(result.isOk, isTrue);
    final second = await db.macrosDao.getByFileName('profile-1', 'Foto.FCMacro');
    expect(second!.id, first!.id);
    expect(second.installedAt, first.installedAt);
    expect(
      File(p.join(paths.profilePaths('profile-1').root, 'Foto.FCMacro')).readAsStringSync(),
      'print(2)',
    );
    expect((await db.macrosDao.getByProfile('profile-1')), hasLength(1));
  });

  test('reports missing macros and profiles', () async {
    controller.loaded.value = true;
    controller.start();
    await pumpEventQueue();

    expect((await controller.install(name: 'Ghost', profileId: 'profile-1')).isErr, isTrue);

    controller.macros.value = [entry()];
    expect((await controller.install(name: 'Foto', profileId: 'missing')).isErr, isTrue);
  });

  test('filters by name, comment and description', () async {
    controller.loaded.value = true;
    controller.macros.value = [
      entry(name: 'Foto', comment: 'Camera helper'),
      entry(name: 'TreeHelper', comment: 'BIM tools'),
    ];
    controller.start();
    await pumpEventQueue();

    expect(controller.filtered.value, hasLength(2));
    controller.query.value = 'camera';
    expect(controller.filtered.value.single.name, 'Foto');
    controller.query.value = 'bim';
    expect(controller.filtered.value.single.name, 'TreeHelper');
    controller.query.value = '';
    expect(controller.filtered.value, hasLength(2));
  });
}
