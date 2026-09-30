// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/launch_command.dart';
import 'package:freecad_launcher/domain/profiles/launch_plan.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';

void main() {
  final paths = ProfilePaths('/data/profiles/p1');

  LaunchPlan plan() {
    return LaunchPlan(
      executable: '/data/builds/b1/FreeCAD',
      arguments: ['-u', paths.userCfg, '-s', paths.systemCfg],
      environment: {
        'PATH': '/usr/bin',
        'FREECAD_USER_HOME': paths.root,
        'FREECAD_USER_TEMP': paths.temp,
        'HOME': paths.home,
        'TMPDIR': paths.temp,
        'APPIMAGE_EXTRACT_AND_RUN': '1',
      },
    );
  }

  test('keeps only changed or added variables and lists removed ones', () {
    final command = LaunchCommand.fromPlan(
      plan(),
      inheritedEnvironment: {
        'PATH': '/usr/bin',
        'FREECAD_USER_HOME': '/home/user',
        'PYTHONPATH': '/system/python',
        'VIRTUAL_ENV': '/venv',
      },
    );

    expect(command.environment.keys, [
      'APPIMAGE_EXTRACT_AND_RUN',
      'FREECAD_USER_HOME',
      'FREECAD_USER_TEMP',
      'HOME',
      'TMPDIR',
    ]);
    expect(command.environment.containsKey('PATH'), isFalse);
    expect(command.removedEnvironment, ['PYTHONPATH', 'VIRTUAL_ENV']);
    expect(command.arguments, ['-u', '/data/profiles/p1/user.cfg', '-s', '/data/profiles/p1/system.cfg']);
  });

  test('escapes posix values and arguments', () {
    final command = LaunchCommand.fromPlan(
      LaunchPlan(
        executable: '/data/My App/FreeCAD',
        arguments: ['-u', "/data/it's/user.cfg"],
        environment: {'HOME': '/p/home'},
      ),
      inheritedEnvironment: {'HOME': '/home/user'},
    );

    final shell = command.toShellCommand(platform: BuildPlatform.linux);

    expect(shell, r"HOME='/p/home' '/data/My App/FreeCAD' '-u' '/data/it'\''s/user.cfg'");
    expect(shell, isNot(contains('--single-instance')));
  });

  test('formats windows commands with set and quoted paths', () {
    final command = LaunchCommand.fromPlan(
      LaunchPlan(
        executable: r'C:\data\builds\b1\FreeCAD.exe',
        arguments: ['-u', r'C:\data\profiles\p1\user.cfg'],
        environment: {'FREECAD_USER_HOME': r'C:\data\profiles\p1'},
      ),
      inheritedEnvironment: {'PATH': r'C:\Windows'},
    );

    final shell = command.toShellCommand(platform: BuildPlatform.windows);

    expect(shell, startsWith(r'set "FREECAD_USER_HOME=C:\data\profiles\p1" && "C:\data\builds\b1\FreeCAD.exe"'));
    expect(shell, contains(r'"-u" "C:\data\profiles\p1\user.cfg"'));
  });

  test('produces the bare command when there are no overrides', () {
    final command = LaunchCommand.fromPlan(
      const LaunchPlan(executable: '/bin/freecad', arguments: [], environment: {}),
      inheritedEnvironment: const {},
    );

    expect(command.toShellCommand(platform: BuildPlatform.linux), "'/bin/freecad'");
  });
}
