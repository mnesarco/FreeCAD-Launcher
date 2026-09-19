import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/launch_environment.dart';
import 'package:freecad_launcher/domain/profiles/profile_paths.dart';

class LaunchPlan {
  const LaunchPlan({
    required this.executable,
    required this.arguments,
    required this.environment,
  });

  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
}

abstract final class LaunchPlanBuilder {
  static LaunchPlan build({
    required BuildPlatform platform,
    required ProfilePaths paths,
    required String executablePath,
    required Map<String, String> inheritedEnvironment,
    List<String> userArguments = const [],
    bool appImageExtractAndRun = false,
  }) {
    return LaunchPlan(
      executable: executablePath,
      arguments: [
        ...userArguments,
        '-u',
        paths.userCfg,
        '-s',
        paths.systemCfg,
      ],
      environment: LaunchEnvironment.build(
        platform: platform,
        paths: paths,
        inherited: inheritedEnvironment,
        appImageExtractAndRun: appImageExtractAndRun,
      ),
    );
  }
}
