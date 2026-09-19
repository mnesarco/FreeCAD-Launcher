import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/addons/addon_icon.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

class AddonsView extends StatefulWidget {
  const AddonsView({super.key});

  @override
  State<AddonsView> createState() => _AddonsViewState();
}

class _AddonsViewState extends State<AddonsView> {
  bool _started = false;
  String? _selectedAddonId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      AppScope.of(context).addons.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).addons;
    final selectedId = _selectedAddonId;
    if (selectedId != null && controller.byId(selectedId) != null) {
      return AddonDetailView(
        addonId: selectedId,
        onBack: () => setState(() => _selectedAddonId = null),
      );
    }

    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.addonsTabCatalog),
              Tab(text: l10n.addonsTabCollections),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _CatalogTab(
                  searchController: _searchController,
                  onOpen: (addon) => setState(() => _selectedAddonId = addon.id),
                ),
                EmptyState(
                  icon: Icons.inventory_outlined,
                  title: l10n.addonsTabCollections,
                  message: l10n.addonsCollectionsSoon,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({required this.searchController, required this.onOpen});

  final TextEditingController searchController;
  final ValueChanged<Addon> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).addons;
    final loading = controller.loading.watch(context);
    final loaded = controller.loaded.watch(context);
    final error = controller.error.watch(context);
    final addons = controller.addons.watch(context);
    final filtered = controller.filteredAddons.watch(context);
    final freshness = controller.freshness.watch(context);
    final freecadFilter = controller.freecadFilter.watch(context);
    final versions = controller.freecadVersions.watch(context);
    final installedCounts = controller.installedCounts.watch(context);
    final query = controller.query.watch(context);

    Widget body;
    if (loading && addons.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null && addons.isEmpty) {
      body = EmptyState(
        icon: Icons.cloud_off_outlined,
        title: l10n.addonsLoadFailed,
        message: error.toString(),
        action: FilledButton.tonal(
          onPressed: () => controller.load(forceRefresh: true),
          child: Text(l10n.versionsRetry),
        ),
      );
    } else if (loaded && addons.isEmpty) {
      body = EmptyState(
        icon: Icons.extension_outlined,
        title: l10n.addonsCatalogEmptyTitle,
        message: l10n.addonsCatalogEmptyMessage,
        action: FilledButton.tonal(
          onPressed: () => controller.load(forceRefresh: true),
          child: Text(l10n.addonsRefresh),
        ),
      );
    } else if (filtered.isEmpty) {
      body = Center(child: Text(l10n.addonsFilteredEmpty));
    } else {
      body = GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 380,
          mainAxisExtent: 170,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final addon = filtered[index];
          return _AddonCard(
            addon: addon,
            installedCount: installedCounts[addon.id] ?? 0,
            onTap: () => onOpen(addon),
          );
        },
      );
    }

    return Column(
      children: [
        if (freshness == CatalogFreshness.stale)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.addonsStale)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => controller.query.value = value,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.addonsSearchHint,
                    isDense: true,
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: l10n.addonsClearSearch,
                            onPressed: () {
                              searchController.clear();
                              controller.query.value = '';
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const _FilterMenu(),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.addonsRefresh,
                onPressed: loading ? null : () => controller.load(forceRefresh: true),
              ),
            ],
          ),
        ),
        if (versions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _CompactDropdown<String?>(
                  value: freecadFilter,
                  hint: Text(l10n.addonsFilterFreecad),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.addonsFilterAnyVersion),
                    ),
                    for (final version in versions)
                      DropdownMenuItem(value: version, child: Text(version)),
                  ],
                  onChanged: controller.setFreecadFilter,
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(child: body),
      ],
    );
  }
}

class _AddonCard extends StatelessWidget {
  const _AddonCard({
    required this.addon,
    required this.installedCount,
    required this.onTap,
  });

