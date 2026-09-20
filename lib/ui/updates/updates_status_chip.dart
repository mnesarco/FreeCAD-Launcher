import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/updates/updates_summary_sheet.dart';

class UpdatesStatusChip extends StatelessWidget {
  const UpdatesStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final count = AppScope.of(context).updates.outdated.watch(context).length;
    if (count == 0) {
      return const SizedBox.shrink();
    }
    return TextButton.icon(
      onPressed: () => showUpdatesSummarySheet(context),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        iconSize: 14,
      ),
      icon: const Icon(Icons.system_update_alt),
      label: Text(l10n.updatesBadge(count), style: theme.textTheme.labelSmall),
    );
  }
}
