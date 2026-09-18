import 'package:flutter/material.dart';

import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

class AddonsView extends StatelessWidget {
  const AddonsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.extension_outlined,
      title: l10n.addonsEmptyTitle,
      message: l10n.addonsEmptyMessage,
    );
  }
}
