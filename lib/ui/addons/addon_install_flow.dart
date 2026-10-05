// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/addon_dependencies.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/addons/addon_dependencies_dialog.dart';
import 'package:freecad_launcher/ui/addons/addon_install_warnings_dialog.dart';

Future<void> installAddonIntoProfile(
  BuildContext context, {
  required Addon addon,
  required String branchRef,
  required String profileId,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = AppScope.of(context).addons;
  final messenger = ScaffoldMessenger.of(context);

  try {
    final plan = await controller.prepareDependencies(
      addonId: addon.id,
      branchRef: branchRef,
      profileId: profileId,
    );
    if (!context.mounted) {
      return;
    }
    AddonDependencySelection? selection;
    if (plan.hasInstallable || plan.invalidRequirements.isNotEmpty) {
      selection = await showAddonDependenciesDialog(
        context,
        addonName: addon.displayName,
        plan: plan,
      );
      if (!context.mounted || selection == null) {
        return;
      }
    }

    final result = await controller.install(
      addonId: addon.id,
      branchRef: branchRef,
      profileId: profileId,
      selection: selection,
      onDependencies: (plan) async {
        if (!context.mounted) {
          return null;
        }
        return showAddonDependenciesDialog(context, addonName: addon.displayName, plan: plan);
      },
    );
    if (!context.mounted) {
      return;
    }
    result.fold(
      (_) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.addonsInstalledMessage)));
        final warnings = controller.installWarnings.value[addon.id] ?? const <String>[];
        if (warnings.isNotEmpty && context.mounted) {
          showAddonInstallWarningsDialog(context, addonName: addon.displayName, warnings: warnings);
        }
      },
      (error) =>
          messenger.showSnackBar(SnackBar(content: Text('${l10n.addonsInstallFailed}: $error'))),
    );
  } on Object catch (error, stackTrace) {
    appLogger.error(
      'addon install failed before the job started',
      error: error,
      stackTrace: stackTrace,
      tag: 'addons',
    );
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text('${l10n.addonsInstallFailed}: $error')));
  }
}
