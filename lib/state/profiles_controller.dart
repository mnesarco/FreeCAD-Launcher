import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/launch.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';

class LaunchResult {
  const LaunchResult.started(ProcessHandle this.handle)
    : error = null,
      quarantineAppPath = null;

  const LaunchResult.quarantineRequired(String this.quarantineAppPath)
    : handle = null,
      error = null;

  const LaunchResult.failure(AppError this.error)
    : handle = null,
      quarantineAppPath = null;

  final ProcessHandle? handle;
  final AppError? error;
  final String? quarantineAppPath;

  bool get isStarted => handle != null;

  bool get isQuarantineRequired => quarantineAppPath != null;

  bool get isFailure => error != null;
}

class ProfilesController {
  ProfilesController({
    required AppDatabase database,
    required ProfilesRepository repository,
    required AppPaths paths,
    required BuildPlatform platform,
    required FreeCadRuntime runtime,
  }) : _database = database,
       _repository = repository,
       _paths = paths,
       _platform = platform,
       _runtime = runtime;

  final AppDatabase _database;
  final ProfilesRepository _repository;
  final AppPaths _paths;
  final BuildPlatform _platform;
  final FreeCadRuntime _runtime;

  final profiles = signal<List<Profile>>([]);

  StreamSubscription<List<Profile>>? _profilesSubscription;

  void start() {
    _profilesSubscription ??= _repository.watchAll().listen(
      (value) => profiles.value = value,
    );
  }

  Future<List<Profile>> getAll() => _repository.getAll();

  Future<Profile?> getById(String id) => _repository.getById(id);

  Future<Result<Profile>> create({
    required String name,
    required String buildId,
    String? description,
  }) {
    return _repository.create(name: name, buildId: buildId, description: description);
  }

  Future<Result<Profile>> duplicate({
    required String profileId,
    required String name,
    bool copyPayload = false,
  }) {
    return _repository.duplicate(
      profileId: profileId,
      name: name,
      copyPayload: copyPayload,
    );
  }

  Future<Result<Profile>> rename({required String profileId, required String name}) {
    return _repository.rename(profileId: profileId, name: name);
  }

  Future<Result<ProfileBuildChange>> setBuild({
    required String profileId,
    required String buildId,
  }) {
    return _repository.setBuild(profileId: profileId, buildId: buildId);
  }

  Future<Result<void>> delete(String profileId) => _repository.delete(profileId);

  Future<LaunchResult> launch({
    required String profileId,
    List<String> userArguments = const [],
    bool quarantineConsent = false,
  }) async {
    final profile = await _repository.getById(profileId);
    if (profile == null) {
      return LaunchResult.failure(const AppError(message: 'Profile not found'));
    }

    final build = await _database.buildsDao.getById(profile.buildId);
    if (build == null) {
      return LaunchResult.failure(
        const AppError(message: "This profile's build no longer exists"),
      );
    }
    if (build.status != BuildStatus.installed) {
      return LaunchResult.failure(
        AppError(
          message: 'This build is ${build.status.name} and cannot be launched',
          detail: 'Verify or repair the build first.',
        ),
      );
    }

    await _paths.ensureProfileDirectories(profile.id, _platform);
    final plan = await _runtime.planFor(
      kind: build.kind,
      executablePath: build.localPath,
      paths: _paths.profilePaths(profile.id),
      userArguments: userArguments,
    );

    final appPath = await _runtime.quarantineAppPath(plan.executable);
    if (appPath != null) {
      if (!quarantineConsent) {
        return LaunchResult.quarantineRequired(appPath);
      }
      try {
        await _runtime.clearQuarantine(appPath);
      } on Object catch (error) {
        return LaunchResult.failure(AppError.from(error, retryable: true));
      }
    }

    try {
      final handle = await _runtime.start(plan);
      await _repository.markUsed(profile.id);
      return LaunchResult.started(handle);
    } on Object catch (error) {
      return LaunchResult.failure(AppError.from(error, retryable: true));
    }
  }

  void dispose() {
    _profilesSubscription?.cancel();
    _profilesSubscription = null;
  }
}
