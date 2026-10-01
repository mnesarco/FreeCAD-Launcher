// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';
import 'package:freecad_launcher/domain/profiles/profile_rules.dart';
import 'package:freecad_launcher/platform/paths.dart';

class ProfileBuildChange {
  const ProfileBuildChange({required this.profile, required this.pythonChanged});

  final Profile profile;
  final bool pythonChanged;
}

class ProfilesRepository {
  ProfilesRepository({
    required AppDatabase database,
    required AppPaths paths,
    required BuildPlatform platform,
    DateTime Function()? clock,
  }) : _database = database,
       _paths = paths,
       _platform = platform,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final AppPaths _paths;
  final BuildPlatform _platform;
  final DateTime Function() _clock;

  Stream<List<Profile>> watchAll() => _database.profilesDao.watchAll();

  Future<List<Profile>> getAll() => _database.profilesDao.getAll();

  Future<Profile?> getById(String id) => _database.profilesDao.getById(id);

  Future<Profile?> getByName(String name) => _database.profilesDao.getByName(name);

  Future<Result<Profile>> create({
    required String name,
    required String buildId,
    String? description,
  }) async {
    final normalized = normalizeProfileName(name);
    final nameIssue = validateProfileName(normalized);
    if (nameIssue != null) {
      return Err(_nameError(nameIssue));
    }
    if (await _database.profilesDao.getByName(normalized) != null) {
      return Err(_duplicateNameError(normalized));
    }

    final build = await _database.buildsDao.getById(buildId);
    if (build == null) {
      return const Err(AppError(message: 'The selected build no longer exists'));
    }
    final bindingIssue = validateProfileBinding(
      status: build.status,
      pythonVersion: build.pythonVersion,
    );
    if (bindingIssue != null) {
      return Err(_bindingError(bindingIssue));
    }

    final now = _clock();
    final profile = Profile(
      id: const Uuid().v4(),
      name: normalized,
      description: description,
      buildId: build.id,
      pythonVersion: build.pythonVersion!,
      createdAt: now,
      updatedAt: now,
    );

    final staged = await _stageDirectory(profile.id);
    final stageError = staged.errorOrNull;
    if (stageError != null) {
      return Err(stageError);
    }
    final saveError = await _saveProfile(profile);
    if (saveError != null) {
      return Err(saveError);
    }
    return Ok(profile);
  }

  Future<Result<Profile>> duplicate({
    required String profileId,
    required String name,
    bool copyPayload = false,
  }) async {
    final source = await _database.profilesDao.getById(profileId);
    if (source == null) {
      return const Err(AppError(message: 'Profile not found'));
    }

    final normalized = normalizeProfileName(name);
    final nameIssue = validateProfileName(normalized);
    if (nameIssue != null) {
      return Err(_nameError(nameIssue));
    }
    if (await _database.profilesDao.getByName(normalized) != null) {
      return Err(_duplicateNameError(normalized));
    }

    final now = _clock();
    final newId = const Uuid().v4();
    final sourceRoot = _profileRoot(source.id);
    final newRoot = _profileRoot(newId);

    final staged = await _stageDirectory(
      newId,
      copyFrom: sourceRoot,
      copyPayload: copyPayload,
    );
    final stageError = staged.errorOrNull;
    if (stageError != null) {
      return Err(stageError);
    }

    final duplicate = Profile(
      id: newId,
      name: normalized,
      description: source.description,
      buildId: source.buildId,
      pythonVersion: source.pythonVersion,
      iconColor: source.iconColor,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _database.profilesDao.save(duplicate);
      if (copyPayload) {
        await _copyPayloadRows(source.id, newId, sourceRoot, newRoot);
      }
    } on Object catch (error) {
      _deleteDirectory(newRoot);
      try {
        await _database.profilesDao.deleteById(newId);
      } on Object {
        // Best-effort rollback; the directory is already gone.
      }
      return Err(AppError.from(error, retryable: true));
    }
    return Ok(duplicate);
  }

