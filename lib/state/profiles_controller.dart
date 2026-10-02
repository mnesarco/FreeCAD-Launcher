// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/path_segments.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/launch_plan.dart';
import 'package:freecad_launcher/platform/config_snapshots.dart';
import 'package:freecad_launcher/platform/directory_size.dart';
import 'package:freecad_launcher/platform/freecad_preferences.dart';
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
    ConfigSnapshotService configSnapshots = const ConfigSnapshotService(),
    FreeCadPreferences freecadPreferences = const FreeCadPreferences(),
    DateTime Function()? clock,
  }) : _database = database,
       _repository = repository,
       _paths = paths,
       _platform = platform,
       _runtime = runtime,
       _configSnapshots = configSnapshots,
       _freecadPreferences = freecadPreferences,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final ProfilesRepository _repository;
  final AppPaths _paths;
  final BuildPlatform _platform;
  final FreeCadRuntime _runtime;
  final ConfigSnapshotService _configSnapshots;
  final FreeCadPreferences _freecadPreferences;
  final DateTime Function() _clock;

  final configSnapshots = signal<Map<String, List<ConfigSnapshot>>>({});

  final profiles = signal<List<Profile>>([]);
  final profilesLoaded = signal(false);
  final profilesError = signal<AppError?>(null);
  final buildsById = signal<Map<String, Build>>({});
  final addonCounts = signal<Map<String, int>>({});
  final installedAddons = signal<List<InstalledAddon>>([]);
  final packageCounts = signal<Map<String, int>>({});
  final profileSizes = signal<Map<String, int>>({});
  final runningProfiles = signal<Set<String>>({});
  final launchLogs = signal<Map<String, String>>({});
  final lastExitCodes = signal<Map<String, int>>({});

  late final recentProfiles = computed<List<Profile>>(() {
    final builds = buildsById.value;
    final recent = profiles.value
        .where(
          (profile) =>
              profile.lastUsedAt != null &&
              builds[profile.buildId]?.status == BuildStatus.installed,
        )
        .toList()
      ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
    return recent.take(5).toList(growable: false);
  });

  final Map<String, int> _runningCounts = {};

  StreamSubscription<List<Profile>>? _profilesSubscription;
  StreamSubscription<List<Build>>? _buildsSubscription;
  StreamSubscription<List<InstalledAddon>>? _addonsSubscription;
  StreamSubscription<List<PythonPackage>>? _packagesSubscription;

  void start() {
    _profilesSubscription ??= _repository.watchAll().listen(
      (value) {
        profiles.value = value;
        profilesLoaded.value = true;
        profilesError.value = null;
        unawaited(refreshSizes());
      },
      onError: (Object error) {
        profilesError.value = AppError.from(error, retryable: true);
      },
    );
    _buildsSubscription ??= _database.buildsDao.watchAll().listen(
      (builds) => buildsById.value = {for (final build in builds) build.id: build},
    );
    _addonsSubscription ??= _database.installedAddonsDao.watchAll().listen(
      (addons) {
        installedAddons.value = addons;
        addonCounts.value = _countByProfile(addons.map((addon) => addon.profileId));
      },
    );
    _packagesSubscription ??= _database.pythonPackagesDao.watchAll().listen(
      (packages) =>
          packageCounts.value = _countByProfile(packages.map((package) => package.profileId)),
    );
  }

  List<InstalledAddon> installedForProfile(String profileId) {
    return installedAddons.value
        .where((addon) => addon.profileId == profileId)
        .toList(growable: false);
  }

  Future<void> refreshSizes() async {
    final profiles = await _repository.getAll();
    final sizes = <String, int>{};
    for (final profile in profiles) {
      sizes[profile.id] = await directorySize(_paths.profilePaths(profile.id).root);
    }
    profileSizes.value = sizes;
  }

  Map<String, int> _countByProfile(Iterable<String> profileIds) {
    final counts = <String, int>{};
    for (final id in profileIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  bool isRunning(String profileId) => runningProfiles.value.contains(profileId);

  Future<List<Profile>> getAll() => _repository.getAll();

  Future<Profile?> getById(String id) => _repository.getById(id);

  Future<Result<Profile>> create({
    required String name,
    required String buildId,
    String? description,
  }) async {
    final result = await _repository.create(
      name: name,
      buildId: buildId,
      description: description,
    );
    if (result.isOk) {
      unawaited(refreshSizes());
    }
    return result;
  }

  Future<Result<Profile>> duplicate({
    required String profileId,
    required String name,
    bool copyPayload = false,
  }) async {
    final result = await _repository.duplicate(
      profileId: profileId,
      name: name,
      copyPayload: copyPayload,
    );
    if (result.isOk) {
      unawaited(refreshSizes());
    }
    return result;
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

  Future<Result<void>> delete(String profileId) async {
    final result = await _repository.delete(profileId);
    if (result.isOk) {
      unawaited(refreshSizes());
    }
    return result;
  }

  Future<Result<LaunchPlan>> planFor(String profileId) async {
    final resolved = await _resolveLaunch(profileId);
    if (resolved.isErr) {
      return Err(resolved.errorOrNull!);
    }
    return Ok(resolved.valueOrNull!.plan);
  }

  Future<LaunchResult> launch({
    required String profileId,
    List<String> userArguments = const [],
    bool quarantineConsent = false,
  }) async {
    final resolved = await _resolveLaunch(profileId, userArguments: userArguments);
    if (resolved.isErr) {
      return LaunchResult.failure(resolved.errorOrNull!);
    }
    final context = resolved.valueOrNull!;
    final profile = context.profile;
    final plan = context.plan;

    _freecadPreferences.ensureMacroPath(
      userCfgPath: _paths.profilePaths(profile.id).userCfg,
      macroPath: _paths.profilePaths(profile.id).macros,
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

  Future<Result<_LaunchContext>> _resolveLaunch(
    String profileId, {
    List<String> userArguments = const [],
  }) async {
    final profile = await _repository.getById(profileId);
    if (profile == null) {
      return Err(const AppError(message: 'Profile not found'));
    }

    final build = await _database.buildsDao.getById(profile.buildId);
    if (build == null) {
      return Err(const AppError(message: "This profile's build no longer exists"));
    }
    if (build.status != BuildStatus.installed) {
      return Err(
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
    return Ok(_LaunchContext(profile: profile, build: build, plan: plan));
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
      if (!exitCompleter.isCompleted) {
        exitCompleter.complete(code);
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
    final safeName = safePathSegment(profile.name);
    final stamp = _clock().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    return File(p.join(_paths.logsDir, 'launch-$safeName-$stamp.log'));
  }

  void refreshConfigSnapshots(String profileId) {
    configSnapshots.value = {
      ...configSnapshots.value,
      profileId: _configSnapshots.list(_paths.profilePaths(profileId).root),
    };
  }

  Future<Result<ConfigSnapshot?>> createConfigSnapshot(String profileId) async {
    try {
      final snapshot = await _configSnapshots.create(
        profileRoot: _paths.profilePaths(profileId).root,
        now: _clock(),
      );
      refreshConfigSnapshots(profileId);
      return Ok(snapshot);
    } on Object catch (failure) {
      return Err(AppError.from(failure, retryable: true));
    }
  }

  Future<Result<void>> restoreConfigSnapshot(
    String profileId,
    ConfigSnapshot snapshot,
  ) async {
    try {
      await _configSnapshots.restore(
        profileRoot: _paths.profilePaths(profileId).root,
        snapshot: snapshot,
      );
      refreshConfigSnapshots(profileId);
      return const Ok(null);
    } on Object catch (failure) {
      return Err(AppError.from(failure, retryable: true));
    }
  }

  Future<Result<void>> deleteConfigSnapshot(
    String profileId,
    ConfigSnapshot snapshot,
  ) async {
    try {
      await _configSnapshots.delete(snapshot);
      refreshConfigSnapshots(profileId);
      return const Ok(null);
    } on Object catch (failure) {
      return Err(AppError.from(failure, retryable: true));
    }
  }

  void dispose() {
    _profilesSubscription?.cancel();
    _profilesSubscription = null;
    _buildsSubscription?.cancel();
    _buildsSubscription = null;
    _addonsSubscription?.cancel();
    _addonsSubscription = null;
    _packagesSubscription?.cancel();
    _packagesSubscription = null;
  }
}

class _LaunchContext {
  const _LaunchContext({required this.profile, required this.build, required this.plan});

  final Profile profile;
  final Build build;
  final LaunchPlan plan;
}
