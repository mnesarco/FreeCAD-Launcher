// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'package:freecad_launcher/ui/theme/app_colors.dart';

enum CompactBadgeTone { neutral, info, success, warning, danger, running }

class CompactBadge extends StatelessWidget {
  const CompactBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = CompactBadgeTone.neutral,
  });

  final String label;
  final IconData? icon;
  final CompactBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = AppStatusColors.of(context);
    final (background, foreground) = switch (tone) {
      CompactBadgeTone.neutral => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      CompactBadgeTone.info => (status.infoContainer, status.onInfoContainer),
      CompactBadgeTone.success => (status.successContainer, status.onSuccessContainer),
      CompactBadgeTone.warning => (status.warningContainer, status.onWarningContainer),
      CompactBadgeTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
      CompactBadgeTone.running => (status.runningContainer, status.onRunningContainer),
    };

    return Chip(
      avatar: icon == null ? null : Icon(icon, size: 14, color: foreground),
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall?.copyWith(color: foreground),
      backgroundColor: background,
      side: BorderSide(color: foreground.withValues(alpha: 0.22)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
