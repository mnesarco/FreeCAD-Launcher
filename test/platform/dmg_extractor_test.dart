import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/dmg_extractor.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_process.dart';

void main() {
  late Directory tempDirectory;
  late Directory mountPoint;
  late FakeProcessLauncher launcher;
  late ProcessRunner runner;
  late File dmgFile;
  late String destination;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_dmg_test');
    mountPoint = Directory(p.join(tempDirectory.path, 'mnt'))..createSync(recursive: true);
    launcher = FakeProcessLauncher();
    runner = ProcessRunner(launcher: launcher);
    dmgFile = File(p.join(tempDirectory.path, 'FreeCAD.dmg'))..writeAsStringSync('');
    destination = p.join(tempDirectory.path, 'out');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> waitForHandle(int index) async {
    for (var attempt = 0; attempt < 250 && launcher.handles.length <= index; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  ProcessDmgExtractor buildExtractor() => ProcessDmgExtractor(
    processRunner: runner,
    mountPointFactory: () => mountPoint.path,
  );

  test('attaches, copies with ditto and detaches', () async {
    Directory(p.join(mountPoint.path, 'FreeCAD.app')).createSync();

    final future = buildExtractor().extractApp(dmgFile.path, destination);

    await waitForHandle(0);
    launcher.handles[0].exit(0);
    await waitForHandle(1);
    launcher.handles[1].exit(0);
    await waitForHandle(2);
    launcher.handles[2].exit(0);

    final appPath = await future;

    expect(launcher.specs[0].executable, 'hdiutil');
    expect(launcher.specs[0].arguments, [
      'attach',
      '-nobrowse',
      '-readonly',
      '-mountpoint',
      mountPoint.path,
      dmgFile.path,
    ]);
    expect(launcher.specs[1].executable, 'ditto');
    expect(launcher.specs[1].arguments, [
      p.join(mountPoint.path, 'FreeCAD.app'),
      p.join(destination, 'FreeCAD.app'),
    ]);
    expect(launcher.specs[2].arguments, ['detach', mountPoint.path]);
    expect(appPath, p.join(destination, 'FreeCAD.app'));
  });

  test('retries detach with -force', () async {
    Directory(p.join(mountPoint.path, 'FreeCAD.app')).createSync();

    final future = buildExtractor().extractApp(dmgFile.path, destination);

    await waitForHandle(0);
    launcher.handles[0].exit(0);
    await waitForHandle(1);
    launcher.handles[1].exit(0);
    await waitForHandle(2);
    launcher.handles[2]
      ..emitStderr('Resource busy')
      ..exit(1);
    await waitForHandle(3);
    launcher.handles[3].exit(0);

    await future;

    expect(launcher.specs[2].arguments, ['detach', mountPoint.path]);
    expect(launcher.specs[3].arguments, ['detach', '-force', mountPoint.path]);
  });

  test('fails when FreeCAD.app is missing and still detaches', () async {
    final future = buildExtractor().extractApp(dmgFile.path, destination);

    await waitForHandle(0);
    launcher.handles[0].exit(0);
    await waitForHandle(1);
    launcher.handles[1].exit(0);

    await expectLater(future, throwsA(isA<ArchiveExtractionException>()));

    expect(launcher.specs[1].arguments, ['detach', mountPoint.path]);
  });
}
