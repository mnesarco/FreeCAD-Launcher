import 'dart:io';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/format.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/profiles/launch_command_dialog.dart';
import 'package:freecad_launcher/ui/profiles/profile_actions.dart';
import 'package:freecad_launcher/ui/profiles/profile_dialogs.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

class ProfileDetailView extends StatelessWidget {
  const ProfileDetailView({super.key, required this.profileId, required this.onBack});

  final String profileId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final controller = services.profiles;
    final profiles = controller.profiles.watch(context);

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
    final running = controller.runningProfiles.watch(context).contains(current.id);
    final build = controller.buildsById.watch(context)[current.buildId];

    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          _DetailHeader(
            title: current.name,
            onBack: onBack,
            running: running,
            onLaunch: () => launchProfile(context, current),
            onShowCommand: () => showLaunchCommandDialog(
              context,
              profileId: current.id,
            ),
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
                _ComingSoonTab(icon: Icons.extension_outlined, label: l10n.profilesTabAddons),
                _ComingSoonTab(icon: Icons.terminal_outlined, label: l10n.profilesTabPython),
                _ComingSoonTab(icon: Icons.auto_fix_high_outlined, label: l10n.profilesTabMacros),
                _ComingSoonTab(icon: Icons.tune_outlined, label: l10n.profilesTabConfig),
                _ComingSoonTab(icon: Icons.backup_outlined, label: l10n.profilesTabBackups),
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
    required this.onEdit,
  });

  final String title;
  final VoidCallback onBack;
  final bool running;
  final VoidCallback? onLaunch;
  final VoidCallback? onShowCommand;
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
            Chip(
              avatar: const Icon(Icons.play_arrow, size: 16),
              label: Text(l10n.profilesRunning),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
          ],
          if (onShowCommand != null)
            IconButton(
              icon: const Icon(Icons.terminal_outlined),
              tooltip: l10n.profilesShowCommand,
              onPressed: onShowCommand,
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

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.profile, required this.buildInfo});

  final Profile profile;
  final Build? buildInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final paths = services.paths.profilePaths(profile.id);
    final launchLog = services.profiles.launchLogs.watch(context)[profile.id];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: l10n.profilesBuild,
          children: [
            _InfoRow(label: l10n.profilesBuild, value: buildInfo?.version ?? '—'),
            if (buildInfo != null)
              _InfoRow(label: l10n.profilesChannel, value: buildInfo!.channel.name),
            _InfoRow(label: l10n.profilesPythonVersion, value: profile.pythonVersion),
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
            _InfoRow(label: l10n.profilesProfileHome, value: paths.root, selectable: true),
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
            _InfoRow(label: 'user.cfg', value: _fileStatus(paths.userCfg, l10n)),
            _InfoRow(label: 'system.cfg', value: _fileStatus(paths.systemCfg, l10n)),
          ],
        ),
        if (launchLog != null) ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: l10n.profilesRunning,
            children: [
              _InfoRow(
                label: 'log',
                value: '$launchLog${_logSize(launchLog)}',
                selectable: true,
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

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: icon,
      title: label,
      message: l10n.profilesComingSoon,
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
  const _InfoRow({required this.label, required this.value, this.selectable = false});

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
                : Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
