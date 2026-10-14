// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/format.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/profiles/profile_actions.dart';
import 'package:freecad_launcher/ui/profiles/profile_detail_view.dart';
import 'package:freecad_launcher/ui/profiles/profile_dialogs.dart';
import 'package:freecad_launcher/ui/profiles/profile_manifest_dialogs.dart';
import 'package:freecad_launcher/ui/shell/section_shortcuts.dart';
import 'package:freecad_launcher/ui/widgets/compact_badge.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

const double _compactLayoutWidth = 440;

class ProfilesView extends SignalStatefulWidget {
  const ProfilesView({super.key});

  @override
  State<ProfilesView> createState() => ProfilesViewState();
}

class ProfilesViewState extends State<ProfilesView> implements SectionShortcuts {
  bool _started = false;
  String? _selectedProfileId;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _gridScrollController = ScrollController();

  @override
  void dispose() {
    _gridScrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      AppScope.of(context).profiles.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).profiles;
    final profiles = controller.profiles.value;
    final loaded = controller.profilesLoaded.value;
    final error = controller.profilesError.value;
    final query = _searchController.text;
    final normalizedQuery = query.trim().toLowerCase();
    final visibleProfiles = normalizedQuery.isEmpty
        ? profiles
        : profiles
              .where((profile) => profile.name.toLowerCase().contains(normalizedQuery))
              .toList();

    final selectedId = _selectedProfileId;
    if (selectedId != null && profiles.any((profile) => profile.id == selectedId)) {
      return ProfileDetailView(
        profileId: selectedId,
        onBack: () => setState(() => _selectedProfileId = null),
      );
    }

    Widget body;
    if (error != null) {
      body = EmptyState(
        icon: Icons.error_outline,
        title: l10n.profilesLoadFailed,
        message: error.toString(),
      );
    } else if (!loaded) {
      body = const Center(child: CircularProgressIndicator());
    } else if (profiles.isEmpty) {
      body = EmptyState(
        icon: Icons.workspaces_outline,
        title: l10n.profilesEmptyTitle,
        message: l10n.profilesEmptyMessage,
        action: FilledButton.icon(
          onPressed: () => _createProfile(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.profilesNew),
        ),
      );
    } else if (visibleProfiles.isEmpty) {
      body = Center(child: Text(l10n.profilesNoMatches));
    } else {
      body = ReorderableBuilder.builder(
        itemCount: visibleProfiles.length,
        scrollController: _gridScrollController,
        enableDraggable: normalizedQuery.isEmpty,
        onReorder: (ReorderedListFunction<Profile> reorderedListFunction) {
          unawaited(_persistOrder(reorderedListFunction(controller.profiles.value)));
        },
        childBuilder: (itemBuilder) => GridView.builder(
          controller: _gridScrollController,
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 380,
            mainAxisExtent: 170,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: visibleProfiles.length,
          itemBuilder: (context, index) {
            final profile = visibleProfiles[index];
            return itemBuilder(
              _ProfileCard(
                key: ValueKey(profile.id),
                profile: profile,
                onOpen: () => setState(() => _selectedProfileId = profile.id),
              ),
              index,
            );
          },
        ),
      );
    }

    final showSearch = error == null && loaded && profiles.isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < _compactLayoutWidth;
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.navProfiles,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (compact) ...[
                    IconButton(
                      onPressed: () => _importProfile(context),
                      icon: const Icon(Icons.file_open_outlined),
                      tooltip: l10n.profilesImport,
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _createProfile(context),
                      icon: const Icon(Icons.add),
                      tooltip: l10n.profilesNew,
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () => _importProfile(context),
                      icon: const Icon(Icons.file_open_outlined),
                      label: Text(l10n.profilesImport),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _createProfile(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.profilesNew),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        if (showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.profilesSearchHint,
                isDense: true,
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: l10n.profilesClearSearch,
                        onPressed: _clearSearch,
                      ),
              ),
            ),
          ),
        Expanded(child: body),
      ],
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  Future<void> _persistOrder(List<Profile> ordered) async {
    final l10n = AppLocalizations.of(context);
    final result = await AppScope.of(
      context,
    ).profiles.reorder([for (final profile in ordered) profile.id]);
    if (!mounted) {
      return;
    }
    result.fold(
      (_) {},
      (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.profilesReorderFailed}: $error'))),
    );
  }

  Future<void> _createProfile(BuildContext context) async {
    final profile = await showProfileFormDialog(context, controller: AppScope.of(context).profiles);
    if (profile == null || !mounted) {
      return;
    }
    setState(() => _selectedProfileId = profile.id);
  }

  @override
  void refresh() {
    final controller = AppScope.of(context).profiles;
    controller.start();
    unawaited(controller.refreshSizes());
  }

  @override
  void focusSearch() {
    final controller = AppScope.of(context).profiles;
    if (_selectedProfileId != null || controller.profiles.value.isEmpty) {
      return;
    }
    _searchFocusNode.requestFocus();
  }

  void createProfile() => unawaited(_createProfile(context));

  void openProfile(String profileId) {
    setState(() => _selectedProfileId = profileId);
  }

  Future<void> _importProfile(BuildContext context) async {
    final outcome = await importProfileManifest(context);
    if (outcome == null || !mounted) {
      return;
    }
    setState(() => _selectedProfileId = outcome.profile.id);
  }
}

