import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/profiles/profile_rules.dart';

class ProfileBuildChange {
  const ProfileBuildChange({required this.profile, required this.pythonChanged});

  final Profile profile;
  final bool pythonChanged;
}

class ProfilesRepository {
  ProfilesRepository({required AppDatabase database, DateTime Function()? clock})
    : _database = database,
      _clock = clock ?? DateTime.now;

  final AppDatabase _database;
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
    await _database.profilesDao.save(profile);
    return Ok(profile);
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

  Future<Result<void>> delete(String profileId) async {
    final deleted = await _database.profilesDao.deleteById(profileId);
    if (deleted == 0) {
      return const Err(AppError(message: 'Profile not found'));
    }
    return const Ok(null);
  }

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
