import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freecad_launcher/controller/addons.dart';
import 'package:freecad_launcher/model/addons.dart';
import 'package:freecad_launcher/config.dart';
import 'package:freecad_launcher/controller/main.dart';
import 'package:freecad_launcher/service/database.dart';
import 'package:freecad_launcher/service/download.dart';
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
    final controller = MainController.of(context);
    final updates = controller.addonsUpdateCheck.updated.watch(context);
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      addon.displayName,
                      style: theme.textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                    UpdateIndicator(addon: addon, updates: updates, size: 24),
                  ],
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

  Future<void> _upgrade(
    AddonEntry entry,
    AddonDownloadController downloadedAddons,
    DownloadManager dm,
  ) async {}

  Future<void> _download(
    AddonEntry entry,
    AddonDownloadController downloadedAddons,
    DownloadManager dm, {
    int ttl = -1,
  }) async {
    final fileName = await dm.download(entry.downloadUrl, '${entry.sha1}.zip', ttl);
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
  }

  Widget _chipPythonCompat(AddonEntry entry, ThemeData theme) {
    return Chip(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      avatar: Icon(FreeCADIcons.python, size: 16),
      label: Text('Python ${entry.minPython}+', style: theme.textTheme.labelSmall),
    );
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
    final updates = controller.addonsUpdateCheck.updated.watch(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                if (entry.repository.isNotEmpty) _gitRepoLink(entry),
                Text(entry.branchDisplayName, style: theme.textTheme.titleLarge),
                if (entry.metadata?.version != null)
                  Text(entry.metadata!.version!, style: theme.textTheme.titleMedium),
                Text(
                  fmtDateTime(entry.lastUpdateTime),
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              Text(entry.note!, style: theme.textTheme.bodySmall),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isDownloading)
                  Chip(label: Text('Downloading...'), avatar: CircularProgressIndicator()),
                if (!isDownloading) _downloadActions(entry, downloadedAddons, dm, updates),
                if (dm.failedDownload(entry.downloadUrl)) _failedDownload(theme),
                if (compat.isNotEmpty) _freecadCompat(compat, theme),
                _chipPythonCompat(entry, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _downloadActions(
    AddonEntry entry,
    AddonDownloadController downloadedAddons,
    DownloadManager dm,
    Future<Map<String, AddonUpdate>> updates,
  ) => FutureBuilder(
    future: downloadedAddons.findBranch(addon.id, entry.gitRef),
    builder: (context, snapshot) {
      if (snapshot.hasError || snapshot.connectionState == ConnectionState.waiting) {
        return Container();
      }
      if (snapshot.data == null) {
        return FilledButton.icon(
          onPressed: () async => await _download(entry, downloadedAddons, dm),
          icon: Icon(Icons.download, size: 16),
          label: Text('Download'),
        );
      }
      return FutureBuilder(
        future: updates,
        builder: (context, snapshot) {
          if (snapshot.hasError ||
              snapshot.connectionState == ConnectionState.waiting ||
              snapshot.data == null) {
            return Container();
          }
          if (snapshot.data![entry.sha1] == null) {
            return FilledButton.icon(
              onPressed: () async => await _download(entry, downloadedAddons, dm, ttl: 0),
              icon: Icon(Icons.download, size: 16),
              label: Text('Force Re-Download'),
            );
          }
          return FilledButton.icon(
            onPressed: () async => await _upgrade(entry, downloadedAddons, dm),
            icon: Icon(Icons.update, size: 16),
            label: Text('Upgrade'),
          );
        },
      );
    },
  );

  Widget _failedDownload(ThemeData theme) => Tooltip(
    message: 'Error downloading the file',
    child: Icon(Icons.error, color: theme.colorScheme.error),
  );

  Widget _freecadCompat(String compat, ThemeData theme) {
    return Chip(
      avatar: Icon(FreeCADIcons.freecad, size: 16),
      label: Text(compat, style: theme.textTheme.labelSmall),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _gitRepoLink(AddonEntry entry) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse(entry.repository)),
        child: Tooltip(
          message: 'Url: ${entry.repository}',
          child: Icon(FreeCADIcons.git, size: 16),
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
