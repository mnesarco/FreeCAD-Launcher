import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../addon_catalog.dart';
import 'widgets.dart';
import 'icons.dart';

/// Displays the addon catalog in a searchable list.
class AddonCatalogView extends StatefulWidget {
  final Future<AddonCatalog> catalogFuture;

  const AddonCatalogView({super.key, required this.catalogFuture});

  @override
  State<AddonCatalogView> createState() => _AddonCatalogViewState();
}

class _AddonCatalogViewState extends State<AddonCatalogView> {
  final _searchFilter = signal('');

  @override
  void dispose() {
    _searchFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AddonCatalog>(
      future: widget.catalogFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading addons: ${snapshot.error}'));
        }
        final catalog = snapshot.data!;
        return _AddonListBody(catalog: catalog, searchFilter: _searchFilter);
      },
    );
  }
}

class _AddonListBody extends StatelessWidget {
  final AddonCatalog catalog;
  final Signal<String> searchFilter;

  const _AddonListBody({required this.catalog, required this.searchFilter});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final query = searchFilter.watch(context);
    final filtered = catalog.search(query);

    return Column(
      children: [
        SearchField(value: searchFilter, hintText: 'Filter addons by name or description...'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${filtered.length} addon${filtered.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No addons found.'))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) => _AddonTile(addon: filtered[i]),
                ),
        ),
      ],
    );
  }
}

String ellipsis(String? value, int width) {
  if (value == null) return "";
  if (value.length <= width) return value;
  return "${value.substring(0, width)}...";
}

class _AddonTile extends StatelessWidget {
  final Addon addon;
  const _AddonTile({required this.addon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      titleAlignment: ListTileTitleAlignment.top,
      leading: _icon(theme),
      title: _title(theme),
      subtitle: _subtitle(theme),
      trailing: _trailing(theme),
      onTap: () => _showDetail(context),
    );
  }

  Widget _title(ThemeData theme) {
    final entry = addon.primary;
    final version = addon.version == null ? null : 'v${addon.version}';
    return Row(
      spacing: 8,
      children: [
        Flexible(
          child: Text(
            addon.displayName,
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (entry.curated) Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
        if (version != null) Text(version, overflow: TextOverflow.clip),
        if (entry.lastUpdateTime != null)
          Text(entry.lastUpdateTime!.substring(0, 10), overflow: TextOverflow.clip),
      ],
    );
  }

  Widget _subtitle(ThemeData theme) {
    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          TextSpan(text: ellipsis(addon.description, 256).replaceAll(RegExp(r'\s+'), ' ')),
          if (addon.tagsDisplay.isNotEmpty) ...[
            const TextSpan(text: '  '),
            TextSpan(
              text: addon.tagsDisplay,
              style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _trailing(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [
        if (addon.entries.length > 1)
          Chip(
            label: Text('${addon.entries.length} branches', style: theme.textTheme.bodySmall),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        if (addon.author != null)
          Chip(
            label: Text('By ${ellipsis(addon.author!.name, 32)}', style: theme.textTheme.bodySmall),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            backgroundColor: theme.colorScheme.inversePrimary,
          ),
      ],
    );
  }

  Widget _iconFrame(Widget child, {double size = 48.0}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: SizedBox(child: child, width: 52, height: 52),
      ),
    );
  }

  Widget _icon(ThemeData theme) {
    return _iconFrame(AddonIcon(addon, size: 32), size: 32);
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
          child: _AddonDetailSheet(addon: addon),
        ),
      ),
    );
  }
}

class AddonIcon extends StatelessWidget {
  final Addon addon;
  final double size;
  const AddonIcon(this.addon, {this.size = 48.0, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = addon.primary.metadata;
    final Uint8List? bytes = metadata?.iconBytes;

    if (bytes == null) {
      return _defaultIcon(theme: theme, size: size);
    }

    return metadata!.iconIsSvg
        ? SvgPicture.memory(bytes, width: size, height: size, fit: BoxFit.contain)
        : Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _defaultIcon(theme: theme, size: size),
          );
  }

  Widget _defaultIcon({ThemeData? theme, double size = 48.0}) {
    return Icon(Icons.extension, color: theme?.colorScheme.primary ?? Colors.black45, size: size);
  }
}

class _AddonDetailSheet extends StatelessWidget {
  final Addon addon;

  const _AddonDetailSheet({required this.addon});

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
                ..._version(theme),
                ..._lastUpdate(theme),
                ..._description(theme),
                ..._tags(theme),
                ..._people(theme),
                ..._branches(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _description(ThemeData theme) {
    return [Text(addon.description, style: theme.textTheme.bodyMedium)];
  }

  List<Widget> _lastUpdate(ThemeData theme) {
    if (addon.lastUpdate != null) {
      return [
        const SizedBox(height: 4),
        Text(
          'Last updated: ${addon.lastUpdate}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
        const Divider(height: 24),
      ];
    }
    return [];
  }

  List<Widget> _version(ThemeData theme) {
    if (addon.version != null) {
      return [
        const SizedBox(height: 4),
        Text('Version ${addon.version}', style: theme.textTheme.bodyMedium),
      ];
    }
    return [];
  }

  List<Widget> _header(BuildContext context) {
    final theme = Theme.of(context);
    return [
      Row(
        children: [
          AddonIcon(addon),
          const SizedBox(width: 12),
          Text(addon.displayName, style: theme.textTheme.headlineSmall),
        ],
      ),
      const Divider(height: 24),
    ];
  }

  List<Widget> _branches(BuildContext context) {
    final theme = Theme.of(context);
    return [
      const Divider(height: 24),
      Text('Branches / Releases', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      ...addon.entries.map((e) => _entryCard(context, e)),
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
          title: Text(a.name),
          leading: Icon(
            isAuthor ? Icons.person : Icons.person_outline,
            color: isAuthor ? theme.colorScheme.primary : theme.colorScheme.secondary,
          ),
          trailing: Text(_rolesDisplay(a.roles), overflow: TextOverflow.ellipsis),
          subtitle: SelectableText(a.contact ?? 'No contact', maxLines: 1),
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

  Widget _entryCard(BuildContext context, AddonEntry entry) {
    final theme = Theme.of(context);
    final compat = [
      if (entry.freecadMin != null) 'min: ${entry.freecadMin}',
      if (entry.freecadMax != null) 'max: ${entry.freecadMax}',
    ].join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, size: 18),
                const SizedBox(width: 8),
                Text(entry.branchDisplayName, style: theme.textTheme.titleSmall),
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
            const SizedBox(height: 4),
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
