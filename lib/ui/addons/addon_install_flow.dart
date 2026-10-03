// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/python/requirements_parser.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/addons/requirements_dialog.dart';

Future<void> installAddonIntoProfile(
  BuildContext context, {
  required Addon addon,
  required String branchRef,
  required String profileId,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = AppScope.of(context).addons;
  final messenger = ScaffoldMessenger.of(context);

  final branch = controller.branchOf(addon, branchRef);
  var installRequirements = false;
  if (branch.hasRequirements) {
    final requirements = parseRequirements(branch.metadata?.requirements ?? '');
    final choice = await showRequirementsConsentDialog(
      context,
      addonName: addon.displayName,
      requirements: requirements,
    );
    if (!context.mounted || choice == RequirementsChoice.cancel) {
      return;
    }
    installRequirements = choice == RequirementsChoice.installPackages;
  }

  final result = await controller.install(
    addonId: addon.id,
    branchRef: branchRef,
    profileId: profileId,
    installRequirements: installRequirements,
  );
  if (!context.mounted) {
    return;
  }
  result.fold(
    (_) => messenger.showSnackBar(SnackBar(content: Text(l10n.addonsInstalledMessage))),
    (error) =>
        messenger.showSnackBar(SnackBar(content: Text('${l10n.addonsInstallFailed}: $error'))),
  );
}
