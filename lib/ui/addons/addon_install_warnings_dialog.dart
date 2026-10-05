// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'package:freecad_launcher/l10n/gen/app_localizations.dart';

/// Shown after a successful install when the archive contained entries that
/// were intentionally skipped (symbolic links).
Future<void> showAddonInstallWarningsDialog(
  BuildContext context, {
  required String addonName,
  required List<String> warnings,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.addonsInstallSkippedTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$addonName\n'),
              Text(l10n.addonsInstallSkippedMessage),
              const SizedBox(height: 12),
              for (final warning in warnings)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    warning,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.addonsInstallSkippedClose),
        ),
      ],
    ),
  );
}
