// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/profiles/launch_environment.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';

class PipResult {
  const PipResult({
    required this.exitCode,
    required this.logPath,
    required this.outputTail,
  });

  final int exitCode;
  final String logPath;
  final String outputTail;

  bool get isSuccess => exitCode == 0;
}

class PipRunner {
  PipRunner({required ProcessRunner processRunner, required AppPaths paths})
    : _processRunner = processRunner,
      _paths = paths;

  final ProcessRunner _processRunner;
  final AppPaths _paths;

  Future<void> _queue = Future.value();

  Future<PipResult> install({
    required String pythonPath,
    required String targetDirectory,
    required List<String> packages,
    required String label,
    void Function(String line)? onOutput,
    Duration timeout = const Duration(minutes: 30),
  }) {
    final previous = _queue;
    final next = Completer<void>();
    _queue = next.future;
    return previous
        .then(
          (_) => _installLocked(
            pythonPath: pythonPath,
            targetDirectory: targetDirectory,
            packages: packages,
            label: label,
            onOutput: onOutput,
            timeout: timeout,
          ),
        )
        .whenComplete(next.complete);
  }

  Future<PipResult> _installLocked({
    required String pythonPath,
    required String targetDirectory,
    required List<String> packages,
    required String label,
    void Function(String line)? onOutput,
    required Duration timeout,
  }) async {
    await Directory(targetDirectory).create(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final logFile = File(p.join(_paths.logsDir, 'pip-$label-$stamp.log'));
    final sink = logFile.openWrite();

    void write(String line) {
      sink.writeln(line);
      onOutput?.call(line);
    }

    try {
      final result = await _processRunner.run(
        ProcessSpec(
          executable: pythonPath,
          arguments: [
            '-m',
            'pip',
            'install',
            '--upgrade',
            '--target',
            targetDirectory,
            ...packages,
            '--disable-pip-version-check',
            '--no-warn-script-location',
          ],
          environment: _environment(),
        ),
        timeout: timeout,
        onStdout: write,
        onStderr: write,
      );
      return PipResult(
        exitCode: result.exitCode,
        logPath: logFile.path,
        outputTail: _tail('${result.stdout}\n${result.stderr}'),
      );
    } finally {
      try {
        await sink.close();
      } on Object {
        // The sink may already be closed.
      }
    }
  }

  Map<String, String> _environment() {
    final environment = Map<String, String>.from(Platform.environment);
    for (final key in sanitizedEnvironmentKeys) {
      environment.remove(key);
    }
    environment['PIP_DISABLE_PIP_VERSION_CHECK'] = '1';
    environment['PIP_NO_INPUT'] = '1';
    environment['PYTHONNOUSERSITE'] = '1';
    return environment;
  }

  String _tail(String output) {
    final lines = output
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length <= 5) {
      return lines.join('\n');
    }
    return lines.sublist(lines.length - 5).join('\n');
  }
}
