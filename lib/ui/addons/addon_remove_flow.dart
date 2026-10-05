// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';

Future<void> removeAddonFromProfile(
  BuildContext context, {
  required String addonId,
  required String displayName,
  required String profileId,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = AppScope.of(context).addons;
  final messenger = ScaffoldMessenger.of(context);
  final dependents = controller.dependentsOf(profileId, addonId);
  final warning = dependents.isEmpty
      ? ''
      : '\n\n${l10n.addonsDependenciesRequiredBy(dependents.join(', '))}';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.addonsRemoveTitle),
      content: Text('$displayName\n\n${l10n.addonsRemoveMessage}$warning'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.versionsCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.addonsRemove),
        ),
      ],
    ),
  );
  if (!(confirmed ?? false) || !context.mounted) {
    return;
  }
  final result = await controller.remove(addonId: addonId, profileId: profileId);
  if (!context.mounted) {
    return;
  }
  result.fold(
    (_) => messenger.showSnackBar(SnackBar(content: Text(l10n.addonsRemovedMessage))),
    (error) =>
        messenger.showSnackBar(SnackBar(content: Text('${l10n.addonsRemoveFailed}: $error'))),
  );
}
