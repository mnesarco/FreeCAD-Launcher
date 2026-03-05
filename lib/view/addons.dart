import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../addon_catalog.dart';
import 'widgets.dart';

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
            label: Text('By ${ellipsis(addon.author, 32)}', style: theme.textTheme.bodySmall),
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

  Widget _defaultIcon({ThemeData? theme, double size = 48.0}) {
    return Icon(Icons.extension, color: Colors.black87, size: size);
  }

  Widget _icon(ThemeData theme) {
    const iconSize = 32.0;
    final metadata = addon.primary.metadata;
    final Uint8List? bytes = metadata?.iconBytes;

    if (bytes == null) {
      return _iconFrame(_defaultIcon(theme: theme, size: iconSize));
    }

    return _iconFrame(
      metadata!.iconIsSvg
          ? SvgPicture.memory(bytes, width: iconSize, height: iconSize, fit: BoxFit.contain)
          : Image.memory(
              bytes,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _defaultIcon(theme: theme, size: iconSize),
            ),
      size: iconSize,
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 5,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.8,
        builder: (context, scrollController) =>
            _AddonDetailSheet(addon: addon, scrollController: scrollController),
      ),
    );
  }
}

class _AddonDetailSheet extends StatelessWidget {
  final Addon addon;
  final ScrollController scrollController;

  const _AddonDetailSheet({required this.addon, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(addon.displayName, style: theme.textTheme.headlineSmall),
        if (addon.version != null) ...[
          const SizedBox(height: 4),
          Text('Version ${addon.version}', style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 8),
        Text(addon.description, style: theme.textTheme.bodyMedium),
        if (addon.lastUpdate != null) ...[
          const SizedBox(height: 8),
          Text(
            'Last updated: ${addon.lastUpdate}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
        _tags(theme),
        const Divider(height: 24),
        Text('Branches / Releases', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...addon.entries.map((e) => _entryCard(context, e)),
      ],
    );
  }

  Widget _tags(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
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
    );
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
                    label: Text(compat, style: theme.textTheme.labelSmall),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
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
