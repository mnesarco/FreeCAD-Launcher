import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/build_installer.dart';
import 'package:freecad_launcher/platform/dmg_extractor.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_process.dart';

class FakeArchiveExtractor implements ArchiveExtractor {
  final List<({String archive, String destination})> calls = [];
  void Function(String destination)? onCreate;
  Object? error;

  @override
  Future<void> extract(String archivePath, String destination) async {
    calls.add((archive: archivePath, destination: destination));
    if (error != null) {
      throw error!;
    }
    onCreate?.call(destination);
  }
}

class FakeDmgExtractor implements DmgExtractor {
  final List<String> calls = [];
  void Function(String destination)? onCreate;

  @override
  Future<String> extractApp(String dmgPath, String destination) async {
    calls.add(dmgPath);
    onCreate?.call(destination);
    return p.join(destination, 'FreeCAD.app');
  }
}

void main() {
  late Directory tempDirectory;
  late AppPaths paths;
  late FakeProcessLauncher launcher;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_installer_test');
    paths = AppPaths(dataRoot: p.join(tempDirectory.path, 'data'));
    launcher = FakeProcessLauncher();
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

  Future<File> writeArchive(String name, List<int> bytes) async {
    return File(p.join(tempDirectory.path, name))..writeAsBytesSync(bytes);
  }

  test('installs an AppImage by copying and marking it executable', () async {
    final archive = await writeArchive('FreeCAD.AppImage', [1, 2, 3, 4]);
    final installer = BuildInstaller(
      paths: paths,
      processRunner: ProcessRunner(launcher: launcher),
    );

    final future = installer.install(
      InstallRequest(
        buildId: 'b1',
        kind: BuildKind.appimage,
        archivePath: archive.path,
        assetName: 'FreeCAD.AppImage',
      ),
    );
    await waitForHandle(0);
    launcher.handles.first.exit(0);
    final installed = await future;

    expect(File(installed.executablePath).readAsBytesSync(), [1, 2, 3, 4]);
    expect(installed.executablePath, p.join(paths.buildDir('b1'), 'FreeCAD.AppImage'));
    expect(installed.sizeBytes, 4);
    expect(launcher.specs.single.executable, 'chmod');
    expect(launcher.specs.single.arguments.first, '755');
    expect(launcher.specs.single.arguments.last, endsWith(p.join('b1.part', 'FreeCAD.AppImage')));
    expect(Directory('${paths.buildDir('b1')}.part').existsSync(), isFalse);
  });

  test('cleans up when marking the AppImage executable fails', () async {
    final archive = await writeArchive('FreeCAD.AppImage', [1]);
    final installer = BuildInstaller(
      paths: paths,
      processRunner: ProcessRunner(launcher: launcher),
    );

    final future = installer.install(
      InstallRequest(buildId: 'b1', kind: BuildKind.appimage, archivePath: archive.path),
    );
    await waitForHandle(0);
    launcher.handles.first
      ..emitStderr('permission denied')
      ..exit(1);

    await expectLater(future, throwsA(isA<ArchiveExtractionException>()));
    expect(Directory(paths.buildDir('b1')).existsSync(), isFalse);
    expect(Directory('${paths.buildDir('b1')}.part').existsSync(), isFalse);
  });

  test('extracts an archive and finds the FreeCAD executable', () async {
    final extractor = FakeArchiveExtractor()
      ..onCreate = (destination) {
        final directory = Directory(p.join(destination, 'pkg'))..createSync(recursive: true);
        File(p.join(directory.path, 'FreeCAD.exe')).writeAsStringSync('exe');
      };
    final archive = await writeArchive('FreeCAD.zip', [0]);
    final installer = BuildInstaller(
      paths: paths,
      processRunner: ProcessRunner(launcher: launcher),
      archiveExtractor: extractor,
    );

    final installed = await installer.install(
      InstallRequest(
        buildId: 'b1',
        kind: BuildKind.archive,
        archivePath: archive.path,
        assetName: 'FreeCAD.zip',
      ),
    );

    expect(installed.executablePath, p.join(paths.buildDir('b1'), 'pkg', 'FreeCAD.exe'));
    expect(File(installed.executablePath).readAsStringSync(), 'exe');
    expect(extractor.calls, hasLength(1));
    expect(extractor.calls.single.archive, archive.path);
  });

  test('uses the 7-Zip extractor for .7z archives', () async {
    final sevenZip = FakeArchiveExtractor()
      ..onCreate = (destination) {
        Directory(p.join(destination, 'FreeCAD_1.1.3-Windows-x86_64-py311')).createSync();
        File(
          p.join(destination, 'FreeCAD_1.1.3-Windows-x86_64-py311', 'FreeCAD.exe'),
        ).writeAsStringSync('exe');
      };
    final regular = FakeArchiveExtractor();
    final archive = await writeArchive('FreeCAD.7z', [0]);
    final installer = BuildInstaller(
      paths: paths,
      processRunner: ProcessRunner(launcher: launcher),
      archiveExtractor: regular,
      sevenZipExtractor: sevenZip,
    );

    final installed = await installer.install(
      InstallRequest(
        buildId: 'b1',
        kind: BuildKind.archive,
        archivePath: archive.path,
        assetName: 'FreeCAD_1.1.3-Windows-x86_64-py311.7z',
      ),
    );

    expect(sevenZip.calls, hasLength(1));
    expect(regular.calls, isEmpty);
    expect(
      installed.executablePath,
      p.join(
        paths.buildDir('b1'),
        'FreeCAD_1.1.3-Windows-x86_64-py311',
        'FreeCAD.exe',
      ),
    );
  });

  test('fails and cleans up when no executable is found', () async {
    final extractor = FakeArchiveExtractor();
    final archive = await writeArchive('FreeCAD.zip', [0]);
    final installer = BuildInstaller(
      paths: paths,
      processRunner: ProcessRunner(launcher: launcher),
      archiveExtractor: extractor,
    );

    await expectLater(
      installer.install(
        InstallRequest(buildId: 'b1', kind: BuildKind.archive, archivePath: archive.path),
      ),
      throwsA(isA<ArchiveExtractionException>()),
    );

    expect(Directory(paths.buildDir('b1')).existsSync(), isFalse);
    expect(Directory('${paths.buildDir('b1')}.part').existsSync(), isFalse);
  });

  test('installs a dmg using the configured extractor', () async {
    final dmg = FakeDmgExtractor()
      ..onCreate = (destination) {
        Directory(p.join(destination, 'FreeCAD.app', 'Contents', 'MacOS')).createSync(recursive: true);
      };
    final archive = await writeArchive('FreeCAD.dmg', [0]);
    final installer = BuildInstaller(
      paths: paths,
      processRunner: ProcessRunner(launcher: launcher),
      dmgExtractor: dmg,
    );

    final installed = await installer.install(
      InstallRequest(
        buildId: 'b1',
        kind: BuildKind.dmg,
        archivePath: archive.path,
        assetName: 'FreeCAD.dmg',
      ),
    );

    expect(dmg.calls, hasLength(1));
    expect(
      installed.executablePath,
      p.join(paths.buildDir('b1'), 'FreeCAD.app', 'Contents', 'MacOS', 'FreeCAD'),
    );
  });
}
