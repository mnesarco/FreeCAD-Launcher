import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/pip_runner.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_env.dart';
import 'package:path/path.dart' as p;

void main() {
  final binary = Platform.environment['FCL_PIP_BINARY'] ??
      '/tmp/opencode/squashfs-root/usr/bin/freecad';

  test(
    'installs a real package into a profile target with pip',
    () async {
      final root = Directory('/tmp/opencode/fcl_pip_e2e');
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      final paths = AppPaths(dataRoot: root.path);
      await paths.ensureBaseDirectories();

      final runner = ProcessRunner();
      final resolver = PythonEnvResolver(processRunner: runner);
      final interpreter = await resolver.resolve(
        kind: BuildKind.custom,
        buildDirectory: p.dirname(binary),
        executablePath: binary,
      );
      expect(interpreter, isNotNull);
      // ignore: avoid_print
      print('interpreter=$interpreter');

      final target = p.join(
        root.path,
        'profiles',
        'p1',
        'AdditionalPythonPackages',
        'py310',
      );
      final pip = PipRunner(processRunner: runner, paths: paths);
      final result = await pip.install(
        pythonPath: interpreter!,
        targetDirectory: target,
        packages: const ['six'],
        label: 'manual',
      );
      // ignore: avoid_print
      print('pip exit=${result.exitCode} log=${result.logPath}');
      expect(result.isSuccess, isTrue);
      expect(File(p.join(target, 'six.py')).existsSync(), isTrue);

      final probe = await runner.run(
        ProcessSpec(
          executable: interpreter,
          arguments: const ['-c', 'import six; print(six.__version__)'],
          environment: {...Platform.environment, 'PYTHONPATH': target},
        ),
      );
      // ignore: avoid_print
      print('import six -> ${probe.stdout.trim()}');
      expect(probe.isSuccess, isTrue);

      root.deleteSync(recursive: true);
    },
    skip: Platform.environment['FCL_REAL_PIP'] != '1'
        ? 'Manual test: set FCL_REAL_PIP=1 to run a real pip install'
        : null,
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
