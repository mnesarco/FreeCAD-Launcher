// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon_id_rules.dart';
import 'package:freecad_launcher/domain/addons/addon_source.dart';
import 'package:freecad_launcher/domain/addons/repository_archive.dart';
import 'package:freecad_launcher/domain/python/requirements_parser.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/addons/requirements_dialog.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';
import 'package:freecad_launcher/ui/widgets/form_row.dart';

class CustomAddonsTab extends SignalStatefulWidget {
  const CustomAddonsTab({super.key});

  @override
  State<CustomAddonsTab> createState() => _CustomAddonsTabState();
}

class _CustomAddonsTabState extends State<CustomAddonsTab> {
  final TextEditingController _repositoryController = TextEditingController();
  final TextEditingController _refController = TextEditingController(text: 'main');

  String? _profileId;
  XFile? _archive;
  String? _directoryPath;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repositoryController.addListener(_handleFormChanged);
    _refController.addListener(_handleFormChanged);
  }

  void _handleFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _repositoryController.removeListener(_handleFormChanged);
    _refController.removeListener(_handleFormChanged);
    _repositoryController.dispose();
    _refController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final profiles = services.profiles.profiles.value;
    var profileId = _profileId;
    if (profileId == null || !profiles.any((profile) => profile.id == profileId)) {
      profileId = profiles.isEmpty ? null : profiles.first.id;
    }
    final installed = services.addons.installedAddons.value
        .where((row) => addonSourceFromStorage(row.source).isCustom)
        .toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    final profileNames = {for (final profile in profiles) profile.id: profile.name};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (profiles.isEmpty)
          Text(l10n.addonsNoProfiles, style: Theme.of(context).textTheme.bodyMedium)
        else
          FormRow(
            label: l10n.addonsInstallTarget,
            icon: Icons.person_outline,
            field: FormDropdown<String>(
              value: profileId,
              items: [
                for (final profile in profiles)
                  DropdownMenuItem(value: profile.id, child: Text(profile.name)),
              ],
              onChanged: _busy ? null : (value) => setState(() => _profileId = value),
            ),
          ),
        if (_error != null) ...[
          Text(
            _error!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
        ],
        _RepositoryCard(
          repositoryController: _repositoryController,
          refController: _refController,
          busy: _busy,
          enabled: profileId != null && !_busy,
          onInstall: profileId == null ? null : () => _installRepository(profileId!, l10n),
        ),
        const SizedBox(height: 12),
        _ArchiveCard(
          archive: _archive,
          busy: _busy,
          enabled: profileId != null && !_busy,
          onChoose: _chooseArchive,
          onInstall: profileId == null ? null : () => _installArchive(profileId!, l10n),
        ),
        const SizedBox(height: 12),
        _DirectoryCard(
          directoryPath: _directoryPath,
          busy: _busy,
          enabled: profileId != null && !_busy,
          onChoose: _chooseDirectory,
          onInstall: profileId == null ? null : () => _installDirectory(profileId!, l10n),
        ),
        const SizedBox(height: 12),
        _CustomInstallsCard(
          l10n: l10n,
          rows: installed,
          profileNames: profileNames,
          busy: _busy,
          onUpdate: (row) => _updateRepository(row, l10n),
          onReinstall: (row) => _reinstallArchive(row, l10n),
          onInstallInProfile: (row) => _installInProfile(row, l10n),
          onReveal: (row) => _revealTarget(row),
          onRemove: (row) => _remove(row, l10n),
        ),
      ],
    );
  }

  Future<void> _chooseArchive() async {
    const typeGroup = XTypeGroup(
      label: 'Addon archives',
      extensions: ['zip', 'tar.gz', 'tgz', 'tar'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      _archive = file;
      _error = null;
    });
  }

  Future<void> _chooseDirectory() async {
    final path = await getDirectoryPath();
    if (path == null || !mounted) {
      return;
    }
    setState(() {
      _directoryPath = path;
      _error = null;
    });
  }

  Future<void> _installRepository(String profileId, AppLocalizations l10n) {
    final url = _repositoryController.text;
    final name = addonIdFromRepositoryUrl(url) ?? l10n.addonsTabCustom;
    return _run(
      () => AppScope.of(context).addons.installFromRepository(
        repositoryUrl: url,
        gitRef: _refController.text,
        profileId: profileId,
        onRequirements: (requirements) => _askRequirements(requirements, name),
      ),
      l10n.addonsInstalledMessage,
    );
  }

  Future<void> _installArchive(String profileId, AppLocalizations l10n) {
    final archive = _archive;
    if (archive == null) {
      setState(() => _error = l10n.addonsCustomArchiveRequired);
      return Future.value();
    }
    final name = addonIdFromArchivePath(archive.path) ?? l10n.addonsTabCustom;
    return _run(
      () => AppScope.of(context).addons.installFromArchive(
        archivePath: archive.path,
        profileId: profileId,
        onRequirements: (requirements) => _askRequirements(requirements, name),
      ),
      l10n.addonsInstalledMessage,
    );
  }

  Future<void> _installDirectory(String profileId, AppLocalizations l10n) {
    final directoryPath = _directoryPath;
    if (directoryPath == null) {
      setState(() => _error = l10n.addonsCustomDirectoryRequired);
      return Future.value();
    }
    final name = addonIdFromDirectory(directoryPath);
    return _run(
      () => AppScope.of(context).addons.installFromDirectory(
        sourcePath: directoryPath,
        profileId: profileId,
        onRequirements: (requirements) => _askRequirements(requirements, name),
      ),
      l10n.addonsInstalledMessage,
    );
  }

  Future<void> _updateRepository(InstalledAddon row, AppLocalizations l10n) {
    return _run(
      () => AppScope.of(context).addons.updateFromRepository(
        addonId: row.addonId,
        profileId: row.profileId,
        onRequirements: (requirements) => _askRequirements(requirements, row.displayName),
      ),
      l10n.addonsUpdatedMessage,
    );
  }

  Future<void> _reinstallArchive(InstalledAddon row, AppLocalizations l10n) async {
    const typeGroup = XTypeGroup(
      label: 'Addon archives',
      extensions: ['zip', 'tar.gz', 'tgz', 'tar'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null || !mounted) {
      return;
    }
    return _run(
      () => AppScope.of(context).addons.reinstallFromArchive(
        addonId: row.addonId,
        profileId: row.profileId,
        archivePath: file.path,
        onRequirements: (requirements) => _askRequirements(requirements, row.displayName),
      ),
      l10n.addonsUpdatedMessage,
    );
  }

  Future<void> _installInProfile(InstalledAddon row, AppLocalizations l10n) async {
    final services = AppScope.of(context);
    final source = addonSourceFromStorage(row.source);
    String? archivePath;
    if (source == AddonSource.zip) {
      final stored = row.sourcePath;
      if (stored == null || !File(stored).existsSync()) {
        const typeGroup = XTypeGroup(
          label: 'Addon archives',
          extensions: ['zip', 'tar.gz', 'tgz', 'tar'],
        );
        final file = await openFile(acceptedTypeGroups: [typeGroup]);
        if (file == null || !mounted) {
          return;
        }
        archivePath = file.path;
      }
    }
    final candidates = services.profiles.profiles.value
        .where((profile) => !services.addons.isInstalledIn(profile.id, row.addonId))
        .toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addonsCustomAllProfiles)));
      return;
    }
    final target = await showDialog<Profile>(
      context: context,
      builder: (context) => _ProfilePickerDialog(
        title: l10n.addonsCustomInstallInProfileTitle(row.displayName),
        profiles: candidates,
      ),
    );
    if (target == null || !mounted) {
      return;
    }
    await _run(
      () => AppScope.of(context).addons.installCustomInProfile(
        addon: row,
        profileId: target.id,
        archivePath: archivePath,
        onRequirements: (requirements) => _askRequirements(requirements, row.displayName),
      ),
      l10n.addonsInstalledMessage,
    );
  }

  Future<void> _remove(InstalledAddon row, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addonsRemoveTitle),
        content: Text('${row.displayName}\n\n${l10n.addonsRemoveMessage}'),
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
    await _run(
      () => AppScope.of(context).addons.remove(addonId: row.addonId, profileId: row.profileId),
      l10n.addonsRemovedMessage,
    );
  }

  Future<void> _revealTarget(InstalledAddon row) async {
    final path = row.sourcePath;
    if (path == null) {
      return;
    }
    try {
      await AppScope.of(context).fileActions.openDirectory(path);
    } on Object {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addonsCustomRevealFailed)));
    }
  }

  Future<CustomRequirementsDecision> _askRequirements(
    List<PythonRequirement> requirements,
    String addonName,
  ) async {
    final choice = await showRequirementsConsentDialog(
      context,
      addonName: addonName,
      requirements: requirements,
    );
    return switch (choice) {
      RequirementsChoice.installPackages => CustomRequirementsDecision.installPackages,
      RequirementsChoice.addonOnly => CustomRequirementsDecision.addonOnly,
      RequirementsChoice.cancel => CustomRequirementsDecision.cancel,
    };
  }

  Future<void> _run(Future<Result<void>> Function() action, String successMessage) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await action();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage))),
      (error) => setState(() => _error = error.message),
    );
  }
}

