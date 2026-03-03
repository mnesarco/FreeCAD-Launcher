import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

extension PathOps on String {
  String operator /(String str) {
    return p.join(this, str);
  }
}

class Path {
  final String str;
  String? _resolved;
  FileSystemEntityType? _type;

  Path(this.str);

  @override
  String toString() {
    return str;
  }

  Future<FileSystemEntityType> type() async {
    _type ??= await FileSystemEntity.type(str);
    return _type!;
  }

  Future<bool> exists() async {
    return (await type()) != FileSystemEntityType.notFound;
  }

  Future<bool> isFile() async {
    return await resolveSymbolicLinks() && await type() == FileSystemEntityType.file;
  }

  Future<bool> isDir() async {
    return await resolveSymbolicLinks() && await type() == FileSystemEntityType.directory;
  }

  Future<bool> resolveSymbolicLinks() async {
    var type = await this.type();
    if (type == FileSystemEntityType.link) {
      try {
        _resolved ??= await Link(str).resolveSymbolicLinks();
        _type = await FileSystemEntity.type(_resolved!);
      } on FileSystemException {
        return false;
      }
    }
    return true;
  }

  Path operator /(dynamic other) {
    if (other is String) {
      return Path(p.join(str, other));
    }
    if (other is Path) {
      return Path(p.join(str, other.toString()));
    }
    throw ArgumentError("Invalid type, only String and Path are allowed for / operator here.");
  }

  static Future<Path> home() async {
    Future<Path> docs() async => Path((await getApplicationDocumentsDirectory()).path);
    String? envVar;

    if (Platform.isWindows) {
      envVar = 'USERPROFILE';
    } else if (Platform.isLinux || Platform.isMacOS) {
      envVar = 'HOME';
    }

    if (envVar == null) {
      return await docs();
    }

    var envValue = Platform.environment[envVar];
    if (envValue == null) {
      return await docs();
    }

    return Path(envValue);
  }

  Path parent() {
    return Path(p.dirname(str));
  }
}
