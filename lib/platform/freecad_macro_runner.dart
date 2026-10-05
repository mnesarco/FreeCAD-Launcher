// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/platform/process.dart';

class FreeCadMacroOutcome {
  const FreeCadMacroOutcome({required this.exitCode, this.stdout = '', this.payload, this.error});

  final int exitCode;
  final String stdout;

  /// Decoded tagged JSON payload, or `null` when the macro did not report one.
  final Object? payload;
  final String? error;

  bool get hasPayload => payload != null;

  Map<String, Object?>? get payloadMap {
    final value = payload;
    return value is Map<String, Object?> ? value : null;
  }
}

/// Runs a generated `.FCMacro` inside a FreeCAD binary in console mode
/// (`<exe> -c -M <dir> <macro>`), with an isolated home/temp and a sanitized
/// Python environment. Used to execute Python inside a mounted AppImage
/// without extracting it (D-112).
class FreeCadMacroRunner {
  FreeCadMacroRunner({required ProcessRunner processRunner}) : _processRunner = processRunner;

  final ProcessRunner _processRunner;

  static const String outputTag = 'freecad-launcher:out';

  static const List<String> _sanitizedEnvironmentKeys = [
    'PYTHONPATH',
    'PYTHONHOME',
    'VIRTUAL_ENV',
    'PYTHONUSERBASE',
  ];

  /// Runs [macroBody] as a macro. When [extractAndRun] is set, the AppImage
  /// runtime is asked to extract itself to a temporary directory instead of
  /// using FUSE (`APPIMAGE_EXTRACT_AND_RUN=1`).
  Future<FreeCadMacroOutcome> run({
    required String executablePath,
    required String macroBody,
    Duration timeout = const Duration(seconds: 60),
    String tag = outputTag,
    bool extractAndRun = false,
    Map<String, String> environment = const {},
    void Function(String line)? onOutput,
    String macroName = 'FCL_Macro',
  }) async {
    final scriptDirectory = await Directory.systemTemp.createTemp('fcl-macro-');
    final script = File(p.join(scriptDirectory.path, '$macroName.FCMacro'));
    final home = Directory(p.join(scriptDirectory.path, 'home'))..createSync();
    final temp = Directory(p.join(scriptDirectory.path, 'temp'))..createSync();
    await script.writeAsString(macroBody);
    try {
      final ProcessResult result;
      try {
        result = await _processRunner.run(
          ProcessSpec(
            executable: executablePath,
            arguments: ['-c', '-M', scriptDirectory.path, script.path],
            environment: _environment(
              home.path,
              temp.path,
              extractAndRun: extractAndRun,
              extra: environment,
            ),
          ),
          timeout: timeout,
          onStdout: onOutput,
          onStderr: onOutput,
        );
      } on ProcessTimeoutException {
        return FreeCadMacroOutcome(exitCode: -1, error: 'FreeCAD macro timed out after $timeout');
      } on Object catch (error) {
        return FreeCadMacroOutcome(exitCode: -1, error: 'FreeCAD macro failed: $error');
      }

      return FreeCadMacroOutcome(
        exitCode: result.exitCode,
        stdout: result.stdout,
        payload: parsePayload(result.stdout, tag: tag),
      );
    } finally {
      await _cleanUpDirectory(scriptDirectory);
    }
  }

  /// AppImage convenience: retries with `APPIMAGE_EXTRACT_AND_RUN=1` when the
  /// first (FUSE) run produced no payload, e.g. on systems without libfuse.
  Future<FreeCadMacroOutcome> runAppImage({
    required String appImagePath,
    required String macroBody,
    Duration timeout = const Duration(seconds: 60),
    String tag = outputTag,
    Map<String, String> environment = const {},
    void Function(String line)? onOutput,
    String macroName = 'FCL_Macro',
  }) async {
    final first = await run(
      executablePath: appImagePath,
      macroBody: macroBody,
      timeout: timeout,
      tag: tag,
      environment: environment,
      onOutput: onOutput,
      macroName: macroName,
    );
    if (first.hasPayload) {
      return first;
    }
    final fallback = await run(
      executablePath: appImagePath,
      macroBody: macroBody,
      timeout: timeout,
      tag: tag,
      extractAndRun: true,
      environment: environment,
      onOutput: onOutput,
      macroName: macroName,
    );
    return fallback.hasPayload ? fallback : first;
  }

  /// Extracts the last `[tag]{json}[/tag]` payload from [stdout].
  static Object? parsePayload(String stdout, {String tag = outputTag}) {
    final pattern = RegExp('\\[$tag\\](.*?)\\[/$tag\\]', dotAll: true);
    Object? payload;
    for (final match in pattern.allMatches(stdout)) {
      try {
        payload = jsonDecode(match.group(1)!.trim());
      } on FormatException {
        continue;
      }
    }
    return payload;
  }

  Map<String, String> _environment(
    String home,
    String temp, {
    required bool extractAndRun,
    required Map<String, String> extra,
  }) {
    final environment = Map<String, String>.from(Platform.environment);
    for (final key in _sanitizedEnvironmentKeys) {
      environment.remove(key);
    }
    environment['FREECAD_USER_HOME'] = home;
    environment['FREECAD_USER_TEMP'] = temp;
    if (!Platform.isWindows) {
      environment['HOME'] = home;
      environment['TMPDIR'] = temp;
    }
    if (extractAndRun) {
      environment['APPIMAGE_EXTRACT_AND_RUN'] = '1';
    }
    environment.addAll(extra);
    return environment;
  }

  Future<void> _cleanUpDirectory(Directory directory) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (!directory.existsSync()) {
          return;
        }
        await directory.delete(recursive: true);
        return;
      } on FileSystemException {
        // An AppImage FUSE mount inside TMPDIR can still be tearing down
        // (ENOTCONN); retry briefly, then leave the directory to the OS.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
    appLogger.warn('Could not remove the FreeCAD macro directory ${directory.path}');
  }
}
