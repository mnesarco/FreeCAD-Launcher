import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/debug_bundle.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late AppPaths paths;
  late DebugBundleService service;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('fcl_debug_bundle');
    paths = AppPaths(dataRoot: root.path);
    await paths.ensureBaseDirectories();
    service = DebugBundleService(paths: paths);
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  Archive unzip(String path) =>
      ZipDecoder().decodeBytes(File(path).readAsBytesSync());

  test('bundles system info, diagnostics and redacted logs', () async {
    File(p.join(paths.logsDir, 'app.log')).writeAsStringSync(
      'ok line\n'
      'token=github_pat_ABCDEFGHIJKLMNOPQRSTUVWXYZ123456\n'
      'Bearer abc.def.ghi\n',
    );
    File(p.join(paths.logsDir, 'launch-Test-2026.log')).writeAsStringSync('launch ok\n');
    final output = p.join(root.path, 'bundle.zip');

    final result = await service.create(
      outputPath: output,
      systemInfo: 'system summary',
      diagnostics: 'diagnostics summary',
    );

    expect(result.path, output);
    expect(result.logFiles, 2);
    expect(File('$output.part').existsSync(), isFalse);

    final archive = unzip(output);
    final names = archive.files.map((file) => file.name).toList();
    expect(
      names,
      containsAll([
        'system.txt',
        'diagnostics.txt',
        'logs/app.log',
        'logs/launch-Test-2026.log',
      ]),
    );

    String text(String name) =>
        utf8.decode(archive.files.firstWhere((file) => file.name == name).content);

    expect(text('system.txt'), 'system summary');
    expect(text('diagnostics.txt'), 'diagnostics summary');
    final appLog = text('logs/app.log');
    expect(appLog, contains('ok line'));
    expect(appLog, contains('<redacted>'));
    expect(appLog, isNot(contains('github_pat_')));
    expect(appLog, isNot(contains('abc.def.ghi')));
  });

  test('tolerates malformed log bytes and missing log directory', () async {
    File(p.join(paths.logsDir, 'binary.log')).writeAsBytesSync([0xff, 0xfe, 0x00]);
    final output = p.join(root.path, 'bundle2.zip');

    final result = await service.create(
      outputPath: output,
      systemInfo: 's',
      diagnostics: 'd',
    );

    expect(result.logFiles, 1);
    final archive = unzip(output);
    expect(archive.files.map((file) => file.name), contains('logs/binary.log'));

    Directory(paths.logsDir).deleteSync(recursive: true);
    final second = await service.create(
      outputPath: p.join(root.path, 'bundle3.zip'),
      systemInfo: 's',
      diagnostics: 'd',
    );
    expect(second.logFiles, 0);
  });

  test('suggested file name is timestamped', () {
    expect(
      DebugBundleService.suggestedFileName(DateTime(2026, 9, 20, 8, 5, 3)),
      'freecad-launcher-debug-20260920-080503.zip',
    );
  });
}
