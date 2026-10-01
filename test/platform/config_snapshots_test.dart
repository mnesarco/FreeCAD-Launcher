// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/config_snapshots.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;
  const service = ConfigSnapshotService();

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_config_snapshots');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('returns null when no config files exist', () async {
    expect(await service.create(profileRoot: tempDirectory.path), isNull);
    expect(service.list(tempDirectory.path), isEmpty);
  });

  test('copies the present config files into a timestamped snapshot', () async {
    File(p.join(tempDirectory.path, 'user.cfg')).writeAsStringSync('<user/>');
    File(p.join(tempDirectory.path, 'not-config.txt')).writeAsStringSync('x');

    final snapshot = await service.create(
      profileRoot: tempDirectory.path,
      now: DateTime.utc(2026, 9, 19, 16),
    );

    expect(snapshot, isNotNull);
    expect(snapshot!.name, 'config-2026-09-19T16-00-00-000Z');
    expect(snapshot.files, ['user.cfg']);
    expect(snapshot.sizeBytes, 7);
    expect(
      File(p.join(snapshot.directory, 'user.cfg')).readAsStringSync(),
      '<user/>',
    );
    expect(
      Directory(p.join(tempDirectory.path, 'backups', snapshot.name)).existsSync(),
      isTrue,
    );
  });

  test('lists snapshots newest first and ignores other backups', () async {
    File(p.join(tempDirectory.path, 'user.cfg')).writeAsStringSync('a');
    final first = await service.create(
      profileRoot: tempDirectory.path,
      now: DateTime.utc(2026, 9, 19, 10),
    );
    final second = await service.create(
      profileRoot: tempDirectory.path,
      now: DateTime.utc(2026, 9, 19, 11),
    );
    Directory(p.join(tempDirectory.path, 'backups', 'addon-A2plus-x')).createSync(recursive: true);

    final snapshots = service.list(tempDirectory.path);

    expect(snapshots.map((snapshot) => snapshot.name), [second!.name, first!.name]);
  });

  test('prunes older snapshots beyond the cap', () async {
    const capped = ConfigSnapshotService(maxSnapshots: 2);
    File(p.join(tempDirectory.path, 'user.cfg')).writeAsStringSync('a');

    final first = await capped.create(
      profileRoot: tempDirectory.path,
      now: DateTime.utc(2026, 9, 19, 10),
    );
    await capped.create(
      profileRoot: tempDirectory.path,
      now: DateTime.utc(2026, 9, 19, 11),
    );
    final third = await capped.create(
      profileRoot: tempDirectory.path,
      now: DateTime.utc(2026, 9, 19, 12),
    );

    final snapshots = capped.list(tempDirectory.path);
    expect(snapshots, hasLength(2));
    expect(snapshots.first.name, third!.name);
    expect(Directory(first!.directory).existsSync(), isFalse);
  });

  test('restores files over the current config and deletes snapshots', () async {
    final userCfg = File(p.join(tempDirectory.path, 'user.cfg'))..writeAsStringSync('v1');
    File(p.join(tempDirectory.path, 'system.cfg')).writeAsStringSync('s1');
    final snapshot = await service.create(profileRoot: tempDirectory.path);

    userCfg.writeAsStringSync('v2');
    await service.restore(profileRoot: tempDirectory.path, snapshot: snapshot!);
    expect(userCfg.readAsStringSync(), 'v1');

    await service.delete(snapshot);
    expect(Directory(snapshot.directory).existsSync(), isFalse);
  });
}
