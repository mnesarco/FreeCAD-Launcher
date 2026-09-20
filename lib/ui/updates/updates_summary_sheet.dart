import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/domain/addons/addon_update.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/profiles/profile_actions.dart' show formatProfileDateTime;

Future<void> showUpdatesSummarySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const UpdatesSummarySheet(),
  );
}

class UpdatesSummarySheet extends StatefulWidget {
  const UpdatesSummarySheet({super.key});

  @override
  State<UpdatesSummarySheet> createState() => _UpdatesSummarySheetState();
}

class _UpdatesSummarySheetState extends State<UpdatesSummarySheet> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final services = AppScope.of(context);
      services.updates.start();
      services.profiles.start();
    }
  }

  Future<void> _check() async {
    final l10n = AppLocalizations.of(context);
    final count = await AppScope.of(context).updates.check();
    if (!mounted) {
      return;
    }
    final message = switch (count) {
      null => l10n.updatesCheckFailed,
      0 => l10n.updatesNone,
      final found => l10n.updatesBadge(found),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final grouped = services.updates.outdatedByProfile.watch(context);
    final checking = services.updates.checking.watch(context);
    final lastChecked = services.updates.lastCheckedAt.watch(context);
    final profiles = services.profiles.profiles.watch(context);
    final names = {for (final profile in profiles) profile.id: profile.name};

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.system_update_alt, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.updatesTitle, style: theme.textTheme.titleMedium),
                  ),
                  TextButton.icon(
                    onPressed: checking ? null : _check,
                    icon: checking
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 16),
                    label: Text(l10n.updatesCheck),
                  ),
                ],
              ),
              if (lastChecked != null)
                Text(
                  l10n.updatesLastChecked(formatProfileDateTime(l10n, lastChecked)),
                  style: theme.textTheme.labelSmall,
                ),
              const SizedBox(height: 8),
              if (grouped.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(l10n.updatesNone)),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            names[entry.key] ?? entry.key,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        for (final update in entry.value)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.extension_outlined),
                            title: Text(update.displayName),
                            subtitle: Text(_versionLine(l10n, update)),
                            trailing: Chip(
                              label: Text(l10n.addonsUpdateBadge),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _versionLine(AppLocalizations l10n, AddonUpdate update) {
    final versions = <String>[
      if ((update.installedVersion ?? '').isNotEmpty) 'v${update.installedVersion}',
      if ((update.catalogVersion ?? '').isNotEmpty) 'v${update.catalogVersion}',
    ];
    final line = versions.isEmpty ? l10n.addonsUpdateBadge : versions.join('  →  ');
    return update.branchRef.isEmpty ? line : '$line  ·  ${update.branchRef}';
  }
}
