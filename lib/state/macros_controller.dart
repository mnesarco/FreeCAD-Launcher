import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/domain/macros/macro_types.dart';
import 'package:freecad_launcher/platform/macro_installer.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/jobs_controller.dart';

class MacrosController {
  MacrosController({
    required AppDatabase database,
    required MacroCatalog catalog,
    required AppPaths paths,
    MacroInstaller installer = const MacroInstaller(),
    JobsController? jobs,
    DateTime Function()? clock,
  }) : _database = database,
       _catalog = catalog,
       _paths = paths,
       _installer = installer,
       _jobs = jobs,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final MacroCatalog _catalog;
  final AppPaths _paths;
  final MacroInstaller _installer;
  final JobsController? _jobs;
  final DateTime Function() _clock;

  StreamSubscription<List<Macro>>? _macrosSubscription;

  final loading = signal(false);
  final loaded = signal(false);
  final error = signal<Object?>(null);
  final freshness = signal<CatalogFreshness>(CatalogFreshness.fresh);
  final macros = signal<List<MacroCatalogEntry>>([]);
  final query = signal('');
  final selectedProfileId = signal<String?>(null);
  final installing = signal<Set<String>>({});
  final installErrors = signal<Map<String, String>>({});
  final installedMacros = signal<List<Macro>>([]);

  late final filtered = computed<List<MacroCatalogEntry>>(() {
    final text = query.value.trim().toLowerCase();
    if (text.isEmpty) {
      return macros.value;
    }
    return [
      for (final macro in macros.value)
        if (macro.name.toLowerCase().contains(text) ||
            macro.comment.toLowerCase().contains(text) ||
            macro.description.toLowerCase().contains(text) ||
            macro.author.toLowerCase().contains(text))
          macro,
    ];
  });

  void start() {
    _macrosSubscription ??= _database.macrosDao.watchAll().listen(
      (rows) => installedMacros.value = rows,
      onError: (Object failure) => error.value = failure,
    );
    if (!loaded.value && !loading.value) {
      unawaited(load());
    }
  }

  Future<void> load({bool forceRefresh = false}) async {
    loading.value = true;
    error.value = null;
    try {
      final result = await _catalog.load(forceRefresh: forceRefresh);
      macros.value = result.macros;
      freshness.value = result.freshness;
      loaded.value = true;
      if (result.isStale) {
        error.value = result.error;
      }
    } on Object catch (failure) {
      error.value = failure;
    } finally {
      loading.value = false;
    }
  }

  MacroCatalogEntry? byName(String name) {
    for (final macro in macros.value) {
      if (macro.name == name) {
        return macro;
      }
    }
    return null;
  }

  bool isInstalled(String profileId, MacroCatalogEntry entry) {
    return installedMacros.value.any(
      (row) => row.profileId == profileId && row.fileName == entry.fileName,
    );
  }

  Future<Result<void>> install({required String name, required String profileId}) async {
    final entry = byName(name);
    if (entry == null) {
      return const Err(AppError(message: 'Macro not found in the catalog'));
    }
    final profile = await _database.profilesDao.getById(profileId);
    if (profile == null) {
      return const Err(AppError(message: 'Profile not found'));
    }
    final jobs = _jobs;
    if (jobs == null) {
      return _installLocked(entry, profileId, null);
    }
    final result = await jobs.run<Result<void>>(
      kind: JobKind.install,
      label: 'Install macro ${entry.name}',
      profileId: profileId,
      onRetry: () async {
        await install(name: name, profileId: profileId);
      },
      task: (context) => _installLocked(entry, profileId, context),
    );
    return result ?? const Err(AppError(message: 'Install cancelled'));
  }

  Future<Result<void>> _installLocked(
    MacroCatalogEntry entry,
    String profileId,
    JobContext? context,
  ) async {
    installing.value = {...installing.value, entry.name};
    installErrors.value = {...installErrors.value}..remove(entry.name);
    try {
      context?.report(detail: 'Installing macro');
      final installed = await _installer.install(
        macro: entry,
        macroDirectory: _paths.profilePaths(profileId).root,
      );
      final existing = await _database.macrosDao.getByFileName(profileId, installed.fileName);
      final now = _clock();
      await _database.macrosDao.save(
        Macro(
          id: existing?.id ?? const Uuid().v4(),
          profileId: profileId,
          name: entry.name,
          fileName: installed.fileName,
          source: MacroSource.catalog,
          installedAt: existing?.installedAt ?? now,
          updatedAt: now,
          catalogCommit: existing?.catalogCommit,
        ),
      );
      return const Ok(null);
    } on Object catch (failure) {
      final appError = failure is AppError ? failure : AppError.from(failure, retryable: true);
      installErrors.value = {...installErrors.value, entry.name: appError.toString()};
      context?.fail(appError.message);
      return Err(appError);
    } finally {
      installing.value = {...installing.value}..remove(entry.name);
    }
  }

  void dispose() {
    _macrosSubscription?.cancel();
    _macrosSubscription = null;
  }
}
