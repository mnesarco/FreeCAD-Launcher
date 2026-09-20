import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:freecad_launcher/domain/profiles/profile_rules.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/profile_manifest_controller.dart';
import 'package:freecad_launcher/ui/widgets/form_row.dart';

Future<void> exportProfileManifest(
  BuildContext context, {
  required String profileId,
  required String profileName,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final encoded = await AppScope.of(context).manifests.exportJson(profileId);
  if (!context.mounted) {
    return;
  }
  final json = encoded.valueOrNull;
  if (json == null) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('${l10n.profilesExportFailed}: ${encoded.errorOrNull}'),
      ),
    );
    return;
  }
  final fileName = '${_sanitizeFileName(profileName)}.manifest.json';
  final location = await getSaveLocation(suggestedName: fileName);
  if (location == null || !context.mounted) {
    return;
  }
  try {
    await File(location.path).writeAsString(json);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.profilesExportDone)));
  } on Object catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('${l10n.profilesExportFailed}: $error')),
    );
  }
}

Future<ManifestImportOutcome?> importProfileManifest(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final file = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(label: l10n.manifestImportFile, extensions: const ['json']),
    ],
  );
  if (file == null || !context.mounted) {
    return null;
  }
  final String text;
  try {
    text = await File(file.path).readAsString();
  } on Object catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('${l10n.manifestReadFailed}: $error')),
    );
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  final outcome = await showDialog<ManifestImportOutcome>(
    context: context,
    builder: (context) => ManifestImportDialog(jsonText: text),
  );
  if (outcome == null || !context.mounted) {
    return null;
  }
  final details = [
    l10n.manifestImportSummary(
      outcome.addonsInstalled,
      outcome.packagesInstalled,
    ),
    if (outcome.addonsFailed.isNotEmpty || outcome.packagesFailed.isNotEmpty)
      l10n.manifestImportWarnings(
        [...outcome.addonsFailed, ...outcome.packagesFailed].join('; '),
      )
    else if (outcome.warnings.isNotEmpty)
      l10n.manifestImportWarnings(outcome.warnings.join('; ')),
  ];
  messenger.showSnackBar(
    SnackBar(content: Text('${l10n.manifestImported}\n${details.join('\n')}')),
  );
  return outcome;
}

class ManifestImportDialog extends StatefulWidget {
  const ManifestImportDialog({super.key, required this.jsonText});

  final String jsonText;

  @override
  State<ManifestImportDialog> createState() => _ManifestImportDialogState();
}

