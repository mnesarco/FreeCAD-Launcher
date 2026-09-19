import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/bundles/bundle_rules.dart';
import 'package:freecad_launcher/state/bundles_controller.dart';

import '../data/test_fixtures.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late BundlesController controller;

  setUp(() {
    db = createTestDatabase();
    controller = BundlesController(
      database: db,
      clock: () => DateTime.utc(2026, 9, 19, 16),
    );
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  test('creates, lists and updates bundles', () async {
    controller.start();
    final created = await controller.create(name: '  Essentials  ', description: ' Core ');
    await pumpEventQueue();

    expect(created.isOk, isTrue);
    expect(controller.bundles.value, hasLength(1));
    final bundle = created.valueOrNull!;
    expect(bundle.name, 'Essentials');
    expect(bundle.description, 'Core');
    expect(bundle.createdAt, DateTime.utc(2026, 9, 19, 16));
    expect(controller.byId(bundle.id), isNotNull);

    final updated = await controller.update(
      bundleId: bundle.id,
      name: 'Essentials 2',
      description: '   ',
    );
    await pumpEventQueue();

    expect(updated.isOk, isTrue);
    expect(controller.byId(bundle.id)!.name, 'Essentials 2');
    expect(controller.byId(bundle.id)!.description, isNull);
    expect(controller.byId(bundle.id)!.createdAt, DateTime.utc(2026, 9, 19, 16));
    expect((await controller.update(bundleId: 'missing', name: 'X')).isErr, isTrue);
  });

  test('rejects empty, long and duplicate names', () async {
    controller.start();
    await controller.create(name: 'Base');
    await pumpEventQueue();

    expect((await controller.create(name: '   ')).isErr, isTrue);
    expect((await controller.create(name: 'x' * 65)).isErr, isTrue);
    expect((await controller.create(name: 'base')).isErr, isTrue);
    expect(controller.bundles.value, hasLength(1));

    final id = controller.bundles.value.single.id;
    expect((await controller.update(bundleId: id, name: ' Base ')).isOk, isTrue);
    expect((await controller.update(bundleId: id, name: 'Other')).isOk, isTrue);
  });

  test('deletes a bundle and cascades its items', () async {
    final created = (await controller.create(
      name: 'Base',
      initialItems: (bundleId) => [
        sampleBundleItem(bundleId: bundleId, addonId: 'A2plus'),
      ],
    )).valueOrNull!;
    controller.start();
    await pumpEventQueue();

    expect(controller.itemsFor(created.id), hasLength(1));

    expect((await controller.delete(created.id)).isOk, isTrue);
    await pumpEventQueue();

    expect(controller.bundles.value, isEmpty);
    expect(controller.itemsFor(created.id), isEmpty);
    expect((await controller.delete(created.id)).isErr, isTrue);
  });

  test('adds, re-branches and removes items', () async {
    final created = (await controller.create(name: 'Base')).valueOrNull!;
    controller.start();
    await pumpEventQueue();

    expect(
      (await controller.addItem(bundleId: created.id, addonId: 'A2plus', gitRef: 'master')).isOk,
      isTrue,
    );
    expect((await controller.addItem(bundleId: created.id, addonId: '  ')).isErr, isTrue);
    expect((await controller.addItem(bundleId: 'missing', addonId: 'X')).isErr, isTrue);
    await pumpEventQueue();

    expect(controller.itemFor(created.id, 'A2plus')!.gitRef, 'master');
    expect(controller.itemsFor(created.id).map((item) => item.addonId), ['A2plus']);
    expect(controller.items.value, hasLength(1));

    expect(
      (await controller.setItemBranch(
        bundleId: created.id,
        addonId: 'A2plus',
        gitRef: 'dev',
      )).isOk,
      isTrue,
    );
    await pumpEventQueue();
    expect(controller.itemFor(created.id, 'A2plus')!.gitRef, 'dev');

    expect((await controller.removeItem(bundleId: created.id, addonId: 'A2plus')).isOk, isTrue);
    await pumpEventQueue();
    expect(controller.itemsFor(created.id), isEmpty);
    expect((await controller.removeItem(bundleId: created.id, addonId: 'A2plus')).isErr, isTrue);
  });

  test("creates a bundle from a profile's installed addons", () async {
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    await db.installedAddonsDao.save(
      sampleAddon(profileId: 'profile-1', addonId: 'A2plus', gitRef: 'master'),
    );
    await db.installedAddonsDao.save(
      sampleAddon(id: 'addon-2', profileId: 'profile-1', addonId: 'MacroTool', gitRef: null),
    );

    final result = await controller.createFromProfile(profileId: 'profile-1', name: 'Dev set');
    controller.start();
    await pumpEventQueue();

    expect(result.isOk, isTrue);
    final items = controller.itemsFor(result.valueOrNull!.id);
    expect(items.map((item) => item.addonId).toSet(), {'A2plus', 'MacroTool'});
    expect(items.firstWhere((item) => item.addonId == 'A2plus').gitRef, 'master');
    expect(items.firstWhere((item) => item.addonId == 'MacroTool').gitRef, isNull);
  });

  test('checkName reports the issue and messages', () async {
    expect(await controller.checkName(''), BundleNameIssue.empty);
    expect(controller.nameIssueMessage(BundleNameIssue.duplicate), contains('already exists'));
    expect(
      controller.nameIssueMessage(BundleNameIssue.tooLong),
      contains('$maxBundleNameLength'),
    );
  });
}