class _RepositoryCard extends StatelessWidget {
  const _RepositoryCard({
    required this.repositoryController,
    required this.refController,
    required this.busy,
    required this.enabled,
    required this.onInstall,
  });

  final TextEditingController repositoryController;
  final TextEditingController refController;
  final bool busy;
  final bool enabled;
  final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resolution = resolveRepositoryArchive(repositoryController.text, refController.text);
    String? resolvedText;
    if (repositoryController.text.trim().isNotEmpty) {
      final uri = resolution.uri;
      resolvedText = uri == null
          ? _resolutionError(l10n, resolution.issue!)
          : l10n.addonsCustomRepoResolved(uri.toString());
    }
    return _SectionCard(
      title: l10n.addonsCustomRepoTitle,
      children: [
        FormRow(
          label: l10n.addonsCustomRepoUrl,
          icon: Icons.link,
          field: FormTextField(
            controller: repositoryController,
            hintText: l10n.addonsCustomRepoUrlHint,
            enabled: !busy,
          ),
        ),
        FormRow(
          label: l10n.addonsCustomRepoRef,
          icon: Icons.call_split,
          field: FormTextField(
            controller: refController,
            hintText: l10n.addonsCustomRepoRefHint,
            enabled: !busy,
          ),
        ),
        if (resolvedText != null)
          Padding(
            padding: const EdgeInsets.only(left: formLabelWidth + 12, bottom: 8),
            child: Text(
              resolvedText,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: enabled ? onInstall : null,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            label: Text(l10n.addonsInstall),
          ),
        ),
      ],
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({
    required this.archive,
    required this.busy,
    required this.enabled,
    required this.onChoose,
    required this.onInstall,
  });

  final XFile? archive;
  final bool busy;
  final bool enabled;
  final VoidCallback onChoose;
  final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.addonsCustomArchiveTitle,
      children: [
        FormRow(
          label: l10n.addonsCustomArchiveField,
          icon: Icons.folder_zip_outlined,
          field: Row(
            children: [
              Expanded(
                child: Text(
                  archive?.path ?? l10n.addonsCustomArchiveHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: busy ? null : onChoose,
                icon: const Icon(Icons.folder_open, size: 16),
                label: Text(l10n.addonsCustomArchiveChoose),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: enabled && archive != null ? onInstall : null,
            icon: const Icon(Icons.download_outlined),
            label: Text(l10n.addonsInstall),
          ),
        ),
      ],
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({
    required this.directoryPath,
    required this.busy,
    required this.enabled,
    required this.onChoose,
    required this.onInstall,
  });

  final String? directoryPath;
  final bool busy;
  final bool enabled;
  final VoidCallback onChoose;
  final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.addonsCustomDirectoryTitle,
      children: [
        FormRow(
          label: l10n.addonsCustomDirectoryField,
          icon: Icons.developer_mode,
          field: Row(
            children: [
              Expanded(
                child: Text(
                  directoryPath ?? l10n.addonsCustomDirectoryHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: busy ? null : onChoose,
                icon: const Icon(Icons.folder_open, size: 16),
                label: Text(l10n.addonsCustomDirectoryChoose),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: formLabelWidth + 12, bottom: 8),
          child: Text(
            l10n.addonsCustomDirectoryWarning,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: enabled && directoryPath != null ? onInstall : null,
            icon: const Icon(Icons.link),
            label: Text(l10n.addonsInstall),
          ),
        ),
      ],
    );
  }
}

class _CustomInstallsCard extends StatelessWidget {
  const _CustomInstallsCard({
    required this.l10n,
    required this.rows,
    required this.profileNames,
    required this.busy,
    required this.onUpdate,
    required this.onReinstall,
    required this.onInstallInProfile,
    required this.onReveal,
    required this.onRemove,
  });

  final AppLocalizations l10n;
  final List<InstalledAddon> rows;
  final Map<String, String> profileNames;
  final bool busy;
  final ValueChanged<InstalledAddon> onUpdate;
  final ValueChanged<InstalledAddon> onReinstall;
  final ValueChanged<InstalledAddon> onInstallInProfile;
  final ValueChanged<InstalledAddon> onReveal;
  final ValueChanged<InstalledAddon> onRemove;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return _SectionCard(
        title: l10n.addonsCustomInstalledTitle,
        children: [
          EmptyState(
            icon: Icons.extension_outlined,
            title: l10n.addonsCustomEmptyTitle,
            message: l10n.addonsCustomEmptyMessage,
          ),
        ],
      );
    }
    return _SectionCard(
      title: l10n.addonsCustomInstalledTitle,
      children: [for (final row in rows) _row(context, row)],
    );
  }

  Widget _row(BuildContext context, InstalledAddon row) {
    final source = addonSourceFromStorage(row.source);
    final subtitle = [
      if ((row.version ?? '').isNotEmpty) 'v${row.version}',
      switch (source) {
        AddonSource.repo => l10n.addonsCustomSourceRepo,
        AddonSource.zip => l10n.addonsCustomSourceArchive,
        AddonSource.symlink => l10n.addonsCustomSourceLink,
        AddonSource.catalog => '',
      },
      profileNames[row.profileId] ?? '',
    ].where((part) => part.isNotEmpty).join('  ·  ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.extension_outlined),
      title: Text(row.displayName),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (source.isUpdateableFromRepository)
            IconButton(
              tooltip: l10n.addonsUpdate,
              icon: const Icon(Icons.upgrade_outlined),
              onPressed: busy ? null : () => onUpdate(row),
            ),
          if (source == AddonSource.zip)
            IconButton(
              tooltip: l10n.addonsCustomReinstall,
              icon: const Icon(Icons.refresh),
              onPressed: busy ? null : () => onReinstall(row),
            ),
          if (source.isLiveLink)
            IconButton(
              tooltip: l10n.addonsCustomReveal,
              icon: const Icon(Icons.folder_open),
              onPressed: busy ? null : () => onReveal(row),
            ),
          IconButton(
            tooltip: l10n.addonsCustomInstallInProfile,
            icon: const Icon(Icons.playlist_add),
            onPressed: busy ? null : () => onInstallInProfile(row),
          ),
          IconButton(
            tooltip: l10n.addonsRemove,
            icon: const Icon(Icons.delete_outline),
            onPressed: busy ? null : () => onRemove(row),
          ),
        ],
      ),
    );
  }
}

class _ProfilePickerDialog extends StatefulWidget {
  const _ProfilePickerDialog({required this.title, required this.profiles});

