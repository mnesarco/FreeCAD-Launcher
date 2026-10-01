// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/cli_wrapper.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_process.dart';

void main() {
  late Directory tempDirectory;
  late FakeProcessLauncher launcher;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_cli_wrapper');
    launcher = FakeProcessLauncher();
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  CliWrapperInstaller installer({
    BuildPlatform platform = BuildPlatform.linux,
    String pathEnvironment = '',
  }) {
    return CliWrapperInstaller(
      platform: platform,
      processRunner: ProcessRunner(launcher: launcher),
      homeDirectory: tempDirectory.path,
      localAppData: tempDirectory.path,
      appExecutable: '/opt/app/freecad_launcher',
      pathEnvironment: pathEnvironment,
    );
  }

  test('installs a posix wrapper with exec and argument passthrough', () async {
    if (Platform.isWindows) {
      return;
    }
    final wrapper = installer(pathEnvironment: '/usr/bin');
    expect(wrapper.status().installed, isFalse);
    expect(wrapper.status().onPath, isFalse);

    final future = wrapper.install();
    await pumpEventQueue();
    launcher.handles.single.exit(0);
    final result = await future;

    expect(result.isOk, isTrue);
    expect(wrapper.status().installed, isTrue);
    expect(File(wrapper.wrapperPath).readAsStringSync(), '''
#!/bin/sh
exec "/opt/app/freecad_launcher" "\$@"
''');
    expect(launcher.specs.single.executable, 'chmod');
    expect(launcher.specs.single.arguments, ['755', wrapper.wrapperPath]);
  });

  test('reports when the wrapper directory is on PATH', () {
    final directory = p.posix.join(tempDirectory.path, '.local', 'bin');
    expect(installer(pathEnvironment: directory).status().onPath, isTrue);
    expect(
      installer(pathEnvironment: '/usr/bin:$directory').status().onPath,
      isTrue,
    );
    expect(installer(pathEnvironment: '/usr/bin').status().onPath, isFalse);
  });

  test('generates a windows cmd wrapper', () {
    final wrapper = installer(platform: BuildPlatform.windows);

    expect(wrapper.wrapperPath, endsWith(r'FreeCADLauncher\bin\freecad-launcher.cmd'));
    expect(wrapper.wrapperScript(), '@echo off\r\n"/opt/app/freecad_launcher" %*\r\n');
  });

  test('removes an installed wrapper', () async {
    if (Platform.isWindows) {
      return;
    }
    final wrapper = installer();
    final future = wrapper.install();
    await pumpEventQueue();
    launcher.handles.single.exit(0);
    await future;
    expect(wrapper.status().installed, isTrue);

    final removed = await wrapper.remove();

    expect(removed.isOk, isTrue);
    expect(wrapper.status().installed, isFalse);
  });
}
