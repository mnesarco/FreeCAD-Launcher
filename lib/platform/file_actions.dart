// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/process.dart';

class FileActionException implements Exception {
  const FileActionException(this.executable, this.exitCode, this.stderr);

  final String executable;
  final int exitCode;
  final String stderr;

  @override
  String toString() {
    final detail = stderr.trim();
    return 'FileActionException: $executable exited with $exitCode'
        '${detail.isEmpty ? '' : ' ($detail)'}';
  }
}

class FileActions {
  const FileActions({required ProcessRunner processRunner, required BuildPlatform platform})
    : _processRunner = processRunner,
      _platform = platform;

  final ProcessRunner _processRunner;
  final BuildPlatform _platform;

  Future<void> reveal(String path) async {
    await _run(_revealCommand(path));
  }

  Future<void> open(String path) async {
    await _run(_openCommand(path));
  }

  Future<void> openDirectory(String directory) async {
    await _run(_directoryCommand(directory));
  }

  Future<void> _run(List<String> command) async {
    final result = await _processRunner.run(
      ProcessSpec(
        executable: command.first,
        arguments: command.skip(1).toList(),
        includeParentEnvironment: true,
      ),
    );
    if (!result.isSuccess) {
      throw FileActionException(
        command.first,
        result.exitCode,
        result.stderr,
      );
    }
  }

  List<String> _revealCommand(String path) {
    return switch (_platform) {
      BuildPlatform.linux => ['xdg-open', p.dirname(path)],
      BuildPlatform.macos => ['open', '-R', path],
      BuildPlatform.windows => ['explorer.exe', '/select,$path'],
    };
  }

  List<String> _directoryCommand(String directory) {
    return switch (_platform) {
      BuildPlatform.linux => ['xdg-open', directory],
      BuildPlatform.macos => ['open', directory],
      BuildPlatform.windows => ['explorer.exe', directory],
    };
  }

  List<String> _openCommand(String path) {
    return switch (_platform) {
      BuildPlatform.linux => ['xdg-open', path],
      BuildPlatform.macos => ['open', path],
      BuildPlatform.windows => ['cmd', '/c', 'start', '', path],
    };
  }
}
