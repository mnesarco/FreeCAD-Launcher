// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/domain/python/requirements_parser.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/pip_runner.dart';
import 'package:freecad_launcher/platform/python_env.dart';
import 'package:freecad_launcher/platform/python_uninstaller.dart';
import 'package:freecad_launcher/state/jobs_controller.dart';

class PythonController {
  PythonController({
    required AppDatabase database,
    required AppPaths paths,
    required PipRunner pipRunner,
    required PythonEnvResolver pythonResolver,
    PythonUninstaller uninstaller = const PythonUninstaller(),
    JobsController? jobs,
    DateTime Function()? clock,
  }) : _database = database,
       _paths = paths,
       _pipRunner = pipRunner,
       _pythonResolver = pythonResolver,
       _uninstaller = uninstaller,
       _jobs = jobs,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final AppPaths _paths;
  final PipRunner _pipRunner;
  final PythonEnvResolver _pythonResolver;
  final PythonUninstaller _uninstaller;
  final JobsController? _jobs;
  final DateTime Function() _clock;

  final packages = signal<List<PythonPackage>>([]);
  final installing = signal<Set<String>>({});
  final uninstalling = signal<Set<String>>({});
  final errors = signal<Map<String, AppError>>({});

  StreamSubscription<List<PythonPackage>>? _subscription;

  void start() {
    _subscription ??= _database.pythonPackagesDao.watchAll().listen(
      (rows) => packages.value = rows,
    );
  }

  List<PythonPackage> forProfile(String profileId) {
    return packages.value
        .where((package) => package.profileId == profileId)
        .toList(growable: false);
  }

  Future<Result<void>> install({
    required String profileId,
    required String specText,
    String source = 'manual',
  }) async {
    final jobs = _jobs;
    if (jobs == null) {
      return _installInternal(profileId: profileId, specText: specText, source: source);
    }
    final profile = await _database.profilesDao.getById(profileId);
    final result = await jobs.run<Result<void>>(
      kind: JobKind.pip,
      label: 'Install packages (${profile?.name ?? profileId})',
      profileId: profileId,
      onRetry: () async {
        await install(profileId: profileId, specText: specText, source: source);
      },
      task: (context) => _installInternal(
        profileId: profileId,
        specText: specText,
        source: source,
        context: context,
      ),
    );
    return result ?? const Err(AppError(message: 'Install cancelled'));
  }

  Future<Result<void>> _installInternal({
    required String profileId,
    required String specText,
    String source = 'manual',
    JobContext? context,
  }) async {
    final requirements = parseRequirements(specText)
        .where((requirement) => requirement.valid)
        .toList();
    if (requirements.isEmpty) {
      return const Err(AppError(message: 'Enter at least one package'));
    }

    final profile = await _database.profilesDao.getById(profileId);
    if (profile == null) {
      return const Err(AppError(message: 'Profile not found'));
    }
    final build = await _database.buildsDao.getById(profile.buildId);
    if (build == null) {
      return const Err(AppError(message: 'The profile build no longer exists'));
    }

    installing.value = {...installing.value, profileId};
    errors.value = {...errors.value}..remove(profileId);
    try {
      final interpreter = await _pythonResolver.resolve(
        kind: build.kind,
        buildDirectory: _paths.buildDir(build.id),
        executablePath: build.localPath,
        storedPythonPath: build.pythonPath,
      );
      if (interpreter == null) {
        throw const PythonUninstallException(
          'No Python interpreter found for this build',
        );
      }
      final targetDirectory = _targetDirectory(profile);
      context?.report(detail: 'Running pip');
      final result = await _pipRunner.install(
        pythonPath: interpreter,
        targetDirectory: targetDirectory,
        packages: requirements.map(requirementSpec).toList(),
        label: _safeLabel(profile.name),
      );
      context?.setLogPath(result.logPath);
      if (!result.isSuccess) {
        throw PythonUninstallException('pip failed: ${result.outputTail}');
      }
      for (final requirement in requirements) {
        await _database.pythonPackagesDao.save(
          PythonPackage(
            id: const Uuid().v4(),
            profileId: profile.id,
            name: requirement.name,
            targetDir: targetDirectory,
            source: source,
            installedAt: _clock(),
          ),
        );
      }
      return const Ok(null);
    } on Object catch (error) {
      final appError = error is AppError ? error : AppError.from(error, retryable: true);
      errors.value = {...errors.value, profileId: appError};
      context?.fail(appError.message);
      return Err(appError);
    } finally {
      installing.value = {...installing.value}..remove(profileId);
    }
  }

  Future<Result<void>> uninstall({
    required String profileId,
    required String packageName,
  }) async {
    PythonPackage? package;
    for (final candidate in forProfile(profileId)) {
      if (candidate.name.toLowerCase() == packageName.toLowerCase()) {
        package = candidate;
        break;
      }
    }
    if (package == null) {
      return const Err(AppError(message: 'Package not found in this profile'));
    }

    uninstalling.value = {...uninstalling.value, profileId};
    errors.value = {...errors.value}..remove(profileId);
    try {
      await _uninstaller.uninstall(
        targetDirectory: package.targetDir,
        packageName: package.name,
      );
      await _database.pythonPackagesDao.deletePackage(profileId, package.name);
      return const Ok(null);
    } on Object catch (error) {
      final appError = error is AppError ? error : AppError.from(error, retryable: true);
      errors.value = {...errors.value, profileId: appError};
      return Err(appError);
    } finally {
      uninstalling.value = {...uninstalling.value}..remove(profileId);
    }
  }

  String _targetDirectory(Profile profile) {
    return p.join(
      _paths.profilePaths(profile.id).additionalPythonPackages,
      'py${profile.pythonVersion.replaceAll('.', '')}',
    );
  }

  String _safeLabel(String name) {
    return name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
