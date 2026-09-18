import 'dart:io';
import 'dart:convert';

import 'package:freecad_launcher/util/hashlib.dart';
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
  Success({required this.data});
}

class Failure<T> extends Result<T> {
  final String error;
  Failure({required this.error});
}

class Version {
  final String freecad;
  final String python;
  Version({required this.freecad, required this.python});

  @override
  String toString() {
    return "Version(freecad=${freecad}, python=${python})";
  }
}

abstract class AppService {
  final String kind;
  const AppService(this.kind);

  Future<Result<void>> launch(
    String target, {
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  });

  Future<Result<String>> call(
    String target, {
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  });

  Future<Result<List<dynamic>>> callMacro(
    String target, {
    File? macro,
    Future<File> Function(Directory)? macroBuilder,
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  }) async {
    var (Directory fcHome, Directory macroParent, int delete) = await switch ((
      freecadHome,
      macro,
    )) {
      // Prepare Env directories
      (null, null) => () async {
        Directory path = await mkTempFreecadDir();
        return (path, path, 1);
      }(),
      (null, File f) => () async {
        Directory path = await mkTempFreecadDir();
        return (path, f.parent, 1);
      }(),
      (String h, null) => () async {
        Directory path = await mkTempFreecadDir();
        return (Directory(h), path, 2);
      }(),
      (String h, File f) => () async {
        return (Directory(h), f.parent, 0);
      }(),
    };

    // Build macro
    final macroFile = await () async {
      if (macroBuilder != null) {
        return await macroBuilder(macroParent);
      }
      if (macro == null) {
        throw ArgumentError("Either macro or macroBuilder must be provided.");
      }
      return macro;
    }();

    print("${fcHome}, ${macroParent}, ${macroFile}");

    final freecadArgs = [...?args, "-c", "-M", macroParent.path, macroFile.path];

    print(freecadArgs);

    // Execute/Call freecad
    var result = await call(
      target,
      freecadHome: fcHome.path,
      env: env,
      args: freecadArgs,
      workingDirectory: macroParent.path,
    );

    // Env dirs cleanup
    switch (delete) {
      case 1:
        if (await fcHome.exists()) {
          await fcHome.delete(recursive: true);
        }
      case 2:
        if (await macroParent.exists()) {
          await macroParent.delete(recursive: true);
        }
      default:
      // Do Nothing
    }

    // Extract data
    switch (result) {
      case Success(data: var data):
        print(data);
        List<String> records = extractMacroOutput(data);
        print(records);
        return Success(data: records.map((str) => jsonDecode(str)).toList());
      case Failure(error: var err):
        return Failure(error: err);
    }
  }

  Future<Result<List<String>>> find({String? path});
  Future<Result<bool>> test(String target);
  Future<Result<String>> upgrade(String target);

