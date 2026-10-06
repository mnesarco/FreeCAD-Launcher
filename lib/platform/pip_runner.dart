// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/profiles/launch_environment.dart';
import 'package:freecad_launcher/platform/freecad_macro_runner.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_probe.dart';

class PipResult {
  const PipResult({required this.exitCode, required this.logPath, required this.outputTail});

  final int exitCode;
  final String logPath;
  final String outputTail;

  bool get isSuccess => exitCode == 0;
}

class PipRunner {
  PipRunner({required ProcessRunner processRunner, required AppPaths paths})
    : _processRunner = processRunner,
      _paths = paths,
      _macroRunner = FreeCadMacroRunner(processRunner: processRunner);

  final ProcessRunner _processRunner;
  final AppPaths _paths;
  final FreeCadMacroRunner _macroRunner;

  Future<void> _queue = Future.value();

  /// Installs [packages] into [targetDirectory].
  ///
  /// Provide exactly one execution target:
  /// - [pythonPath]: the bundled interpreter (`<python> -m pip install …`);
  /// - [appImagePath]: the AppImage itself; pip runs inside the mounted image
  ///   through a headless macro (D-112), so no extraction is needed.
  Future<PipResult> install({
    String? pythonPath,
    String? appImagePath,
    required String targetDirectory,
    required List<String> packages,
    required String label,
    void Function(String line)? onOutput,
    Duration timeout = const Duration(minutes: 30),
  }) {
    if ((pythonPath == null) == (appImagePath == null)) {
      throw ArgumentError('Provide exactly one of pythonPath or appImagePath');
    }
    final previous = _queue;
    final next = Completer<void>();
    _queue = next.future;
    return previous
        .then(
          (_) => _installLocked(
            pythonPath: pythonPath,
            appImagePath: appImagePath,
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
    required String? pythonPath,
    required String? appImagePath,
    required String targetDirectory,
    required List<String> packages,
    required String label,
    void Function(String line)? onOutput,
    required Duration timeout,
  }) async {
    await Directory(targetDirectory).create(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final logFile = File(p.join(_paths.logsDir, 'pip-$label-$stamp.log'));
    if (appImagePath != null) {
      return _installInAppImage(
        appImagePath: appImagePath,
        targetDirectory: targetDirectory,
        packages: packages,
        logFile: logFile,
        onOutput: onOutput,
        timeout: timeout,
      );
    }
    return _installWithInterpreter(
      pythonPath: pythonPath!,
      targetDirectory: targetDirectory,
      packages: packages,
      logFile: logFile,
      onOutput: onOutput,
      timeout: timeout,
    );
  }

  Future<PipResult> _installWithInterpreter({
    required String pythonPath,
    required String targetDirectory,
    required List<String> packages,
    required File logFile,
    void Function(String line)? onOutput,
    required Duration timeout,
  }) async {
    if (isFreeCadExecutable(pythonPath)) {
      throw ArgumentError(
        'Refusing to run the FreeCAD executable as Python: $pythonPath '
        '(D-115; FreeCAD is only ever invoked with -c)',
      );
    }

    final sink = logFile.openWrite();
    Directory? bootstrapDirectory;

    void write(String line) {
      sink.writeln(line);
      onOutput?.call(line);
    }

    try {
      // pip runs through a bootstrap so the interpreter's DLL directories can be
      // registered before importing ssl/pip (D-118). Some FreeCAD bundles
      // (e.g. the 1.1 weeklies) ship libssl/libcrypto next to python.exe but
      // pip could not find them when spawned by the launcher, which made every
      // HTTPS fetch fail. The bootstrap also records the interpreter identity
      // and the ssl error, so the failure is no longer silent.
      bootstrapDirectory = await Directory.systemTemp.createTemp('fcl-pip-');
      final bootstrap = File(p.join(bootstrapDirectory.path, 'run_pip.py'));
      await bootstrap.writeAsString(_pipBootstrap, flush: true);
      write('# interpreter: $pythonPath');
      write('# target: $targetDirectory');
      write('# packages: ${packages.join(' ')}');

      final result = await _processRunner.run(
        ProcessSpec(
          executable: pythonPath,
          arguments: [bootstrap.path, ..._installArguments(targetDirectory, packages)],
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
      try {
        if (bootstrapDirectory != null && bootstrapDirectory.existsSync()) {
          await bootstrapDirectory.delete(recursive: true);
        }
      } on Object {
        // Bootstrap cleanup is best-effort.
      }
    }
  }

  static List<String> _installArguments(String targetDirectory, List<String> packages) => [
    'install',
    '--upgrade',
    '--target',
    targetDirectory,
    ...packages,
    '--disable-pip-version-check',
    '--no-warn-script-location',
  ];

  /// Runs pip in-process after registering the interpreter's own DLL
  /// directories (Windows) and reporting the ssl availability (D-118).
  static const String _pipBootstrap = r'''
import os
import runpy
import sys
import traceback

_DLL_DIRECTORY_HANDLES = []


def _register_windows_dll_directories():
    if not hasattr(os, "add_dll_directory"):
        return
    interpreter_directory = os.path.dirname(os.path.abspath(sys.executable))
    candidates = [interpreter_directory, os.path.join(interpreter_directory, "DLLs")]
    for candidate in candidates:
        if os.path.isdir(candidate):
            try:
                _DLL_DIRECTORY_HANDLES.append(os.add_dll_directory(candidate))
            except OSError:
                pass
    entries = [candidate for candidate in candidates if os.path.isdir(candidate)]
    if entries:
        existing = os.environ.get("PATH", "")
        os.environ["PATH"] = os.pathsep.join(entries + ([existing] if existing else []))


def _report_ssl():
    try:
        import ssl
    except Exception:
        sys.stderr.write("freecad-launcher: the ssl module is unavailable\n")
        traceback.print_exc()
    else:
        sys.stderr.write("freecad-launcher: ssl {0}\n".format(ssl.OPENSSL_VERSION))


def main():
    sys.stderr.write(
        "freecad-launcher: python {0} at {1}\n".format(sys.version.split()[0], sys.executable)
    )
    _register_windows_dll_directories()
    _report_ssl()
    sys.argv = ["pip"] + sys.argv[1:]
    try:
        runpy.run_module("pip", run_name="__main__", alter_sys=True)
    except SystemExit:
        raise
    except BaseException:
        traceback.print_exc()
        sys.exit(1)
    sys.exit(0)


main()
''';

  Future<PipResult> _installInAppImage({
    required String appImagePath,
    required String targetDirectory,
    required List<String> packages,
    required File logFile,
    void Function(String line)? onOutput,
    required Duration timeout,
  }) async {
    final outcome = await _macroRunner.runAppImage(
      appImagePath: appImagePath,
      macroBody: _appImagePipMacro(
        targetDirectory: targetDirectory,
        packages: packages,
        logPath: logFile.path,
      ),
      timeout: timeout,
      environment: _environment(extra: {'PIP_CACHE_DIR': p.join(_paths.cacheDir, 'pip')}),
      macroName: 'FCL_Pip',
    );
    final logText = logFile.existsSync() ? logFile.readAsStringSync() : '';
    if (onOutput != null) {
      for (final line in logText.split('\n')) {
        if (line.trim().isNotEmpty) {
          onOutput(line);
        }
      }
    }
    final payload = outcome.payloadMap;
    final success = payload?['ok'] == true;
    final code = payload?['code'];
    final failure = outcome.error ?? (logText.isEmpty ? 'pip installation failed' : logText);
    return PipResult(
      exitCode: success ? 0 : (code is int ? code : 1),
      logPath: logFile.path,
      outputTail: _tail(failure),
    );
  }

  String _appImagePipMacro({
    required String targetDirectory,
    required List<String> packages,
    required String logPath,
  }) {
    final target = jsonEncode(targetDirectory);
    final specs = jsonEncode(packages);
    final log = jsonEncode(logPath);
    const tag = FreeCadMacroRunner.outputTag;
    return '''
import contextlib
import io
import json
import sys
import traceback

import FreeCAD

target = $target
packages = $specs
log_path = $log
result = {'ok': False}
buffer = io.StringIO()

try:
    args = ['install', '--upgrade', '--target', target] + packages + [
        '--disable-pip-version-check',
        '--no-warn-script-location',
    ]
    try:
        from pip._internal.cli.main import main as pip_main
    except Exception:
        pip_main = None
    with contextlib.redirect_stdout(buffer), contextlib.redirect_stderr(buffer):
        if pip_main is not None:
            code = pip_main(args)
        else:
            import runpy
            saved_argv = sys.argv
            sys.argv = ['pip'] + args
            code = 0
            try:
                runpy.run_module('pip', run_name='__main__', alter_sys=True)
            except SystemExit as exc:
                code = exc.code if exc.code is not None else 0
            finally:
                sys.argv = saved_argv
    result['code'] = code
    result['ok'] = (code == 0)
except SystemExit as exc:
    result['code'] = exc.code
    result['ok'] = exc.code in (0, None)
except Exception:
    result['error'] = traceback.format_exc()

with open(log_path, 'w', encoding='utf-8') as handle:
    handle.write(buffer.getvalue())
FreeCAD.Console.PrintMessage('[$tag]' + json.dumps(result) + '[/$tag]\\n')
sys.exit(0)
''';
  }

  Map<String, String> _environment({Map<String, String> extra = const {}}) {
    final environment = Map<String, String>.from(Platform.environment);
    removeSanitizedEnvironmentKeys(environment);
    environment['PIP_DISABLE_PIP_VERSION_CHECK'] = '1';
    environment['PIP_NO_INPUT'] = '1';
    environment['PYTHONNOUSERSITE'] = '1';
    environment.addAll(extra);
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
