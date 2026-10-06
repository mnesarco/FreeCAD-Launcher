// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/format.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/addon_dependencies.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/addons/addon_icon.dart';
import 'package:freecad_launcher/ui/addons/addon_install_flow.dart';
import 'package:freecad_launcher/ui/addons/addon_picker_dialog.dart';
import 'package:freecad_launcher/ui/addons/addon_remove_flow.dart';
import 'package:freecad_launcher/ui/macros/installed_macros.dart';
import 'package:freecad_launcher/ui/profiles/config_snapshots_view.dart';
import 'package:freecad_launcher/ui/profiles/launch_command_dialog.dart';
import 'package:freecad_launcher/ui/profiles/profile_actions.dart';
import 'package:freecad_launcher/ui/profiles/profile_dialogs.dart';
import 'package:freecad_launcher/ui/widgets/compact_badge.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';
import 'package:freecad_launcher/ui/widgets/form_row.dart';

class ProfileDetailView extends SignalWidget {
  const ProfileDetailView({
    super.key,
    required this.profileId,
    required this.onBack,
  });

  final String profileId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final controller = services.profiles;
    final profiles = controller.profiles.value;

    Profile? profile;
    for (final candidate in profiles) {
      if (candidate.id == profileId) {
        profile = candidate;
        break;
      }
    }
    if (profile == null) {
      return Column(
        children: [
          _DetailHeader(
            title: l10n.navProfiles,
            onBack: onBack,
            running: false,
            onLaunch: null,
            onShowCommand: null,
            onOpenFolder: null,
            onEdit: null,
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.error_outline,
              title: l10n.profilesLoadFailed,
              message: l10n.profilesEmptyMessage,
            ),
          ),
        ],
      );
    }

    final current = profile;
    final running = controller.runningProfiles.value.contains(current.id);
    final build = controller.buildsById.value[current.buildId];

    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          _DetailHeader(
            title: current.name,
            onBack: onBack,
            running: running,
            onLaunch: () => launchProfile(context, current),
            onShowCommand: () =>
                showLaunchCommandDialog(context, profileId: current.id),
            onOpenFolder: () =>
                unawaited(openProfileFolder(context, current.id)),
            onEdit: () => showProfileFormDialog(
              context,
              controller: controller,
              profile: current,
            ),
          ),
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.profilesTabOverview),
              Tab(text: l10n.profilesTabAddons),
              Tab(text: l10n.profilesTabPython),
              Tab(text: l10n.profilesTabMacros),
              Tab(text: l10n.profilesTabConfig),
              Tab(text: l10n.profilesTabBackups),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OverviewTab(profile: current, buildInfo: build),
                _ProfileAddonsTab(profileId: current.id),
                _ProfilePythonTab(profileId: current.id),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InstalledMacrosList(profileId: current.id),
                ),
                ProfileConfigTab(profileId: current.id),
                ProfileBackupsTab(profileId: current.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.title,
    required this.onBack,
    required this.running,
    required this.onLaunch,
    required this.onShowCommand,
    required this.onOpenFolder,
    required this.onEdit,
  });

  final String title;
  final VoidCallback onBack;
  final bool running;
  final VoidCallback? onLaunch;
  final VoidCallback? onShowCommand;
  final VoidCallback? onOpenFolder;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.profilesBack,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (running) ...[
            CompactBadge(
              icon: Icons.play_arrow,
              label: l10n.profilesRunning,
              tone: CompactBadgeTone.running,
            ),
            const SizedBox(width: 8),
          ],
          if (onShowCommand != null)
            IconButton(
              icon: const Icon(Icons.terminal_outlined),
              tooltip: l10n.profilesShowCommand,
              onPressed: onShowCommand,
            ),
          if (onOpenFolder != null)
            IconButton(
              icon: const Icon(Icons.folder_open_outlined),
              tooltip: l10n.profilesConfigOpenFolder,
              onPressed: onOpenFolder,
            ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.profilesEditTitle,
              onPressed: onEdit,
            ),
          if (onLaunch != null)
            FilledButton.icon(
              onPressed: onLaunch,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.profilesLaunch),
            ),
        ],
      ),
    );
  }
}

