import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/launch_plan.dart';
import 'package:freecad_launcher/platform/launch.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';

class ProfileLaunch {
  ProfileLaunch({
    required this.id,
    required this.profileId,
    required this.logPath,
    required this.startedAt,
    required this.exitCode,
  });

  final String id;
  final String profileId;
  final String logPath;
  final DateTime startedAt;
  final Future<int> exitCode;
}

class LaunchResult {
  const LaunchResult.started(ProfileLaunch this.launch)
    : error = null,
      quarantineAppPath = null;

  const LaunchResult.quarantineRequired(String this.quarantineAppPath)
    : launch = null,
      error = null;

  const LaunchResult.failure(AppError this.error)
    : launch = null,
      quarantineAppPath = null;

  final ProfileLaunch? launch;
  final AppError? error;
  final String? quarantineAppPath;

  bool get isStarted => launch != null;

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
    DateTime Function()? clock,
  }) : _database = database,
       _repository = repository,
       _paths = paths,
       _platform = platform,
       _runtime = runtime,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final ProfilesRepository _repository;
  final AppPaths _paths;
  final BuildPlatform _platform;
  final FreeCadRuntime _runtime;
  final DateTime Function() _clock;

  final profiles = signal<List<Profile>>([]);
  final runningProfiles = signal<Set<String>>({});
  final launchLogs = signal<Map<String, String>>({});
  final lastExitCodes = signal<Map<String, int>>({});

  final Map<String, int> _runningCounts = {};

  StreamSubscription<List<Profile>>? _profilesSubscription;

  void start() {
    _profilesSubscription ??= _repository.watchAll().listen(
      (value) => profiles.value = value,
    );
  }

  bool isRunning(String profileId) => runningProfiles.value.contains(profileId);

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

    final logFile = _newLogFile(profile);
    final logSink = logFile.openWrite();
    try {
      final handle = await _runtime.start(plan);
      final launch = _trackLaunch(profile, plan, handle, logFile, logSink);
      await _repository.markUsed(profile.id);
      return LaunchResult.started(launch);
    } on Object catch (error) {
      try {
        await logSink.close();
      } on Object {
        // The sink may already be closed.
      }
      if (logFile.existsSync()) {
        logFile.deleteSync();
      }
      return LaunchResult.failure(AppError.from(error, retryable: true));
    }
  }

  ProfileLaunch _trackLaunch(
    Profile profile,
    LaunchPlan plan,
    ProcessHandle handle,
    File logFile,
    IOSink logSink,
  ) {
    final exitCompleter = Completer<int>();
    logSink
      ..writeln('# ${_clock().toIso8601String()} profile="${profile.name}"')
      ..writeln('# ${plan.executable}')
      ..writeln('# args: ${plan.arguments.join(' ')}')
      ..writeln('---');

    final stdoutDone = handle.stdout.listen(logSink.add).asFuture<void>();
    final stderrDone = handle.stderr.listen(logSink.add).asFuture<void>();

    unawaited(() async {
      final code = await handle.exitCode;
      _finishLaunch(profile.id, code);
      if (!exitCompleter.isCompleted) {
        exitCompleter.complete(code);
      }
      await Future.wait([
        stdoutDone.timeout(const Duration(seconds: 5), onTimeout: () {}),
        stderrDone.timeout(const Duration(seconds: 5), onTimeout: () {}),
      ]);
      try {
        await logSink.flush();
      } on Object {
        // Best-effort flush; the process is already gone.
      }
      try {
        await logSink.close();
      } on Object {
        // The sink may already be closed.
      }
    }());

    _runningCounts[profile.id] = (_runningCounts[profile.id] ?? 0) + 1;
    runningProfiles.value = {...runningProfiles.value, profile.id};
    launchLogs.value = {...launchLogs.value, profile.id: logFile.path};

    return ProfileLaunch(
      id: const Uuid().v4(),
      profileId: profile.id,
      logPath: logFile.path,
      startedAt: _clock(),
      exitCode: exitCompleter.future,
    );
  }

  void _finishLaunch(String profileId, int exitCode) {
    final remaining = (_runningCounts[profileId] ?? 1) - 1;
    if (remaining <= 0) {
      _runningCounts.remove(profileId);
      runningProfiles.value = {...runningProfiles.value}..remove(profileId);
    } else {
      _runningCounts[profileId] = remaining;
    }
    lastExitCodes.value = {...lastExitCodes.value, profileId: exitCode};
  }

  File _newLogFile(Profile profile) {
    final safeName = profile.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final stamp = _clock().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    return File(p.join(_paths.logsDir, 'launch-$safeName-$stamp.log'));
  }

  void dispose() {
    _profilesSubscription?.cancel();
    _profilesSubscription = null;
  }
}
