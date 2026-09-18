import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';

import 'test_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.inMemory());
  tearDown(() => db.close());

  test('saves and reads a bundle', () async {
    await db.bundlesDao.save(sampleBundle());

    final bundle = await db.bundlesDao.getById('bundle-1');

    expect(bundle, isNotNull);
    expect(bundle!.name, 'Mechanical');
  });

  test('adds, lists and removes items', () async {
    await db.bundlesDao.save(sampleBundle());
    await db.bundlesDao.addItem(sampleBundleItem());
    await db.bundlesDao.addItem(sampleBundleItem(addonId: 'Fasteners', gitRef: null));

    expect(await db.bundlesDao.getItems('bundle-1'), hasLength(2));

    await db.bundlesDao.removeItem('bundle-1', 'A2plus');

    final items = await db.bundlesDao.getItems('bundle-1');
    expect(items, hasLength(1));
    expect(items.single.addonId, 'Fasteners');
  });

  test('replaceItems swaps the item set', () async {
    await db.bundlesDao.save(sampleBundle());
    await db.bundlesDao.addItem(sampleBundleItem());

    await db.bundlesDao.replaceItems('bundle-1', [
      sampleBundleItem(addonId: 'Fasteners'),
      sampleBundleItem(addonId: 'Assembly4'),
    ]);

    final items = await db.bundlesDao.getItems('bundle-1');
    expect(items.map((item) => item.addonId), containsAll(['Fasteners', 'Assembly4']));
    expect(items, hasLength(2));
  });

  test('deleting a bundle cascades to its items', () async {
    await db.bundlesDao.save(sampleBundle());
    await db.bundlesDao.addItem(sampleBundleItem());

    await db.bundlesDao.deleteById('bundle-1');

    expect(await db.bundlesDao.getItems('bundle-1'), isEmpty);
  });
}