class _OverviewTab extends SignalWidget {
  const _OverviewTab({required this.profile, required this.buildInfo});

  final Profile profile;
  final Build? buildInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final paths = services.paths.profilePaths(profile.id);
    final launchLog = services.profiles.launchLogs.value[profile.id];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: l10n.profilesBuild,
          children: [
            _InfoRow(
              label: l10n.profilesBuild,
              value: buildInfo?.displayLabel ?? '—',
            ),
            if (buildInfo != null)
              _InfoRow(
                label: l10n.profilesChannel,
                value: buildInfo!.channel.name,
              ),
            _InfoRow(
              label: l10n.profilesPythonVersion,
              value: profile.pythonVersion,
            ),
            if (buildInfo != null)
              _InfoRow(
                label: l10n.profilesHealth,
                value: switch (buildInfo!.status) {
                  BuildStatus.installed => l10n.diagnosticsStatusOk,
                  BuildStatus.missing => l10n.profilesStatusMissing,
                  BuildStatus.broken => l10n.profilesStatusBroken,
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: l10n.profilesPaths,
          children: [
            _InfoRow(
              label: l10n.profilesProfileHome,
              value: paths.root,
              selectable: true,
            ),
            _InfoRow(label: 'Mod', value: paths.mod, selectable: true),
            _InfoRow(
              label: l10n.profilesTabPython,
              value: paths.additionalPythonPackages,
              selectable: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: l10n.profilesConfigFiles,
          children: [
            _InfoRow(
              label: 'user.cfg',
              value: _fileStatus(paths.userCfg, l10n),
            ),
            _InfoRow(
              label: 'system.cfg',
              value: _fileStatus(paths.systemCfg, l10n),
            ),
          ],
        ),
        if (launchLog != null) ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: l10n.profilesRunning,
            children: [
              _InfoRow(
                label: l10n.jobsLog,
                value: '$launchLog${_logSize(launchLog)}',
                tooltip: l10n.profilesOpenLog,
                onTap: () => unawaited(openProfileLog(context, launchLog)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _fileStatus(String path, AppLocalizations l10n) {
    final file = File(path);
    if (!file.existsSync()) {
      return l10n.profilesConfigMissing;
    }
    return formatBytes(file.lengthSync());
  }

  String _logSize(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return '';
    }
    return '  ·  ${formatBytes(file.lengthSync())}';
  }
}

class _ProfileAddonsTab extends SignalStatefulWidget {
  const _ProfileAddonsTab({required this.profileId});

  final String profileId;

  @override
  State<_ProfileAddonsTab> createState() => _ProfileAddonsTabState();
}

class _ProfileAddonsTabState extends State<_ProfileAddonsTab> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final addons = AppScope.of(context).addons;
      addons.start();
      unawaited(addons.ensureCachedCatalog());
      unawaited(addons.refreshDisabledState());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).profiles;
    final installed = controller.installedAddons.value
        .where((addon) => addon.profileId == widget.profileId)
        .toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    final outdatedIds = {
      for (final update in AppScope.of(context).updates.outdated.value)
        if (update.profileId == widget.profileId) update.addonId,
    };
    final catalogById = {
      for (final addon in AppScope.of(context).addons.addons.value)
        addon.id: addon,
    };
    final addonsController = AppScope.of(context).addons;
    final disabledIds =
        addonsController.disabledAddons.value[widget.profileId] ?? const <String>{};

    final addAction = FilledButton.tonalIcon(
      onPressed: () => _addAddon(context),
      icon: const Icon(Icons.add),
      label: Text(l10n.addonsAdd),
    );

    return Column(
      children: [
        if (installed.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [const Spacer(), addAction]),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: installed.isEmpty
              ? EmptyState(
                  icon: Icons.extension_outlined,
                  title: l10n.addonsEmptyTitle,
                  message: l10n.addonsEmptyMessage,
                  action: addAction,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: installed.length,
                  itemBuilder: (context, index) {
                    final addon = installed[index];
                    final subtitle = [
                      if ((addon.version ?? '').isNotEmpty) 'v${addon.version}',
                      if ((addon.gitRef ?? '').isNotEmpty) addon.gitRef!,
                      formatProfileDateTime(l10n, addon.installedAt),
                    ].join('  ·  ');
                    final pinned = addon.pinnedAt != null;
                    final disabled = disabledIds.contains(addon.addonId);
                    final requirementsError = addonsController
                        .requirementsErrors
                        .value[requirementErrorKey(widget.profileId, addon.addonId)];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: AddonIcon(
                          base64Data: catalogById[addon.addonId]
                              ?.primaryBranch
                              .metadata
                              ?.iconBase64,
                          size: 40,
                        ),
                        title: Text(
                          addon.displayName,
                          style: disabled
                              ? TextStyle(color: Theme.of(context).disabledColor)
                              : null,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subtitle),
                            if (requirementsError != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${l10n.addonsRequirementsFailed}: $requirementsError',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (outdatedIds.contains(addon.addonId))
                              CompactBadge(
                                label: l10n.addonsUpdateBadge,
                                tone: CompactBadgeTone.info,
                              ),
                            if (pinned)
                              CompactBadge(
                                icon: Icons.push_pin,
                                label: l10n.addonsPinned,
                              ),
                            if (disabled)
                              CompactBadge(
                                icon: Icons.visibility_off_outlined,
                                label: l10n.addonsDisabledBadge,
                              ),
                            IconButton(
                              tooltip: pinned ? l10n.addonsUnpin : l10n.addonsPin,
                              icon: Icon(
                                pinned ? Icons.push_pin : Icons.push_pin_outlined,
                              ),
                              onPressed: () => _togglePin(context, addon),
                            ),
                            Tooltip(
                              message: disabled
                                  ? l10n.addonsEnable
                                  : l10n.addonsDisable,
                              child: Switch(
                                value: !disabled,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (_) =>
                                    _toggleDisabled(context, addon, disabled),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: l10n.addonsRemove,
                              onPressed: () => _remove(context, addon),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _addAddon(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final presentIds = services.profiles.installedAddons.value
        .where((addon) => addon.profileId == widget.profileId)
        .map((addon) => addon.addonId)
        .toSet();
    final addon = await showDialog<Addon>(
      context: context,
      builder: (context) => AddonPickerDialog(
        title: l10n.addonsAddTitle,
        actionLabel: l10n.addonsInstall,
        searchHint: l10n.addonsSearchHint,
        presentIds: presentIds,
      ),
    );
    if (addon == null || !context.mounted) {
      return;
    }
    await installAddonIntoProfile(
      context,
      addon: addon,
      branchRef: addon.primaryBranch.gitRef,
      profileId: widget.profileId,
    );
  }

  Future<void> _toggleDisabled(
    BuildContext context,
    InstalledAddon addon,
    bool disabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).addons;
    final result = await controller.setAddonDisabled(
      addonId: addon.addonId,
      profileId: addon.profileId,
      disabled: !disabled,
    );
    if (!context.mounted || result.isOk) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.addonsToggleDisabledFailed}: ${result.errorOrNull}'),
      ),
    );
  }

  Future<void> _togglePin(BuildContext context, InstalledAddon addon) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).addons;
    final result = addon.pinnedAt == null
        ? await controller.pin(
            addonId: addon.addonId,
            profileId: addon.profileId,
          )
        : await controller.unpin(
            addonId: addon.addonId,
            profileId: addon.profileId,
          );
    if (!context.mounted || result.isOk) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.addonsPinFailed}: ${result.errorOrNull}')),
    );
  }

  Future<void> _remove(BuildContext context, InstalledAddon addon) {
    return removeAddonFromProfile(
      context,
      addonId: addon.addonId,
      displayName: addon.displayName,
      profileId: widget.profileId,
    );
  }
}

class _ProfilePythonTab extends SignalStatefulWidget {
  const _ProfilePythonTab({required this.profileId});

  final String profileId;

  @override
  State<_ProfilePythonTab> createState() => _ProfilePythonTabState();
}

class _ProfilePythonTabState extends State<_ProfilePythonTab> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      AppScope.of(context).python.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).python;
    final installed = controller.packages.value
        .where((package) => package.profileId == widget.profileId)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final installing = controller.installing.value.contains(widget.profileId);
    final error = controller.errors.value[widget.profileId];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              if (error != null)
                Expanded(
                  child: Text(
                    '${l10n.pythonInstallFailed}: $error',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              else
                const Spacer(),
              FilledButton.tonalIcon(
                onPressed: installing ? null : () => _install(context),
                icon: installing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(l10n.pythonInstall),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: installed.isEmpty
              ? EmptyState(
                  icon: Icons.terminal_outlined,
                  title: l10n.pythonEmptyTitle,
                  message: l10n.pythonEmptyMessage,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: installed.length,
                  itemBuilder: (context, index) {
                    final package = installed[index];
                    final subtitle = [
                      if ((package.version ?? '').isNotEmpty)
                        'v${package.version}',
                      '${l10n.pythonSource}: ${package.source}',
                    ].join('  ·  ');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.terminal_outlined),
                        title: Text(package.name),
                        subtitle: Text(subtitle),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.pythonRemove,
                          onPressed: () => _uninstall(context, package.name),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _install(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).python;
    final specText = await showDialog<String>(
      context: context,
      builder: (context) => _PythonInstallDialog(l10n: l10n),
    );
    if (specText == null || specText.trim().isEmpty || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.install(
      profileId: widget.profileId,
      specText: specText,
    );
    if (!context.mounted) {
      return;
    }
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.pythonInstalledMessage)),
      ),
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.pythonInstallFailed}: $failure')),
      ),
    );
  }

  Future<void> _uninstall(BuildContext context, String packageName) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).python;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pythonRemoveTitle),
        content: Text('$packageName\n\n${l10n.pythonRemoveMessage}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.versionsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.pythonRemove),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.uninstall(
      profileId: widget.profileId,
      packageName: packageName,
    );
    if (!context.mounted) {
      return;
    }
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.pythonRemovedMessage)),
      ),
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.pythonRemoveFailed}: $error')),
      ),
    );
  }
}

class _PythonInstallDialog extends StatefulWidget {
  const _PythonInstallDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_PythonInstallDialog> createState() => _PythonInstallDialogState();
}

class _PythonInstallDialogState extends State<_PythonInstallDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.pythonInstallTitle),
      content: SizedBox(
        width: 480,
        child: FormRow(
          label: l10n.pythonPackagesLabel,
          padding: EdgeInsets.zero,
          field: FormTextField(
            controller: _controller,
            autofocus: true,
            maxLines: 5,
            minLines: 3,
            hintText: l10n.pythonSpecs,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.versionsCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.pythonInstall),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.selectable = false,
    this.onTap,
    this.tooltip,
  });

  final String label;
  final String value;
  final bool selectable;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onTap = this.onTap;
    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: onTap == null ? 2 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(value, style: theme.textTheme.bodySmall)
                : Text(
                    value,
                    style: onTap == null
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: theme.colorScheme.primary,
                          ),
                  ),
          ),
        ],
      ),
    );
    if (onTap == null) {
      return row;
    }
    return Tooltip(
      message: tooltip ?? value,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: row,
      ),
    );
  }
}
