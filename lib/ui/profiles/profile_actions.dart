import 'package:flutter/material.dart';

import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/profiles/profile_dialogs.dart';

Future<void> launchProfile(BuildContext context, Profile profile) async {
  final l10n = AppLocalizations.of(context);
  final controller = AppScope.of(context).profiles;

  var result = await controller.launch(profileId: profile.id);
  if (!context.mounted) {
    return;
  }
  if (result.isQuarantineRequired) {
    final consent = await confirmQuarantineRemoval(context, result.quarantineAppPath!);
    if (!context.mounted || !consent) {
      return;
    }
    result = await controller.launch(profileId: profile.id, quarantineConsent: true);
  }
  if (!context.mounted) {
    return;
  }
  if (result.isFailure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.profilesLaunchFailed}: ${result.error}')),
    );
  }
}

String formatProfileDateTime(AppLocalizations l10n, DateTime? value) {
  if (value == null) {
    return l10n.profilesNeverUsed;
  }
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
