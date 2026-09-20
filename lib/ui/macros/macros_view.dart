import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/macros/installed_macros.dart';
import 'package:freecad_launcher/ui/widgets/compact_badge.dart';
import 'package:freecad_launcher/ui/widgets/compact_dropdown.dart';
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

    var profileId = controller.selectedProfileId.watch(context);
    if (profileId == null || !profiles.any((profile) => profile.id == profileId)) {
      profileId = profiles.isEmpty ? null : profiles.first.id;
    }

    return Column(
      children: [
        _ProfilePicker(profileId: profileId, profiles: profiles),
        const SizedBox(height: 8),
        Expanded(
          child: profileId == null
              ? EmptyState(
                  icon: Icons.auto_fix_high_outlined,
                  title: l10n.macrosEmptyTitle,
                  message: l10n.macrosEmptyMessage,
                )
              : InstalledMacrosList(profileId: profileId),
        ),
      ],
    );
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
          final installedCount = installedRows
              .where((row) => row.fileName == macro.fileName)
              .length;
          return _CatalogMacroTile(
            macro: macro,
            installedCount: installedCount,
            isInstalling: installing.contains(macro.name),
            error: installErrors[macro.name],
            onInstall: () => _install(context, macro),
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
        const SizedBox(height: 8),
        Expanded(child: body),
      ],
    );
  }

  Future<void> _install(BuildContext context, MacroCatalogEntry macro) async {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final profileId = await showDialog<String>(
      context: context,
      builder: (context) => _InstallMacroDialog(macro: macro),
    );
    if (profileId == null || !context.mounted) {
      return;
    }
    services.macros.selectedProfileId.value = profileId;
    final result = await services.macros.install(
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

class _InstallMacroDialog extends StatefulWidget {
  const _InstallMacroDialog({required this.macro});

  final MacroCatalogEntry macro;

  @override
  State<_InstallMacroDialog> createState() => _InstallMacroDialogState();
}

class _InstallMacroDialogState extends State<_InstallMacroDialog> {
  String? _profileId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final profiles = services.profiles.profiles.watch(context);
    final installedRows = services.macros.installedMacros.watch(context);

    bool isInstalled(String profileId) => installedRows.any(
      (row) => row.profileId == profileId && row.fileName == widget.macro.fileName,
    );

    var selected = _profileId;
    if (selected == null) {
      for (final profile in profiles) {
        if (!isInstalled(profile.id)) {
          selected = profile.id;
          break;
        }
      }
    }

    return AlertDialog(
      title: Text(l10n.macrosSelectProfile),
      content: SizedBox(
        width: 380,
        child: profiles.isEmpty
            ? Text(l10n.addonsNoProfiles)
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: RadioGroup<String>(
                  groupValue: selected,
                  onChanged: (value) => setState(() => _profileId = value),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final profile in profiles)
                          RadioListTile<String>(
                            value: profile.id,
                            enabled: !isInstalled(profile.id),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(profile.name),
                            subtitle: isInstalled(profile.id)
                                ? Text(l10n.addonsInstalledBadge)
                                : null,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.bundlesCancel),
        ),
        if (profiles.isNotEmpty)
          FilledButton(
            onPressed: selected == null ? null : () => Navigator.of(context).pop(selected),
            child: Text(l10n.macrosInstall),
          ),
      ],
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
              child: CompactDropdown<String>(
                value: profileId,
                hint: Text(l10n.addonsInstallTarget),
                items: [
                  for (final profile in profiles)
                    DropdownMenuItem(value: profile.id, child: Text(profile.name)),
                ],
                onChanged: (value) => controller.selectedProfileId.value = value,
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
    required this.installedCount,
    required this.isInstalling,
    required this.error,
    required this.onInstall,
  });

  final MacroCatalogEntry macro;
  final int installedCount;
  final bool isInstalling;
  final String? error;
  final VoidCallback onInstall;

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (installedCount > 0) ...[
              CompactBadge(label: l10n.addonsInstalledIn(installedCount)),
              const SizedBox(width: 8),
            ],
            FilledButton.tonal(
              onPressed: isInstalling ? null : onInstall,
              child: isInstalling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.macrosInstall),
            ),
          ],
        ),
      ),
    );
  }
}
