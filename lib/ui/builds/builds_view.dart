import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/format.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/asset_classifier.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/builds_controller.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

class BuildsView extends StatefulWidget {
  const BuildsView({super.key});

  @override
  State<BuildsView> createState() => _BuildsViewState();
}

class _BuildsViewState extends State<BuildsView> {
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
      itemBuilder: (context, index) => _InstalledBuildTile(buildInfo: builds[index]),
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

    final subtitle = [
      if (buildInfo.sizeBytes != null) '${l10n.versionsSize}: ${formatBytes(buildInfo.sizeBytes!)}',
      if (buildInfo.pythonVersion != null) '${l10n.versionsPython}: ${buildInfo.pythonVersion}',
      buildInfo.arch,
    ].join('  ·  ');

    return ListTile(
      leading: const Icon(Icons.inventory_2_outlined),
      title: Row(
        children: [
          Text(buildInfo.version),
          const SizedBox(width: 8),
          Chip(
            label: Text(buildInfo.channel.name),
            visualDensity: VisualDensity.compact,
          ),
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
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.versionsRemove,
        onPressed: () => _confirmRemove(context, controller, buildInfo),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    BuildsController controller,
    Build build,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.versionsRemoveTitle),
        content: Text('${build.version} — ${l10n.versionsRemoveMessage}'),
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
    if (confirmed ?? false) {
      await controller.remove(build.id);
    }
  }
}

class _AvailableTab extends StatelessWidget {
  const _AvailableTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).builds;
    final candidates = controller.availableBuilds.watch(context);
    final loading = controller.loadingCatalog.watch(context);
    final error = controller.catalogError.watch(context);
    final stale = controller.catalogFreshness.watch(context) == CatalogFreshness.stale;

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
        itemBuilder: (context, index) => _AvailableBuildTile(candidate: candidates[index]),
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
                onPressed: loading ? null : () => controller.loadCatalog(forceRefresh: true),
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
      if (candidate.pythonVersion != null) '${l10n.versionsPython}: ${candidate.pythonVersion}',
      candidate.assetName,
    ].join('  ·  ');

    Widget trailing;
    if (progress != null) {
      trailing = SizedBox(
        width: 180,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LinearProgressIndicator(value: progress.fraction),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  progress.stage == InstallStage.downloading
                      ? l10n.versionsDownloading
                      : l10n.versionsInstalling,
                  style: theme.textTheme.labelSmall,
                ),
                TextButton(
                  onPressed: () => controller.cancelInstall(candidate),
                  child: Text(l10n.versionsCancel),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (installed) {
      trailing = Chip(label: Text(l10n.versionsTabInstalled));
    } else {
      trailing = FilledButton(
        onPressed: () => controller.install(candidate),
        child: Text(l10n.versionsInstall),
      );
    }

    return ListTile(
      leading: const Icon(Icons.system_update_alt),
      title: Text(candidate.versionLabel),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (error != null)
            Text(
              '${l10n.versionsInstallFailed}: $error',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
        ],
      ),
      trailing: trailing,
    );
  }
}

class _CustomTab extends StatelessWidget {
  const _CustomTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.add_link_outlined,
      title: l10n.versionsCustomEmptyTitle,
      message: l10n.versionsCustomEmptyMessage,
    );
  }
}