  final Addon addon;
  final int installedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AddonIcon(
                    base64Data: addon.primaryBranch.metadata?.iconBase64,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon.displayName,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (addon.version.isNotEmpty)
                          Text(
                            'v${addon.version}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (installedCount > 0)
                    Chip(
                      label: Text(l10n.addonsInstalledBadge),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  addon.description,
                  style: theme.textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (addon.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: [
                    for (final tag in addon.tags.take(3))
                      Chip(
                        label: Text(tag, style: theme.textTheme.labelSmall),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddonDetailView extends StatelessWidget {
  const AddonDetailView({super.key, required this.addonId, required this.onBack});

  final String addonId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).addons;
    final addon = controller.byId(addonId);
    if (addon == null) {
      return Column(
        children: [
          _DetailHeader(title: l10n.addonsTabCatalog, onBack: onBack),
          Expanded(
            child: EmptyState(
              icon: Icons.error_outline,
              title: l10n.addonsLoadFailed,
              message: l10n.addonsFilteredEmpty,
            ),
          ),
        ],
      );
    }

    final installedCount = controller.installedCounts.watch(context)[addon.id] ?? 0;
    final selectedRef = controller.branchRefFor(addon);
    final metadata = addon.primaryBranch.metadata;

    return Column(
      children: [
        _DetailHeader(title: addon.displayName, onBack: onBack),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AddonIcon(base64Data: metadata?.iconBase64, size: 56),
                  const SizedBox(width: 16),
                  Expanded(child: Text(addon.description)),
                ],
              ),
              if (installedCount > 0) ...[
                const SizedBox(height: 8),
                Chip(label: Text(l10n.addonsInstalledIn(installedCount))),
              ],
              const SizedBox(height: 16),
              _InfoCard(
                title: l10n.addonsVersion,
                rows: [
                  _InfoRow(l10n.addonsVersion, addon.version),
                  _InfoRow(l10n.addonsLicense, addon.license ?? l10n.addonsNone),
                  _InfoRow(l10n.addonsAuthors, _authors(metadata)),
                  _InfoRow(l10n.addonsFreecadRange, _range(addon)),
                  _InfoRow(l10n.addonsLastUpdate, _lastUpdate(addon)),
                  _InfoRow(
                    l10n.addonsContent,
                    addon.content.map((content) => _contentLabel(l10n, content)).join(', '),
                  ),
                  _InfoRow(
                    l10n.addonsTags,
                    addon.tags.isEmpty ? l10n.addonsNone : addon.tags.join(', '),
                  ),
                  _InfoRow(
                    l10n.addonsRequirements,
                    addon.hasRequirements
                        ? l10n.addonsRequirementsYes
                        : l10n.addonsRequirementsNo,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l10n.addonsRepository,
                rows: [_InfoRow(l10n.addonsRepository, addon.primaryBranch.repositoryUrl)],
                trailing: TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(addon.primaryBranch.repositoryUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l10n.addonsOpenRepository),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addonsBranches,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      RadioGroup<String>(
                        groupValue: selectedRef,
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectBranch(addon.id, value);
                          }
                        },
                        child: Column(
                          children: [
                            for (final branch in addon.branches)
                              RadioListTile<String>(
                                value: branch.gitRef,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(branch.displayName),
                                subtitle: Text(branch.gitRef),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.download_outlined),
                        label: Text(l10n.addonsInstall),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.addonsInstallSoon,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _authors(AddonMetadata? metadata) {
    if (metadata == null || metadata.people.isEmpty) {
      return '';
    }
    return metadata.people
        .map(
          (person) => person.roles.isEmpty
              ? person.name
              : '${person.name} (${person.roles.join(', ')})',
        )
        .join(', ');
  }

  String _range(Addon addon) {
    final min = addon.primaryBranch.freecadMin;
    final max = addon.primaryBranch.freecadMax;
    if (min == null && max == null) {
      return '';
    }
    return '${min ?? '…'} – ${max ?? '…'}';
  }

  String _lastUpdate(Addon addon) {
    final date = addon.primaryBranch.lastUpdateTime;
    if (date == null) {
      return '';
    }
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.addonsBack,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows, this.trailing});

  final String title;
  final List<_InfoRow> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final row in rows) row,
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: value.isEmpty
                ? const SizedBox.shrink()
                : SelectableText(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

String _contentLabel(AppLocalizations l10n, AddonContentType content) {
  return switch (content) {
    AddonContentType.workbench => l10n.addonsContentWorkbench,
    AddonContentType.macro => l10n.addonsContentMacro,
    AddonContentType.preferencePack => l10n.addonsContentPreferencePack,
    AddonContentType.bundle => l10n.addonsContentBundle,
    AddonContentType.other => l10n.addonsContentOther,
  };
}

class _CompactDropdown<T> extends StatelessWidget {
  const _CompactDropdown({
    required this.value,
    this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final Widget? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint,
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).addons;
    final contents = controller.contentFilter.watch(context);
    final installed = controller.installedFilter.watch(context);
    final activeCount = contents.length + installed.length;

    return MenuAnchor(
      builder: (context, menuController, child) => IconButton(
        tooltip: l10n.addonsFilters,
        icon: Badge(
          isLabelVisible: activeCount > 0,
          label: Text('$activeCount'),
          child: const Icon(Icons.menu),
        ),
        onPressed: () =>
            menuController.isOpen ? menuController.close() : menuController.open(),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            l10n.addonsFilterContent,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        for (final content in AddonContentType.values)
          MenuItemButton(
            closeOnActivate: false,
            leadingIcon: _menuCheckbox(contents.contains(content)),
            onPressed: () => controller.toggleContentFilter(content),
            child: Text(_contentLabel(l10n, content)),
          ),
        const Divider(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Text(
            l10n.addonsFilterInstalledState,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        for (final filter in AddonInstalledFilter.values)
          MenuItemButton(
            closeOnActivate: false,
            leadingIcon: _menuCheckbox(installed.contains(filter)),
            onPressed: () => controller.toggleInstalledFilter(filter),
            child: Text(
              filter == AddonInstalledFilter.installed
                  ? l10n.addonsFilterInstalled
                  : l10n.addonsFilterNotInstalled,
            ),
          ),
        const Divider(height: 12),
        MenuItemButton(
          leadingIcon: const Icon(Icons.clear_all, size: 18),
          onPressed: controller.clearFilters,
          child: Text(l10n.addonsFilterClear),
        ),
      ],
    );
  }

  Widget _menuCheckbox(bool checked) {
    return IgnorePointer(
      child: Checkbox(
        value: checked,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: (_) {},
      ),
    );
  }
}
