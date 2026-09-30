// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_env.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_process.dart';

void main() {
  late Directory tempDirectory;
  late FakeProcessLauncher launcher;
  late PythonEnvResolver resolver;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_python_env');
    launcher = FakeProcessLauncher();
    resolver = PythonEnvResolver(
      processRunner: ProcessRunner(launcher: launcher),
    );
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

  test('prefers the stored interpreter path', () async {
    final stored = File(p.join(tempDirectory.path, 'bin', 'python3'))
      ..createSync(recursive: true);

    final result = await resolver.resolve(
      kind: BuildKind.custom,
      buildDirectory: tempDirectory.path,
      executablePath: p.join(tempDirectory.path, 'FreeCAD'),
      storedPythonPath: stored.path,
    );

    expect(result, stored.path);
    expect(launcher.specs, isEmpty);
  });

  test('finds a nearby interpreter for custom builds', () async {
    final python = File(p.join(tempDirectory.path, 'bin', 'python3'))
      ..createSync(recursive: true);

    final result = await resolver.resolve(
      kind: BuildKind.custom,
      buildDirectory: tempDirectory.path,
      executablePath: p.join(tempDirectory.path, 'bin', 'FreeCAD'),
    );

    expect(result, python.path);
  });

  test('extracts an AppImage once and finds its interpreter', () async {
    final buildDirectory = p.join(tempDirectory.path, 'builds', 'b1');
    Directory(buildDirectory).createSync(recursive: true);
    final appImage = File(p.join(tempDirectory.path, 'FreeCAD.AppImage'))
      ..createSync();

    final future = resolver.resolve(
      kind: BuildKind.appimage,
      buildDirectory: buildDirectory,
      executablePath: appImage.path,
    );
    await waitForHandle(0);
    expect(launcher.specs.single.arguments, ['--appimage-extract']);
    expect(
      launcher.specs.single.workingDirectory,
      p.join(buildDirectory, 'extracted'),
    );

    final python = File(
      p.join(buildDirectory, 'extracted', 'squashfs-root', 'usr', 'bin', 'python3'),
    )..createSync(recursive: true);
    launcher.handles[0].exit(0);

    expect(await future, python.path);

    final cached = await resolver.resolve(
      kind: BuildKind.appimage,
      buildDirectory: buildDirectory,
      executablePath: appImage.path,
    );
    expect(cached, python.path);
    expect(launcher.specs, hasLength(1));
  });

  test('returns null when extraction fails', () async {
    final buildDirectory = p.join(tempDirectory.path, 'builds', 'b1');
    Directory(buildDirectory).createSync(recursive: true);
    final appImage = File(p.join(tempDirectory.path, 'FreeCAD.AppImage'))
      ..createSync();

    final future = resolver.resolve(
      kind: BuildKind.appimage,
      buildDirectory: buildDirectory,
      executablePath: appImage.path,
    );
    await waitForHandle(0);
    launcher.handles[0].exit(1);

    expect(await future, isNull);
  });
}
