// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'package:freecad_launcher/domain/addons/addon_dependencies.dart';
import 'package:freecad_launcher/domain/python/python_names.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';

/// Consent dialog for the dependencies declared by an addon (`<depend>` and
/// `requirements.txt`). Returns `null` on cancel, [AddonDependencySelection.none]
/// for "Addon only", or the selected required/optional dependencies.
Future<AddonDependencySelection?> showAddonDependenciesDialog(
  BuildContext context, {
  required String addonName,
  required AddonDependencyPlan plan,
}) {
  final selectedOptionalAddons = <String>{};
  final selectedOptionalPackages = <String>{};
  return showDialog<AddonDependencySelection>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.addonsDependenciesTitle),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(addonName),
                  const SizedBox(height: 8),
                  Text(l10n.addonsDependenciesMessage),
                  const SizedBox(height: 12),
                  if (plan.requiredAddons.isNotEmpty) ...[
                    _SectionTitle(l10n.addonsDependenciesRequiredAddons),
                    for (final dependency in plan.requiredAddons)
                      _DependencyLine(text: dependency.addon?.displayName ?? ''),
                  ],
                  if (plan.optionalAddons.isNotEmpty) ...[
                    _SectionTitle(l10n.addonsDependenciesOptionalAddons),
                    for (final dependency in plan.optionalAddons)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: selectedOptionalAddons.contains(dependency.addon!.id),
                        title: Text(dependency.addon?.displayName ?? ''),
                        onChanged: (checked) => setState(() {
                          if (checked ?? false) {
                            selectedOptionalAddons.add(dependency.addon!.id);
                          } else {
                            selectedOptionalAddons.remove(dependency.addon!.id);
                          }
                        }),
                      ),
                  ],
                  if (plan.requiredPython.isNotEmpty) ...[
                    _SectionTitle(l10n.addonsDependenciesRequiredPython),
                    for (final entry in plan.requiredPython)
                      _DependencyLine(text: entry.requirement.display),
                  ],
                  if (plan.optionalPython.isNotEmpty) ...[
                    _SectionTitle(l10n.addonsDependenciesOptionalPython),
                    for (final entry in plan.optionalPython)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: selectedOptionalPackages.contains(
                          normalizePythonPackageName(entry.requirement.name),
                        ),
                        title: Text(entry.requirement.display),
                        onChanged: (checked) => setState(() {
                          final key = normalizePythonPackageName(entry.requirement.name);
                          if (checked ?? false) {
                            selectedOptionalPackages.add(key);
                          } else {
                            selectedOptionalPackages.remove(key);
                          }
                        }),
                      ),
                  ],
                  if (plan.internalWorkbenches.isNotEmpty) ...[
                    _SectionTitle(l10n.addonsDependenciesInternal),
                    _DependencyLine(text: plan.internalWorkbenches.join(', ')),
                  ],
                  if (plan.unresolved.isNotEmpty) ...[
                    _SectionTitle(l10n.addonsDependenciesUnresolved),
                    _DependencyLine(text: plan.unresolved.join(', '), isError: true),
                  ],
                  if (plan.invalidRequirements.isNotEmpty) ...[
                    _SectionTitle(l10n.addonsDependenciesInvalid),
                    for (final requirement in plan.invalidRequirements)
                      _DependencyLine(
                        text: '${requirement.raw}  —  ${l10n.addonsRequirementsInvalid}',
                        isError: true,
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.versionsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(AddonDependencySelection.none),
              child: Text(l10n.addonsDependenciesAddonOnly),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                AddonDependencySelection(
                  installRequired: true,
                  optionalAddonIds: selectedOptionalAddons,
                  optionalPackageNames: selectedOptionalPackages,
                ),
              ),
              child: Text(l10n.addonsDependenciesInstall),
            ),
          ],
        ),
      );
    },
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _DependencyLine extends StatelessWidget {
  const _DependencyLine({required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: isError ? Theme.of(context).colorScheme.error : null,
        ),
      ),
    );
  }
}
