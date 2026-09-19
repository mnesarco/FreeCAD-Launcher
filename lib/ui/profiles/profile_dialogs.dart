import 'package:flutter/material.dart';

import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/profiles_controller.dart';

class ProfileFormResult {
  const ProfileFormResult({required this.name, required this.buildId});

  final String name;
  final String buildId;
}

class DuplicateProfileResult {
  const DuplicateProfileResult({required this.name, required this.copyPayload});

  final String name;
  final bool copyPayload;
}

Future<ProfileFormResult?> showProfileFormDialog(
  BuildContext context, {
  required ProfilesController controller,
  Profile? profile,
}) {
  return showDialog<ProfileFormResult>(
    context: context,
    builder: (context) => _ProfileFormDialog(controller: controller, profile: profile),
  );
}

Future<DuplicateProfileResult?> showDuplicateProfileDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<DuplicateProfileResult>(
    context: context,
    builder: (context) => _DuplicateProfileDialog(initialName: initialName),
  );
}

Future<bool> confirmDeleteProfile(BuildContext context, Profile profile) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.profilesDeleteTitle),
      content: Text('${profile.name}\n\n${l10n.profilesDeleteMessage}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.versionsCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.profilesDelete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<bool> confirmQuarantineRemoval(BuildContext context, String appPath) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.profilesQuarantineTitle),
      content: Text('$appPath\n\n${l10n.profilesQuarantineMessage}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.versionsCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.profilesQuarantineRemove),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _ProfileFormDialog extends StatefulWidget {
  const _ProfileFormDialog({required this.controller, this.profile});

  final ProfilesController controller;
  final Profile? profile;

  @override
  State<_ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<_ProfileFormDialog> {
  late final TextEditingController _nameController;
  String? _buildId;
  bool _saving = false;

  bool get _isEdit => widget.profile != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _buildId = widget.profile?.buildId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<Build> _selectableBuilds(Profile? profile) {
    final builds = widget.controller.buildsById.value.values.where((build) {
      if (build.id == profile?.buildId) {
        return true;
      }
      return build.status == BuildStatus.installed &&
          (build.pythonVersion?.trim().isNotEmpty ?? false);
    }).toList();
    builds.sort((a, b) => b.version.compareTo(a.version));
    return builds;
  }

  bool _pythonChanges(Profile? profile, Build build) {
    return profile != null && profile.pythonVersion != build.pythonVersion;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text;
    final buildId = _buildId;
    if (buildId == null) {
      return;
    }

    setState(() => _saving = true);
    final result = _isEdit
        ? await _edit(name, buildId)
        : await widget.controller.create(name: name, buildId: buildId);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    result.fold(
      (_) => Navigator.of(context).pop(ProfileFormResult(name: name, buildId: buildId)),
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_isEdit ? l10n.profilesEditFailed : l10n.profilesCreateFailed}: $error',
            ),
          ),
        );
      },
    );
  }

  Future<Result<Profile>> _edit(String name, String buildId) async {
    final profile = widget.profile!;
    final renamed = await widget.controller.rename(profileId: profile.id, name: name);
    if (renamed.isErr) {
      return renamed;
    }
    if (profile.buildId != buildId) {
      final rebound = await widget.controller.setBuild(
        profileId: profile.id,
        buildId: buildId,
      );
      if (rebound.isErr) {
        return Err(rebound.errorOrNull!);
      }
    }
    return renamed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = widget.profile;
    final builds = _selectableBuilds(profile);
    final selected = _buildId == null || !builds.any((build) => build.id == _buildId)
        ? null
        : builds.firstWhere((build) => build.id == _buildId);
    final pythonChanged = selected != null && _pythonChanges(profile, selected);

    return AlertDialog(
      title: Text(_isEdit ? l10n.profilesEditTitle : l10n.profilesCreateTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.profilesName),
            ),
            const SizedBox(height: 12),
            if (builds.isEmpty)
              Text(l10n.profilesNoBuildsMessage)
            else
              DropdownButtonFormField<String>(
                initialValue: selected?.id,
                decoration: InputDecoration(labelText: l10n.profilesBuild),
                items: [
                  for (final build in builds)
                    DropdownMenuItem(
                      value: build.id,
                      child: Text(
                        '${build.version} · ${build.channel.name}'
                        '${build.pythonVersion == null ? '' : ' · py${build.pythonVersion}'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _saving ? null : (value) => setState(() => _buildId = value),
              ),
            if (pythonChanged) ...[
              const SizedBox(height: 12),
              Text(
                l10n.profilesBuildChangedWarning,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.versionsCancel),
        ),
        FilledButton(
          onPressed: _saving || _buildId == null ? null : _submit,
          child: Text(_isEdit ? l10n.profilesSave : l10n.profilesCreate),
        ),
      ],
    );
  }
}

class _DuplicateProfileDialog extends StatefulWidget {
  const _DuplicateProfileDialog({required this.initialName});

  final String initialName;

  @override
  State<_DuplicateProfileDialog> createState() => _DuplicateProfileDialogState();
}

class _DuplicateProfileDialogState extends State<_DuplicateProfileDialog> {
  late final TextEditingController _nameController;
  bool _copyPayload = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '${widget.initialName} (copy)');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.profilesDuplicateTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.profilesName),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _copyPayload,
              onChanged: (value) => setState(() => _copyPayload = value),
              title: Text(
                _copyPayload ? l10n.profilesDuplicatePayload : l10n.profilesDuplicateConfig,
              ),
              subtitle: Text(l10n.profilesDuplicatePayloadHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.versionsCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            DuplicateProfileResult(
              name: _nameController.text,
              copyPayload: _copyPayload,
            ),
          ),
          child: Text(l10n.profilesDuplicate),
        ),
      ],
    );
  }
}
