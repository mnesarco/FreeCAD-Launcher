import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/format.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/config_snapshots.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/profiles/profile_manifest_dialogs.dart';

class ProfileConfigTab extends StatefulWidget {
  const ProfileConfigTab({super.key, required this.profileId});

  final String profileId;

  @override
  State<ProfileConfigTab> createState() => _ProfileConfigTabState();
}

class _ProfileConfigTabState extends State<ProfileConfigTab> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      AppScope.of(context).profiles.refreshConfigSnapshots(widget.profileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final paths = services.paths.profilePaths(widget.profileId);
    final snapshots =
        services.profiles.configSnapshots.watch(context)[widget.profileId] ?? const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.profilesPaths, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _PathRow(label: l10n.profilesProfileHome, value: paths.root),
                _PathRow(label: 'user.cfg', value: _fileStatus(paths.userCfg, l10n)),
                _PathRow(label: 'system.cfg', value: _fileStatus(paths.systemCfg, l10n)),
                _PathRow(label: 'backups', value: paths.backups),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => unawaited(_openFolder(context, paths.root)),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text(l10n.profilesConfigOpenFolder),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.icon(
              onPressed: () => _create(context),
              icon: const Icon(Icons.backup_outlined),
              label: Text(l10n.profilesConfigBackup),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SnapshotsCard(profileId: widget.profileId, snapshots: snapshots),
      ],
    );
  }

  Future<void> _create(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await AppScope.of(context).profiles.createConfigSnapshot(widget.profileId);
    if (!context.mounted) {
      return;
    }
    result.fold(
      (snapshot) => messenger.showSnackBar(
        SnackBar(
          content: Text(
            snapshot == null ? l10n.profilesConfigNothing : l10n.profilesConfigBackupDone,
          ),
        ),
      ),
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.profilesConfigFailed}: $error')),
      ),
    );
  }

  Future<void> _openFolder(BuildContext context, String path) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppScope.of(context).fileActions.openDirectory(path);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.profilesConfigOpenFailed}: $error')),
      );
    }
  }

  String _fileStatus(String path, AppLocalizations l10n) {
    final file = File(path);
    if (!file.existsSync()) {
      return l10n.profilesConfigMissing;
    }
    return formatBytes(file.lengthSync());
  }
}

class ProfileBackupsTab extends StatefulWidget {
  const ProfileBackupsTab({super.key, required this.profileId});

  final String profileId;

  @override
  State<ProfileBackupsTab> createState() => _ProfileBackupsTabState();
}

class _ProfileBackupsTabState extends State<ProfileBackupsTab> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      AppScope.of(context).profiles.refreshConfigSnapshots(widget.profileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final snapshots =
        services.profiles.configSnapshots.watch(context)[widget.profileId] ?? const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _export(context),
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(l10n.profilesExportManifest),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => importProfileManifest(context),
              icon: const Icon(Icons.file_open_outlined),
              label: Text(l10n.profilesImport),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SnapshotsCard(profileId: widget.profileId, snapshots: snapshots),
      ],
    );
  }

  Future<void> _export(BuildContext context) async {
    final services = AppScope.of(context);
    final profile = await services.profiles.getById(widget.profileId);
    if (profile == null || !context.mounted) {
      return;
    }
    await exportProfileManifest(
      context,
      profileId: profile.id,
      profileName: profile.name,
    );
  }
}

class _SnapshotsCard extends StatelessWidget {
  const _SnapshotsCard({required this.profileId, required this.snapshots});

  final String profileId;
  final List<ConfigSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profilesConfigSnapshots, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (snapshots.isEmpty)
              Text(l10n.profilesConfigSnapshotsEmpty, style: theme.textTheme.bodySmall)
            else
              for (final snapshot in snapshots)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.history),
                  title: Text(_formatDate(snapshot.createdAt)),
                  subtitle: Text(
                    '${snapshot.files.join(', ')}  ·  ${formatBytes(snapshot.sizeBytes)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.tonal(
                        onPressed: () => _restore(context, snapshot),
                        child: Text(l10n.profilesConfigRestore),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.profilesConfigDeleteSnapshot,
                        onPressed: () => _delete(context, snapshot),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context, ConfigSnapshot snapshot) async {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profilesConfigRestoreTitle),
        content: Text(l10n.profilesConfigRestoreMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.versionsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.profilesConfigRestore),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) {
      return;
    }
    final result = await services.profiles.restoreConfigSnapshot(profileId, snapshot);
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.profilesConfigRestored)),
      ),
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.profilesConfigFailed}: $error')),
      ),
    );
  }

  Future<void> _delete(BuildContext context, ConfigSnapshot snapshot) async {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profilesConfigDeleteSnapshot),
        content: Text(_formatDate(snapshot.createdAt)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.versionsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.bundlesDelete),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) {
      return;
    }
    final result = await services.profiles.deleteConfigSnapshot(profileId, snapshot);
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.profilesConfigSnapshotDeleted)),
      ),
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.profilesConfigFailed}: $error')),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({required this.label, required this.value});

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
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: SelectableText(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
