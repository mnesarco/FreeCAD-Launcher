// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/domain/addons/addon_update.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/profiles/profile_actions.dart'
    show formatProfileDateTime;
import 'package:freecad_launcher/ui/widgets/build_version_label.dart';
import 'package:freecad_launcher/ui/widgets/compact_badge.dart';

Future<void> showUpdatesSummarySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const UpdatesSummarySheet(),
  );
}

class UpdatesSummarySheet extends SignalStatefulWidget {
  const UpdatesSummarySheet({super.key});

  @override
  State<UpdatesSummarySheet> createState() => _UpdatesSummarySheetState();
}

class _UpdatesSummarySheetState extends State<UpdatesSummarySheet> {
  bool _started = false;
  final Set<String> _unchecked = {};
  AddonUpdateApplySummary? _summary;

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

  String _key(AddonUpdate update) => '${update.profileId}:${update.addonId}';

  List<AddonUpdate> _selected(List<AddonUpdate> outdated) => [
    for (final update in outdated)
      if (!_unchecked.contains(_key(update))) update,
  ];

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _apply(List<AddonUpdate> updates) async {
    if (updates.isEmpty) {
      return;
    }
    setState(() => _summary = null);
    final summary = await AppScope.of(context).updates.applyUpdates(updates);
    if (!mounted) {
      return;
    }
    setState(() => _summary = summary);
  }

  Future<void> _retryFailed() async {
    final failures = _summary?.failures ?? const <AddonUpdateApplyResult>[];
    await _apply([for (final failure in failures) failure.update]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final grouped = services.updates.outdatedByProfile.value;
    final outdated = services.updates.outdated.value;
    final buildUpdates = services.updates.outdatedBuilds.value;
    final checking = services.updates.checking.value;
    final lastChecked = services.updates.lastCheckedAt.value;
    final applying = services.updates.applying.value;
    final completed = services.updates.applyCompleted.value;
    final total = services.updates.applyTotal.value;
    final profiles = services.profiles.profiles.value;
    final names = {for (final profile in profiles) profile.id: profile.name};
    final selected = _selected(outdated);
    final summary = _summary;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.system_update_alt,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.updatesTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: checking || applying ? null : _check,
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
                  l10n.updatesLastChecked(
                    formatProfileDateTime(l10n, lastChecked),
                  ),
                  style: theme.textTheme.labelSmall,
                ),
              const SizedBox(height: 8),
              if (grouped.isEmpty && buildUpdates.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(l10n.updatesNone)),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (buildUpdates.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            l10n.updatesBuildsSection,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        for (final update in buildUpdates)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(buildVersionLabel(update.installedVersion, l10n)),
                            subtitle: Text(
                              '${buildVersionLabel(update.installedVersion, l10n)}  →  '
                              '${buildVersionLabel(update.latestVersion, l10n)}',
                            ),
                            trailing: CompactBadge(
                              label: l10n.addonsUpdateBadge,
                              tone: CompactBadgeTone.info,
                            ),
                          ),
                      ],
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            names[entry.key] ?? entry.key,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        for (final update in entry.value)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: !_unchecked.contains(_key(update)),
                            onChanged: applying
                                ? null
                                : (checked) => setState(() {
                                    if (checked == true) {
                                      _unchecked.remove(_key(update));
                                    } else {
                                      _unchecked.add(_key(update));
                                    }
                                  }),
                            title: Text(update.displayName),
                            subtitle: Text(_versionLine(l10n, update)),
                          ),
                      ],
                    ],
                  ),
                ),
              if (applying) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: total == 0 ? null : completed / total,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.updatesApplyingCount(completed, total),
                  style: theme.textTheme.labelSmall,
                ),
              ] else if (outdated.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: selected.isEmpty
                          ? null
                          : () => _apply(selected),
                      icon: const Icon(Icons.system_update_alt, size: 18),
                      label: Text(l10n.updatesUpdateSelected(selected.length)),
                    ),
                    if (_unchecked.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(_unchecked.clear),
                        child: Text(l10n.updatesSelectAll),
                      ),
                    ],
                  ],
                ),
              ],
              if (summary != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (summary.count(AddonUpdateApplyStatus.updated) > 0)
                      CompactBadge(
                        label: l10n.updatesSummaryUpdated(
                          summary.count(AddonUpdateApplyStatus.updated),
                        ),
                        tone: CompactBadgeTone.success,
                      ),
                    if (summary.count(AddonUpdateApplyStatus.failed) > 0)
                      CompactBadge(
                        label: l10n.updatesSummaryFailed(
                          summary.count(AddonUpdateApplyStatus.failed),
                        ),
                        tone: CompactBadgeTone.danger,
                      ),
                  ],
                ),
                if (summary.failures.isNotEmpty)
                  TextButton.icon(
                    onPressed: applying ? null : _retryFailed,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(l10n.updatesRetryFailed),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _versionLine(AppLocalizations l10n, AddonUpdate update) {
    final versions = <String>[
      if ((update.installedVersion ?? '').isNotEmpty)
        'v${update.installedVersion}',
      if ((update.catalogVersion ?? '').isNotEmpty) 'v${update.catalogVersion}',
    ];
    final line = versions.isEmpty
        ? l10n.addonsUpdateBadge
        : versions.join('  →  ');
    return update.branchRef.isEmpty ? line : '$line  ·  ${update.branchRef}';
  }
}
