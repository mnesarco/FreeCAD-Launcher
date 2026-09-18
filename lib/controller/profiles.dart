import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:freecad_launcher/service/applications.dart';
import 'package:freecad_launcher/service/database.dart';
import 'package:freecad_launcher/util/path.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

class ProfileController {
  final Database db;

  final searchFilter = signal('');

  late final items = streamSignal(() {
    return db.watchProfiles(searchFilter.value);
  });

  late final apps = streamSignal(() {
    return db.watchApps("");
  });

  ProfileController(this.db);

  void add(String name, String args, int? appId, String freecadVersion, String pythonVersion) {
    db.addProfile(
      ProfilesCompanion.insert(
        name: name,
        args: args,
        freecadVersion: freecadVersion,
        pythonVersion: pythonVersion,
        appId: Value(appId),
      ),
    );
  }

  Future<Version?> resolveFreeCADVersion(App app) async {
    final service = appServiceForKind(app.kind);
    final result = await service.getVersion(app.command);
    return result.fold(onSuccess: (version) => version, onFailure: (err) => null);
  }
}

enum AddonDeployResult { installed, upgraded, downgraded, removed, ignored, error }

extension ProfileExt on Profile {
  Future<Path> get path async => await Path.support() / "profiles" / "profile$id";
  Future<Path> get cwd async => await path;
}

extension DownloadedAddonExt on DownloadedAddon {
  Future<Path> get path async => await Path.support() / "downloads" / downloadedName;
}

class DeployException implements Exception {
  final Profile profile;
  final DownloadedAddon addon;
  final String message;
  DeployException({required this.profile, required this.addon, required this.message});

  @override
  String toString() {
    return message;
  }
}

class ProfileDirectoryController {
  Future<Path> getDirectory(Profile profile, [List<String>? children]) async {
    final path = await profile.path / children;
    final dir = Directory(path.str);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  Future<AddonDeployResult> deploy(Profile profile, DownloadedAddon addon) async {
    final src = await addon.path;
    if (!await src.exists()) {
      throw DeployException(
        profile: profile,
        addon: addon,
        message: 'Source download not found: $src',
      );
    }

    Path mod;
    Path deploy;

    try {
      mod = await getDirectory(profile, ['Mod']);
      deploy = await getDirectory(profile, ['__deploy']);
    } catch (ex) {
      throw DeployException(
        profile: profile,
        addon: addon,
        message: 'Failed to create directories',
      );
    }

    final uuid = Uuid();
    final target = mod / addon.name;
    final backup = deploy / uuid.v4();
    final tmp = deploy / uuid.v4();

    if (!await _unzip(src, tmp)) {
      throw DeployException(profile: profile, addon: addon, message: 'Failed to unzip: $src');
    }

    final replace = await target.exists();

    if (replace) {
      try {
        Directory(target.str).rename(backup.str);
      } catch (ex) {
        throw DeployException(
          profile: profile,
          addon: addon,
          message: 'Failed to create backup of: $target',
        );
      }
    }

    final tmpList = await tmp
        .asDir()
        .list(followLinks: false, recursive: false)
        .where((e) => e is Directory)
        .take(2)
        .toList();

    final unwrap = tmpList.length == 1 ? tmpList.first : tmp.asDir();

    try {
      await unwrap.rename(target.str);
    } catch (ex) {
      if (replace) {
        Directory(backup.str).rename(target.str);
      }
      if (await tmp.exists()) {
        Directory(tmp.str).delete(recursive: true);
      }
      throw DeployException(profile: profile, addon: addon, message: 'Failed to deploy: $target');
    }

    if (await backup.exists()) {
      await Directory(backup.str).delete(recursive: true);
    }

    if (await tmp.exists()) {
      await Directory(tmp.str).delete(recursive: true);
    }

    final manifest = deploy / '${addon.name}.json';
    await manifest.asFile().writeAsString(jsonEncode(addon.toJson()));

    return AddonDeployResult.installed;
  }

  Future<bool> _unzip(Path src, Path target) async {
    final input = InputFileStream(src.str);
    try {
      final zip = ZipDecoder().decodeStream(input);
      await extractArchiveToDisk(zip, target.str);
      return true;
    } catch (ex) {
      return false;
    } finally {
      await input.close();
    }
  }
}
