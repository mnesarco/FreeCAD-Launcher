// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
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
    tempDirectory = Directory(
      Directory.systemTemp.createTempSync('fcl_python_probe_test').resolveSymbolicLinksSync(),
    );
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

  String headlessPayload({required String version, String? prefix, String? executable}) {
    final data = <String, Object?>{
      'python': version,
      'prefix': ?prefix,
      'executable': ?executable,
    };
    return '[freecad-launcher:out]${jsonEncode(data)}[/freecad-launcher:out]\n';
  }

  Future<void> completeHeadless(
    int index, {
    required String version,
    String? prefix,
    String? executable,
  }) async {
    await waitForHandle(index);
    launcher.handles[index]
      ..emitStdout(
        headlessPayload(version: version, prefix: prefix, executable: executable),
      )
      ..exit(0);
  }

  group('bundled interpreter discovery', () {
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

    test('keeps the known version but never as the interpreter path', () async {
      final detection = await probe.detect(
        kind: BuildKind.archive,
        installDirectory: tempDirectory.path,
        executablePath: p.join(tempDirectory.path, 'bin', 'FreeCAD.exe'),
        knownVersion: '3.11',
      );

      expect(detection.found, isFalse);
      expect(detection.detectedVersion, '3.11');
      expect(detection.python, isNull);
      expect(launcher.specs, isEmpty);
    });

    test('probes the bundled interpreter when a known version is provided', () async {
      final python = File(p.join(tempDirectory.path, 'bin', 'python.exe'))
        ..createSync(recursive: true);

      final future = probe.detect(
        kind: BuildKind.archive,
        installDirectory: tempDirectory.path,
        executablePath: p.join(tempDirectory.path, 'bin', 'FreeCAD.exe'),
        knownVersion: '3.11',
      );
      await waitForHandle(0);
      launcher.handles.first
        ..emitStdout('3.12\n')
        ..exit(0);
      final detection = await future;

      expect(detection.found, isTrue);
      expect(detection.python!.executablePath, python.path);
      expect(detection.python!.version, '3.12');
      expect(launcher.specs.single.executable, python.path);
    });

    test('falls back to the hint version when the interpreter probe fails', () async {
      File(p.join(tempDirectory.path, 'bin', 'python.exe')).createSync(recursive: true);

      final future = probe.detect(
        kind: BuildKind.archive,
        installDirectory: tempDirectory.path,
        executablePath: p.join(tempDirectory.path, 'bin', 'FreeCAD.exe'),
        knownVersion: '3.11',
      );
      await waitForHandle(0);
      launcher.handles.first.exit(1);
      final detection = await future;

      expect(detection.found, isFalse);
      expect(detection.detectedVersion, '3.11');
      expect(detection.python, isNull);
    });
  });

  group('headless FreeCAD probe', () {
    test('runs the prototype macro and resolves the interpreter under sys.prefix', () async {
      final prefix = Directory(p.join(tempDirectory.path, 'python-prefix'))..createSync();
      final python = File(p.join(prefix.path, 'bin', 'python3.11'))
        ..createSync(recursive: true);
      final executable = File(p.join(tempDirectory.path, 'FreeCAD'))..createSync();

      final future = probe.detectFromFreeCad(executablePath: executable.path);
      await completeHeadless(
        0,
        version: '3.11.13',
        prefix: prefix.path,
        executable: executable.path,
      );
      await waitForHandle(1);
      launcher.handles[1]
        ..emitStdout('3.11\n')
        ..exit(0);

      final detection = await future;

      expect(detection.found, isTrue);
      expect(detection.python!.version, '3.11');
      expect(detection.python!.executablePath, python.path);
      expect(launcher.specs[0].executable, executable.path);
      expect(launcher.specs[0].arguments.take(2).toList(), ['-c', '-M']);
      expect(launcher.specs[0].arguments[3], endsWith('FCL_PythonProbe.FCMacro'));
      expect(launcher.specs[1].executable, python.path);
    });

    test('prefers a sibling FreeCADCmd', () async {
      final command = File(p.join(tempDirectory.path, 'FreeCADCmd'))..createSync();
      final executable = File(p.join(tempDirectory.path, 'FreeCAD'))..createSync();
      final prefix = Directory(p.join(tempDirectory.path, 'python-prefix'))..createSync();
      final python = File(p.join(prefix.path, 'bin', 'python3.11'))
        ..createSync(recursive: true);

      final future = probe.detectFromFreeCad(executablePath: executable.path);
      await waitForHandle(0);
      expect(launcher.specs[0].executable, command.path);
      expect(launcher.specs[0].arguments.take(2).toList(), ['-c', '-M']);
      launcher.handles[0]
        ..emitStdout(
          headlessPayload(version: '3.11.13', prefix: prefix.path),
        )
        ..exit(0);
      await waitForHandle(1);
      launcher.handles[1]
        ..emitStdout('3.11\n')
        ..exit(0);

      final detection = await future;

      expect(detection.python!.executablePath, python.path);
    });

    test('reports version-only when the prefix is gone after exit', () async {
      final executable = File(p.join(tempDirectory.path, 'freecad'))..createSync();

      final future = probe.detectFromFreeCad(executablePath: executable.path);
      await completeHeadless(
        0,
        version: '3.10.13',
        prefix: '/tmp/.mount_freecad/usr',
        executable: '/tmp/.mount_freecad/usr/bin/freecad',
      );

      final detection = await future;

      expect(detection.found, isFalse);
      expect(detection.detectedVersion, '3.10');
      expect(detection.reason, contains('manually'));
      expect(launcher.specs, hasLength(1));
    });

    test('falls back to a nearby interpreter when headless fails', () async {
      final bin = Directory(p.join(tempDirectory.path, 'bin'))..createSync();
      final python = File(p.join(bin.path, 'python3'))..createSync();
      final executable = File(p.join(bin.path, 'FreeCAD'))..createSync();

      final future = probe.detectFromFreeCad(executablePath: executable.path);
      await waitForHandle(0);
      launcher.handles[0].exit(1);
      await waitForHandle(1);
      launcher.handles[1]
        ..emitStdout('3.12\n')
        ..exit(0);

      final detection = await future;

      expect(detection.python!.version, '3.12');
      expect(detection.python!.executablePath, python.path);
    });

    test('rejects interpreters that do not match the headless version', () async {
      final prefix = Directory(p.join(tempDirectory.path, 'python-prefix'))..createSync();
      File(p.join(prefix.path, 'bin', 'python3.10')).createSync(recursive: true);
      final executable = File(p.join(tempDirectory.path, 'FreeCAD'))..createSync();

      final future = probe.detectFromFreeCad(executablePath: executable.path);
      await completeHeadless(0, version: '3.11.13', prefix: prefix.path);
      await waitForHandle(1);
      launcher.handles[1]
        ..emitStdout('3.10\n')
        ..exit(0);

      final detection = await future;

      expect(detection.found, isFalse);
      expect(detection.detectedVersion, '3.11');
    });

    test('detects a user-selected interpreter directly', () async {
      final future = probe.detectInterpreter(executablePath: '/usr/bin/python3');
      await waitForHandle(0);
      launcher.handles[0]
        ..emitStdout('3.11\n')
        ..exit(0);

      final detection = await future;

      expect(detection.found, isTrue);
      expect(detection.python!.version, '3.11');
      expect(launcher.specs.single.executable, '/usr/bin/python3');
      expect(launcher.specs.single.arguments, ['-c', anything]);
    });
  });

  group('AppImage detection', () {
    test('probes an extracted squashfs interpreter directly', () async {
      final python = File(
        p.join(tempDirectory.path, 'squashfs-root', 'usr', 'bin', 'python3.11'),
      )..createSync(recursive: true);

      final future = probe.detect(
        kind: BuildKind.appimage,
        installDirectory: tempDirectory.path,
        executablePath: p.join(tempDirectory.path, 'FreeCAD.AppImage'),
      );
      await waitForHandle(0);
      launcher.handles[0]
        ..emitStdout('3.11\n')
        ..exit(0);

      final detection = await future;

      expect(detection.found, isTrue);
      expect(detection.python!.executablePath, python.path);
      expect(launcher.specs, hasLength(1));
      expect(launcher.specs.single.executable, python.path);
    });

    test('detects a non-extracted AppImage through the headless probe', () async {
      final appImage = File(p.join(tempDirectory.path, 'FreeCAD.AppImage'))
        ..createSync(recursive: true);

      final future = probe.detect(
        kind: BuildKind.appimage,
        installDirectory: tempDirectory.path,
        executablePath: appImage.path,
      );
      await completeHeadless(
        0,
        version: '3.10.13',
        prefix: '/tmp/.mount_freecad/usr',
        executable: '/tmp/.mount_freecad/usr/bin/freecad',
      );

      final detection = await future;

      expect(detection.detectedVersion, '3.10');
      expect(detection.found, isFalse);
      expect(launcher.specs, hasLength(1));
      expect(launcher.specs.single.executable, appImage.path);
    });

    test('falls back to the asset-name hint as version only when the probe fails', () async {
      final appImage = File(p.join(tempDirectory.path, 'FreeCAD.AppImage'))
        ..createSync(recursive: true);

      final future = probe.detect(
        kind: BuildKind.appimage,
        installDirectory: tempDirectory.path,
        executablePath: appImage.path,
        knownVersion: '3.12',
      );
      await waitForHandle(0);
      launcher.handles[0].exit(1);

      final detection = await future;

      expect(detection.found, isFalse);
      expect(detection.detectedVersion, '3.12');
      expect(detection.python, isNull);
    });
  });
}
