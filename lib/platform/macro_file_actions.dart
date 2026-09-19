import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/process.dart';

class MacroFileActions {
  const MacroFileActions({required ProcessRunner processRunner, required BuildPlatform platform})
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

  Future<void> _run(List<String> command) async {
    await _processRunner.run(
      ProcessSpec(executable: command.first, arguments: command.skip(1).toList()),
    );
  }

  List<String> _revealCommand(String path) {
    return switch (_platform) {
      BuildPlatform.linux => ['xdg-open', p.dirname(path)],
      BuildPlatform.macos => ['open', '-R', path],
      BuildPlatform.windows => ['explorer.exe', '/select,$path'],
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
