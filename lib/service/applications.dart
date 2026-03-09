import 'dart:io';

import 'package:freecad_launcher/util/path.dart';
import 'package:snapd/snapd.dart';
import 'package:path/path.dart' as p;

sealed class Result<T> {
  R fold<R>({required R Function(T data) onSuccess, required R Function(String error) onFailure}) =>
      switch (this) {
        Success<T> s => onSuccess(s.data),
        Failure<T> f => onFailure(f.error),
      };
}

class Success<T> extends Result<T> {
  final T data;
  Success(this.data);
}

class Failure<T> extends Result<T> {
  final String error;
  Failure(this.error);
}

abstract class AppService {
  final String kind;
  const AppService(this.kind);

  Future<Result<void>> launch(
    String target, [
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  ]);

  Future<Result<List<String>>> find({String? path});
  Future<Result<bool>> test(String target);
  Future<Result<String>> getVersion(String target);
  Future<Result<String>> upgrade(String target);
}

class FlatpakTarget {
  final String ref;
  final String install;
  final String? version;
  FlatpakTarget(this.ref, this.install, this.version);

  static FlatpakTarget fromString(String target) {
    List<String> parts = target.split('::');
    return FlatpakTarget(
      parts[0],
      parts.length > 1 ? parts[1] : 'system',
      parts.length > 2 ? parts[2] : null,
    );
  }

  @override
  String toString() {
    return version == null ? "$ref::$install" : "$ref::$install::$version";
  }
}

class FlatpakService extends AppService {
  static const String appId = "org.freecad.FreeCAD";
  FlatpakService() : super("Flatpak");

  @override
  Future<Result<List<String>>> find({String? path}) async {
    try {
      final result = await Process.run("flatpak", [
        "list",
        "--app",
        "--columns=ref:f,install:f,version:f",
      ], runInShell: true);

      if (result.exitCode != 0) {
        return Success([]);
      }

      final installedRefs = result.stdout
          .toString()
          .split('\n')
          .where((line) => line.contains(appId))
          .map((line) => line.trim().split(RegExp(r'\t+')).join('::'))
          .toList();

      return Success(installedRefs);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> getVersion(String target) async {
    final FlatpakTarget f = FlatpakTarget.fromString(target);
    try {
      final result = await Process.run("flatpak", [
        "list",
        "--app",
        "--${f.install}",
        "--columns=ref:f,version:f",
      ], runInShell: true);

      if (result.exitCode != 0) {
        return Failure(result.stderr.toString());
      }

      final version = result.stdout
          .toString()
          .split('\n')
          .where((line) => line.contains(f.ref))
          .map((line) => line.trim().split(RegExp(r'\t+'))[1])
          .firstOrNull;

      if (version == null) {
        return Failure("No Version found for ${f.ref}");
      }

      return Success(version);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> launch(
    String target, [
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  ]) async {
    try {
      final fTarget = FlatpakTarget.fromString(target);
      final workingDir = workingDirectory ?? (await Path.home()).str;
      final envExt = {...?env, "FREECAD_HOME": ?freecadHome};
      final passEnv = envExt.entries
          .map((e) => "--env=${e.key}=${e.value}")
          .toList(growable: false);

      await Process.start(
        "flatpak",
        ['run', '--${fTarget.install}', ...passEnv, appId, ...?args],
        workingDirectory: workingDir,
        environment: {...Platform.environment, ...envExt},
        mode: ProcessStartMode.detached,
      );

      return Success(null);
    } catch (e) {
      return Failure('$e');
    }
  }

  @override
  Future<Result<bool>> test(String target) {
    // TODO: implement test
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> upgrade(String target) {
    // TODO: implement upgrade
    throw UnimplementedError();
  }
}

class SnapService extends AppService {
  static const String appId = "freecad";
  SnapService() : super("Snap");

  @override
  Future<Result<List<String>>> find({String? path}) async {
    final client = SnapdClient();
    try {
      final snaps = await client.getApps(names: [appId]);
      return Success(
        snaps.map((s) => "$appId.${s.name}").where((name) => name == "$appId.$appId").toList(),
      );
    } catch (e) {
      return Success([]);
    } finally {
      client.close();
    }
  }

  @override
  Future<Result<String>> getVersion(String target) async {
    final client = SnapdClient();
    try {
      final snap = await client.getSnap(appId);
      return Success(snap.version);
    } catch (e) {
      return Failure("No Snap found. $e");
    } finally {
      client.close();
    }
  }

  @override
  Future<Result<void>> launch(
    String target, [
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  ]) async {
    try {
      final workingDir = workingDirectory ?? (await Path.home()).str;
      final envExt = {...?env, "FREECAD_USER_HOME": ?freecadHome};

      await Process.start(
        "snap",
        ['run', appId, ...?args],
        workingDirectory: workingDir,
        environment: {...Platform.environment, ...envExt},
        mode: ProcessStartMode.detached,
      );

      return Success(null);
    } catch (e) {
      return Failure('$e');
    }
  }

  @override
  Future<Result<bool>> test(String target) {
    // TODO: implement test
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> upgrade(String target) {
    // TODO: implement upgrade
    throw UnimplementedError();
  }
}

class ExecutableService extends AppService {
  ExecutableService([super.kind = "Executable"]);

  @override
  Future<Result<List<String>>> find({String? path}) async {
    final dir = Directory(path ?? (await Path.home()).str);
    final List<String> files = [];
    await for (final file in dir.list(recursive: false)) {
      if (file is! File) continue;
      try {
        if (!await isExecutable(file)) continue;
        if (!file.uri.pathSegments.last.toLowerCase().contains("freecad")) continue;
        files.add(file.absolute.path);
      } catch (e) {
        // pass, IO errors ignored here intentionally.
      }
    }
    return Success(files);
  }

  @override
  Future<Result<String>> getVersion(String target) {
    // TODO: implement getVersion
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> launch(
    String target, [
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  ]) {
    // TODO: implement launch
    throw UnimplementedError();
  }

  @override
  Future<Result<bool>> test(String target) {
    // TODO: implement test
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> upgrade(String target) {
    // TODO: implement upgrade
    throw UnimplementedError();
  }
}

/*
class SystemAppService extends AppService {}


class AppImageService extends AppService {}

*/

Future<bool> _isExecutable(File file) async {
  final stat = await file.stat();
  // mode bits: owner(rwx) group(rwx) others(rwx)
  // 0x49 = 0b001001001 = execute bit for owner, group, and others
  return (stat.mode & 0x49) != 0;
}

Future<bool> _isWin32Executable(File file) async {
  final ext = file.path.split('.').last.toLowerCase();
  return ext == "exe";
}

final isExecutable = Platform.isWindows ? _isWin32Executable : _isExecutable;

Future<String?> which(String command) async {
  final path = Platform.environment['PATH'] ?? '';
  final separator = Platform.isWindows ? ';' : ':';
  final extension = Platform.isWindows ? '.exe' : '';

  for (final dir in path.split(separator)) {
    final file = File('$dir${Platform.pathSeparator}$command$extension');
    if (file.existsSync() && await isExecutable(file)) {
      return file.path;
    }
  }
  return null;
}

Future<String> macroVersionCheck() async {
  final tmpDir = Directory.systemTemp.path;
  final file = File(p.join(tmpDir, 'FCL_Version.FCMacro'));
  if (!await file.exists()) {
    file.writeAsString(
      'import json, sys, FreeCAD\n'
      'print("[freecad-launcher]", json.dumps(FreeCAD.Version()), "[/freecad-launcher]")\n'
      'sys.exit(0)");\n',
    );
  }
  return file.path;
}
