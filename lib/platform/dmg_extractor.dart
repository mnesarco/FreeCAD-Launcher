import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/process.dart';

abstract interface class DmgExtractor {
  Future<String> extractApp(String dmgPath, String destination);
}

class ProcessDmgExtractor implements DmgExtractor {
  ProcessDmgExtractor({
    required ProcessRunner processRunner,
    this.appName = 'FreeCAD.app',
    String Function()? mountPointFactory,
  }) : _processRunner = processRunner,
       _mountPointFactory =
           mountPointFactory ??
           (() => p.join(Directory.systemTemp.path, 'fcl-dmg-${DateTime.now().microsecondsSinceEpoch}'));

  final ProcessRunner _processRunner;
  final String appName;
  final String Function() _mountPointFactory;

  @override
  Future<String> extractApp(String dmgPath, String destination) async {
    final mountPoint = _mountPointFactory();
    await Directory(mountPoint).create(recursive: true);

    try {
      await _runOrThrow(
        ['hdiutil', 'attach', '-nobrowse', '-readonly', '-mountpoint', mountPoint, dmgPath],
        'hdiutil attach',
      );

      final source = p.join(mountPoint, appName);
      if (!Directory(source).existsSync()) {
        throw ArchiveExtractionException('$appName not found inside $dmgPath');
      }

      final target = p.join(destination, appName);
      await _runOrThrow(['ditto', source, target], 'ditto');
      return target;
    } finally {
      await _detach(mountPoint);
    }
  }

  Future<void> _detach(String mountPoint) async {
    final detached = await _processRunner.run(
      ProcessSpec(executable: 'hdiutil', arguments: ['detach', mountPoint]),
    );
    if (detached.isSuccess) {
      return;
    }
    final forced = await _processRunner.run(
      ProcessSpec(executable: 'hdiutil', arguments: ['detach', '-force', mountPoint]),
    );
    if (!forced.isSuccess) {
      throw ArchiveExtractionException(
        'hdiutil detach failed: ${forced.stderr.trim().isEmpty ? forced.stdout.trim() : forced.stderr.trim()}',
      );
    }
  }

  Future<void> _runOrThrow(List<String> command, String label) async {
    final result = await _processRunner.run(
      ProcessSpec(executable: command.first, arguments: command.sublist(1)),
    );
    if (!result.isSuccess) {
      final details = result.stderr.trim().isEmpty ? result.stdout.trim() : result.stderr.trim();
      throw ArchiveExtractionException('$label failed${details.isEmpty ? '' : ': $details'}');
    }
  }
}
