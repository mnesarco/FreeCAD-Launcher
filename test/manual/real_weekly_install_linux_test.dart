// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// MANUAL TEST — explicit local invocation only; never runs in a default `flutter test` and
// never on CI: it downloads the full weekly AppImage (~770 MB) from GitHub.
// Run:  FCL_REAL_WEEKLY=1 flutter test test/manual/real_weekly_install_linux_test.dart
// Opt:  FCL_WEEKLY_TAG / FCL_WEEKLY_ASSET (default weekly-2026.09.30)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/build_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_probe.dart';
import 'package:http/http.dart' as http;

import '../helpers/release_digest.dart';

/// Hard gate for manual tests: never run on CI, even if the `FCL_*` flag were present.
String? _manualSkip() {
  final ci = Platform.environment['CI'];
  final actions = Platform.environment['GITHUB_ACTIONS'];
  if ((ci != null && ci.isNotEmpty && ci != 'false') || actions == 'true') {
    return 'Manual test disabled on CI (explicit local invocation only)';
  }
  if (Platform.environment['FCL_REAL_WEEKLY'] != '1') {
    return 'Manual test: set FCL_REAL_WEEKLY=1 to download a real weekly AppImage';
  }
  return null;
}

void main() {
  test(
    'installs and probes the real weekly Linux AppImage',
    () async {
      final tag = Platform.environment['FCL_WEEKLY_TAG'] ?? 'weekly-2026.09.30';
      final asset = Platform.environment['FCL_WEEKLY_ASSET'] ??
          'FreeCAD_weekly-2026.09.30-Linux-x86_64.AppImage';

      final root = Directory('/tmp/opencode/fcl_manual_weekly_install_check');
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      final paths = AppPaths(dataRoot: root.path);
      await paths.ensureBaseDirectories();

      final baseUrl = 'https://github.com/FreeCAD/FreeCAD/releases/download/$tag/$asset';

      final downloader = Downloader(
        source: HttpDownloadSource(http.Client()),
        cacheDirectory: paths.downloadsCacheDir,
      );

      final expected = await fetchReleaseAssetSha256(tag: tag, asset: asset);
      expect(expected, isNotNull);

      final appImage = await downloader.download(
        uri: Uri.parse(baseUrl),
        fileName: asset,
        expectedSha256: expected,
      );
      expect(appImage.sha256, expected);

      final runner = ProcessRunner();
      final installer = BuildInstaller(
        paths: paths,
        processRunner: runner,
        pythonProbe: ProcessPythonProbe(processRunner: runner),
      );
      final installed = await installer.install(
        InstallRequest(
          buildId: 'real-$tag',
          kind: BuildKind.appimage,
          archivePath: appImage.path,
          assetName: asset,
        ),
      );

      expect(File(installed.executablePath).existsSync(), isTrue);
      expect(installed.sizeBytes, greaterThan(100 * 1024 * 1024));
      expect(installed.pythonVersion, isNotNull);

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
      print(
        'weekly=$tag installed=${installed.executablePath} '
        'size=${installed.sizeBytes} python=${installed.pythonVersion}',
      );
      // ignore: avoid_print
      print('version stdout=${result.stdout.trim()}');
    },
    skip: _manualSkip(),
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
