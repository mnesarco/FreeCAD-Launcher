import 'package:flutter/material.dart';

import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

class MacrosView extends StatelessWidget {
  const MacrosView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.auto_fix_high_outlined,
      title: l10n.macrosEmptyTitle,
      message: l10n.macrosEmptyMessage,
    );
  }
}