  Future<Result<Profile>> rename({required String profileId, required String name}) async {
    final profile = await _database.profilesDao.getById(profileId);
    if (profile == null) {
      return const Err(AppError(message: 'Profile not found'));
    }

    final normalized = normalizeProfileName(name);
    final nameIssue = validateProfileName(normalized);
    if (nameIssue != null) {
      return Err(_nameError(nameIssue));
    }
    final existing = await _database.profilesDao.getByName(normalized);
    if (existing != null && existing.id != profile.id) {
      return Err(_duplicateNameError(normalized));
    }

    final updated = profile.copyWith(name: normalized, updatedAt: _clock());
    await _database.profilesDao.save(updated);
    return Ok(updated);
  }

  Future<Result<ProfileBuildChange>> setBuild({
    required String profileId,
    required String buildId,
  }) async {
    final profile = await _database.profilesDao.getById(profileId);
    if (profile == null) {
      return const Err(AppError(message: 'Profile not found'));
    }

    final build = await _database.buildsDao.getById(buildId);
    if (build == null) {
      return const Err(AppError(message: 'The selected build no longer exists'));
    }
    final bindingIssue = validateProfileBinding(
      status: build.status,
      pythonVersion: build.pythonVersion,
    );
    if (bindingIssue != null) {
      return Err(_bindingError(bindingIssue));
    }

    final pythonChanged = profile.pythonVersion != build.pythonVersion;
    final updated = profile.copyWith(
      buildId: build.id,
      pythonVersion: build.pythonVersion,
      updatedAt: _clock(),
    );
    await _database.profilesDao.save(updated);
    return Ok(ProfileBuildChange(profile: updated, pythonChanged: pythonChanged));
  }

  Future<void> markUsed(String profileId, {DateTime? at}) {
    return _database.profilesDao.touchLastUsed(profileId, at ?? _clock());
  }

  Future<Result<void>> delete(String profileId) async {
    final profile = await _database.profilesDao.getById(profileId);
    if (profile == null) {
      return const Err(AppError(message: 'Profile not found'));
    }

    try {
      _deleteDirectory(_profileRoot(profile.id));
    } on Object catch (error) {
      return Err(
        AppError(
          message: 'Could not delete the profile files',
          detail: '$error',
          retryable: true,
        ),
      );
    }

    await _database.profilesDao.deleteById(profileId);
    return const Ok(null);
  }

  Future<AppError?> _saveProfile(Profile profile) async {
    try {
      await _database.profilesDao.save(profile);
      return null;
    } on Object catch (error) {
      _deleteDirectory(_profileRoot(profile.id));
      return AppError.from(error, retryable: true);
    }
  }

  Future<Result<void>> _stageDirectory(
    String id, {
    String? copyFrom,
    bool copyPayload = false,
  }) async {
    final finalRoot = _profileRoot(id);
    final stagingRoot = '$finalRoot.part';
    final staging = Directory(stagingRoot);

    try {
      if (staging.existsSync()) {
        staging.deleteSync(recursive: true);
      }
      _createLayout(stagingRoot);
      if (copyFrom != null) {
        _copyConfig(copyFrom, stagingRoot);
        if (copyPayload) {
          _copyPayload(copyFrom, stagingRoot);
        }
      }
      _deleteDirectory(finalRoot);
      await staging.rename(finalRoot);
      return const Ok(null);
    } on Object catch (error) {
      if (staging.existsSync()) {
        staging.deleteSync(recursive: true);
      }
      return Err(
        AppError(
          message: 'Could not create the profile files',
          detail: '$error',
          retryable: true,
        ),
      );
    }
  }

  void _createLayout(String root) {
    for (final path in ProfilePaths(root).directoriesFor(_platform)) {
      Directory(path).createSync(recursive: true);
    }
  }

  void _copyConfig(String sourceRoot, String destinationRoot) {
    for (final name in const ['user.cfg', 'system.cfg']) {
      final sourcePath = p.join(sourceRoot, name);
      if (File(sourcePath).existsSync()) {
        File(sourcePath).copySync(p.join(destinationRoot, name));
      } else if (Directory(sourcePath).existsSync()) {
        throw FileSystemException('Expected a file', sourcePath);
      }
    }
  }

