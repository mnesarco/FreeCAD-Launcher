// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:freecad_launcher/core/path_segments.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';

class AppPaths {
  AppPaths({required this.dataRoot, p.Context? context}) : _p = context ?? p.context;

  final String dataRoot;
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

  static Future<AppPaths> resolve() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return AppPaths(dataRoot: supportDirectory.path);
  }
}
