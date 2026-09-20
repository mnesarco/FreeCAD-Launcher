import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/format.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

class InstalledMacrosList extends StatefulWidget {
  const InstalledMacrosList({super.key, required this.profileId});

  final String profileId;

  @override
  State<InstalledMacrosList> createState() => _InstalledMacrosListState();
}

class _InstalledMacrosListState extends State<InstalledMacrosList> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final controller = AppScope.of(context).macros;
      controller.start();
      unawaited(controller.reconcile(widget.profileId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).macros;
    final installed = controller.installedMacros.watch(context);
    final rows = installed.where((row) => row.profileId == widget.profileId).toList();

    if (rows.isEmpty) {
      return EmptyState(
        icon: Icons.auto_fix_high_outlined,
        title: l10n.macrosEmptyTitle,
        message: l10n.macrosEmptyMessage,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: rows.length,
      itemBuilder: (context, index) => InstalledMacroTile(
        macro: rows[index],
        profileId: widget.profileId,
      ),
    );
  }
}

class InstalledMacroTile extends StatelessWidget {
  const InstalledMacroTile({super.key, required this.macro, required this.profileId});

  final Macro macro;
  final String profileId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final services = AppScope.of(context);
    final path = p.join(services.paths.profilePaths(profileId).macros, macro.fileName);

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