  Future<Result<Version>> getVersion(String target) async {
    Future<File> macro(Directory d) async => await macroVersionCheck(d);
    var output = await callMacro(target, macroBuilder: macro);

    switch (output) {
      case Success(data: var data):
        {
          if (data.isNotEmpty) {
            var freecad = data[0]['freecad'] as List<dynamic>;
            var python = (data[0]['python'] as String).split(".");
            return Success(
              data: Version(
                freecad: "${freecad[0]}.${freecad[1]}",
                python: "${python[0]}.${python[1]}",
              ),
            );
          }
          return Failure(error: "Invalid FreeCAD Version");
        }
      case Failure(error: var err):
        {
          return Failure(error: err);
        }
    }
  }
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
        return Success(data: []);
      }

      final installedRefs = result.stdout
          .toString()
          .split('\n')
          .where((line) => line.contains(appId))
          .map((line) => line.trim().split(RegExp(r'\t+')).join('::'))
          .toList();

      return Success(data: installedRefs);
    } catch (e) {
      return Failure(error: e.toString());
    }
  }

  // @override
  // Future<Result<String>> getVersion(String target) async {
  //   final FlatpakTarget f = FlatpakTarget.fromString(target);
  //   try {
  //     final result = await Process.run("flatpak", [
  //       "list",
  //       "--app",
  //       "--${f.install}",
  //       "--columns=ref:f,version:f",
  //     ], runInShell: true);

  //     if (result.exitCode != 0) {
  //       return Failure(result.stderr.toString());
  //     }

  //     final version = result.stdout
  //         .toString()
  //         .split('\n')
  //         .where((line) => line.contains(f.ref))
  //         .map((line) => line.trim().split(RegExp(r'\t+'))[1])
  //         .firstOrNull;

  //     if (version == null) {
  //       return Failure("No Version found for ${f.ref}");
  //     }

  //     return Success(version);
  //   } catch (e) {
  //     return Failure(e.toString());
  //   }
  // }

  @override
  Future<Result<void>> launch(
    String target, {
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  }) async {
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

      return Success(data: null);
    } catch (e) {
      return Failure(error: '$e');
    }
  }

  @override
  Future<Result<String>> call(
    String target, {
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  }) async {
    try {
      final fTarget = FlatpakTarget.fromString(target);
      final workingDir = workingDirectory ?? (await Path.home()).str;
      final envExt = {...?env, "FREECAD_HOME": ?freecadHome};
      final passEnv = envExt.entries
          .map((e) => "--env=${e.key}=${e.value}")
          .toList(growable: false);

      final result = await Process.run(
        "flatpak",
        ['run', '--${fTarget.install}', ...passEnv, appId, ...?args],
        workingDirectory: workingDir,
        environment: {...Platform.environment, ...envExt},
      );

      if (result.exitCode == 0) {
        return Success(data: result.stdout.toString().trim());
      }

      return Failure(error: result.stderr.toString().trim());
    } catch (e) {
      return Failure(error: '$e');
    }
  }

  @override
  Future<Result<bool>> test(String target) {
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> upgrade(String target) {
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
        data: snaps
            .map((s) => "$appId.${s.name}")
            .where((name) => name == "$appId.$appId")
            .toList(),
      );
    } catch (e) {
      return Success(data: []);
    } finally {
      client.close();
    }
  }

  // @override
  // Future<Result<String>> getVersion(String target) async {
  //   final client = SnapdClient();
  //   try {
  //     final snap = await client.getSnap(appId);
  //     return Success(snap.version);
  //   } catch (e) {
  //     return Failure("No Snap found. $e");
  //   } finally {
  //     client.close();
  //   }
  // }

  @override
  Future<Result<void>> launch(
    String target, {
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  }) async {
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

      return Success(data: null);
    } catch (e) {
      return Failure(error: '$e');
    }
  }

  @override
  Future<Result<String>> call(
    String target, {
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  }) async {
    try {
      final workingDir = workingDirectory ?? (await Path.home()).str;
      final envExt = {...?env, "FREECAD_USER_HOME": ?freecadHome};

      final result = await Process.run(
        "snap",
        ['run', appId, ...?args],
        workingDirectory: workingDir,
        environment: {...Platform.environment, ...envExt},
      );

      if (result.exitCode == 0) {
        return Success(data: result.stdout.toString().trim());
      }

      return Failure(error: result.stderr.toString().trim());
    } catch (e) {
      return Failure(error: '$e');
    }
  }

  @override
  Future<Result<bool>> test(String target) {
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> upgrade(String target) {
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
    return Success(data: files);
  }

  // @override
  // Future<Result<String>> getVersion(String target) {
  //   // TODO: implement getVersion
  //   throw UnimplementedError();
  // }

  @override
  Future<Result<void>> launch(
    String target, {
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> call(
    String target, {
    String? freecadHome,
    Map<String, String>? env,
    List<String>? args,
    String? workingDirectory,
  }) {
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

AppService appServiceForKind(String kind) {
  return switch (kind) {
    'Flatpak' => FlatpakService(),
    'Snap' => SnapService(),
    _ => ExecutableService(kind),
  };
}

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

class Macro {
  static final String OUTPUT_TAG = "freecad-launcher:out";
}

Future<File> macroVersionCheck(Directory parent) async {
  final file = File(p.join(parent.path, 'FCL_Version.FCMacro'));
  await file.writeAsString(
    'import json, sys, platform, FreeCAD\n'
    'data = {"freecad": FreeCAD.Version(), "python": platform.python_version()}\n'
    'FreeCAD.Console.PrintMessage("[${Macro.OUTPUT_TAG}]" + json.dumps(data) + "[/${Macro.OUTPUT_TAG}]")\n'
    'sys.exit(0)\n',
  );
  return file;
}

Future<Directory> mkTempFreecadDir() async {
  final home = await Path.home();
  final dir = Directory(p.join(home.str, ".FCL", generateRandomHex()));
  await dir.create(recursive: true);
  return dir;
}

List<String> extractMacroOutput(String source) {
  RegExp regex = RegExp('\\[${Macro.OUTPUT_TAG}\\](.*?)\\[/${Macro.OUTPUT_TAG}\\]', dotAll: true);
  return regex.allMatches(source).map((match) => match.group(1)!).toList();
}
