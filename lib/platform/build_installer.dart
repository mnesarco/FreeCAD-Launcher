import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/archive_extract.dart';
import 'package:freecad_launcher/platform/dmg_extractor.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_probe.dart';

class InstallRequest {
  const InstallRequest({
    required this.buildId,
    required this.kind,
    required this.archivePath,
    this.assetName,
    this.pythonVersionHint,
  });

  final String buildId;
  final BuildKind kind;
  final String archivePath;
  final String? assetName;
  final String? pythonVersionHint;
}

class InstalledBuild {
  const InstalledBuild({
    required this.directory,
    required this.executablePath,
    required this.sizeBytes,
    this.pythonVersion,
  });

  final String directory;
  final String executablePath;
  final int sizeBytes;
  final String? pythonVersion;
}

class BuildInstaller {
  BuildInstaller({
    required AppPaths paths,
    required ProcessRunner processRunner,
    ArchiveExtractor? archiveExtractor,
    ArchiveExtractor? sevenZipExtractor,
    DmgExtractor? dmgExtractor,
    PythonProbe? pythonProbe,
  }) : _paths = paths,
       _processRunner = processRunner,
       _archiveExtractor = archiveExtractor ?? const SafeArchiveExtractor(),
       _sevenZipExtractor = sevenZipExtractor,
       _dmgExtractor = dmgExtractor,
       _pythonProbe = pythonProbe;

  static const List<String> _executableNames = [
    'FreeCAD.exe',
    'freecad.exe',
    'FreeCAD',
    'freecad',
    'AppRun',
  ];

  final AppPaths _paths;
  final ProcessRunner _processRunner;
  final ArchiveExtractor _archiveExtractor;
  final ArchiveExtractor? _sevenZipExtractor;
  final DmgExtractor? _dmgExtractor;
  final PythonProbe? _pythonProbe;

  Future<InstalledBuild> install(InstallRequest request) async {
    final finalDirectory = Directory(_paths.buildDir(request.buildId));
    final staging = Directory('${finalDirectory.path}.part');
    if (staging.existsSync()) {
      staging.deleteSync(recursive: true);
    }
    await staging.create(recursive: true);

    try {
      final executable = switch (request.kind) {
        BuildKind.appimage => await _installAppImage(request, staging.path),
        BuildKind.archive => await _installArchive(request, staging.path),
        BuildKind.dmg => await _installDmg(request, staging.path),
        BuildKind.custom => throw const ArchiveExtractionException(
          'Custom builds are not installed by this pipeline',
        ),
      };

      final relativeExecutable = p.relative(executable, from: staging.path);
      if (finalDirectory.existsSync()) {
        finalDirectory.deleteSync(recursive: true);
      }
      final moved = await staging.rename(finalDirectory.path);
      final finalExecutable = p.join(moved.path, relativeExecutable);

      return InstalledBuild(
        directory: moved.path,
        executablePath: finalExecutable,
        sizeBytes: await _directorySize(moved.path),
        pythonVersion: await _detectPythonVersion(request, moved.path, finalExecutable),
      );
    } on Object {
      if (staging.existsSync()) {
        staging.deleteSync(recursive: true);
      }
      rethrow;
    }
  }

  Future<String> _installAppImage(InstallRequest request, String directory) async {
    final fileName = request.assetName ?? p.basename(request.archivePath);
    final target = p.join(directory, fileName);
    await File(request.archivePath).copy(target);

    final chmod = await _processRunner.run(
      ProcessSpec(executable: 'chmod', arguments: ['755', target]),
    );
    if (!chmod.isSuccess) {
      throw ArchiveExtractionException(
        'Could not mark the AppImage as executable: ${chmod.stderr.trim()}',
      );
    }
    return target;
  }

  Future<String> _installArchive(InstallRequest request, String directory) async {
    final fileName = request.assetName ?? p.basename(request.archivePath);

    if (fileName.toLowerCase().endsWith('.7z')) {
      final extractor = _sevenZipExtractor;
      if (extractor == null) {
        throw const ArchiveExtractionException('7-Zip extraction is not configured');
      }
      await extractor.extract(request.archivePath, directory);
    } else {
      await _archiveExtractor.extract(request.archivePath, directory);
    }

    final executable = await _findExecutable(directory);
    if (executable == null) {
      throw ArchiveExtractionException(
        'No FreeCAD executable found after extracting $fileName',
      );
    }
    return executable;
  }

  Future<String> _installDmg(InstallRequest request, String directory) async {
    final extractor = _dmgExtractor;
    if (extractor == null) {
      throw const ArchiveExtractionException('DMG installation is not configured');
    }
    final appDirectory = await extractor.extractApp(request.archivePath, directory);
    return p.join(appDirectory, 'Contents', 'MacOS', 'FreeCAD');
  }

  Future<String?> _findExecutable(String root, {int maxDepth = 3}) async {
    var currentLevel = [Directory(root)];

    for (var depth = 0; depth < maxDepth && currentLevel.isNotEmpty; depth++) {
      final nextLevel = <Directory>[];
      final files = <File>[];

      for (final directory in currentLevel) {
        if (!directory.existsSync()) {
          continue;
        }
        for (final entity in directory.listSync(followLinks: false)) {
          if (entity is File) {
            files.add(entity);
          } else if (entity is Directory) {
            nextLevel.add(entity);
          }
        }
      }

      for (final candidate in _executableNames) {
        for (final file in files) {
          if (p.basename(file.path).toLowerCase() == candidate.toLowerCase()) {
            return file.path;
          }
        }
      }

      currentLevel = nextLevel;
    }
    return null;
  }

  Future<int> _directorySize(String root) async {
    var total = 0;
    await for (final entity in Directory(root).list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<String?> _detectPythonVersion(
    InstallRequest request,
    String directory,
    String executablePath,
  ) async {
    final probe = _pythonProbe;
    if (probe == null) {
      return request.pythonVersionHint;
    }
    final detection = await probe.detect(
      kind: request.kind,
      installDirectory: directory,
      executablePath: executablePath,
      knownVersion: request.pythonVersionHint,
    );
    return detection.python?.version ?? request.pythonVersionHint;
  }
}
