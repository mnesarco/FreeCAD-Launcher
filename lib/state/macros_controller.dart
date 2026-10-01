// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/catalog/macro_catalog.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/domain/macros/macro_types.dart';
import 'package:freecad_launcher/platform/macro_icon_cache.dart';
import 'package:freecad_launcher/platform/macro_installer.dart';
import 'package:freecad_launcher/platform/macro_scanner.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:path/path.dart' as p;
import 'package:freecad_launcher/state/jobs_controller.dart';

class MacrosController {
  MacrosController({
    required AppDatabase database,
    required MacroCatalog catalog,
    required AppPaths paths,
    MacroInstaller installer = const MacroInstaller(),
    MacroScanner scanner = const MacroScanner(),
    MacroIconCache? iconCache,
    JobsController? jobs,
    DateTime Function()? clock,
  }) : _database = database,
       _catalog = catalog,
       _paths = paths,
       _installer = installer,
       _scanner = scanner,
       _iconCache = iconCache,
       _jobs = jobs,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final MacroCatalog _catalog;
  final AppPaths _paths;
  final MacroInstaller _installer;
  final MacroScanner _scanner;
  final MacroIconCache? _iconCache;
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
    unawaited(reconcileAll());
  }

  Future<void> reconcileAll() async {
    final profiles = await _database.profilesDao.getAll();
    for (final profile in profiles) {
      await reconcile(profile.id);
    }
  }

  Future<void> reconcile(String profileId) async {
    final scanned = await _scanner.scan(_paths.profilePaths(profileId).macros);
    final rows = await _database.macrosDao.getByProfile(profileId);
    for (final row in rows) {
      if (!scanned.any((macro) => macro.fileName == row.fileName)) {
        await _database.macrosDao.deleteByFileName(profileId, row.fileName);
      }
    }
    for (final macro in scanned) {
      Macro? existing;
      for (final row in rows) {
        if (row.fileName == macro.fileName) {
          existing = row;
          break;
        }
      }
      if (existing == null) {
        await _database.macrosDao.save(
          Macro(
            id: const Uuid().v4(),
            profileId: profileId,
            name: macro.name,
            fileName: macro.fileName,
            source: MacroSource.local,
            installedAt: macro.modifiedAt,
            updatedAt: macro.modifiedAt,
            sizeBytes: macro.sizeBytes,
          ),
        );
      } else if (existing.sizeBytes != macro.sizeBytes ||
          existing.updatedAt != macro.modifiedAt) {
        await _database.macrosDao.save(
          existing.copyWith(
            sizeBytes: Value(macro.sizeBytes),
            updatedAt: macro.modifiedAt,
          ),
        );
      }
    }
  }

  Future<Result<void>> delete({
    required String profileId,
    required String fileName,
  }) async {
    final row = await _database.macrosDao.getByFileName(profileId, fileName);
    if (row == null) {
      return const Err(AppError(message: 'Macro is not installed in this profile'));
    }
    try {
      final file = File(p.join(_paths.profilePaths(profileId).macros, fileName));
      if (file.existsSync()) {
        file.deleteSync();
      }
      await _database.macrosDao.deleteByFileName(profileId, fileName);
      return const Ok(null);
    } on Object catch (failure) {
      return Err(AppError.from(failure, retryable: true));
    }
  }

  Future<void> load({bool forceRefresh = false}) async {
    final stopwatch = Stopwatch()..start();
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
      if (result.freshness == CatalogFreshness.refreshed) {
        _pruneIconCache(result.macros);
      }
      appLogger.info(
        'macro catalog: ${result.macros.length} macros in '
        '${stopwatch.elapsedMilliseconds} ms (${result.freshness.name})',
        tag: 'perf',
      );
    } on Object catch (failure) {
      error.value = failure;
    } finally {
      loading.value = false;
    }
  }

  void _pruneIconCache(List<MacroCatalogEntry> entries) {
    final cache = _iconCache;
    if (cache == null) {
      return;
    }
    final keep = <String>[];
    for (final entry in entries) {
      final key = MacroIconCache.keyFor(entry.iconBase64);
      if (key != null) {
        keep.add(key);
      }
    }
    cache.prune(keep);
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
        macroDirectory: _paths.profilePaths(profileId).macros,
      );
      final existing = await _database.macrosDao.getByFileName(profileId, installed.fileName);
      final now = _clock();
      var sizeBytes = 0;
      for (final filePath in installed.files) {
        final file = File(filePath);
        if (file.existsSync()) {
          sizeBytes += file.lengthSync();
        }
      }
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
          license: entry.hasLicense ? entry.license : null,
          sizeBytes: sizeBytes,
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
