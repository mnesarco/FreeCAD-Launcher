import 'package:flutter/material.dart';

import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

class ProfilesView extends StatelessWidget {
  const ProfilesView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.workspaces_outline,
      title: l10n.profilesEmptyTitle,
      message: l10n.profilesEmptyMessage,
    );
  }
}
