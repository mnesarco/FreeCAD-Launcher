import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/format.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/asset_classifier.dart';
import 'package:freecad_launcher/domain/builds/build_label_rules.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/builds/build_update.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/builds_controller.dart';
import 'package:freecad_launcher/ui/icons.dart';
import 'package:freecad_launcher/ui/shell/section_shortcuts.dart';
import 'package:freecad_launcher/ui/widgets/compact_badge.dart';
import 'package:freecad_launcher/ui/widgets/form_row.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

String _stageLabel(AppLocalizations l10n, InstallStage stage) {
  return switch (stage) {
    InstallStage.hashing => l10n.versionsHashing,
    InstallStage.downloading => l10n.versionsDownloading,
    InstallStage.installing => l10n.versionsInstalling,
    InstallStage.detectingPython => l10n.versionsDetectingPython,
  };
}

String _progressDetail(InstallProgress progress) {
  final parts = <String>[
    if (progress.receivedBytes != null && progress.totalBytes != null)
      '${formatBytes(progress.receivedBytes!)} / ${formatBytes(progress.totalBytes!)}'
    else if (progress.receivedBytes != null)
      formatBytes(progress.receivedBytes!),
    if (progress.bytesPerSecond != null && progress.bytesPerSecond! > 0)
      '${formatBytes(progress.bytesPerSecond!)}/s',
  ];
  return parts.join('  ·  ');
}

bool _isInPlace(Build build) {
  if (build.kind == BuildKind.custom) {
    return true;
  }
  return build.kind == BuildKind.appimage &&
      build.channel == BuildChannel.custom &&
      build.sourceUrl == null;
}

class BuildsView extends StatefulWidget {
  const BuildsView({super.key});

  @override
  State<BuildsView> createState() => BuildsViewState();
}

class BuildsViewState extends State<BuildsView> implements SectionShortcuts {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      AppScope.of(context).builds.start();
    }
  }

  @override
  void refresh() {
    unawaited(AppScope.of(context).builds.loadCatalog(forceRefresh: true));
  }

  @override
  void focusSearch() {}

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.versionsTabInstalled),
              Tab(text: l10n.versionsTabAvailable),
              Tab(text: l10n.versionsTabCustom),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const _InstalledTab(),
                const _AvailableTab(),
                const _CustomTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstalledTab extends StatelessWidget {
  const _InstalledTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).builds;
    final builds = controller.installedBuilds.watch(context);

    if (builds.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: l10n.versionsEmptyTitle,
        message: l10n.versionsEmptyMessage,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: builds.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          _InstalledBuildTile(buildInfo: builds[index]),
    );
  }
}

class _InstalledBuildTile extends StatelessWidget {
  const _InstalledBuildTile({required this.buildInfo});

  final Build buildInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).builds;
    final theme = Theme.of(context);
    BuildUpdate? buildUpdate;
    for (final update in AppScope.of(
      context,
    ).updates.outdatedBuilds.watch(context)) {
      if (update.buildId == buildInfo.id) {
        buildUpdate = update;
        break;
      }
    }

    final subtitle = [
      if (buildInfo.sizeBytes != null)
        '${l10n.versionsSize}: ${formatBytes(buildInfo.sizeBytes!)}',
      if (buildInfo.pythonVersion != null)
        '${l10n.versionsPython}: ${buildInfo.pythonVersion}',
      buildInfo.arch,
    ].join('  ·  ');

    return ListTile(
      leading: const Icon(FreeCADIcons.freecad),
      title: Row(
        children: [
          Text(buildInfo.displayLabel),
          const SizedBox(width: 8),
          CompactBadge(label: buildInfo.channel.name),
          if (buildInfo.status != BuildStatus.installed) ...[
            const SizedBox(width: 8),
            CompactBadge(
              icon: Icons.warning_amber_outlined,
              label: buildInfo.status == BuildStatus.missing
                  ? l10n.versionsStatusMissing
                  : l10n.versionsStatusBroken,
            ),
          ],
          if (buildUpdate != null) ...[
            const SizedBox(width: 8),
            CompactBadge(
              icon: Icons.system_update_alt,
              label:
                  '${buildUpdate.installedVersion} → ${buildUpdate.latestVersion}',
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          Text(
            buildInfo.localPath,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.versionsRelabel,
            onPressed: () => _relabel(context, controller, buildInfo),
          ),
          IconButton(
            icon: const Icon(Icons.verified_outlined),
            tooltip: l10n.versionsVerify,
            onPressed: () => _verify(context, controller, buildInfo),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.versionsRemove,
            onPressed: () => _confirmRemove(context, controller, buildInfo),
          ),
        ],
      ),
    );
  }

  Future<void> _verify(
    BuildContext context,
    BuildsController controller,
    Build build,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await controller.verify(build.id);
    if (!context.mounted) {
      return;
    }
    final message = result.fold(
      (status) => switch (status) {
        BuildStatus.installed => l10n.versionsVerifyOk,
        BuildStatus.missing => l10n.versionsVerifyMissing,
        BuildStatus.broken => l10n.versionsVerifyBroken,
      },
      (error) => error.toString(),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _relabel(
    BuildContext context,
    BuildsController controller,
    Build build,
  ) async {
    final l10n = AppLocalizations.of(context);
    final label = await showDialog<String>(
      context: context,
      builder: (context) => _RelabelDialog(build: build),
    );
    if (label == null || !context.mounted) {
      return;
    }
    final result = await controller.relabel(build.id, label);
    if (!context.mounted) {
      return;
    }
    final error = result.errorOrNull;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.versionsRelabelFailed}: $error')),
      );
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    BuildsController controller,
    Build build,
  ) async {
    final l10n = AppLocalizations.of(context);
    final message = _isInPlace(build)
        ? l10n.versionsRemoveMessageInPlace
        : l10n.versionsRemoveMessage;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.versionsRemoveTitle),
        content: Text('${build.displayLabel} — $message'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.versionsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.versionsRemoveConfirm),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) {
      return;
    }
    final result = await controller.remove(build.id);
    if (!context.mounted) {
      return;
    }
    final error = result.errorOrNull;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.versionsRemoveFailed}: $error')),
      );
    }
  }
}

