import 'package:flutter/material.dart';

import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(l10n.settingsDataDirectory),
          subtitle: Text(services.paths.dataRoot),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.settingsVersion),
          subtitle: Text('$appName $appVersion'),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(l10n.settingsLicense),
          subtitle: const Text('GPL-3.0-or-later'),
        ),
      ],
    );
  }
}
