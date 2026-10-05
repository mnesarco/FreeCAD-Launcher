// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:freecad_launcher/domain/profiles/launch_environment.dart';
import 'package:freecad_launcher/domain/python/python_names.dart';
import 'package:freecad_launcher/platform/freecad_macro_runner.dart';
import 'package:freecad_launcher/platform/process.dart';

/// Detects which Python packages are already importable for a build, mirroring
/// the AddonManager check (`importlib.util.find_spec` first, then
/// `importlib.metadata.distribution`). Used to skip packages bundled with
/// FreeCAD, installed in the profile, or shipped by the standard library.
class PythonPackageProbe {
  PythonPackageProbe({required ProcessRunner processRunner})
    : _processRunner = processRunner,
      _macroRunner = FreeCadMacroRunner(processRunner: processRunner);

  final ProcessRunner _processRunner;
  final FreeCadMacroRunner _macroRunner;

  static const String marker = 'FCL_PACKAGES:';

  static final RegExp _validName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');

  static const String _script =
      '''
import importlib.metadata
import importlib.util
import json
import re
import sys


def normalize(name):
    return re.sub(r"[-_.]+", "-", name).lower()


available = []
for name in sys.argv[1:]:
    try:
        if importlib.util.find_spec(name) is not None:
            available.append(normalize(name))
            continue
    except Exception:
        pass
    try:
        importlib.metadata.distribution(name)
        available.append(normalize(name))
    except Exception:
        pass
print("$marker" + json.dumps(available))
''';

  /// Returns the PEP 503-normalized names that are already importable, or
  /// `null` when the probe could not run (interpreter missing, timeout,
  /// malformed output). An empty set means "none of the candidates".
  Future<Set<String>?> availablePackages({
    required String pythonPath,
    required String targetDirectory,
    required Iterable<String> names,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final candidates = <String>{
      for (final name in names)
        if (_validName.hasMatch(name.trim())) normalizePythonPackageName(name),
    };
    if (candidates.isEmpty) {
      return <String>{};
    }

    final ProcessResult result;
    try {
      result = await _processRunner.run(
        ProcessSpec(
          executable: pythonPath,
          arguments: ['-c', _script, ...candidates],
          environment: _environment(targetDirectory),
        ),
        timeout: timeout,
      );
    } on Object {
      return null;
    }
    if (!result.isSuccess) {
      return null;
    }
    for (final line in result.stdout.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.startsWith(marker)) {
        continue;
      }
      try {
        final decoded = jsonDecode(trimmed.substring(marker.length));
        if (decoded is List) {
          return {
            for (final item in decoded)
              if (item is String) item,
          };
        }
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  /// Same availability check as [availablePackages], executed inside a mounted
  /// AppImage through a headless macro (D-112), so no extraction is needed.
  /// The profile target is appended to `sys.path` to mirror FreeCAD's runtime
  /// order. Returns `null` when the macro produced no result.
  Future<Set<String>?> availablePackagesInFreeCad({
    required String executablePath,
    required String targetDirectory,
    required Iterable<String> names,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final candidates = <String>{
      for (final name in names)
        if (_validName.hasMatch(name.trim())) normalizePythonPackageName(name),
    }.toList();
    if (candidates.isEmpty) {
      return <String>{};
    }
    final outcome = await _macroRunner.runAppImage(
      appImagePath: executablePath,
      macroBody: _appImageProbeMacro(targetDirectory: targetDirectory, names: candidates),
      timeout: timeout,
      macroName: 'FCL_Packages',
    );
    final available = outcome.payloadMap?['available'];
    if (available is List) {
      return {
        for (final item in available)
          if (item is String) item,
      };
    }
    return null;
  }

  String _appImageProbeMacro({required String targetDirectory, required List<String> names}) {
    final target = jsonEncode(targetDirectory);
    final candidates = jsonEncode(names);
    const tag = FreeCadMacroRunner.outputTag;
    return '''
import importlib.metadata
import importlib.util
import json
import os
import re
import sys

import FreeCAD

target = $target
if target and os.path.isdir(target):
    sys.path.append(target)
available = []
for name in $candidates:
    found = False
    try:
        if importlib.util.find_spec(name) is not None:
            found = True
    except Exception:
        pass
    if not found:
        try:
            importlib.metadata.distribution(name)
            found = True
        except Exception:
            pass
    if found:
        available.append(re.sub(r'[-_.]+', '-', name).lower())
FreeCAD.Console.PrintMessage('[$tag]' + json.dumps({'available': available}) + '[/$tag]\\n')
sys.exit(0)
''';
  }

  Map<String, String> _environment(String targetDirectory) {
    final environment = Map<String, String>.from(Platform.environment);
    removeSanitizedEnvironmentKeys(environment);
    if (Directory(targetDirectory).existsSync()) {
      environment['PYTHONPATH'] = targetDirectory;
    }
    environment['PYTHONNOUSERSITE'] = '1';
    environment['PYTHONIOENCODING'] = 'utf-8';
    return environment;
  }
}
