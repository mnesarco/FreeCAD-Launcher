// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
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

class ProfilesView extends StatefulWidget {
  const ProfilesView({super.key});

  @override
  State<ProfilesView> createState() => ProfilesViewState();
}

class ProfilesViewState extends State<ProfilesView> implements SectionShortcuts {
  bool _started = false;
  String? _selectedProfileId;

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
    final profiles = controller.profiles.watch(context);
    final loaded = controller.profilesLoaded.watch(context);
    final error = controller.profilesError.watch(context);

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
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: profiles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return _ProfileCard(
            profile: profile,
            onOpen: () => setState(() => _selectedProfileId = profile.id),
          );
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.navProfiles,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Future<void> _createProfile(BuildContext context) async {
    await showProfileFormDialog(context, controller: AppScope.of(context).profiles);
  }

  @override
  void refresh() {
    final controller = AppScope.of(context).profiles;
    controller.start();
    unawaited(controller.refreshSizes());
  }

  @override
  void focusSearch() {}

  void createProfile() => unawaited(_createProfile(context));

  Future<void> _importProfile(BuildContext context) async {
    final outcome = await importProfileManifest(context);
    if (outcome == null || !mounted) {
      return;
    }
    setState(() => _selectedProfileId = outcome.profile.id);
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onOpen});

  final Profile profile;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).profiles;
    final builds = controller.buildsById.watch(context);
    final build = builds[profile.buildId];
    final running = controller.runningProfiles.watch(context).contains(profile.id);
    final addons = controller.addonCounts.watch(context)[profile.id] ?? 0;
    final updatesOutdated =
        AppScope.of(context).updates.outdatedByProfile.watch(context)[profile.id]?.length ?? 0;
    final packages = controller.packageCounts.watch(context)[profile.id] ?? 0;
    final size = controller.profileSizes.watch(context)[profile.id];

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

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onOpen,
        leading: Icon(
          Icons.workspaces,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Row(
          children: [
            Flexible(child: Text(profile.name, overflow: TextOverflow.ellipsis)),
            if (running) ...[
              const SizedBox(width: 8),
              CompactBadge(icon: Icons.play_arrow, label: l10n.profilesRunning),
            ],
            if (build != null && build.status != BuildStatus.installed) ...[
              const SizedBox(width: 8),
              CompactBadge(
                icon: Icons.warning_amber_outlined,
                label: build.status == BuildStatus.missing
                    ? l10n.profilesStatusMissing
                    : l10n.profilesStatusBroken,
              ),
            ],
            if (updatesOutdated > 0) ...[
              const SizedBox(width: 8),
              CompactBadge(
                icon: Icons.system_update_alt,
                label: l10n.updatesBadge(updatesOutdated),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(versionLine, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(detailLine, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonal(
              onPressed: () => launchProfile(context, profile),
              child: Text(l10n.profilesLaunch),
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
                PopupMenuItem(
                  value: _ProfileAction.delete,
                  child: Text(l10n.profilesDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, _ProfileAction action) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).profiles;
    switch (action) {
      case _ProfileAction.duplicate:
        final input = await showDuplicateProfileDialog(
          context,
          initialName: profile.name,
        );
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
          (error) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.profilesDuplicateFailed}: $error')),
          ),
        );
      case _ProfileAction.export:
        await exportProfileManifest(
          context,
          profileId: profile.id,
          profileName: profile.name,
        );
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
          (error) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.profilesDeleteFailed}: $error')),
          ),
        );
    }
  }
}

enum _ProfileAction { duplicate, export, delete }
