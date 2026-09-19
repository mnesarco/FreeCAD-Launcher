import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/format.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

class MacrosView extends StatefulWidget {
  const MacrosView({super.key});

  @override
  State<MacrosView> createState() => _MacrosViewState();
}

class _MacrosViewState extends State<MacrosView> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final services = AppScope.of(context);
      services.macros.start();
      services.profiles.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.macrosTabInstalled),
              Tab(text: l10n.macrosTabCatalog),
            ],
          ),
          const Expanded(
            child: TabBarView(children: [_InstalledTab(), _CatalogTab()]),
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
    final services = AppScope.of(context);
    final controller = services.macros;
    final profiles = services.profiles.profiles.watch(context);
    final installed = controller.installedMacros.watch(context);

    var profileId = controller.selectedProfileId.watch(context);
    if (profileId == null || !profiles.any((profile) => profile.id == profileId)) {
      profileId = profiles.isEmpty ? null : profiles.first.id;
    }
    final rows = profileId == null
        ? const <Macro>[]
        : installed.where((row) => row.profileId == profileId).toList();

    return Column(
      children: [
        _ProfilePicker(profileId: profileId, profiles: profiles),
        const SizedBox(height: 8),
        Expanded(
          child: rows.isEmpty
              ? EmptyState(
                  icon: Icons.auto_fix_high_outlined,
                  title: l10n.macrosEmptyTitle,
                  message: l10n.macrosEmptyMessage,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: rows.length,
                  itemBuilder: (context, index) => _InstalledMacroTile(
                    macro: rows[index],
                    profileId: profileId!,
                  ),
                ),
        ),
      ],
    );
  }
}

class _InstalledMacroTile extends StatelessWidget {
  const _InstalledMacroTile({required this.macro, required this.profileId});

  final Macro macro;
  final String profileId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final services = AppScope.of(context);
    final path = p.join(services.paths.profilePaths(profileId).root, macro.fileName);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.auto_fix_high_outlined),
        title: Text(macro.name),
        subtitle: Text(
          [
            if (macro.sizeBytes != null) formatBytes(macro.sizeBytes!),
            _date(macro.updatedAt),
            if ((macro.license ?? '').isNotEmpty) macro.license!,
          ].join('  ·  '),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: l10n.macrosOpen,
              onPressed: () => _run(context, () => services.fileActions.open(path)),
            ),
            IconButton(
              icon: const Icon(Icons.folder_open_outlined),
              tooltip: l10n.macrosReveal,
              onPressed: () => _run(context, () => services.fileActions.reveal(path)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.macrosDelete,
              onPressed: () => _delete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.macrosActionFailed}: $error')),
      );
    }
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.macrosDeleteTitle),
        content: Text('${macro.name}\n\n${l10n.macrosDeleteMessage}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.bundlesCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.macrosDelete),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) {
      return;
    }
    final result = await services.macros.delete(
      profileId: profileId,
      fileName: macro.fileName,
    );
    result.fold(
      (_) => messenger.showSnackBar(SnackBar(content: Text(l10n.macrosDeleted))),
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.macrosDeleteFailed}: $error')),
      ),
    );
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final controller = services.macros;
    final loading = controller.loading.watch(context);
    final loaded = controller.loaded.watch(context);
    final error = controller.error.watch(context);
    final freshness = controller.freshness.watch(context);
    final macros = controller.macros.watch(context);
    final filtered = controller.filtered.watch(context);
    final query = controller.query.watch(context);
    final installing = controller.installing.watch(context);
    final installErrors = controller.installErrors.watch(context);
    final installedRows = controller.installedMacros.watch(context);
    final profiles = services.profiles.profiles.watch(context);

    var profileId = controller.selectedProfileId.watch(context);
    if (profileId == null || !profiles.any((profile) => profile.id == profileId)) {
      profileId = profiles.isEmpty ? null : profiles.first.id;
    }

    Widget body;
    if (loading && macros.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null && macros.isEmpty) {
      body = EmptyState(
        icon: Icons.cloud_off_outlined,
        title: l10n.macrosLoadFailed,
        message: error.toString(),
        action: FilledButton.tonal(
          onPressed: () => controller.load(forceRefresh: true),
          child: Text(l10n.versionsRetry),
        ),
      );
    } else if (loaded && macros.isEmpty) {
      body = EmptyState(
        icon: Icons.auto_fix_high_outlined,
        title: l10n.macrosCatalogEmptyTitle,
        message: l10n.macrosCatalogEmptyMessage,
        action: FilledButton.tonal(
          onPressed: () => controller.load(forceRefresh: true),
          child: Text(l10n.macrosRefresh),
        ),
      );
    } else if (filtered.isEmpty) {
      body = Center(child: Text(l10n.macrosNoMatches));
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final macro = filtered[index];
          final isInstalled = profileId != null &&
              installedRows.any(
                (row) => row.profileId == profileId && row.fileName == macro.fileName,
              );
          return _CatalogMacroTile(
            macro: macro,
            isInstalled: isInstalled,
            isInstalling: installing.contains(macro.name),
            canInstall: profileId != null && !isInstalled,
            error: installErrors[macro.name],
            onInstall: profileId == null ? null : () => _install(context, macro, profileId!),
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
                Expanded(child: Text(l10n.macrosStale)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => controller.query.value = value,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.macrosSearchHint,
                    isDense: true,
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: l10n.macrosClearSearch,
                            onPressed: () => controller.query.value = '',
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.macrosRefresh,
                onPressed: loading ? null : () => controller.load(forceRefresh: true),
              ),
            ],
          ),
        ),
        _ProfilePicker(profileId: profileId, profiles: profiles),
        const SizedBox(height: 8),
        Expanded(child: body),
      ],
    );
  }

  Future<void> _install(
    BuildContext context,
    MacroCatalogEntry macro,
    String profileId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await AppScope.of(context).macros.install(
      name: macro.name,
      profileId: profileId,
    );
    if (!context.mounted) {
      return;
    }
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.macrosInstalledMessage)),
      ),
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.macrosInstallFailed}: $error')),
      ),
    );
  }
}

