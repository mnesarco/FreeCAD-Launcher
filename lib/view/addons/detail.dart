import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freecad_launcher/model/addons.dart';
import 'package:freecad_launcher/config.dart';
import 'package:freecad_launcher/controller/main.dart';
import 'package:freecad_launcher/util/format.dart';
import 'package:freecad_launcher/view/addons/icon.dart';
import 'package:freecad_launcher/view/addons/stats.dart';
import 'package:freecad_launcher/view/icons.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AddonDetailSheet extends StatelessWidget {
  final Addon addon;

  const AddonDetailSheet({required this.addon, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._header(context),
          Expanded(
            child: ListView(
              children: [
                ..._branches(context),
                ..._description(theme),
                ..._tags(theme),
                ..._people(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _description(ThemeData theme) {
    return [
      Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Text(addon.description, style: theme.textTheme.bodyMedium),
        ),
      ),
    ];
  }

  List<Widget> _lastUpdate(ThemeData theme) {
    if (addon.lastUpdate != null) {
      final date = fmtDateTime(addon.lastUpdate);
      return [Text('Last updated: $date', style: theme.textTheme.bodyMedium), SizedBox(width: 8)];
    }
    return [];
  }

  List<Widget> _version(ThemeData theme) {
    if (addon.version != null) {
      return [Text('Version ${addon.version}', style: theme.textTheme.bodyMedium)];
    }
    return [];
  }

  List<Widget> _header(BuildContext context) {
    final theme = Theme.of(context);
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 12,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: AddonIcon(addon),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addon.displayName,
                  style: theme.textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._version(theme),
                    ..._lastUpdate(theme),
                    CuratedIndicator(addon: addon, size: 20),
                    AddonContentIcons(addon: addon, size: 20),
                    AddonStats(addon: addon, full: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      const Divider(height: 24),
    ];
    // return [
    //   ListTile(
    //     dense: false,
    //     leading: Container(
    //       padding: EdgeInsets.all(8),
    //       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
    //       child: AddonIcon(addon),
    //     ),
    //     title: Text(
    //       addon.displayName,
    //       style: theme.textTheme.headlineSmall,
    //       overflow: TextOverflow.ellipsis,
    //     ),
    //     subtitle: Row(
    //       children: [
    //         ..._version(theme),
    //         ..._lastUpdate(theme),
    //         if (addon.primary.curated && mainConfig.showCuratedIcon) ...[
    //           Icon(curatedIcon, size: 24, color: theme.colorScheme.primary),
    //           SizedBox(width: 8),
    //         ],
    //         AddonContentIcons(addon: addon),
    //       ],
    //     ),
    //   ),
    //   const Divider(height: 24),
    // ];
  }

  List<Widget> _branches(BuildContext context) {
    final theme = Theme.of(context);
    return [
      Text('Branches / Releases', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      ...addon.entries.map((e) => _branch(context, e)),
    ];
  }

  List<Widget> _people(ThemeData theme) {
    final people = addon.primary.metadata?.people ?? [];
    if (people.isEmpty) {
      return [];
    }
    return [
      const Divider(height: 24),
      Text('Authors/Maintainers', style: theme.textTheme.titleMedium),
      ...people.map((a) {
        final isAuthor = a.roles.contains(AddonPersonRole.author);
        return ListTile(
          title: Text(a.name, overflow: TextOverflow.ellipsis),
          leading: Icon(
            isAuthor ? Icons.person : Icons.person_outline,
            color: isAuthor ? theme.colorScheme.primary : theme.colorScheme.secondary,
          ),
          trailing: Text(_rolesDisplay(a.roles), overflow: TextOverflow.ellipsis),
          subtitle: SelectableText(a.contact, maxLines: 1),
        );
      }),
    ];
  }

  List<Widget> _tags(ThemeData theme) {
    if (addon.tags.isEmpty) {
      return [];
    }
    return [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ...addon.tags.map(
              (tag) => Chip(
                label: Text(tag, style: theme.textTheme.bodySmall),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _branch(BuildContext context, AddonEntry entry) {
    final theme = Theme.of(context);
    final controller = MainController.of(context);
    final dm = controller.downloadManager;
    final downloadedAddons = controller.downloadedAddons;

    final compat = [
      if (entry.freecadMin != null) 'min: ${entry.freecadMin}',
      if (entry.freecadMax != null) 'max: ${entry.freecadMax}',
    ].join(', ');

    // ignore: unused_local_variable
    final downloadList = dm.activeDownloads.watch(context);

    final isDownloading = dm.isDownloading(entry.downloadUrl);
    final action = isDownloading
        ? null
        : () async {
            final fileName = await dm.download(entry.downloadUrl, '${entry.sha1}.zip');
            final file = File(fileName);
            final downloadAt = await file.lastModified();
            downloadedAddons.add(
              addon.id,
              entry.repository,
              entry.zipUrl,
              entry.gitRef,
              entry.metadata?.version ?? '',
              entry.lastUpdateTime ?? downloadAt,
              file.uri.pathSegments.last,
              downloadAt,
            );
          };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FilledButton.icon(
                  onPressed: action,
                  icon: Icon(isDownloading ? Icons.downloading : Icons.download, size: 16),
                  label: Text(isDownloading ? 'Downloading...' : 'Download'),
                ),
                if (dm.failedDownload(entry.downloadUrl)) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Error downloading the file',
                    child: Icon(Icons.error, color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(width: 8),
                Text(entry.branchDisplayName, style: theme.textTheme.titleSmall),
                const SizedBox(width: 8),
                Text(
                  fmtDateTime(entry.lastUpdateTime),
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (compat.isNotEmpty)
                  Chip(
                    label: Row(
                      children: [
                        Icon(FreeCADIcons.freecad, size: 16),
                        SizedBox(width: 4),
                        Text(compat, style: theme.textTheme.labelSmall),
                      ],
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  label: Row(
                    children: [
                      Icon(FreeCADIcons.python, size: 16),
                      SizedBox(width: 4),
                      Text('Python ${addon.minPython}+', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(entry.repository)),
              child: Text(
                entry.repository,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary,
                ),
              ),
            ),
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(entry.note!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  String _rolesDisplay(List<AddonPersonRole> roles) {
    return roles
        .map(
          (e) => switch (e) {
            AddonPersonRole.author => 'Author',
            AddonPersonRole.maintainer => 'Maintainer',
            AddonPersonRole.contributor => 'Contributor',
          },
        )
        .join(', ');
  }
}
