import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/addon_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

void main() {
  test(
    'installs the real A2plus addon and verifies its package files',
    () async {
      final root = Directory('/tmp/opencode/fcl_addon_e2e');
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      final downloadDirectory = p.join(root.path, 'downloads');
      final destination = p.join(root.path, 'profiles', 'p1', 'Mod', 'A2plus');
      final installer = AddonInstaller(
        downloader: Downloader(
          source: HttpDownloadSource(http.Client()),
          cacheDirectory: downloadDirectory,
        ),
      );

      final result = await installer
          .install(
            zipUri: Uri.parse(
              'https://github.com/kbwbe/A2plus/archive/refs/heads/master.zip',
            ),
            destinationDirectory: destination,
            downloadDirectory: downloadDirectory,
            assetName: 'A2plus-master.zip',
          )
          .timeout(const Duration(minutes: 5));

      final packageXml = File(p.join(result.directory, 'package.xml'));
      final initGui = File(p.join(result.directory, 'InitGui.py'));
      // ignore: avoid_print
      print(
        'installed=${result.directory} size=${result.sizeBytes} '
        'packageXml=${packageXml.existsSync()} initGui=${initGui.existsSync()}',
      );

      expect(packageXml.existsSync(), isTrue);
      expect(packageXml.readAsStringSync(), contains('<name>A2plus</name>'));
      expect(initGui.existsSync(), isTrue);
      expect(Directory('$destination.part').existsSync(), isFalse);

      root.deleteSync(recursive: true);
    },
    skip: Platform.environment['FCL_REAL_ADDON'] != '1'
        ? 'Manual test: set FCL_REAL_ADDON=1 to download and install the real A2plus'
        : null,
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
