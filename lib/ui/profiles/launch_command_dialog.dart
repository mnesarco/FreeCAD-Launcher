import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:freecad_launcher/domain/profiles/launch_command.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/host.dart';
import 'package:freecad_launcher/state/app_services.dart';

Future<void> showLaunchCommandDialog(BuildContext context, {required String profileId}) async {
  final l10n = AppLocalizations.of(context);
  final services = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final result = await services.profiles.planFor(profileId);
  if (!context.mounted) {
    return;
  }
  final plan = result.valueOrNull;
  if (plan == null) {
    messenger.showSnackBar(
      SnackBar(content: Text('${l10n.profilesCommandFailed}: ${result.errorOrNull}')),
    );
    return;
  }

  final command = LaunchCommand.fromPlan(
    plan,
    inheritedEnvironment: services.launchRuntime.inheritedEnvironment,
  );
  final shellCommand = command.toShellCommand(platform: hostPlatform);

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.profilesCommandTitle),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                shellCommand,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
              if (command.environment.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.profilesCommandEnvironment,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  command.environment.entries
                      .map((entry) => '${entry.key}=${entry.value}')
                      .join('\n'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              if (command.removedEnvironment.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.profilesCommandRemoved,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  command.removedEnvironment.join('\n'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: shellCommand));
            if (context.mounted) {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.profilesCommandCopied)),
              );
            }
          },
          child: Text(l10n.profilesCopy),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.profilesClose),
        ),
      ],
    ),
  );
}
