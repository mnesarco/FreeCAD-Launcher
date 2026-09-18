import 'package:flutter/material.dart';

import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

class BuildsView extends StatelessWidget {
  const BuildsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: l10n.versionsEmptyTitle,
      message: l10n.versionsEmptyMessage,
    );
  }
}
