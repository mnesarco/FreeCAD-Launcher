import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/diagnostics.dart';
import 'package:freecad_launcher/state/app_services.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  DiagnosticsReport? _report;
  bool _running = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      AppScope.of(context).settings.refreshWrapper();
    }
  }

  Future<void> _runDiagnostics() async {
    setState(() => _running = true);
    final report = await AppScope.of(context).diagnostics.runAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _report = report;
      _running = false;
    });
  }

  Future<void> _toggleWrapper(BuildContext context, bool installed) async {
    final l10n = AppLocalizations.of(context);
    final settings = AppScope.of(context).settings;
    final result = installed
        ? await settings.removeWrapper()
        : await settings.installWrapper();
    if (!context.mounted) {
      return;
    }
    final message = result.fold(
      (_) => installed
          ? l10n.settingsCliWrapperRemovedMessage
          : l10n.settingsCliWrapperInstalledMessage,
      (error) => '${l10n.settingsCliWrapperFailed}: $error',
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final results = _report?.results ?? const <DiagnosticResult>[];

    final settings = services.settings;
    final wrapperInstalled = settings.wrapperInstalled.watch(context);
    final wrapperOnPath = settings.wrapperOnPath.watch(context);
    final wrapperPath = settings.wrapperPath.watch(context);
    final wrapperDirectory = settings.wrapperDirectory.watch(context);
    final wrapperBusy = settings.wrapperBusy.watch(context);

    final wrapperStatus = !wrapperInstalled
        ? l10n.settingsCliWrapperNotInstalled
        : wrapperOnPath
        ? l10n.settingsCliWrapperOnPath
        : l10n.settingsCliWrapperNotOnPath(wrapperDirectory ?? '');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(l10n.settingsDataDirectory),
          subtitle: Text(services.paths.dataRoot),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.settingsVersion),
          subtitle: Text('$appName $appVersion'),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(l10n.settingsLicense),
          subtitle: const Text('GPL-3.0-or-later'),
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.terminal_outlined),
          title: Text(l10n.settingsCliWrapper),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(wrapperPath),
              Text(wrapperStatus, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          trailing: FilledButton.tonal(
            onPressed: wrapperBusy ? null : () => _toggleWrapper(context, wrapperInstalled),
            child: Text(
              wrapperInstalled
                  ? l10n.settingsCliWrapperRemove
                  : l10n.settingsCliWrapperInstall,
            ),
          ),
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(l10n.settingsDiagnostics, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _running ? null : _runDiagnostics,
                icon: _running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_running ? l10n.diagnosticsRunning : l10n.diagnosticsRun),
              ),
            ],
          ),
        ),
        for (final result in results)
          ListTile(
            leading: Icon(_statusIcon(result.status), color: _statusColor(context, result.status)),
            title: Text(_diagnosticLabel(l10n, result.id)),
            subtitle: Text(
              [
                _statusLabel(l10n, result.status),
                if (result.detail != null) result.detail!,
              ].join(' — '),
            ),
          ),
      ],
    );
  }
}

String _diagnosticLabel(AppLocalizations l10n, String id) => switch (id) {
  DiagnosticIds.dataDirectory => l10n.diagnosticDataDirectory,
  DiagnosticIds.fuse => l10n.diagnosticFuse,
  DiagnosticIds.gatekeeper => l10n.diagnosticGatekeeper,
  DiagnosticIds.diskSpace => l10n.diagnosticDiskSpace,
  _ => id,
};

String _statusLabel(AppLocalizations l10n, DiagnosticStatus status) => switch (status) {
  DiagnosticStatus.ok => l10n.diagnosticsStatusOk,
  DiagnosticStatus.warning => l10n.diagnosticsStatusWarning,
  DiagnosticStatus.error => l10n.diagnosticsStatusError,
  DiagnosticStatus.notApplicable => l10n.diagnosticsStatusNotApplicable,
};

IconData _statusIcon(DiagnosticStatus status) => switch (status) {
  DiagnosticStatus.ok => Icons.check_circle_outline,
  DiagnosticStatus.warning => Icons.warning_amber_outlined,
  DiagnosticStatus.error => Icons.error_outline,
  DiagnosticStatus.notApplicable => Icons.remove_circle_outline,
};

Color _statusColor(BuildContext context, DiagnosticStatus status) => switch (status) {
  DiagnosticStatus.ok => Colors.green,
  DiagnosticStatus.warning => Colors.orange,
  DiagnosticStatus.error => Theme.of(context).colorScheme.error,
  DiagnosticStatus.notApplicable => Theme.of(context).colorScheme.outline,
};
