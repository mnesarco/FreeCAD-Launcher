// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/addons/addon_icon.dart';
import 'package:freecad_launcher/ui/widgets/compact_badge.dart';

class AddonPickerDialog extends SignalStatefulWidget {
  const AddonPickerDialog({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.presentIds,
    this.searchHint,
  });

  final String title;
  final String actionLabel;
  final Set<String> presentIds;
  final String? searchHint;

  @override
  State<AddonPickerDialog> createState() => _AddonPickerDialogState();
}

class _AddonPickerDialogState extends State<AddonPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final addons = services.addons.addons.value;
    final loading = services.addons.loading.value;
    final error = services.addons.error.value;
    final matches = _matches(addons);

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
                hintText: widget.searchHint ?? l10n.bundlesSearchHint,
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: addons.isEmpty && loading
                  ? const Center(child: CircularProgressIndicator())
                  : addons.isEmpty
                  ? Center(
                      child: Text(
                        error == null ? l10n.addonsLoadFailed : '${l10n.addonsLoadFailed}: $error',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : matches.isEmpty
                  ? Center(child: Text(l10n.bundlesNoMatches))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final addon = matches[index];
                        final present = widget.presentIds.contains(addon.id);
                        return ListTile(
                          leading: AddonIcon(
                            base64Data: addon.primaryBranch.metadata?.iconBase64,
                            size: 32,
                          ),
                          title: Text(addon.displayName),
                          subtitle: Text(
                            addon.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: present
                              ? CompactBadge(
                                  label: l10n.addonsInstalledBadge,
                                  tone: CompactBadgeTone.success,
                                )
                              : FilledButton.tonal(
                                  onPressed: () => Navigator.of(context).pop(addon),
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

  List<Addon> _matches(List<Addon> addons) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return addons;
    }
    if (query.startsWith('#')) {
      final tag = query.substring(1);
      return [
        for (final addon in addons)
          if (addon.tags.any((candidate) => candidate.toLowerCase().contains(tag))) addon,
      ];
    }
    return [
      for (final addon in addons)
        if (addon.id.toLowerCase().contains(query) ||
            addon.displayName.toLowerCase().contains(query) ||
            addon.description.toLowerCase().contains(query))
          addon,
    ];
  }
}
