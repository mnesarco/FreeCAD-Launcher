// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/python_uninstaller.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;
  late String targetDirectory;
  const uninstaller = PythonUninstaller();

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_py_uninstall');
    targetDirectory = p.join(tempDirectory.path, 'target');
    Directory(targetDirectory).createSync(recursive: true);
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  void write(String relative, [String content = 'x']) {
    File(p.join(targetDirectory, relative)).createSync(recursive: true);
    File(p.join(targetDirectory, relative)).writeAsStringSync(content);
  }

  test('removes files listed in RECORD and prunes empty directories', () async {
    write('numpy/__init__.py');
    write('numpy/core/values.py');
    write('numpy-1.26.4.dist-info/METADATA');
    write('numpy-1.26.4.dist-info/RECORD', '''
numpy/__init__.py,,
numpy/core/values.py,,
numpy-1.26.4.dist-info/METADATA,,
numpy-1.26.4.dist-info/RECORD,,
''');
    write('six.py');

    final removed = await uninstaller.uninstall(
      targetDirectory: targetDirectory,
      packageName: 'numpy',
    );

    expect(removed, 4);
    expect(Directory(p.join(targetDirectory, 'numpy')).existsSync(), isFalse);
    expect(
      Directory(p.join(targetDirectory, 'numpy-1.26.4.dist-info')).existsSync(),
      isFalse,
    );
    expect(File(p.join(targetDirectory, 'six.py')).existsSync(), isTrue);
  });

  test('rejects unsafe RECORD paths and keeps the outside file', () async {
    write('numpy/__init__.py');
    write('numpy-1.26.4.dist-info/RECORD', '''
../escape.txt,,
numpy/__init__.py,,
''');
    final outside = File(p.join(tempDirectory.path, 'escape.txt'))..writeAsStringSync('keep');

    await expectLater(
      uninstaller.uninstall(targetDirectory: targetDirectory, packageName: 'numpy'),
      throwsA(isA<PythonUninstallException>()),
    );

    expect(outside.readAsStringSync(), 'keep');
  });

  test('throws when no distribution is installed', () async {
    await expectLater(
      uninstaller.uninstall(targetDirectory: targetDirectory, packageName: 'missing'),
      throwsA(isA<PythonUninstallException>()),
    );
  });

  test('normalizes package names for the dist-info lookup', () async {
    write('my_pkg/__init__.py');
    write('my_pkg-1.0.dist-info/RECORD', 'my_pkg/__init__.py,,\n');

    final removed = await uninstaller.uninstall(
      targetDirectory: targetDirectory,
      packageName: 'My-Pkg',
    );

    expect(removed, 1);
    expect(Directory(p.join(targetDirectory, 'my_pkg')).existsSync(), isFalse);
  });
}
