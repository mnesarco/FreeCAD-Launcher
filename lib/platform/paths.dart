// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/core/path_segments.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';

typedef DirectoryMove = void Function(String from, String to);

class AppPaths {
  AppPaths({required this.dataRoot, p.Context? context, this.migrationWarning})
    : _p = context ?? p.context;

  final String dataRoot;

  /// Non-null when the Windows legacy data directory could not be moved to the
  /// pinned location and the legacy root is being used for this session.
  final String? migrationWarning;

  final p.Context _p;

  String get databaseFile => _p.join(dataRoot, 'config.db');

  String get buildsDir => _p.join(dataRoot, 'builds');

  String get profilesDir => _p.join(dataRoot, 'profiles');

  String get cacheDir => _p.join(dataRoot, 'cache');

  String get logsDir => _p.join(dataRoot, 'logs');

  String get exportsDir => _p.join(dataRoot, 'exports');

  String get downloadsCacheDir => _p.join(cacheDir, 'downloads');

  String get githubCacheDir => _p.join(cacheDir, 'github');

  String get addonsCacheDir => _p.join(cacheDir, 'addons');

  String get macrosCacheDir => _p.join(cacheDir, 'macros');

  String get macroIconsCacheDir => _p.join(macrosCacheDir, 'icons');

  String get newsCacheDir => _p.join(cacheDir, 'news');

  String buildDir(String buildId) => _p.join(buildsDir, safePathSegment(buildId));

  /// Directory names a build may use: the D-095 sanitized name and, on POSIX,
  /// the legacy unsanitized one from installs created before D-095.
  List<String> buildDirCandidates(String buildId) {
    final sanitized = buildDir(buildId);
    final legacy = _p.join(buildsDir, buildId);
    return legacy == sanitized ? [sanitized] : [sanitized, legacy];
  }

  /// Existing build directory, preferring the sanitized name.
  String? existingBuildDir(String buildId) {
    for (final candidate in buildDirCandidates(buildId)) {
      if (Directory(candidate).existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  ProfilePaths profilePaths(String profileId) =>
      ProfilePaths(_p.join(profilesDir, profileId), context: _p);

  List<String> get baseDirectories => [
    dataRoot,
    buildsDir,
    profilesDir,
    cacheDir,
    logsDir,
    exportsDir,
    downloadsCacheDir,
    githubCacheDir,
    addonsCacheDir,
    macrosCacheDir,
    macroIconsCacheDir,
    newsCacheDir,
  ];

  Future<void> ensureBaseDirectories() async {
    for (final path in baseDirectories) {
      await Directory(path).create(recursive: true);
    }
  }

  Future<void> ensureProfileDirectories(String profileId, BuildPlatform platform) async {
    for (final path in profilePaths(profileId).directoriesFor(platform)) {
      final directory = Directory(path);
      if (directory.existsSync()) {
        continue;
      }
      await directory.create(recursive: true);
    }
  }

  static Future<AppPaths> resolve({
    bool? windows,
    Map<String, String>? environment,
    Future<Directory> Function()? supportDirectory,
    DirectoryMove? move,
  }) async {
    final isWindows = windows ?? Platform.isWindows;
    if (isWindows) {
      final resolved = await _resolveWindowsDataRoot(
        environment ?? Platform.environment,
        supportDirectory ?? getApplicationSupportDirectory,
        move ?? _renameDirectory,
      );
      return AppPaths(dataRoot: resolved.path, migrationWarning: resolved.warning);
    }
    final support = await (supportDirectory ?? getApplicationSupportDirectory)();
    return AppPaths(dataRoot: support.path);
  }

  /// The Windows data root is pinned to the application id (D-016/D-116) so
  /// changes to the executable's version metadata can never orphan user data.
  /// The pre-M8-07 location derived from `CompanyName\ProductName` is moved
  /// into place once; on failure the legacy root stays in use and the move is
  /// retried on the next start (never a partial copy).
  static Future<({String path, String? warning})> _resolveWindowsDataRoot(
    Map<String, String> environment,
    Future<Directory> Function() supportDirectory,
    DirectoryMove move,
  ) async {
    final appData = environment['APPDATA'];
    if (appData == null || appData.isEmpty) {
      final support = await supportDirectory();
      return (path: support.path, warning: null);
    }
    final newRoot = p.join(appData, applicationId);
    final legacyRoot = p.join(appData, _legacyWindowsCompany, appName);
    if (!Directory(legacyRoot).existsSync()) {
      return (path: newRoot, warning: null);
    }
    if (_isNonEmptyDirectory(Directory(newRoot))) {
      return (path: newRoot, warning: null);
    }
    try {
      final newDirectory = Directory(newRoot);
      if (newDirectory.existsSync()) {
        newDirectory.deleteSync();
      }
      move(legacyRoot, newRoot);
    } on FileSystemException catch (error) {
      return (
        path: legacyRoot,
        warning:
            'Could not move the legacy data directory $legacyRoot to $newRoot: '
            '${error.message}. Continuing with the legacy location; the move is retried on next start.',
      );
    }
    _removeEmptyDirectory(p.dirname(legacyRoot));
    return (path: newRoot, warning: null);
  }

  static const String _legacyWindowsCompany = 'FreeCAD Launcher contributors';

  static void _renameDirectory(String from, String to) => Directory(from).renameSync(to);

  static bool _isNonEmptyDirectory(Directory directory) {
    try {
      return directory.existsSync() && directory.listSync().isNotEmpty;
    } on FileSystemException {
      return true;
    }
  }

  static void _removeEmptyDirectory(String path) {
    try {
      final directory = Directory(path);
      if (directory.existsSync() && directory.listSync().isEmpty) {
        directory.deleteSync();
      }
    } on FileSystemException {
      // Best-effort cleanup; an empty parent directory is harmless.
    }
  }
}
