// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/process.dart';

class CliWrapperStatus {
  const CliWrapperStatus({
    required this.path,
    required this.directory,
    required this.installed,
    required this.onPath,
  });

  final String path;
  final String directory;
  final bool installed;
  final bool onPath;
}

class CliWrapperInstaller {
  CliWrapperInstaller({
    required BuildPlatform platform,
    required ProcessRunner processRunner,
    String? homeDirectory,
    String? localAppData,
    String? appExecutable,
    String? pathEnvironment,
  }) : _platform = platform,
       _processRunner = processRunner,
       _home = homeDirectory ?? Platform.environment['HOME'] ?? '',
       _localAppData = localAppData ?? Platform.environment['LOCALAPPDATA'] ?? '',
       _appExecutable = appExecutable ?? resolveAppExecutable(),
       _pathValue = pathEnvironment ?? Platform.environment['PATH'] ?? '',
       _context = platform == BuildPlatform.windows
           ? p.Context(style: p.Style.windows)
           : p.Context(style: p.Style.posix);

  final BuildPlatform _platform;
  final ProcessRunner _processRunner;
  final String _home;
  final String _localAppData;
  final String _appExecutable;
  final String _pathValue;
  final p.Context _context;

  String get wrapperPath {
    if (_platform == BuildPlatform.windows) {
      return _context.join(_localAppData, 'FreeCADLauncher', 'bin', 'freecad-launcher.cmd');
    }
    return _context.join(_home, '.local', 'bin', 'freecad-launcher');
  }

  String get wrapperDirectory => _context.dirname(wrapperPath);

  String get appExecutable => _appExecutable;

  CliWrapperStatus status() {
    return CliWrapperStatus(
      path: wrapperPath,
      directory: wrapperDirectory,
      installed: File(wrapperPath).existsSync(),
      onPath: _isOnPath(wrapperDirectory),
    );
  }

  Future<Result<void>> install() async {
    try {
      Directory(wrapperDirectory).createSync(recursive: true);
      File(wrapperPath).writeAsStringSync(wrapperScript());
      if (_platform != BuildPlatform.windows) {
        final chmod = await _processRunner.run(
          ProcessSpec(executable: 'chmod', arguments: ['755', wrapperPath]),
        );
        if (!chmod.isSuccess) {
          throw FileSystemException(
            'Could not mark the wrapper as executable',
            wrapperPath,
          );
        }
      }
      return const Ok(null);
    } on Object catch (error) {
      return Err(AppError.from(error, retryable: true));
    }
  }

  Future<Result<void>> remove() async {
    try {
      final file = File(wrapperPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      return const Ok(null);
    } on Object catch (error) {
      return Err(AppError.from(error, retryable: true));
    }
  }

  String wrapperScript() {
    if (_platform == BuildPlatform.windows) {
      return '@echo off\r\n"${_escapeWindows(_appExecutable)}" %*\r\n';
    }
    return '#!/bin/sh\nexec "${_escapePosix(_appExecutable)}" "\$@"\n';
  }

  bool _isOnPath(String directory) {
    final separator = _platform == BuildPlatform.windows ? ';' : ':';
    final target = _context.normalize(directory);
    for (final entry in _pathValue.split(separator)) {
      if (entry.trim().isEmpty) {
        continue;
      }
      if (_context.normalize(entry.trim()) == target) {
        return true;
      }
    }
    return false;
  }

  static String _escapePosix(String value) => value.replaceAll('"', r'\"');

  static String _escapeWindows(String value) => value.replaceAll('"', '""');
}

String resolveAppExecutable() {
  final appImage = Platform.environment['APPIMAGE'];
  if (Platform.isLinux && appImage != null && appImage.isNotEmpty) {
    return appImage;
  }
  return Platform.resolvedExecutable;
}