class _ManifestImportDialogState extends State<ManifestImportDialog> {
  final TextEditingController _name = TextEditingController();
  ManifestImportPreview? _preview;
  String? _loadError;
  String? _importError;
  String? _step;
  String? _buildId;
  bool _started = false;
  bool _loading = true;
  bool _importing = false;
  bool _reinstall = true;
  bool _requirements = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await AppScope.of(
      context,
    ).manifests.previewImport(widget.jsonText);
    if (!mounted) {
      return;
    }
    result.fold(
      (preview) => setState(() {
        _preview = preview;
        _loading = false;
        _name.text = preview.suggestedName;
        _buildId = preview.matchingBuild?.id;
      }),
      (error) => setState(() {
        _loadError = error.toString();
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = _preview;

    return AlertDialog(
      title: Text(l10n.manifestImportTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: switch ((_loading, _loadError, preview)) {
            (true, _, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            (_, final String error, _) => Text(error),
            (_, _, final ManifestImportPreview value) => _form(
              context,
              l10n,
              value,
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _importing ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.bundlesCancel),
        ),
        if (preview != null)
          FilledButton(
            onPressed: _canImport(l10n) ? _import : null,
            child: Text(l10n.manifestImport),
          ),
      ],
    );
  }

  Widget _form(
    BuildContext context,
    AppLocalizations l10n,
    ManifestImportPreview preview,
  ) {
    final theme = Theme.of(context);
    final manifest = preview.manifest;
    final errorStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.error,
    );
    final nameError = _nameError(l10n);
    final buildVersion = manifest.profile.build;
    final channel = manifest.profile.channel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          manifest.source.os == null
              ? l10n.manifestSourceUnknown
              : l10n.manifestSource(
                  manifest.source.os!,
                  manifest.source.arch ?? '?',
                ),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        FormRow(
          label: l10n.manifestName,
          field: FormTextField(
            controller: _name,
            enabled: !_importing,
            onChanged: (_) => setState(() {}),
            errorText: nameError,
          ),
        ),
        if (preview.usableBuilds.isEmpty)
          Text(l10n.manifestNoBuild, style: errorStyle)
        else ...[
          FormRow(
            label: l10n.manifestBuildLabel,
            field: FormDropdown<String>(
              value: _buildId,
              items: [
                for (final build in preview.usableBuilds)
                  DropdownMenuItem(
                    value: build.id,
                    child: Text(
                      '${build.version} · ${build.channel.name} · '
                      '${l10n.profilesPythonVersion} ${build.pythonVersion}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _importing
                  ? null
                  : (value) => setState(() => _buildId = value),
            ),
          ),
          if (buildVersion == null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.manifestBuildMissingVersion,
              style: theme.textTheme.bodySmall,
            ),
          ] else if (preview.matchingBuild == null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.manifestBuildMissing(buildVersion, channel ?? '?'),
              style: errorStyle,
            ),
          ],
        ],
        const SizedBox(height: 16),
        Text(l10n.manifestContents, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(l10n.manifestAddonsCount(manifest.addons.length)),
        Text(l10n.manifestPackagesCount(manifest.pythonPackages.length)),
        Text(l10n.manifestBundlesCount(manifest.bundles.length)),
        Text(l10n.manifestMacrosCount(manifest.macros.length)),
        if (manifest.configFiles.isNotEmpty)
          Text(l10n.manifestConfigFiles(manifest.configFiles.join(', '))),
        if (preview.missingBundles.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            l10n.manifestBundlesMissing(preview.missingBundles.join(', ')),
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (preview.absolutePaths.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l10n.manifestAbsolutePaths, style: errorStyle),
          for (final entry in preview.absolutePaths.take(8))
            Text(
              '• ${entry.file}: ${entry.path}',
              style: theme.textTheme.bodySmall,
            ),
          if (preview.absolutePaths.length > 8)
            Text(
              '• +${preview.absolutePaths.length - 8}',
              style: theme.textTheme.bodySmall,
            ),
        ],
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _reinstall,
          onChanged: _importing
              ? null
              : (value) => setState(() => _reinstall = value ?? false),
          title: Text(l10n.manifestReinstall),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _requirements,
          onChanged: _importing || !_reinstall
              ? null
              : (value) => setState(() => _requirements = value ?? false),
          title: Text(l10n.manifestInstallRequirements),
        ),
        if (_importing) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          const SizedBox(height: 4),
          Text(
            _step == null
                ? l10n.manifestImporting
                : l10n.manifestImportingStep(_step!),
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (_importError != null) ...[
          const SizedBox(height: 8),
          Text(_importError!, style: errorStyle),
        ],
      ],
    );
  }

  bool _canImport(AppLocalizations l10n) {
    final preview = _preview;
    if (preview == null || _importing) {
      return false;
    }
    if (preview.usableBuilds.isEmpty || _buildId == null) {
      return false;
    }
    return _nameError(l10n) == null;
  }

  String? _nameError(AppLocalizations l10n) {
    final issue = validateProfileName(normalizeProfileName(_name.text));
    return switch (issue) {
      ProfileNameIssue.empty => l10n.manifestNameRequired,
      ProfileNameIssue.tooLong => l10n.manifestNameTooLong(
        maxProfileNameLength,
      ),
      ProfileNameIssue.controlCharacters => l10n.manifestNameControl,
      null => null,
    };
  }

  Future<void> _import() async {
    final preview = _preview;
    final buildId = _buildId;
    if (preview == null || buildId == null) {
      return;
    }
    setState(() {
      _importing = true;
      _importError = null;
      _step = null;
    });
    final result = await AppScope.of(context).manifests.importManifest(
      preview: preview,
      name: _name.text,
      buildId: buildId,
      reinstall: _reinstall,
      installRequirements: _requirements,
      onStep: (step) {
        if (mounted) {
          setState(() => _step = step);
        }
      },
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (outcome) => Navigator.of(context).pop(outcome),
      (error) => setState(() {
        _importing = false;
        _importError = error.toString();
      }),
    );
  }
}

String _sanitizeFileName(String name) {
  final sanitized = name.replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_').trim();
  return sanitized.isEmpty ? 'profile' : sanitized;
}