class _RelabelDialog extends StatefulWidget {
  const _RelabelDialog({required this.build});

  final Build build;

  @override
  State<_RelabelDialog> createState() => _RelabelDialogState();
}

class _RelabelDialogState extends State<_RelabelDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.build.label ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final issue = validateBuildLabel(_controller.text);
    if (issue != null) {
      setState(() {
        _error = switch (issue) {
          BuildLabelIssue.tooLong => l10n.versionsRelabelTooLong(maxBuildLabelLength),
          BuildLabelIssue.controlCharacters => l10n.versionsRelabelInvalid,
        };
      });
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.versionsRelabelTitle),
      content: SizedBox(
        width: 480,
        child: FormRow(
          label: l10n.versionsRelabelField,
          field: FormTextField(
            controller: _controller,
            autofocus: true,
            hintText: l10n.versionsRelabelHint(widget.build.version),
            errorText: _error,
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.versionsCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.versionsRelabelSave),
        ),
      ],
    );
  }
}

class _AvailableTab extends StatefulWidget {
  const _AvailableTab();

  @override
  State<_AvailableTab> createState() => _AvailableTabState();
}

class _AvailableTabState extends State<_AvailableTab> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) {
      return;
    }
    final controller = AppScope.of(context).builds;
    if (controller.catalogFreshness.value != null ||
        controller.availableBuilds.value.isNotEmpty) {
      return;
    }
    _requested = true;
    unawaited(controller.loadCatalog());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).builds;
    final candidates = controller.availableBuilds.watch(context);
    final loading = controller.loadingCatalog.watch(context);
    final error = controller.catalogError.watch(context);
    final stale =
        controller.catalogFreshness.watch(context) == CatalogFreshness.stale;

    Widget body;
    if (error != null && candidates.isEmpty) {
      body = EmptyState(
        icon: Icons.cloud_off_outlined,
        title: l10n.versionsCatalogError,
        message: error.toString(),
        action: FilledButton.tonal(
          onPressed: () => controller.loadCatalog(forceRefresh: true),
          child: Text(l10n.versionsRetry),
        ),
      );
    } else if (loading && candidates.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (candidates.isEmpty) {
      body = EmptyState(
        icon: Icons.cloud_download_outlined,
        title: l10n.versionsAvailableEmptyTitle,
        message: l10n.versionsAvailableEmptyMessage,
        action: FilledButton.tonal(
          onPressed: () => controller.loadCatalog(forceRefresh: true),
          child: Text(l10n.versionsRefresh),
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: candidates.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) =>
            _AvailableBuildTile(candidate: candidates[index]),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              if (stale)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.versionsStaleCatalog)),
                    ],
                  ),
                )
              else
                const Spacer(),
              TextButton.icon(
                onPressed: loading
                    ? null
                    : () => controller.loadCatalog(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.versionsRefresh),
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _AvailableBuildTile extends StatelessWidget {
  const _AvailableBuildTile({required this.candidate});

  final BuildCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).builds;
    final progress = controller.installProgress.watch(context)[candidate.id];
    final installed = controller.isInstalled(candidate);
    final error = controller.installErrors.watch(context)[candidate.id];
    final theme = Theme.of(context);

    final subtitle = [
      '${l10n.versionsSize}: ${formatBytes(candidate.sizeBytes)}',
      if (candidate.pythonVersion != null)
        '${l10n.versionsPython}: ${candidate.pythonVersion}',
      candidate.assetName,
    ].join('  ·  ');
    final detail = progress == null ? '' : _progressDetail(progress);

    final Widget trailing;
    if (progress != null) {
      trailing = TextButton(
        onPressed: () => controller.cancelInstall(candidate),
        child: Text(l10n.versionsCancel),
      );
    } else if (installed) {
      trailing = CompactBadge(label: l10n.versionsTabInstalled);
    } else {
      trailing = FilledButton(
        onPressed: () => _install(context, controller, candidate),
        child: Text(l10n.versionsInstall),
      );
    }

    return ListTile(
      leading: const Icon(FreeCADIcons.freecad),
      title: Text(candidate.versionLabel),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (progress != null) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress.fraction),
            const SizedBox(height: 4),
            Text(
              [
                _stageLabel(l10n, progress.stage),
                if (detail.isNotEmpty) detail,
              ].join('  ·  '),
              style: theme.textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (error != null)
            Text(
              '${l10n.versionsInstallFailed}: $error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
      trailing: trailing,
    );
  }

  Future<void> _install(
    BuildContext context,
    BuildsController controller,
    BuildCandidate candidate,
  ) async {
    final tabController = DefaultTabController.of(context);
    final result = await controller.install(candidate);
    if (result.isOk) {
      tabController.animateTo(0);
    }
  }
}

