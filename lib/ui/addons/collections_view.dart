import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/bundles/bundle_json.dart';
import 'package:freecad_launcher/domain/bundles/bundle_planner.dart';
import 'package:freecad_launcher/domain/bundles/bundle_rules.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/bundle_apply_controller.dart';
import 'package:freecad_launcher/state/bundles_controller.dart';
import 'package:freecad_launcher/ui/addons/addon_icon.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

class CollectionsTab extends StatefulWidget {
  const CollectionsTab({super.key});

  @override
  State<CollectionsTab> createState() => _CollectionsTabState();
}

class _CollectionsTabState extends State<CollectionsTab> {
  String? _selectedBundleId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.of(context).bundles.start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).bundles;
    final selectedId = _selectedBundleId;
    if (selectedId != null && controller.byId(selectedId) != null) {
      return BundleDetailView(
        bundleId: selectedId,
        onBack: () => setState(() => _selectedBundleId = null),
      );
    }

    final bundles = controller.bundles.watch(context);
    final items = controller.items.watch(context);
    final loading = controller.loading.watch(context);
    final error = controller.error.watch(context);

    Widget body;
    if (loading && bundles.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null && bundles.isEmpty) {
      body = EmptyState(
        icon: Icons.error_outline,
        title: l10n.bundlesLoadFailed,
        message: error.toString(),
      );
    } else if (bundles.isEmpty) {
      body = EmptyState(
        icon: Icons.inventory_outlined,
        title: l10n.bundlesEmptyTitle,
        message: l10n.bundlesEmptyMessage,
        action: FilledButton.icon(
          onPressed: () => _createBundle(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.bundlesCreate),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: bundles.length,
        itemBuilder: (context, index) {
          final bundle = bundles[index];
          final count = items.where((item) => item.bundleId == bundle.id).length;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(bundle.name),
              subtitle: Text(
                [
                  if ((bundle.description ?? '').isNotEmpty) bundle.description!,
                  l10n.bundlesItemCount(count),
                ].join('\n'),
              ),
              isThreeLine: (bundle.description ?? '').isNotEmpty,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _selectedBundleId = bundle.id),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.addonsTabCollections,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _importBundle,
                icon: const Icon(Icons.file_open_outlined),
                label: Text(l10n.bundlesImport),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _createBundle(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.bundlesCreate),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: body),
      ],
    );
  }

  Future<void> _importBundle() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(label: l10n.bundlesImportFile, extensions: const ['json']),
      ],
    );
    if (file == null || !mounted) {
      return;
    }
    final text = await File(file.path).readAsString();
    if (!mounted) {
      return;
    }
    final result = await showDialog<BundleImportResult>(
      context: context,
      builder: (dialogContext) => BundleImportDialog(jsonText: text),
    );
    if (result == null || !mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.unresolvedAddonIds.isEmpty
              ? l10n.bundlesImported
              : l10n.bundlesImportedUnresolved(result.unresolvedAddonIds.length),
        ),
      ),
    );
    setState(() => _selectedBundleId = result.bundle.id);
  }

  Future<void> _createBundle(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bundle = await showDialog<Bundle>(
      context: context,
      builder: (context) => const BundleEditDialog(),
    );
    if (bundle == null || !mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.bundlesCreated)));
    setState(() => _selectedBundleId = bundle.id);
  }
}

class BundleDetailView extends StatefulWidget {
  const BundleDetailView({super.key, required this.bundleId, required this.onBack});

  final String bundleId;
  final VoidCallback onBack;

  @override
  State<BundleDetailView> createState() => _BundleDetailViewState();
}

