// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/core/path_segments.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';

class AppPaths {
  AppPaths({required this.dataRoot, p.Context? context, this.legacyRoot})
    : _p = context ?? p.context;

  final String dataRoot;

  /// The pre-M8-07 Windows data root, set when the pinned root is in use so
  /// stored absolute paths under it can be repaired at startup (D-117).
  final String? legacyRoot;

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
  }) async {
    final isWindows = windows ?? Platform.isWindows;
    if (isWindows) {
      final resolved = await _resolveWindowsDataRoot(
        environment ?? Platform.environment,
        supportDirectory ?? getApplicationSupportDirectory,
      );
      return AppPaths(dataRoot: resolved.path, legacyRoot: resolved.legacy);
    }
    final support = await (supportDirectory ?? getApplicationSupportDirectory)();
    return AppPaths(dataRoot: support.path);
  }

  /// The Windows data root is pinned to the application id (D-016) so changes
  /// to the executable's version metadata can never move the data again. The
  /// pre-M8-07 directory is never renamed: the database stores absolute paths,
  /// so existing installs keep using their directory in place (D-117). Fresh
  /// installs use the pinned root.
  static Future<({String path, String? legacy})> _resolveWindowsDataRoot(
    Map<String, String> environment,
    Future<Directory> Function() supportDirectory,
  ) async {
    final appData = environment['APPDATA'];
    if (appData == null || appData.isEmpty) {
      final support = await supportDirectory();
      return (path: support.path, legacy: null);
    }
    final pinnedRoot = p.join(appData, applicationId);
    final legacyRoot = p.join(appData, _legacyWindowsCompany, appName);
    final pinnedInstalled = File(p.join(pinnedRoot, 'config.db')).existsSync();
    final legacyInstalled = File(p.join(legacyRoot, 'config.db')).existsSync();
    if (pinnedInstalled || !legacyInstalled) {
      return (path: pinnedRoot, legacy: legacyRoot);
    }
    return (path: legacyRoot, legacy: null);
  }

  static const String _legacyWindowsCompany = 'FreeCAD Launcher contributors';
}
