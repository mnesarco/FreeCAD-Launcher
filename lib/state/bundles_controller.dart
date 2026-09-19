import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/bundles/bundle_rules.dart';

class BundlesController {
  BundlesController({required AppDatabase database, DateTime Function()? clock})
    : _database = database,
      _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _clock;

  StreamSubscription<List<Bundle>>? _bundlesSubscription;
  StreamSubscription<List<BundleItem>>? _itemsSubscription;

  final bundles = signal<List<Bundle>>([]);
  final items = signal<List<BundleItem>>([]);
  final loading = signal(false);
  final error = signal<Object?>(null);

  void start() {
    if (_bundlesSubscription != null) {
      return;
    }
    loading.value = true;
    _bundlesSubscription = _database.bundlesDao.watchAll().listen(
      (rows) {
        bundles.value = rows;
        loading.value = false;
      },
      onError: (Object failure) {
        error.value = failure;
        loading.value = false;
      },
    );
    _itemsSubscription = _database.bundlesDao.watchAllItems().listen(
      (rows) => items.value = rows,
      onError: (Object failure) => error.value = failure,
    );
  }

  Bundle? byId(String id) {
    for (final bundle in bundles.value) {
      if (bundle.id == id) {
        return bundle;
      }
    }
    return null;
  }

  List<BundleItem> itemsFor(String bundleId) => [
    for (final item in items.value)
      if (item.bundleId == bundleId) item,
  ];

  BundleItem? itemFor(String bundleId, String addonId) {
    for (final item in items.value) {
      if (item.bundleId == bundleId && item.addonId == addonId) {
        return item;
      }
    }
    return null;
  }

  Future<BundleNameIssue?> checkName(String name, {String? currentBundleId}) async {
    final structural = validateBundleName(name, existingNames: const []);
    if (structural != null) {
      return structural;
    }
    final lower = normalizeBundleName(name).toLowerCase();
    final existing = await _database.bundlesDao.getAll();
    final clash = existing.any(
      (bundle) => bundle.id != currentBundleId && bundle.name.trim().toLowerCase() == lower,
    );
    return clash ? BundleNameIssue.duplicate : null;
  }

  String nameIssueMessage(BundleNameIssue issue) {
    return switch (issue) {
      BundleNameIssue.empty => 'Enter a name',
      BundleNameIssue.tooLong => 'Name is too long (max $maxBundleNameLength characters)',
      BundleNameIssue.controlCharacters => 'Name contains control characters',
      BundleNameIssue.duplicate => 'A collection with this name already exists',
    };
  }

  Future<Result<Bundle>> create({
    required String name,
    String? description,
    List<BundleItem> Function(String bundleId)? initialItems,
  }) async {
    final issue = await checkName(name);
    if (issue != null) {
      return Err(AppError(message: nameIssueMessage(issue)));
    }
    final now = _clock();
    final bundle = Bundle(
      id: const Uuid().v4(),
      name: normalizeBundleName(name),
      description: _cleanDescription(description),
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _database.transaction(() async {
        await _database.bundlesDao.save(bundle);
        final items = initialItems?.call(bundle.id) ?? const <BundleItem>[];
        if (items.isNotEmpty) {
          await _database.bundlesDao.replaceItems(bundle.id, items);
        }
      });
      return Ok(bundle);
    } on Object catch (failure) {
      return Err(AppError.from(failure, retryable: true));
    }
  }

  Future<Result<Bundle>> createFromProfile({
    required String profileId,
    required String name,
    String? description,
  }) async {
    final installed = await _database.installedAddonsDao.getByProfile(profileId);
    return create(
      name: name,
      description: description,
      initialItems: (bundleId) => [
        for (final row in installed)
          BundleItem(bundleId: bundleId, addonId: row.addonId, gitRef: row.gitRef),
      ],
    );
  }

  Future<Result<Bundle>> update({
    required String bundleId,
    required String name,
    String? description,
  }) async {
    final bundle = byId(bundleId);
    if (bundle == null) {
      return const Err(AppError(message: 'Collection not found'));
    }
    final issue = await checkName(name, currentBundleId: bundleId);
    if (issue != null) {
      return Err(AppError(message: nameIssueMessage(issue)));
    }
    final updated = Bundle(
      id: bundle.id,
      name: normalizeBundleName(name),
      description: _cleanDescription(description),
      createdAt: bundle.createdAt,
      updatedAt: _clock(),
    );
    try {
      await _database.bundlesDao.save(updated);
      return Ok(updated);
    } on Object catch (failure) {
      return Err(AppError.from(failure, retryable: true));
    }
  }

  Future<Result<void>> delete(String bundleId) async {
    try {
      final deleted = await _database.bundlesDao.deleteById(bundleId);
      if (deleted == 0) {
        return const Err(AppError(message: 'Collection not found'));
      }
      return const Ok(null);
    } on Object catch (failure) {
      return Err(AppError.from(failure, retryable: true));
    }
  }

  Future<Result<void>> addItem({
    required String bundleId,
    required String addonId,
    String? gitRef,
  }) async {
    if (byId(bundleId) == null) {
      return const Err(AppError(message: 'Collection not found'));
    }
    if (addonId.trim().isEmpty) {
      return const Err(AppError(message: 'Select an addon'));
    }
    try {
      await _database.bundlesDao.addItem(
        BundleItem(bundleId: bundleId, addonId: addonId, gitRef: gitRef),
      );
      return const Ok(null);
    } on Object catch (failure) {
      return Err(AppError.from(failure, retryable: true));
    }
  }

  Future<Result<void>> removeItem({
    required String bundleId,
    required String addonId,
  }) async {
    try {
      final deleted = await _database.bundlesDao.removeItem(bundleId, addonId);
      if (deleted == 0) {
        return const Err(AppError(message: 'Addon is not part of this collection'));
      }
      return const Ok(null);
    } on Object catch (failure) {
      return Err(AppError.from(failure, retryable: true));
    }
  }

  Future<Result<void>> setItemBranch({
    required String bundleId,
    required String addonId,
    String? gitRef,
  }) {
    return addItem(bundleId: bundleId, addonId: addonId, gitRef: gitRef);
  }

  String? _cleanDescription(String? description) {
    final trimmed = description?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  void dispose() {
    _bundlesSubscription?.cancel();
    _itemsSubscription?.cancel();
    _bundlesSubscription = null;
    _itemsSubscription = null;
  }
}
