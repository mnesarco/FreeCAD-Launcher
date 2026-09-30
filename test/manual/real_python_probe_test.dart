// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_probe.dart';
import 'package:path/path.dart' as p;

void main() {
  final binary = Platform.environment['FCL_PROBE_BINARY'] ??
      '${Platform.environment['HOME']}/.local/bin/freecad';

  test(
    'detects Python from a real FreeCAD binary',
    () async {
      final probe = ProcessPythonProbe(processRunner: ProcessRunner());
      final detection = await probe.detect(
        kind: BuildKind.appimage,
        installDirectory: p.dirname(binary),
        executablePath: binary,
      );

      // ignore: avoid_print
      print(
        'binary=$binary version=${detection.detectedVersion} '
        'python=${detection.python?.executablePath} reason=${detection.reason}',
      );

      expect(detection.detectedVersion, isNotNull);
    },
    skip: Platform.environment['FCL_REAL_PROBE'] != '1'
        ? 'Manual test: set FCL_REAL_PROBE=1 to probe a real FreeCAD binary'
        : null,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