  void _copyPayload(String sourceRoot, String destinationRoot) {
    for (final name in const ['Mod', 'AdditionalPythonPackages', 'Macro']) {
      _copyDirectoryIfExists(
        p.join(sourceRoot, name),
        p.join(destinationRoot, name),
      );
    }

    final source = Directory(sourceRoot);
    if (!source.existsSync()) {
      return;
    }
    for (final entity in source.listSync(followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.fcmacro')) {
        entity.copySync(p.join(destinationRoot, p.basename(entity.path)));
      }
    }
  }

  void _copyDirectoryIfExists(String sourcePath, String destinationPath) {
    final source = Directory(sourcePath);
    if (!source.existsSync()) {
      return;
    }
    Directory(destinationPath).createSync(recursive: true);
    for (final entity in source.listSync(recursive: true, followLinks: false)) {
      final relative = p.relative(entity.path, from: sourcePath);
      final target = p.join(destinationPath, relative);
      if (entity is File) {
        File(target).parent.createSync(recursive: true);
        entity.copySync(target);
      } else if (entity is Directory) {
        Directory(target).createSync(recursive: true);
      }
    }
  }

  Future<void> _copyPayloadRows(
    String sourceId,
    String newId,
    String sourceRoot,
    String newRoot,
  ) async {
    for (final addon in await _database.installedAddonsDao.getByProfile(sourceId)) {
      await _database.installedAddonsDao.save(
        InstalledAddon(
          id: const Uuid().v4(),
          profileId: newId,
          addonId: addon.addonId,
          displayName: addon.displayName,
          gitRef: addon.gitRef,
          version: addon.version,
          installedAt: addon.installedAt,
          updatedAt: addon.updatedAt,
          catalogLastUpdate: addon.catalogLastUpdate,
          sourceUrl: addon.sourceUrl,
          source: addon.source,
          sourcePath: addon.sourcePath,
          hasRequirements: addon.hasRequirements,
        ),
      );
    }

    for (final package in await _database.pythonPackagesDao.getByProfile(sourceId)) {
      await _database.pythonPackagesDao.save(
        PythonPackage(
          id: const Uuid().v4(),
          profileId: newId,
          name: package.name,
          version: package.version,
          targetDir: _rewriteTargetDir(package.targetDir, sourceRoot, newRoot),
          source: package.source,
          installedAt: package.installedAt,
        ),
      );
    }

    for (final macro in await _database.macrosDao.getByProfile(sourceId)) {
      await _database.macrosDao.save(
        Macro(
          id: const Uuid().v4(),
          profileId: newId,
          name: macro.name,
          fileName: macro.fileName,
          source: macro.source,
          installedAt: macro.installedAt,
          updatedAt: macro.updatedAt,
          catalogCommit: macro.catalogCommit,
        ),
      );
    }
  }

  String _rewriteTargetDir(String targetDir, String sourceRoot, String newRoot) {
    if (targetDir == sourceRoot || p.isWithin(sourceRoot, targetDir)) {
      return p.join(newRoot, p.relative(targetDir, from: sourceRoot));
    }
    return targetDir;
  }

  void _deleteDirectory(String root) {
    final directory = Directory(root);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }

  String _profileRoot(String id) => _paths.profilePaths(id).root;

  AppError _nameError(ProfileNameIssue issue) {
    return switch (issue) {
      ProfileNameIssue.empty => const AppError(message: 'Enter a profile name'),
      ProfileNameIssue.tooLong => const AppError(
        message: 'Profile names are limited to $maxProfileNameLength characters',
      ),
      ProfileNameIssue.controlCharacters => const AppError(
        message: 'Profile names cannot contain control characters',
      ),
    };
  }

  AppError _duplicateNameError(String name) {
    return AppError(message: 'A profile named "$name" already exists');
  }

  AppError _bindingError(ProfileBindingIssue issue) {
    return switch (issue) {
      ProfileBindingIssue.buildNotInstalled => const AppError(
        message: 'This build is not installed',
        detail: 'Verify or repair the build before creating a profile with it.',
      ),
      ProfileBindingIssue.pythonNotDetected => const AppError(
        message: 'This build has no detected Python version',
        detail: 'Profiles need Python for addons and packages; select the interpreter first.',
      ),
    };
  }
}
