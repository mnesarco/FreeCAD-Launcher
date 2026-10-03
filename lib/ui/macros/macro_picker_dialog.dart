// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/macros/macro_icon.dart';
import 'package:freecad_launcher/ui/widgets/compact_badge.dart';

class MacroPickerDialog extends SignalStatefulWidget {
  const MacroPickerDialog({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.profileId,
    this.searchHint,
  });

  final String title;
  final String actionLabel;
  final String profileId;
  final String? searchHint;

  @override
  State<MacroPickerDialog> createState() => _MacroPickerDialogState();
}

class _MacroPickerDialogState extends State<MacroPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).macros;
    final macros = controller.macros.value;
    final loading = controller.loading.value;
    final error = controller.error.value;
    final matches = _matches(macros);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        height: 380,
        child: Column(
          children: [
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: widget.searchHint ?? l10n.macrosSearchHint,
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: macros.isEmpty && loading
                  ? const Center(child: CircularProgressIndicator())
                  : macros.isEmpty
                  ? Center(
                      child: Text(
                        error == null ? l10n.macrosLoadFailed : '${l10n.macrosLoadFailed}: $error',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : matches.isEmpty
                  ? Center(child: Text(l10n.macrosNoMatches))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final macro = matches[index];
                        final installed = controller.isInstalled(widget.profileId, macro);
                        return ListTile(
                          leading: MacroIcon(macro: macro),
                          title: Text(macro.name),
                          subtitle: Text(
                            macro.comment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: installed
                              ? CompactBadge(
                                  label: l10n.addonsInstalledBadge,
                                  tone: CompactBadgeTone.success,
                                )
                              : FilledButton.tonal(
                                  onPressed: () => Navigator.of(context).pop(macro),
                                  child: Text(widget.actionLabel),
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.bundlesCancel)),
      ],
    );
  }

  List<MacroCatalogEntry> _matches(List<MacroCatalogEntry> macros) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return macros;
    }
    return [
      for (final macro in macros)
        if (macro.name.toLowerCase().contains(query) ||
            macro.comment.toLowerCase().contains(query) ||
            macro.description.toLowerCase().contains(query) ||
            macro.author.toLowerCase().contains(query))
          macro,
    ];
  }
}
