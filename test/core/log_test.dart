import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('freecad_launcher_log_test');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  group('RotatingFileSink', () {
    test('writes formatted records under the logs directory', () {
      final sink = RotatingFileSink(directory: tempDirectory);
      final logger = Logger(
        sinks: [sink],
        clock: () => DateTime.utc(2026, 9, 18, 10, 30),
      );

      logger.info('hello', tag: 'test');

      final file = File(p.join(tempDirectory.path, 'app.log'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('2026-09-18T10:30:00.000Z [INFO ] [test] hello'));
    });

    test('rotates and caps the number of files', () {
      final sink = RotatingFileSink(directory: tempDirectory, maxBytes: 200, maxFiles: 3);
      final logger = Logger(sinks: [sink], clock: () => DateTime.utc(2026));

      for (var index = 0; index < 100; index++) {
        logger.info('line $index');
      }

      expect(File(p.join(tempDirectory.path, 'app.log')).existsSync(), isTrue);
      expect(File(p.join(tempDirectory.path, 'app.log.1')).existsSync(), isTrue);
      expect(File(p.join(tempDirectory.path, 'app.log.2')).existsSync(), isTrue);
      expect(File(p.join(tempDirectory.path, 'app.log.3')).existsSync(), isFalse);
    });

    test('does not write below the configured level', () {
      final sink = RotatingFileSink(directory: tempDirectory);
      final logger = Logger(sinks: [sink], level: LogLevel.warn);

      logger.debug('debug line');
      logger.info('info line');
      logger.warn('warn line');

      final contents = File(p.join(tempDirectory.path, 'app.log')).readAsStringSync();
      expect(contents, isNot(contains('debug line')));
      expect(contents, isNot(contains('info line')));
      expect(contents, contains('warn line'));
    });
  });

  group('redactSensitive', () {
    test('masks GitHub tokens', () {
      expect(redactSensitive('using ghp_abcdefghijklmnopqrstuvwxyz'), 'using <redacted>');
      expect(
        redactSensitive('using github_pat_abcdefghijklmnopqrstuvwxyz0123456789'),
        'using <redacted>',
      );
    });

    test('masks bearer and query tokens', () {
      expect(redactSensitive('Authorization: Bearer abc.def-123'), contains('<redacted>'));
      expect(redactSensitive('https://x/api?token=secret&page=1'), contains('token= <redacted>'));
    });
  });
}
