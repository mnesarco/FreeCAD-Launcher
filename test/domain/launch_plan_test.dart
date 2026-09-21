import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/launch_plan.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';
import 'package:path/path.dart' as p;

void main() {
  final posix = p.Context(style: p.Style.posix);
  final windows = p.Context(style: p.Style.windows);
  final posixPaths = ProfilePaths('/data/profiles/p1', context: posix);
  final windowsPaths = ProfilePaths(r'C:\data\profiles\p1', context: windows);

  test('passes the executable and user arguments before the config flags', () {
    final plan = LaunchPlanBuilder.build(
      platform: BuildPlatform.linux,
      paths: posixPaths,
      executablePath: '/data/builds/b1/FreeCAD.AppImage',
      inheritedEnvironment: const {},
      userArguments: const ['--no-splash', 'file.FCStd'],
    );

    expect(plan.executable, '/data/builds/b1/FreeCAD.AppImage');
    expect(plan.arguments, [
      '--no-splash',
      'file.FCStd',
      '-u',
      '/data/profiles/p1/user.cfg',
      '-s',
      '/data/profiles/p1/system.cfg',
    ]);
    expect(plan.arguments, isNot(contains('--single-instance')));
  });

  test('adds --console when --version is requested', () {
    final plan = LaunchPlanBuilder.build(
      platform: BuildPlatform.linux,
      paths: posixPaths,
      executablePath: '/data/builds/b1/FreeCAD',
      inheritedEnvironment: const {},
      userArguments: const ['--version'],
    );

    expect(plan.arguments, [
      '--console',
      '--version',
      '-u',
      '/data/profiles/p1/user.cfg',
      '-s',
      '/data/profiles/p1/system.cfg',
    ]);
  });

  test('keeps an explicit --console when --version is requested', () {
    final plan = LaunchPlanBuilder.build(
      platform: BuildPlatform.linux,
      paths: posixPaths,
      executablePath: '/data/builds/b1/FreeCAD',
      inheritedEnvironment: const {},
      userArguments: const ['--console', '--version'],
    );

    expect(plan.arguments, [
      '--console',
      '--version',
      '-u',
      '/data/profiles/p1/user.cfg',
      '-s',
      '/data/profiles/p1/system.cfg',
    ]);
  });

  test('uses the platform path style for config flags', () {
    final plan = LaunchPlanBuilder.build(
      platform: BuildPlatform.windows,
      paths: windowsPaths,
      executablePath: r'C:\data\builds\b1\FreeCAD.exe',
      inheritedEnvironment: const {},
    );

    expect(plan.arguments, [
      '-u',
      r'C:\data\profiles\p1\user.cfg',
      '-s',
      r'C:\data\profiles\p1\system.cfg',
    ]);
  });

  test('applies the linux isolation environment and the AppImage fallback', () {
    final plan = LaunchPlanBuilder.build(
      platform: BuildPlatform.linux,
      paths: posixPaths,
      executablePath: '/data/builds/b1/FreeCAD.AppImage',
      inheritedEnvironment: const {'PYTHONPATH': '/system', 'PATH': '/usr/bin'},
      appImageExtractAndRun: true,
    );

    expect(plan.environment['FREECAD_USER_HOME'], '/data/profiles/p1');
    expect(plan.environment['HOME'], '/data/profiles/p1/home');
    expect(plan.environment['XDG_CONFIG_HOME'], '/data/profiles/p1/xdg/config');
    expect(plan.environment['TMPDIR'], '/data/profiles/p1/temp');
    expect(plan.environment['APPIMAGE_EXTRACT_AND_RUN'], '1');
    expect(plan.environment.containsKey('PYTHONPATH'), isFalse);
    expect(plan.environment['PATH'], '/usr/bin');
  });

  test('applies the windows isolation environment', () {
    final plan = LaunchPlanBuilder.build(
      platform: BuildPlatform.windows,
      paths: windowsPaths,
      executablePath: r'C:\data\builds\b1\FreeCAD.exe',
      inheritedEnvironment: const {},
      appImageExtractAndRun: true,
    );

    expect(plan.environment['FREECAD_USER_HOME'], r'C:\data\profiles\p1');
    expect(plan.environment['APPDATA'], r'C:\data\profiles\p1\AppData\Roaming');
    expect(plan.environment['LOCALAPPDATA'], r'C:\data\profiles\p1\AppData\Local');
    expect(plan.environment['TEMP'], r'C:\data\profiles\p1\temp');
    expect(plan.environment.containsKey('HOME'), isFalse);
    expect(plan.environment.containsKey('APPIMAGE_EXTRACT_AND_RUN'), isFalse);
  });

  test('applies the macos isolation environment', () {
    final plan = LaunchPlanBuilder.build(
      platform: BuildPlatform.macos,
      paths: posixPaths,
      executablePath: '/data/builds/b1/FreeCAD.app/Contents/MacOS/FreeCAD',
      inheritedEnvironment: const {},
    );

    expect(plan.environment['HOME'], '/data/profiles/p1/home');
    expect(plan.environment['TMPDIR'], '/data/profiles/p1/temp');
    expect(plan.environment.containsKey('XDG_CONFIG_HOME'), isFalse);
    expect(plan.environment.containsKey('APPDATA'), isFalse);
  });

  test('every environment directory exists in the platform layout', () {
    for (final platform in BuildPlatform.values) {
      final isWindows = platform == BuildPlatform.windows;
      final context = isWindows ? windows : posix;
      final paths = isWindows ? windowsPaths : posixPaths;
      final plan = LaunchPlanBuilder.build(
        platform: platform,
        paths: paths,
        executablePath: 'x',
        inheritedEnvironment: const {},
      );
      final layout = paths
          .directoriesFor(platform)
          .map(context.normalize)
          .toSet();
      final environmentDirectories = [
        plan.environment['FREECAD_USER_HOME'],
        plan.environment['FREECAD_USER_TEMP'],
        plan.environment['HOME'],
        plan.environment['TMPDIR'],
        plan.environment['XDG_CONFIG_HOME'],
        plan.environment['XDG_DATA_HOME'],
        plan.environment['XDG_CACHE_HOME'],
        plan.environment['APPDATA'],
        plan.environment['LOCALAPPDATA'],
      ].whereType<String>();

      for (final directory in environmentDirectories) {
        expect(
          layout,
          contains(context.normalize(directory)),
          reason: '$platform: $directory',
        );
      }
    }
  });
}
