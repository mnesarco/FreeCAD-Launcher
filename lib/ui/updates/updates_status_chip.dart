// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/theme/app_colors.dart';
import 'package:freecad_launcher/ui/updates/updates_summary_sheet.dart';

class UpdatesStatusChip extends SignalWidget {
  const UpdatesStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final count = AppScope.of(context).updates.outdatedCount.value;
    if (count == 0) {
      return const SizedBox.shrink();
    }
    return TextButton.icon(
      onPressed: () => showUpdatesSummarySheet(context),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        iconSize: 14,
        foregroundColor: AppStatusColors.of(context).info,
      ),
      icon: const Icon(Icons.system_update_alt),
      label: Text(l10n.updatesBadge(count), style: theme.textTheme.labelSmall),
    );
  }
}
