// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:path/path.dart' as p;

class ConfigSnapshot {
  const ConfigSnapshot({
    required this.name,
    required this.directory,
    required this.createdAt,
    required this.files,
    required this.sizeBytes,
  });

  final String name;
  final String directory;
  final DateTime createdAt;
  final List<String> files;
  final int sizeBytes;
}

class ConfigSnapshotException implements Exception {
  const ConfigSnapshotException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ConfigSnapshotException: $message';
}

class ConfigSnapshotService {
  const ConfigSnapshotService({this.maxSnapshots = 10});

  static const List<String> configFiles = ['user.cfg', 'system.cfg'];

  final int maxSnapshots;

  Future<ConfigSnapshot?> create({required String profileRoot, DateTime? now}) async {
    final present = [
      for (final file in configFiles)
        if (File(p.join(profileRoot, file)).existsSync()) file,
    ];
    if (present.isEmpty) {
      return null;
    }
    final name = 'config-${_timestamp((now ?? DateTime.now()).toUtc())}';
    final directory = Directory(p.join(profileRoot, 'backups', name));
    try {
      directory.createSync(recursive: true);
      for (final file in present) {
        File(p.join(profileRoot, file)).copySync(p.join(directory.path, file));
      }
    } on Object catch (error) {
      throw ConfigSnapshotException('Could not create the config snapshot', cause: error);
    }
    await _prune(profileRoot);
    return _snapshot(directory);
  }

  List<ConfigSnapshot> list(String profileRoot) {
    final backups = Directory(p.join(profileRoot, 'backups'));
    if (!backups.existsSync()) {
      return [];
    }
    final snapshots = <ConfigSnapshot>[];
    for (final entity in backups.listSync()) {
      if (entity is Directory && p.basename(entity.path).startsWith('config-')) {
        snapshots.add(_snapshot(entity));
      }
    }
    snapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshots;
  }

  Future<void> restore({
    required String profileRoot,
    required ConfigSnapshot snapshot,
  }) async {
    try {
      for (final file in snapshot.files) {
        final source = File(p.join(snapshot.directory, file));
        if (source.existsSync()) {
          source.copySync(p.join(profileRoot, file));
        }
      }
    } on Object catch (error) {
      throw ConfigSnapshotException('Could not restore the config snapshot', cause: error);
    }
  }

  Future<void> delete(ConfigSnapshot snapshot) async {
    final directory = Directory(snapshot.directory);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }

  Future<void> _prune(String profileRoot) async {
    final snapshots = list(profileRoot);
    for (final old in snapshots.skip(maxSnapshots)) {
      await delete(old);
    }
  }

  ConfigSnapshot _snapshot(Directory directory) {
    final files = <String>[];
    var sizeBytes = 0;
    for (final entity in directory.listSync()) {
      if (entity is File && configFiles.contains(p.basename(entity.path))) {
        files.add(p.basename(entity.path));
        sizeBytes += entity.lengthSync();
      }
    }
    files.sort();
    final name = p.basename(directory.path);
    return ConfigSnapshot(
      name: name,
      directory: directory.path,
      createdAt: _createdAt(name, directory),
      files: files,
      sizeBytes: sizeBytes,
    );
  }

  DateTime _createdAt(String name, Directory directory) {
    final match = RegExp(
      r'^config-(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})-(\d{2})-(\d{3})Z$',
    ).firstMatch(name);
    if (match == null) {
      return directory.statSync().modified;
    }
    return DateTime.utc(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
      int.parse(match.group(7)!),
    );
  }

  String _timestamp(DateTime value) {
    String two(int part) => part.toString().padLeft(2, '0');
    String three(int part) => part.toString().padLeft(3, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}'
        'T${two(value.hour)}-${two(value.minute)}-${two(value.second)}'
        '-${three(value.millisecond)}Z';
  }
}
