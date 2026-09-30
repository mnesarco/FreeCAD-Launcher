// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'package:freecad_launcher/domain/python/requirements_parser.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';

enum RequirementsChoice { installPackages, addonOnly, cancel }

Future<RequirementsChoice> showRequirementsConsentDialog(
  BuildContext context, {
  required String addonName,
  required List<PythonRequirement> requirements,
}) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showDialog<RequirementsChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.addonsRequirementsTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$addonName\n'),
              Text(l10n.addonsRequirementsMessage),
              const SizedBox(height: 12),
              for (final requirement in requirements)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    requirement.valid
                        ? requirement.display
                        : '${requirement.raw}  —  ${l10n.addonsRequirementsInvalid}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: requirement.valid
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(RequirementsChoice.cancel),
          child: Text(l10n.versionsCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(RequirementsChoice.addonOnly),
          child: Text(l10n.addonsRequirementsAddonOnly),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(RequirementsChoice.installPackages),
          child: Text(l10n.addonsRequirementsInstall),
        ),
      ],
    ),
  );
  return choice ?? RequirementsChoice.cancel;
}