class _CustomTab extends StatefulWidget {
  const _CustomTab();

  @override
  State<_CustomTab> createState() => _CustomTabState();
}

class _CustomTabState extends State<_CustomTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _checksumController = TextEditingController();
  bool _importing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _sourceController.dispose();
    _labelController.dispose();
    _checksumController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context);
    final typeGroups = <XTypeGroup>[
      XTypeGroup(
        label: l10n.versionsCustomBuilds,
        extensions: const ['AppImage', '7z', 'zip', 'dmg', 'tgz', 'tar', 'gz'],
      ),
      XTypeGroup(label: l10n.versionsCustomAllFiles),
    ];
    final file = await openFile(acceptedTypeGroups: typeGroups);
    if (file != null && mounted) {
      setState(() => _sourceController.text = file.path);
    }
  }

  Future<void> _offerPythonPicker(String buildId) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).builds;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.versionsCustomPythonMissingTitle),
        content: Text(l10n.versionsCustomPythonMissingMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.versionsCustomPythonSkip),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.versionsCustomPythonChoose),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) {
      return;
    }

    final pythonFile = await openFile(
      acceptedTypeGroups: [XTypeGroup(label: l10n.versionsCustomAllFiles)],
    );
    if (pythonFile == null || !mounted) {
      return;
    }

    final result = await controller.setCustomPython(
      buildId: buildId,
      pythonExecutable: pythonFile.path,
    );
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.versionsCustomPythonSaved)),
      ),
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.versionsCustomPythonFailed}: $error')),
      ),
    );
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).builds;
    final tabController = DefaultTabController.of(context);
    final source = _sourceController.text.trim();
    if (source.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.versionsCustomTrustTitle),
        content: Text('$source\n\n${l10n.versionsCustomTrustMessage}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.versionsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.versionsCustomTrustConfirm),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) {
      return;
    }

    setState(() => _importing = true);
    final result = await controller.importCustom(
      source: source,
      versionLabel: _labelController.text,
      sha256: _checksumController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _importing = false);

    final messenger = ScaffoldMessenger.of(context);
    result.fold(
      (build) {
        _sourceController.clear();
        _labelController.clear();
        _checksumController.clear();
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.versionsCustomImported}: ${build.displayLabel}'),
          ),
        );
        tabController.animateTo(0);
        if (build.pythonVersion == null) {
          unawaited(_offerPythonPicker(build.id));
        }
      },
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.versionsCustomFailed}: $error')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).builds;
    final progressByBuild = controller.installProgress.watch(context);
    InstallProgress? progress;
    for (final entry in progressByBuild.entries) {
      if (entry.key.startsWith('custom:')) {
        progress = entry.value;
        break;
      }
    }

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FormRow(
              label: l10n.versionsCustomSource,
              field: FormTextField(
                controller: _sourceController,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.folder_open),
                  tooltip: l10n.versionsCustomChooseFile,
                  onPressed: _importing ? null : _pickFile,
                ),
              ),
            ),
            FormRow(
              label: l10n.versionsCustomLabel,
              field: FormTextField(controller: _labelController),
            ),
            FormRow(
              label: l10n.versionsCustomChecksum,
              field: FormTextField(controller: _checksumController),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _importing ? null : _import,
                  icon: _importing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(l10n.versionsCustomImport),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress.fraction),
              const SizedBox(height: 4),
              Text(
                _stageLabel(l10n, progress.stage),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (_progressDetail(progress).isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  _progressDetail(progress),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
