import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_probe.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_process.dart';

void main() {
  late Directory tempDirectory;
  late FakeProcessLauncher launcher;
  late ProcessPythonProbe probe;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_python_probe_test');
    launcher = FakeProcessLauncher();
    probe = ProcessPythonProbe(processRunner: ProcessRunner(launcher: launcher));
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

  test('finds the Windows archive interpreter and parses the version', () async {
    final python = File(p.join(tempDirectory.path, 'bin', 'python.exe'))
      ..createSync(recursive: true);
    final executable = p.join(tempDirectory.path, 'FreeCAD.exe');

    final future = probe.detect(
      kind: BuildKind.archive,
      installDirectory: tempDirectory.path,
      executablePath: executable,
    );
    await waitForHandle(0);
    launcher.handles.first
      ..emitStdout('3.11\n')
      ..exit(0);

    final detection = await future;

    expect(detection.found, isTrue);
    expect(detection.python!.version, '3.11');
    expect(detection.python!.executablePath, python.path);
    expect(launcher.specs.single.executable, python.path);
    expect(launcher.specs.single.arguments.first, '-c');
  });

  test('prefers the plain interpreter over versioned ones', () async {
    File(p.join(tempDirectory.path, 'bin', 'python3.11.exe')).createSync(recursive: true);
    final plain = File(p.join(tempDirectory.path, 'bin', 'python.exe'))
      ..createSync(recursive: true);

    final future = probe.detect(
      kind: BuildKind.archive,
      installDirectory: tempDirectory.path,
      executablePath: p.join(tempDirectory.path, 'FreeCAD.exe'),
    );
    await waitForHandle(0);
    launcher.handles.first
      ..emitStdout('3.11\n')
      ..exit(0);
    final detection = await future;

    expect(detection.python!.executablePath, plain.path);
  });

  test('finds the macOS app interpreter', () async {
    final python = File(
      p.join(tempDirectory.path, 'FreeCAD.app', 'Contents', 'Resources', 'bin', 'python'),
    )..createSync(recursive: true);

    final future = probe.detect(
      kind: BuildKind.dmg,
      installDirectory: tempDirectory.path,
      executablePath: p.join(tempDirectory.path, 'FreeCAD.app', 'Contents', 'MacOS', 'FreeCAD'),
    );
    await waitForHandle(0);
    launcher.handles.first
      ..emitStdout('3.11\n')
      ..exit(0);
    final detection = await future;

    expect(detection.python!.executablePath, python.path);
  });

  test('reports a missing interpreter without running anything', () async {
    final detection = await probe.detect(
      kind: BuildKind.archive,
      installDirectory: tempDirectory.path,
      executablePath: p.join(tempDirectory.path, 'FreeCAD.exe'),
    );

    expect(detection.found, isFalse);
    expect(detection.reason, contains('No bundled Python interpreter'));
    expect(launcher.specs, isEmpty);
  });

  test('reports AppImages that have not been extracted', () async {
    final detection = await probe.detect(
      kind: BuildKind.appimage,
      installDirectory: tempDirectory.path,
      executablePath: p.join(tempDirectory.path, 'FreeCAD.AppImage'),
    );

    expect(detection.found, isFalse);
    expect(detection.reason, contains('AppImage'));
    expect(launcher.specs, isEmpty);
  });

  test('reports probe failures', () async {
    File(p.join(tempDirectory.path, 'bin', 'python.exe')).createSync(recursive: true);

    final future = probe.detect(
      kind: BuildKind.archive,
      installDirectory: tempDirectory.path,
      executablePath: p.join(tempDirectory.path, 'FreeCAD.exe'),
    );
    await waitForHandle(0);
    launcher.handles.first.exit(1);
    final detection = await future;

    expect(detection.found, isFalse);
    expect(detection.reason, contains('exit code 1'));
  });

  test('reports unexpected output', () async {
    File(p.join(tempDirectory.path, 'bin', 'python.exe')).createSync(recursive: true);

    final future = probe.detect(
      kind: BuildKind.archive,
      installDirectory: tempDirectory.path,
      executablePath: p.join(tempDirectory.path, 'FreeCAD.exe'),
    );
    await waitForHandle(0);
    launcher.handles.first
      ..emitStdout('Python 3.11.9\n')
      ..exit(0);
    final detection = await future;

    expect(detection.found, isFalse);
    expect(detection.reason, contains('Unexpected Python version output'));
  });

  test('short-circuits when a known version is provided', () async {
    final detection = await probe.detect(
      kind: BuildKind.appimage,
      installDirectory: tempDirectory.path,
      executablePath: '/data/FreeCAD.AppImage',
      knownVersion: '3.11',
    );

    expect(detection.found, isTrue);
    expect(detection.python!.version, '3.11');
    expect(detection.python!.executablePath, '/data/FreeCAD.AppImage');
    expect(launcher.specs, isEmpty);
  });
}