class _BundleDetailViewState extends State<BundleDetailView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final controller = services.bundles;
    final bundle = controller.byId(widget.bundleId);
    if (bundle == null) {
      return Column(
        children: [
          _Header(title: l10n.addonsTabCollections, onBack: widget.onBack),
          Expanded(
            child: EmptyState(
              icon: Icons.error_outline,
              title: l10n.bundlesLoadFailed,
              message: l10n.bundlesEmptyMessage,
            ),
          ),
        ],
      );
    }
    final items = controller.itemsFor(bundle.id);

    return Column(
      children: [
        _Header(
          title: bundle.name,
          onBack: widget.onBack,
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: l10n.bundlesExport,
              onPressed: () => _export(context, bundle),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.bundlesEdit,
              onPressed: () => _edit(context, bundle),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.bundlesDelete,
              onPressed: () => _delete(context, bundle),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if ((bundle.description ?? '').isNotEmpty) ...[
                Text(bundle.description!, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
              ],
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${l10n.bundlesItems} · ${l10n.bundlesItemCount(items.length)}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: items.isEmpty ? null : () => _apply(context, bundle),
                            icon: const Icon(Icons.playlist_add_check),
                            label: Text(l10n.bundlesApply),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: () => _addAddon(context, bundle),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.bundlesAddAddon),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            l10n.bundlesNoItems,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      else
                        for (final item in items) _BundleItemTile(bundleId: bundle.id, item: item),
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

  Future<void> _export(BuildContext context, Bundle bundle) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).bundles;
    final messenger = ScaffoldMessenger.of(context);
    final encoded = controller.exportJson(bundle.id);
    encoded.fold(
      (json) => null,
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.bundlesExportFailed}: $error')),
      ),
    );
    final json = encoded.valueOrNull;
    if (json == null) {
      return;
    }
    final fileName = '${bundle.name.replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_')}.json';
    final location = await getSaveLocation(suggestedName: fileName);
    if (location == null || !mounted) {
      return;
    }
    try {
      await File(location.path).writeAsString(json);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.bundlesExported)));
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.bundlesExportFailed}: $error')),
      );
    }
  }

  Future<void> _edit(BuildContext context, Bundle bundle) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final updated = await showDialog<Bundle>(
      context: context,
      builder: (context) => BundleEditDialog(bundle: bundle),
    );
    if (updated == null || !mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.bundlesSaved)));
  }

  Future<void> _delete(BuildContext context, Bundle bundle) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).bundles;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bundlesDeleteTitle),
        content: Text('${bundle.name}\n\n${l10n.bundlesDeleteMessage}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.bundlesCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.bundlesDelete),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) {
      return;
    }
    final result = await controller.delete(bundle.id);
    if (!mounted) {
      return;
    }
    result.fold(
      (_) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.bundlesDeleted)));
        widget.onBack();
      },
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.bundlesDeleteFailed}: $error')),
      ),
    );
  }

  Future<void> _apply(BuildContext context, Bundle bundle) async {
    await showDialog<BundleApplySummary>(
      context: context,
      builder: (context) => BundleApplyDialog(bundleId: bundle.id),
    );
  }

  Future<void> _addAddon(BuildContext context, Bundle bundle) async {
    final addon = await showDialog<Addon>(
      context: context,
      builder: (context) => AddAddonDialog(bundleId: bundle.id),
    );
    if (addon == null || !context.mounted) {
      return;
    }
    final controller = AppScope.of(context).bundles;
    await controller.addItem(
      bundleId: bundle.id,
      addonId: addon.id,
      gitRef: addon.primaryBranch.gitRef,
    );
  }
}

class _BundleItemTile extends StatelessWidget {
  const _BundleItemTile({required this.bundleId, required this.item});

  final String bundleId;
  final BundleItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final addon = services.addons.byId(item.addonId);
    final metadata = addon?.primaryBranch.metadata;
    final value = item.gitRef ?? addon?.primaryBranch.gitRef;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AddonIcon(base64Data: metadata?.iconBase64, size: 32),
      title: Text(addon?.displayName ?? item.addonId),
      subtitle: addon == null
          ? Text('${l10n.bundlesUnknownAddon}  ·  ${item.gitRef ?? ''}'.trim())
          : Row(
              children: [
                Text(l10n.bundlesBranch),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: value,
                  isDense: true,
                  items: [
                    for (final branch in addon.branches)
                      DropdownMenuItem(value: branch.gitRef, child: Text(branch.gitRef)),
                    if (value != null &&
                        !addon.branches.any((branch) => branch.gitRef == value))
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (ref) => services.bundles.setItemBranch(
                    bundleId: bundleId,
                    addonId: item.addonId,
                    gitRef: ref,
                  ),
                ),
              ],
            ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: l10n.bundlesRemoveItem,
        onPressed: () => services.bundles.removeItem(
          bundleId: bundleId,
          addonId: item.addonId,
        ),
      ),
    );
  }
}

class BundleEditDialog extends StatefulWidget {
  const BundleEditDialog({super.key, this.bundle});

  final Bundle? bundle;

