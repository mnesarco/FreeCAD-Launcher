// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freecad_launcher/data/catalog/releases_catalog.dart'
    show CatalogFreshness;
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/python/requirements_parser.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/addons/addon_icon.dart';
import 'package:freecad_launcher/ui/addons/collections_view.dart';
import 'package:freecad_launcher/ui/addons/custom_addons_view.dart';
import 'package:freecad_launcher/ui/addons/requirements_dialog.dart';
import 'package:freecad_launcher/ui/shell/section_shortcuts.dart';
import 'package:freecad_launcher/ui/widgets/compact_badge.dart';
import 'package:freecad_launcher/ui/widgets/compact_dropdown.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';
import 'package:freecad_launcher/ui/widgets/form_row.dart';

class AddonsView extends StatefulWidget {
  const AddonsView({super.key});

  @override
  State<AddonsView> createState() => AddonsViewState();
}

class AddonsViewState extends State<AddonsView>
    with SingleTickerProviderStateMixin
    implements SectionShortcuts {
  bool _started = false;
  String? _selectedAddonId;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final services = AppScope.of(context);
      services.addons.start();
      services.profiles.start();
      services.updates.start();
    }
  }

  @override
  void refresh() {
    unawaited(AppScope.of(context).addons.load(forceRefresh: true));
  }

  @override
  void focusSearch() {
    _tabs.animateTo(0);
    _searchFocusNode.requestFocus();
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
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.addonsTabCatalog),
            Tab(text: l10n.addonsTabCollections),
            Tab(text: l10n.addonsTabCustom),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _CatalogTab(
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                onOpen: (addon) => setState(() => _selectedAddonId = addon.id),
              ),
              const CollectionsTab(),
              const CustomAddonsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({
    required this.searchController,
    required this.searchFocusNode,
    required this.onOpen,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<Addon> onOpen;

  Future<void> _checkUpdates(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final count = await AppScope.of(context).updates.check();
    if (!context.mounted) {
      return;
    }
    final message = switch (count) {
      null => l10n.updatesCheckFailed,
      0 => l10n.updatesNone,
      final found => l10n.updatesBadge(found),
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
    final updates = AppScope.of(context).updates;
    final checking = updates.checking.watch(context);
    final outdatedByAddon = <String, int>{};
    for (final update in updates.outdated.watch(context)) {
      outdatedByAddon[update.addonId] =
          (outdatedByAddon[update.addonId] ?? 0) + 1;
    }

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
            updateCount: outdatedByAddon[addon.id] ?? 0,
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
                  focusNode: searchFocusNode,
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
              if (versions.isNotEmpty) ...[
                IntrinsicWidth(
                  child: CompactDropdown<String?>(
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
                ),
                const SizedBox(width: 8),
              ],
              const _FilterMenu(),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.system_update_alt),
                tooltip: l10n.updatesCheck,
                onPressed: checking ? null : () => _checkUpdates(context),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.addonsRefresh,
                onPressed: loading
                    ? null
                    : () => controller.load(forceRefresh: true),
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
    this.updateCount = 0,
    required this.onTap,
  });

  final Addon addon;
  final int installedCount;
  final int updateCount;
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
                  if (updateCount > 0)
                    CompactBadge(
                      icon: Icons.system_update_alt,
                      label: l10n.updatesBadge(updateCount),
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                    )
                  else if (installedCount > 0)
                    CompactBadge(label: l10n.addonsInstalledBadge),
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
                      CompactBadge(label: tag),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddonDetailView extends StatefulWidget {
  const AddonDetailView({
    super.key,
    required this.addonId,
    required this.onBack,
  });

  final String addonId;
  final VoidCallback onBack;

  @override
  State<AddonDetailView> createState() => _AddonDetailViewState();
}

class _AddonDetailViewState extends State<AddonDetailView> {
  String? _profileId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).addons;
    final catalog = controller.addons.watch(context);
    Addon? addon;
    for (final candidate in catalog) {
      if (candidate.id == widget.addonId) {
        addon = candidate;
        break;
      }
    }
    if (addon == null) {
      return Column(
        children: [
          _DetailHeader(title: l10n.addonsTabCatalog, onBack: widget.onBack),
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

    final profiles = AppScope.of(context).profiles.profiles.watch(context);
    var profileId = _profileId;
    if (profileId == null ||
        !profiles.any((profile) => profile.id == profileId)) {
      profileId = profiles.isEmpty ? null : profiles.first.id;
    }
    final currentAddon = addon;
    final selectedBranches = controller.selectedBranches.watch(context);
    final selectedRef =
        selectedBranches[currentAddon.id] ?? currentAddon.primaryBranch.gitRef;
    final metadata = currentAddon.primaryBranch.metadata;
    final installedRows = controller.installedAddons.watch(context);
    final installedCount =
        controller.installedCounts.watch(context)[currentAddon.id] ?? 0;
    final installing = controller.installing
        .watch(context)
        .contains(currentAddon.id);
    final installedInSelected =
        profileId != null &&
        installedRows.any(
          (row) => row.profileId == profileId && row.addonId == currentAddon.id,
        );
    final pinned =
        profileId != null && controller.isPinned(profileId, currentAddon.id);
    final updateAvailable =
        !pinned &&
        profileId != null &&
        controller.isUpdateAvailable(profileId, currentAddon.id);
    final installError = controller.installErrors.watch(
      context,
    )[currentAddon.id];
    final requirementsError = controller.requirementsErrors.watch(
      context,
    )[currentAddon.id];
    final canInstall = profileId != null && !installing && !installedInSelected;

    return Column(
      children: [
        _DetailHeader(title: currentAddon.displayName, onBack: widget.onBack),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AddonIcon(base64Data: metadata?.iconBase64, size: 56),
                  const SizedBox(width: 16),
                  Expanded(child: Text(currentAddon.description)),
                ],
              ),
              if (installedCount > 0) ...[
                const SizedBox(height: 8),
                CompactBadge(label: l10n.addonsInstalledIn(installedCount)),
              ],
              const SizedBox(height: 16),
              _InfoCard(
                title: l10n.addonsVersion,
                rows: [
                  _InfoRow(l10n.addonsVersion, currentAddon.version),
                  _InfoRow(
                    l10n.addonsLicense,
                    currentAddon.license ?? l10n.addonsNone,
                  ),
                  _InfoRow(l10n.addonsAuthors, _authors(metadata)),
                  _InfoRow(l10n.addonsFreecadRange, _range(addon)),
                  _InfoRow(l10n.addonsLastUpdate, _lastUpdate(addon)),
                  _InfoRow(
                    l10n.addonsContent,
                    currentAddon.content
                        .map((content) => _contentLabel(l10n, content))
                        .join(', '),
                  ),
                  _InfoRow(
                    l10n.addonsTags,
                    currentAddon.tags.isEmpty
                        ? l10n.addonsNone
                        : currentAddon.tags.join(', '),
                  ),
                  _InfoRow(
                    l10n.addonsRequirements,
                    currentAddon.hasRequirements
                        ? l10n.addonsRequirementsYes
                        : l10n.addonsRequirementsNo,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l10n.addonsRepository,
                rows: [
                  _InfoRow(
                    l10n.addonsRepository,
                    currentAddon.primaryBranch.repositoryUrl,
                  ),
                ],
                trailing: TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(currentAddon.primaryBranch.repositoryUrl),
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
                            controller.selectBranch(currentAddon.id, value);
                          }
                        },
                        child: Column(
                          children: [
                            for (final branch in currentAddon.branches)
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
                      if (profiles.isEmpty)
                        Text(
                          l10n.addonsNoProfiles,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else ...[
                        FormRow(
                          label: l10n.addonsInstallTarget,
                          field: FormDropdown<String>(
                            value: profileId,
                            items: [
                              for (final profile in profiles)
                                DropdownMenuItem(
                                  value: profile.id,
                                  child: Text(profile.name),
                                ),
                            ],
                            onChanged: installing
                                ? null
                                : (value) => setState(() => _profileId = value),
                          ),
                        ),
                        Row(
                          children: [
                            if (installedInSelected)
                              if (pinned)
                                CompactBadge(
                                  icon: Icons.push_pin,
                                  label: l10n.addonsPinned,
                                )
                              else if (updateAvailable)
                                FilledButton.icon(
                                  onPressed: installing
                                      ? null
                                      : () => _update(
                                          currentAddon,
                                          selectedRef,
                                          profileId!,
                                        ),
                                  icon: const Icon(Icons.upgrade_outlined),
                                  label: Text(l10n.addonsUpdate),
                                )
                              else
                                CompactBadge(label: l10n.addonsInstalledBadge)
                            else
                              FilledButton.icon(
                                onPressed: canInstall
                                    ? () => _install(
                                        currentAddon,
                                        selectedRef,
                                        profileId!,
                                      )
                                    : null,
                                icon: installing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.download_outlined),
                                label: Text(l10n.addonsInstall),
                              ),
                            if (installedInSelected) ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: installing
                                    ? null
                                    : () => _remove(currentAddon, profileId!),
                                icon: const Icon(Icons.delete_outline),
                                label: Text(l10n.addonsRemove),
                              ),
                            ],
                          ],
                        ),
                        if (installedInSelected && updateAvailable) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.addonsUpdateAvailable,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (installError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.addonsInstallFailed}: $installError',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                        if (requirementsError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.addonsRequirementsFailed}: $requirementsError',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                      ],
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

  Future<void> _install(Addon addon, String branchRef, String profileId) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).addons;
    final messenger = ScaffoldMessenger.of(context);

    final branch = controller.branchOf(addon, branchRef);
    var installRequirements = false;
    if (branch.hasRequirements) {
      final requirements = parseRequirements(
        branch.metadata?.requirements ?? '',
      );
      final choice = await showRequirementsConsentDialog(
        context,
        addonName: addon.displayName,
        requirements: requirements,
      );
      if (!mounted || choice == RequirementsChoice.cancel) {
        return;
      }
      installRequirements = choice == RequirementsChoice.installPackages;
    }

    final result = await controller.install(
      addonId: addon.id,
      branchRef: branchRef,
      profileId: profileId,
      installRequirements: installRequirements,
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.addonsInstalledMessage)),
      ),
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.addonsInstallFailed}: $error')),
      ),
    );
  }

  Future<void> _update(Addon addon, String branchRef, String profileId) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).addons;
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.update(
      addonId: addon.id,
      branchRef: branchRef,
      profileId: profileId,
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.addonsUpdatedMessage)),
      ),
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.addonsUpdateFailed}: $error')),
      ),
    );
  }

  Future<void> _remove(Addon addon, String profileId) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).addons;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addonsRemoveTitle),
        content: Text('${addon.displayName}\n\n${l10n.addonsRemoveMessage}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.versionsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.addonsRemove),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.remove(
      addonId: addon.id,
      profileId: profileId,
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.addonsRemovedMessage)),
      ),
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.addonsRemoveFailed}: $error')),
      ),
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
          child: const Icon(Icons.filter_list),
        ),
        onPressed: () => menuController.isOpen
            ? menuController.close()
            : menuController.open(),
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
