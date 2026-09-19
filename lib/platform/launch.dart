import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/launch_plan.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';
import 'package:freecad_launcher/platform/diagnostics.dart';
import 'package:freecad_launcher/platform/process.dart';

abstract interface class QuarantineGuard {
  Future<bool> isQuarantined(String appPath);

  Future<void> clear(String appPath);
}

class QuarantineException implements Exception {
  const QuarantineException(this.message);

  final String message;

  @override
  String toString() => message;
}

class XattrQuarantineGuard implements QuarantineGuard {
  XattrQuarantineGuard(this._processRunner);

  final ProcessRunner _processRunner;

  @override
  Future<bool> isQuarantined(String appPath) async {
    final result = await _processRunner.run(
      ProcessSpec(executable: 'xattr', arguments: ['-p', 'com.apple.quarantine', appPath]),
    );
    return result.isSuccess && result.stdout.trim().isNotEmpty;
  }

  @override
  Future<void> clear(String appPath) async {
    final result = await _processRunner.run(
      ProcessSpec(executable: 'xattr', arguments: ['-dr', 'com.apple.quarantine', appPath]),
    );
    if (!result.isSuccess) {
      throw QuarantineException(
        'Could not remove quarantine attributes: ${result.stderr.trim()}',
      );
    }
  }
}

class FreeCadRuntime {
  FreeCadRuntime({
    required ProcessRunner processRunner,
    required DiagnosticsService diagnostics,
    required BuildPlatform platform,
    QuarantineGuard? quarantineGuard,
    Map<String, String>? environment,
  }) : _processRunner = processRunner,
       _diagnostics = diagnostics,
       _platform = platform,
       _quarantineGuard = quarantineGuard ?? XattrQuarantineGuard(processRunner),
       _environment = environment ?? Platform.environment;

  final ProcessRunner _processRunner;
  final DiagnosticsService _diagnostics;
  final BuildPlatform _platform;
  final QuarantineGuard _quarantineGuard;
  final Map<String, String> _environment;

  Map<String, String> get inheritedEnvironment => _environment;

  Future<LaunchPlan> planFor({
    required BuildKind kind,
    required String executablePath,
    required ProfilePaths paths,
    List<String> userArguments = const [],
  }) async {
    final appImageExtractAndRun =
        kind == BuildKind.appimage &&
        _platform == BuildPlatform.linux &&
        !await _diagnostics.fuseAvailable();

    return LaunchPlanBuilder.build(
      platform: _platform,
      paths: paths,
      executablePath: executablePath,
      inheritedEnvironment: _environment,
      userArguments: userArguments,
      appImageExtractAndRun: appImageExtractAndRun,
    );
  }

  Future<ProcessHandle> start(LaunchPlan plan) {
    return _processRunner.start(
      ProcessSpec(
        executable: plan.executable,
        arguments: plan.arguments,
        environment: plan.environment,
      ),
    );
  }

  Future<String?> quarantineAppPath(String executablePath) async {
    if (_platform != BuildPlatform.macos) {
      return null;
    }
    final appPath = macAppBundlePath(executablePath) ?? executablePath;
    if (await _quarantineGuard.isQuarantined(appPath)) {
      return appPath;
    }
    return null;
  }

  Future<void> clearQuarantine(String appPath) => _quarantineGuard.clear(appPath);
}

String? macAppBundlePath(String executablePath) {
  var current = p.dirname(executablePath);
  while (true) {
    if (p.basename(current).toLowerCase().endsWith('.app')) {
      return current;
    }
    final parent = p.dirname(current);
    if (parent == current) {
      return null;
    }
    current = parent;
  }
}