class _ProfileCard extends SignalWidget {
  const _ProfileCard({super.key, required this.profile, required this.onOpen});

  final Profile profile;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).profiles;
    final builds = controller.buildsById.value;
    final build = builds[profile.buildId];
    final running = controller.runningProfiles.value.contains(profile.id);
    final addons = controller.addonCounts.value[profile.id] ?? 0;
    final updatesOutdated =
        AppScope.of(context).updates.outdatedByProfile.value[profile.id]?.length ?? 0;
    final packages = controller.packageCounts.value[profile.id] ?? 0;
    final size = controller.profileSizes.value[profile.id];

    final versionLine = [
      if (build != null) build.displayLabel,
      if (build != null) build.channel.name,
      '${l10n.profilesPythonVersion} ${profile.pythonVersion}',
    ].join('  ·  ');

    final detailLine = [
      '${l10n.profilesAddons}: $addons',
      '${l10n.profilesPackages}: $packages',
      if (size != null) '${l10n.profilesSize}: ${formatBytes(size)}',
      '${l10n.profilesLastUsed}: ${formatProfileDateTime(l10n, profile.lastUsedAt)}',
    ].join('  ·  ');

    final badges = <Widget>[
      if (running)
        CompactBadge(
          icon: Icons.play_arrow,
          label: l10n.profilesRunning,
          tone: CompactBadgeTone.running,
        ),
      if (build != null && build.status != BuildStatus.installed)
        CompactBadge(
          icon: Icons.warning_amber_outlined,
          label: build.status == BuildStatus.missing
              ? l10n.profilesStatusMissing
              : l10n.profilesStatusBroken,
          tone: CompactBadgeTone.danger,
        ),
      if (updatesOutdated > 0)
        CompactBadge(
          icon: Icons.system_update_alt,
          label: l10n.updatesBadge(updatesOutdated),
          tone: CompactBadgeTone.info,
        ),
    ];
    final visibleBadges = badges.length <= 2
        ? badges
        : [badges.first, CompactBadge(label: l10n.profilesMoreBadges(badges.length - 1))];

    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.workspaces, size: 36, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          versionLine,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_ProfileAction>(
                    onSelected: (action) => _handleAction(context, action),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _ProfileAction.duplicate,
                        child: Text(l10n.profilesDuplicate),
                      ),
                      PopupMenuItem(
                        value: _ProfileAction.export,
                        child: Text(l10n.profilesExportManifest),
                      ),
                      PopupMenuItem(value: _ProfileAction.delete, child: Text(l10n.profilesDelete)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  detailLine,
                  style: theme.textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Wrap(spacing: 4, runSpacing: 4, children: visibleBadges)),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => launchProfile(context, profile),
                    icon: const Icon(Icons.play_arrow),
                    tooltip: l10n.profilesLaunch,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, _ProfileAction action) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).profiles;
    switch (action) {
      case _ProfileAction.duplicate:
        final input = await showDuplicateProfileDialog(context, initialName: profile.name);
        if (input == null || !context.mounted) {
          return;
        }
        final result = await controller.duplicate(
          profileId: profile.id,
          name: input.name,
          copyPayload: input.copyPayload,
        );
        if (!context.mounted) {
          return;
        }
        result.fold(
          (_) {},
          (error) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${l10n.profilesDuplicateFailed}: $error'))),
        );
      case _ProfileAction.export:
        await exportProfileManifest(context, profileId: profile.id, profileName: profile.name);
      case _ProfileAction.delete:
        final confirmed = await confirmDeleteProfile(context, profile);
        if (!confirmed || !context.mounted) {
          return;
        }
        final result = await controller.delete(profile.id);
        if (!context.mounted) {
          return;
        }
        result.fold(
          (_) {},
          (error) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${l10n.profilesDeleteFailed}: $error'))),
        );
    }
  }
}

enum _ProfileAction { duplicate, export, delete }
