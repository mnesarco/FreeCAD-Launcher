// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/cli_wrapper.dart';
import 'package:freecad_launcher/platform/process.dart';

void main() {
  final target = Platform.environment['FCL_WRAPPER_TARGET'] ??
      'build/linux/x64/release/bundle/freecad_launcher';

  test(
    'installs a wrapper that runs the real CLI binary',
    () async {
      final home = Directory('/tmp/opencode/fcl_wrapper_home');
      if (home.existsSync()) {
        home.deleteSync(recursive: true);
      }
      home.createSync(recursive: true);

      final installer = CliWrapperInstaller(
        platform: BuildPlatform.linux,
        processRunner: ProcessRunner(),
        homeDirectory: home.path,
        localAppData: home.path,
        appExecutable: File(target).absolute.path,
        pathEnvironment: '',
      );

      final installed = await installer.install();
      expect(installed.isOk, isTrue);
      final status = installer.status();
      expect(status.installed, isTrue);
      expect(status.onPath, isFalse);
      // ignore: avoid_print
      print('wrapper=${status.path} target=${installer.appExecutable}');

      final result = await Process.run(
        installer.wrapperPath,
        ['--version'],
      ).timeout(const Duration(seconds: 60));
      // ignore: avoid_print
      print('wrapper stdout=${result.stdout.toString().trim()}');
      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('FreeCAD Launcher'));

      final removed = await installer.remove();
      expect(removed.isOk, isTrue);
      expect(installer.status().installed, isFalse);
      home.deleteSync(recursive: true);
    },
    skip: Platform.environment['FCL_REAL_WRAPPER'] != '1'
        ? 'Manual test: set FCL_REAL_WRAPPER=1 to install and run a real wrapper'
        : null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
