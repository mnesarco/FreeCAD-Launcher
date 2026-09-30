// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/launch_environment.dart';
import 'package:freecad_launcher/domain/profiles/launch_plan.dart';

class LaunchCommand {
  const LaunchCommand({
    required this.executable,
    required this.arguments,
    required this.environment,
    required this.removedEnvironment,
  });

  final String executable;
  final List<String> arguments;

  /// Variables whose value differs from the inherited environment (the
  /// isolation overrides).
  final Map<String, String> environment;

  /// Sanitized keys that were present in the inherited environment and removed.
  final List<String> removedEnvironment;

  static LaunchCommand fromPlan(
    LaunchPlan plan, {
    required Map<String, String> inheritedEnvironment,
  }) {
    final inheritedByUpper = {
      for (final entry in inheritedEnvironment.entries) entry.key.toUpperCase(): entry.key,
    };
    final planKeys = plan.environment.keys.map((key) => key.toUpperCase()).toSet();

    final overrides = <String, String>{};
    for (final entry in plan.environment.entries) {
      if (inheritedEnvironment[entry.key] != entry.value) {
        overrides[entry.key] = entry.value;
      }
    }
    final sortedOverrides = {
      for (final key in overrides.keys.toList()..sort()) key: overrides[key]!,
    };

    final removed = <String>[];
    for (final key in sanitizedEnvironmentKeys.toList()..sort()) {
      final original = inheritedByUpper[key];
      if (original != null && !planKeys.contains(key)) {
        removed.add(original);
      }
    }

    return LaunchCommand(
      executable: plan.executable,
      arguments: List.unmodifiable(plan.arguments),
      environment: sortedOverrides,
      removedEnvironment: removed,
    );
  }

  String toShellCommand({required BuildPlatform platform}) {
    final environmentPrefix = environment.entries
        .map(
          (entry) => platform == BuildPlatform.windows
              ? 'set "${entry.key}=${_escapeWindowsValue(entry.value)}"'
              : "${entry.key}=${_quotePosix(entry.value)}",
        )
        .join(platform == BuildPlatform.windows ? ' && ' : ' ');

    final executable = platform == BuildPlatform.windows
        ? '"${_escapeWindowsValue(this.executable)}"'
        : _quotePosix(this.executable);
    final arguments = this.arguments.map(
      (argument) => platform == BuildPlatform.windows
          ? '"${_escapeWindowsValue(argument)}"'
          : _quotePosix(argument),
    );
    final command = [executable, ...arguments].join(' ');

    if (environmentPrefix.isEmpty) {
      return command;
    }
    if (platform == BuildPlatform.windows) {
      return '$environmentPrefix && $command';
    }
    return '$environmentPrefix $command';
  }

  static String _quotePosix(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }

  static String _escapeWindowsValue(String value) {
    return value.replaceAll('"', '""');
  }
}