  final String title;
  final List<Profile> profiles;

  @override
  State<_ProfilePickerDialog> createState() => _ProfilePickerDialogState();
}

class _ProfilePickerDialogState extends State<_ProfilePickerDialog> {
  String? _profileId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = _profileId ?? widget.profiles.first.id;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: FormRow(
          label: l10n.addonsInstallTarget,
          field: FormDropdown<String>(
            value: selected,
            items: [
              for (final profile in widget.profiles)
                DropdownMenuItem(value: profile.id, child: Text(profile.name)),
            ],
            onChanged: (value) => setState(() => _profileId = value),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.versionsCancel),
        ),
        FilledButton(
          onPressed: () {
            final target = widget.profiles.firstWhere(
              (profile) => profile.id == selected,
              orElse: () => widget.profiles.first,
            );
            Navigator.of(context).pop(target);
          },
          child: Text(l10n.addonsInstall),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

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
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

String _resolutionError(AppLocalizations l10n, ArchiveResolutionIssue issue) {
  return switch (issue) {
    ArchiveResolutionIssue.invalidUrl => l10n.addonsCustomInvalidUrl,
    ArchiveResolutionIssue.unsupportedScheme => l10n.addonsCustomUnsupportedScheme,
    ArchiveResolutionIssue.unsupportedHost => l10n.addonsCustomUnsupportedHost,
    ArchiveResolutionIssue.missingRef => l10n.addonsCustomMissingRef,
  };
}