  @override
  State<BundleEditDialog> createState() => _BundleEditDialogState();
}

class _BundleEditDialogState extends State<BundleEditDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.bundle?.name);
  late final TextEditingController _description = TextEditingController(
    text: widget.bundle?.description,
  );
  String? _profileId;
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.bundle != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final profiles = services.profiles.profiles.watch(context);
    final controller = services.bundles;

    return AlertDialog(
      title: Text(_isEdit ? l10n.bundlesEdit : l10n.bundlesCreate),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.bundlesName),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              decoration: InputDecoration(labelText: l10n.bundlesDescription),
            ),
            if (!_isEdit && profiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              InputDecorator(
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.bundlesFromProfile,
                ),
                child: DropdownButton<String?>(
                  value: _profileId,
                  isDense: true,
                  isExpanded: true,
                  hint: Text(l10n.bundlesFromProfileNone),
                  items: [
                    for (final profile in profiles)
                      DropdownMenuItem(value: profile.id, child: Text(profile.name)),
                  ],
                  onChanged: (value) => setState(() => _profileId = value),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.bundlesCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(context, controller),
          child: Text(l10n.bundlesSave),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, BundlesController controller) async {
    final l10n = AppLocalizations.of(context);
    final currentId = widget.bundle?.id;
    final issue = await controller.checkName(_name.text, currentBundleId: currentId);
    if (issue != null) {
      setState(() => _error = switch (issue) {
        BundleNameIssue.empty => l10n.bundlesNameEmpty,
        BundleNameIssue.tooLong => l10n.bundlesNameTooLong,
        BundleNameIssue.duplicate => l10n.bundlesNameTaken,
        BundleNameIssue.controlCharacters => l10n.bundlesNameEmpty,
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final profileId = _profileId;
    final result = widget.bundle == null
        ? (profileId == null
              ? await controller.create(
                  name: _name.text,
                  description: _description.text,
                )
              : await controller.createFromProfile(
                  profileId: profileId,
                  name: _name.text,
                  description: _description.text,
                ))
        : await controller.update(
            bundleId: widget.bundle!.id,
            name: _name.text,
            description: _description.text,
          );
    if (!mounted) {
      return;
    }
    result.fold(
      (bundle) => Navigator.of(context).pop(bundle),
      (error) => setState(() {
        _saving = false;
        _error = error.toString();
      }),
    );
  }
}

class AddAddonDialog extends StatefulWidget {
  const AddAddonDialog({super.key, required this.bundleId});

  final String bundleId;

  @override
  State<AddAddonDialog> createState() => _AddAddonDialogState();
}

class _AddAddonDialogState extends State<AddAddonDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final addons = services.addons.addons.watch(context);
    final items = services.bundles.itemsFor(widget.bundleId).map((item) => item.addonId).toSet();
    final matches = _matches(addons);

    return AlertDialog(
      title: Text(l10n.bundlesAddAddonTitle),
      content: SizedBox(
        width: 520,
        height: 380,
        child: Column(
          children: [
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.bundlesSearchHint,
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: matches.isEmpty
                  ? Center(child: Text(l10n.bundlesNoMatches))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final addon = matches[index];
                        final alreadyAdded = items.contains(addon.id);
                        return ListTile(
                          leading: AddonIcon(
                            base64Data: addon.primaryBranch.metadata?.iconBase64,
                            size: 32,
                          ),
                          title: Text(addon.displayName),
                          subtitle: Text(
                            addon.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: alreadyAdded
                              ? Chip(
                                  label: Text(l10n.addonsInstalledBadge),
                                  visualDensity: VisualDensity.compact,
                                )
                              : FilledButton.tonal(
                                  onPressed: () => Navigator.of(context).pop(addon),
                                  child: Text(l10n.bundlesAddAddon),
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.bundlesCancel),
        ),
      ],
    );
  }

  List<Addon> _matches(List<Addon> addons) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return addons;
    }
    if (query.startsWith('#')) {
      final tag = query.substring(1);
      return [
        for (final addon in addons)
          if (addon.tags.any((candidate) => candidate.toLowerCase().contains(tag))) addon,
      ];
    }
    return [
      for (final addon in addons)
        if (addon.id.toLowerCase().contains(query) ||
            addon.displayName.toLowerCase().contains(query) ||
            addon.description.toLowerCase().contains(query))
          addon,
    ];
  }
}

class BundleApplyDialog extends StatefulWidget {
  const BundleApplyDialog({super.key, required this.bundleId});

  final String bundleId;

  @override
  State<BundleApplyDialog> createState() => _BundleApplyDialogState();
}

class _BundleApplyDialogState extends State<BundleApplyDialog> {
  String? _profileId;
  bool _installRequirements = false;
  BundleApplySummary? _summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final applying = services.bundleApply.applying.watch(context);
    final completed = services.bundleApply.completed.watch(context);
    final total = services.bundleApply.total.watch(context);
    final profiles = services.profiles.profiles.watch(context);
    final catalog = services.addons.addons.watch(context);
    final installedRows = services.addons.installedAddons.watch(context);
    final bundleItems = services.bundles.items.watch(context).where(
      (item) => item.bundleId == widget.bundleId,
    );

    final profileId = _profileId ?? (profiles.isEmpty ? null : profiles.first.id);
    final plan = planBundleApply(
      entries: [
        for (final item in bundleItems)
          BundlePlanEntry(addonId: item.addonId, gitRef: item.gitRef),
      ],
      catalog: catalog,
      installed: [
        for (final row in installedRows)
          if (row.profileId == profileId)
            BundlePlanInstalledAddon(
              addonId: row.addonId,
              gitRef: row.gitRef,
              version: row.version,
              catalogLastUpdate: row.catalogLastUpdate,
            ),
      ],
    );

    final summary = _summary;
    Widget content;
    if (summary != null) {
      content = _summaryView(l10n, summary);
    } else if (applying) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.bundlesApplyRunning),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: total == 0 ? null : completed / total),
        ],
      );
    } else {
      content = _previewView(l10n, services, profiles, profileId, plan);
    }

    return AlertDialog(
      title: Text(l10n.bundlesApplyTitle),
      content: SizedBox(width: 520, height: 400, child: content),
      actions: [
        if (summary != null)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(summary),
            child: Text(l10n.bundlesApplyClose),
          )
        else ...[
          TextButton(
            onPressed: applying ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.bundlesCancel),
          ),
          FilledButton(
            onPressed: !applying && profileId != null && plan.actionable.isNotEmpty
                ? () => _run(services, profileId, plan)
                : null,
            child: Text(l10n.bundlesApply),
          ),
        ],
      ],
    );
  }

  Widget _previewView(
    AppLocalizations l10n,
    AppServices services,
    List<Profile> profiles,
    String? profileId,
    BundleApplyPlan plan,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profiles.isEmpty)
          Text(l10n.bundlesApplyNoProfiles)
        else
          InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.bundlesApplyProfile,
            ),
            child: DropdownButton<String>(
              value: profileId,
              isDense: true,
              isExpanded: true,
              items: [
                for (final profile in profiles)
                  DropdownMenuItem(value: profile.id, child: Text(profile.name)),
              ],
              onChanged: (value) => setState(() => _profileId = value),
            ),
          ),
        const SizedBox(height: 8),
        if (plan.items.isEmpty)
          Text(l10n.bundlesApplyNothing)
        else
          Expanded(
            child: ListView(
              children: [for (final item in plan.items) _planRow(l10n, item)],
            ),
          ),
        if (plan.hasRequirements)
          CheckboxListTile(
            value: _installRequirements,
            onChanged: (value) => setState(() => _installRequirements = value ?? false),
            title: Text(l10n.bundlesApplyInstallRequirements),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ],
    );
  }

  Widget _planRow(AppLocalizations l10n, BundleApplyPlanItem item) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(item.addonName ?? item.addonId),
      subtitle: Text(_subtitle(l10n, item), style: theme.textTheme.bodySmall),
      trailing: Chip(
        label: Text(_actionLabel(l10n, item.action)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _summaryView(AppLocalizations l10n, BundleApplySummary summary) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(l10n.bundlesApplyInstalledCount(
              summary.count(BundleApplyItemStatus.installed),
            ))),
            Chip(label: Text(l10n.bundlesApplyUpdatedCount(
              summary.count(BundleApplyItemStatus.updated),
            ))),
            Chip(label: Text(l10n.bundlesApplySkippedCount(
              summary.count(BundleApplyItemStatus.skipped),
            ))),
            Chip(label: Text(l10n.bundlesApplyFailedCount(
              summary.count(BundleApplyItemStatus.failed),
            ))),
          ],
        ),
        const SizedBox(height: 8),
        if (summary.failures.isNotEmpty)
          Expanded(
            child: ListView(
              children: [
                for (final failure in summary.failures)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
                    title: Text(failure.item.addonName ?? failure.item.addonId),
                    subtitle: Text(failure.error ?? ''),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _subtitle(AppLocalizations l10n, BundleApplyPlanItem item) {
    if (item.action == BundleItemAction.unavailable) {
      if (item.isAddonMissing) {
        return l10n.bundlesApplyAddonMissing;
      }
      return l10n.bundlesApplyBranchMissing(item.branchRef ?? '');
    }
    final parts = [
      if (item.branchRef != null) item.branchRef!,
      if (item.action == BundleItemAction.update && item.catalogVersion != null)
        '${item.installedVersion ?? '?'} → ${item.catalogVersion}',
    ];
    return parts.join('  ·  ');
  }

  String _actionLabel(AppLocalizations l10n, BundleItemAction action) {
    return switch (action) {
      BundleItemAction.install => l10n.bundlesApplyActionInstall,
      BundleItemAction.update => l10n.bundlesApplyActionUpdate,
      BundleItemAction.skip => l10n.bundlesApplyActionSkip,
      BundleItemAction.unavailable => l10n.bundlesApplyActionUnavailable,
    };
  }

  Future<void> _run(AppServices services, String profileId, BundleApplyPlan plan) async {
    final summary = await services.bundleApply.apply(
      profileId: profileId,
      items: plan.actionable,
      installRequirements: _installRequirements,
    );
    if (!mounted) {
      return;
    }
    setState(() => _summary = summary);
  }
}

class BundleImportDialog extends StatefulWidget {
  const BundleImportDialog({super.key, required this.jsonText});

  final String jsonText;

  @override
  State<BundleImportDialog> createState() => _BundleImportDialogState();
}

class _BundleImportDialogState extends State<BundleImportDialog> {
  late final TextEditingController _name;
  late final Result<BundleJson> _decoded;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _decoded = decodeBundleJson(widget.jsonText);
    _name = TextEditingController(text: _decoded.valueOrNull?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final decoded = _decoded.valueOrNull;

    return AlertDialog(
      title: Text(l10n.bundlesImportTitle),
      content: SizedBox(
        width: 420,
        child: decoded == null
            ? Text(_decoded.errorOrNull?.toString() ?? l10n.bundlesImportFailed)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _name,
                    autofocus: true,
                    decoration: InputDecoration(labelText: l10n.bundlesImportName),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.bundlesImportAddons(decoded.items.length)),
                  if (_unresolved(decoded).isNotEmpty)
                    Text(
                      l10n.bundlesImportUnresolved(_unresolved(decoded).length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if ((decoded.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(decoded.description!),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.bundlesCancel),
        ),
        if (decoded != null)
          FilledButton(
            onPressed: _saving ? null : () => _import(context, decoded),
            child: Text(l10n.bundlesImport),
          ),
      ],
    );
  }

  List<String> _unresolved(BundleJson decoded) {
    final catalog = AppScope.of(context).addons.addons.watch(context);
    final ids = {for (final addon in catalog) addon.id};
    return [
      for (final item in decoded.items)
        if (!ids.contains(item.addonId)) item.addonId,
    ];
  }

  Future<void> _import(BuildContext context, BundleJson decoded) async {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final name = _name.text;
    final issue = await services.bundles.checkName(name);
    if (issue != null) {
      setState(() => _error = switch (issue) {
        BundleNameIssue.empty => l10n.bundlesNameEmpty,
        BundleNameIssue.tooLong => l10n.bundlesNameTooLong,
        BundleNameIssue.duplicate => l10n.bundlesNameTaken,
        BundleNameIssue.controlCharacters => l10n.bundlesNameEmpty,
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final catalog = services.addons.addons.value;
    final result = await services.bundles.importJson(
      json: widget.jsonText,
      catalog: catalog,
      name: name,
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (imported) => Navigator.of(context).pop(imported),
      (error) => setState(() {
        _saving = false;
        _error = error.toString();
      }),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack, this.actions = const []});

  final String title;
  final VoidCallback onBack;
  final List<Widget> actions;

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
          ...actions,
        ],
      ),
    );
  }
}
