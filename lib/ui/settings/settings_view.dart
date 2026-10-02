// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/core/format.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:freecad_launcher/domain/settings/app_settings.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/diagnostics.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/settings/about_dialog.dart';
import 'package:freecad_launcher/ui/widgets/form_row.dart';

class SettingsView extends SignalStatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  DiagnosticsReport? _report;
  bool _running = false;
  bool _started = false;
  final TextEditingController _newsFeedController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final services = AppScope.of(context);
      services.settings.refreshWrapper();
      _newsFeedController.text = services.settings.newsFeedUrl.value;
      unawaited(services.cache.refresh());
    }
  }

  @override
  void dispose() {
    _newsFeedController.dispose();
    super.dispose();
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

  Future<void> _clearCache(BuildContext context, CacheCategory category) async {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final freed = await services.cache.clear(category);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsCacheCleared(formatBytes(freed)))),
      );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.settingsCacheClearFailed}: $error')),
      );
    }
  }

  Future<void> _cleanUpNow(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final freed = await services.cache.prune(
        services.settings.cacheRetention.value,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsCacheCleared(formatBytes(freed)))),
      );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.settingsCacheClearFailed}: $error')),
      );
    }
  }

  Future<void> _openFolder(BuildContext context, String path) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppScope.of(context).fileActions.openDirectory(path);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.settingsOpenFolderFailed}: $error')),
      );
    }
  }

  Future<void> _revealPath(BuildContext context, String path) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppScope.of(context).fileActions.reveal(path);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.settingsOpenFolderFailed}: $error')),
      );
    }
  }

  Future<void> _exportDebugBundle(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final location = await getSaveLocation(
      suggestedName: services.debugBundle.suggestedFileName(),
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Zip', extensions: ['zip']),
      ],
    );
    if (location == null || !context.mounted) {
      return;
    }
    final result = await services.debugBundle.export(location.path);
    if (!context.mounted) {
      return;
    }
    result.fold(
      (path) => messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.settingsDebugBundleExported(p.basename(path))),
          action: SnackBarAction(
            label: l10n.settingsDebugBundleReveal,
            onPressed: () => unawaited(_revealPath(context, path)),
          ),
        ),
      ),
      (error) => messenger.showSnackBar(
        SnackBar(content: Text('${l10n.settingsDebugBundleFailed}: $error')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final results = _report?.results ?? const <DiagnosticResult>[];

    final settings = services.settings;
    final themeMode = settings.themeMode.value;
    final updateCadence = settings.updateCadence.value;
    final logLevel = settings.logLevel.value;
    final cacheRetention = settings.cacheRetention.value;
    final cacheSizes = services.cache.sizes.value;
    final cacheBusy = services.cache.busy.value;
    final bundleBusy = services.debugBundle.exporting.value;
    final jobsActive = services.jobs.jobs.value.any((job) => job.isActive);
    final wrapperInstalled = settings.wrapperInstalled.value;
    final wrapperOnPath = settings.wrapperOnPath.value;
    final wrapperPath = settings.wrapperPath.value;
    final wrapperDirectory = settings.wrapperDirectory.value;
    final wrapperBusy = settings.wrapperBusy.value;

    final wrapperStatus = !wrapperInstalled
        ? l10n.settingsCliWrapperNotInstalled
        : wrapperOnPath
        ? l10n.settingsCliWrapperOnPath
        : l10n.settingsCliWrapperNotOnPath(wrapperDirectory ?? '');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsCard(
          title: l10n.settingsGeneral,
          children: [
            FormRow(
              label: l10n.settingsTheme,
              field: FormDropdown<AppThemeMode>(
                value: themeMode,
                items: [
                  DropdownMenuItem(
                    value: AppThemeMode.system,
                    child: Text(l10n.settingsThemeSystem),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.light,
                    child: Text(l10n.settingsThemeLight),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.dark,
                    child: Text(l10n.settingsThemeDark),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                  }
                },
              ),
            ),
            FormRow(
              label: l10n.settingsUpdateChecks,
              field: FormDropdown<UpdateCadence>(
                value: updateCadence,
                items: [
                  DropdownMenuItem(
                    value: UpdateCadence.manual,
                    child: Text(l10n.settingsCadenceManual),
                  ),
                  DropdownMenuItem(
                    value: UpdateCadence.daily,
                    child: Text(l10n.settingsCadenceDaily),
                  ),
                  DropdownMenuItem(
                    value: UpdateCadence.weekly,
                    child: Text(l10n.settingsCadenceWeekly),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setUpdateCadence(value);
                  }
                },
              ),
            ),
            FormRow(
              label: l10n.settingsDataDirectory,
              field: _PathRow(
                path: services.paths.dataRoot,
                tooltip: l10n.settingsOpenFolder,
                onOpen: () =>
                    unawaited(_openFolder(context, services.paths.dataRoot)),
              ),
            ),
            FormRow(
              label: l10n.settingsNewsFeed,
              field: FormTextField(
                controller: _newsFeedController,
                hintText: defaultNewsFeedUrl,
                onChanged: (value) => settings.setNewsFeedUrl(value),
              ),
            ),
          ],
        ),
        _SettingsCard(
          title: l10n.settingsLogs,
          children: [
            FormRow(
              label: l10n.settingsLogLevel,
              field: FormDropdown<LogLevel>(
                value: logLevel,
                items: [
                  DropdownMenuItem(
                    value: LogLevel.debug,
                    child: Text(l10n.settingsLogLevelDebug),
                  ),
                  DropdownMenuItem(
                    value: LogLevel.info,
                    child: Text(l10n.settingsLogLevelInfo),
                  ),
                  DropdownMenuItem(
                    value: LogLevel.warn,
                    child: Text(l10n.settingsLogLevelWarn),
                  ),
                  DropdownMenuItem(
                    value: LogLevel.error,
                    child: Text(l10n.settingsLogLevelError),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setLogLevel(value);
                  }
                },
              ),
            ),
            FormRow(
              label: l10n.settingsLogsFolder,
              field: _PathRow(
                path: services.paths.logsDir,
                tooltip: l10n.settingsOpenFolder,
                onOpen: () =>
                    unawaited(_openFolder(context, services.paths.logsDir)),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l10n.settingsDebugBundle),
              subtitle: Text(
                l10n.settingsDebugBundleDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: FilledButton.tonal(
                onPressed: bundleBusy
                    ? null
                    : () => _exportDebugBundle(context),
                child: Text(l10n.settingsDebugBundleExport),
              ),
            ),
          ],
        ),
        _SettingsCard(
          title: l10n.settingsCache,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.settingsCacheRefresh,
                onPressed: cacheBusy
                    ? null
                    : () => unawaited(services.cache.refresh()),
              ),
              TextButton.icon(
                onPressed: cacheBusy || jobsActive
                    ? null
                    : () => _cleanUpNow(context),
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text(l10n.settingsCacheCleanUp),
              ),
            ],
          ),
          children: [
            for (final category in CacheCategory.values)
              FormRow(
                label: _cacheLabel(l10n, category),
                field: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatBytes(cacheSizes[category] ?? 0),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: cacheBusy || jobsActive
                          ? null
                          : () => _clearCache(context, category),
                      child: Text(l10n.settingsCacheClear),
                    ),
                  ],
                ),
              ),
            FormRow(
              label: l10n.settingsCacheRetention,
              field: FormDropdown<CacheRetention>(
                value: cacheRetention,
                items: [
                  DropdownMenuItem(
                    value: CacheRetention.forever,
                    child: Text(l10n.settingsCacheRetentionForever),
                  ),
                  DropdownMenuItem(
                    value: CacheRetention.days7,
                    child: Text(l10n.settingsCacheRetentionDays(7)),
                  ),
                  DropdownMenuItem(
                    value: CacheRetention.days30,
                    child: Text(l10n.settingsCacheRetentionDays(30)),
                  ),
                  DropdownMenuItem(
                    value: CacheRetention.days90,
                    child: Text(l10n.settingsCacheRetentionDays(90)),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setCacheRetention(value);
                  }
                },
              ),
            ),
          ],
        ),
        _SettingsCard(
          title: l10n.settingsCliWrapper,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.terminal_outlined),
              title: Text(wrapperPath),
              subtitle: Text(
                wrapperStatus,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: FilledButton.tonal(
                onPressed: wrapperBusy
                    ? null
                    : () => _toggleWrapper(context, wrapperInstalled),
                child: Text(
                  wrapperInstalled
                      ? l10n.settingsCliWrapperRemove
                      : l10n.settingsCliWrapperInstall,
                ),
              ),
            ),
          ],
        ),
        _SettingsCard(
          title: l10n.settingsAbout,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsAboutOpen),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => showLauncherAboutDialog(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.numbers_outlined),
              title: Text(l10n.settingsVersion),
              subtitle: Text('$appName $appVersion'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.settingsLicense),
              subtitle: const Text('GPL-3.0-or-later'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.copyright_outlined),
              title: Text(l10n.settingsCopyright),
            ),
          ],
        ),
        _SettingsCard(
          title: l10n.settingsDiagnostics,
          trailing: FilledButton.tonalIcon(
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
          children: [
            for (final result in results)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _statusIcon(result.status),
                  color: _statusColor(context, result.status),
                ),
                title: Text(_diagnosticLabel(l10n, result.id)),
                subtitle: Text(
                  [
                    _statusLabel(l10n, result.status),
                    if (result.detail != null) result.detail!,
                  ].join(' — '),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({
    required this.path,
    required this.tooltip,
    required this.onOpen,
  });

  final String path;
  final String tooltip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            path,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.folder_open_outlined),
          tooltip: tooltip,
          onPressed: onOpen,
        ),
      ],
    );
  }
}

String _cacheLabel(AppLocalizations l10n, CacheCategory category) => switch (category) {
  CacheCategory.downloads => l10n.settingsCacheDownloads,
  CacheCategory.github => l10n.settingsCacheGithub,
  CacheCategory.addons => l10n.settingsCacheAddons,
  CacheCategory.macros => l10n.settingsCacheMacros,
  CacheCategory.news => l10n.settingsCacheNews,
};

String _diagnosticLabel(AppLocalizations l10n, String id) => switch (id) {
  DiagnosticIds.dataDirectory => l10n.diagnosticDataDirectory,
  DiagnosticIds.fuse => l10n.diagnosticFuse,
  DiagnosticIds.gatekeeper => l10n.diagnosticGatekeeper,
  DiagnosticIds.diskSpace => l10n.diagnosticDiskSpace,
  DiagnosticIds.network => l10n.diagnosticNetwork,
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
