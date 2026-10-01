// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';

Future<void> showLauncherAboutDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.aboutTitle, textAlign: TextAlign.center),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/freecad-logo.svg',
              width: 96,
              height: 96,
              semanticsLabel: l10n.aboutLogoLabel,
            ),
            const SizedBox(height: 12),
            Text('$appName $appVersion', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${l10n.settingsLicense}: GPL-3.0-or-later'),
            Text(l10n.settingsCopyright, style: theme.textTheme.bodySmall),
            const Divider(height: 28),
            Text(
              l10n.aboutTrademark,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.aboutProject,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.aboutClose),
        ),
      ],
    ),
  );
}
