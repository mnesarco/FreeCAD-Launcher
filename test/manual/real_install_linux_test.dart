// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/build_installer.dart';
import 'package:freecad_launcher/platform/checksum.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'installs and runs the real FreeCAD 1.1.3 Linux AppImage',
    () async {
      final root = Directory('/tmp/opencode/fcl_manual_install_check');
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      final paths = AppPaths(dataRoot: root.path);
      await paths.ensureBaseDirectories();

      const asset = 'FreeCAD_1.1.3-Linux-x86_64-py311.AppImage';
      const baseUrl =
          'https://github.com/FreeCAD/FreeCAD/releases/download/1.1.3/$asset';

      final downloader = Downloader(
        source: HttpDownloadSource(http.Client()),
        cacheDirectory: paths.downloadsCacheDir,
      );

      final sidecar = await downloader.download(
        uri: Uri.parse('$baseUrl-SHA256.txt'),
        fileName: '$asset-SHA256.txt',
      );
      final expected = parseSha256Text(File(sidecar.path).readAsStringSync());
      expect(expected, isNotNull);

      final appImage = await downloader.download(
        uri: Uri.parse(baseUrl),
        fileName: asset,
        expectedSha256: expected,
      );
      expect(appImage.sha256, expected);

      final runner = ProcessRunner();
      final installer = BuildInstaller(paths: paths, processRunner: runner);
      final installed = await installer.install(
        InstallRequest(
          buildId: 'real-1.1.3',
          kind: BuildKind.appimage,
          archivePath: appImage.path,
          assetName: asset,
        ),
      );

      expect(File(installed.executablePath).existsSync(), isTrue);
      expect(installed.sizeBytes, greaterThan(100 * 1024 * 1024));

      final result = await runner.run(
        ProcessSpec(
          executable: installed.executablePath,
          arguments: ['--console', '--version'],
          environment: {...Platform.environment, 'APPIMAGE_EXTRACT_AND_RUN': '1'},
        ),
        timeout: const Duration(seconds: 180),
      );
      expect(result.exitCode, 0);

      // ignore: avoid_print
      print('installed=${installed.executablePath} size=${installed.sizeBytes}');
      // ignore: avoid_print
      print('version stdout=${result.stdout.trim()}');
    },
    skip: Platform.environment['FCL_REAL_INSTALL'] != '1'
        ? 'Manual test: set FCL_REAL_INSTALL=1 to download the real AppImage'
        : null,
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