class _ProfilePicker extends StatelessWidget {
  const _ProfilePicker({required this.profileId, required this.profiles});

  final String? profileId;
  final List<Profile> profiles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).macros;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (profiles.isEmpty)
            Expanded(child: Text(l10n.addonsNoProfiles))
          else
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.addonsInstallTarget,
                ),
                child: DropdownButton<String>(
                  value: profileId,
                  isDense: true,
                  isExpanded: true,
                  items: [
                    for (final profile in profiles)
                      DropdownMenuItem(value: profile.id, child: Text(profile.name)),
                  ],
                  onChanged: (value) => controller.selectedProfileId.value = value,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CatalogMacroTile extends StatelessWidget {
  const _CatalogMacroTile({
    required this.macro,
    required this.isInstalled,
    required this.isInstalling,
    required this.canInstall,
    required this.error,
    required this.onInstall,
  });

  final MacroCatalogEntry macro;
  final bool isInstalled;
  final bool isInstalling;
  final bool canInstall;
  final String? error;
  final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.auto_fix_high_outlined),
        title: Text(macro.name),
        subtitle: Text(
          [
            if (macro.comment.isNotEmpty) macro.comment,
            if (macro.author.isNotEmpty) '${l10n.macrosAuthor}: ${macro.author}',
            macro.hasLicense ? macro.license : l10n.macrosLicenseUnknown,
            if (error != null) '${l10n.macrosInstallFailed}: $error',
          ].join('\n'),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: error == null
              ? null
              : theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
        ),
        isThreeLine: true,
        trailing: isInstalled
            ? Chip(
                label: Text(l10n.addonsInstalledBadge),
                visualDensity: VisualDensity.compact,
              )
            : FilledButton.tonal(
                onPressed: canInstall && !isInstalling ? onInstall : null,
                child: isInstalling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.macrosInstall),
              ),
      ),
    );
  }
}
