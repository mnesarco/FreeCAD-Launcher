import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final results = _report?.results ?? const <DiagnosticResult>[];

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
