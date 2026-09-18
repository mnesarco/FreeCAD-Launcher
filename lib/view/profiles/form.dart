import 'package:flutter/material.dart';
import 'package:freecad_launcher/controller/profiles.dart';
import 'package:freecad_launcher/service/database.dart';
import 'package:freecad_launcher/view/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

class ProfileFormResult {
  final String name;
  final String args;
  final int? appId;
  final String freecadVersion;
  final String pythonVersion;

  const ProfileFormResult({
    required this.name,
    required this.args,
    required this.appId,
    required this.freecadVersion,
    required this.pythonVersion,
  });
}

class ProfileFormController {
  final formKey = GlobalKey<FormState>();
  final name = signal('');
  final args = signal('');
  final selectedAppId = signal<int?>(null);
  final freecadVersion = signal('');
  final pythonVersion = signal('');
  final isLoadingVersion = signal(false);
  final versionError = signal<String?>(null);

  final bool isEditing;
  final Profile? profile;
  final ProfileController profileController;
  final String? _originalFreecadVersion;

  ProfileFormController({required this.profileController, this.profile})
    : isEditing = profile != null,
      _originalFreecadVersion = profile?.freecadVersion {
    final p = profile;
    if (p != null) {
      name.value = p.name;
      args.value = p.args;
      selectedAppId.value = p.appId;
      freecadVersion.value = p.freecadVersion;
      pythonVersion.value = p.pythonVersion;
    }
  }

  Future<void> selectApp(App app) async {
    isLoadingVersion.value = true;
    versionError.value = null;
    try {
      final version = await profileController.resolveFreeCADVersion(app);
      print("Original: ${_originalFreecadVersion}, selected=${version}");
      if (version == null) {
        versionError.value = 'Could not determine FreeCAD version for this app.';
        isLoadingVersion.value = false;
        return;
      }
      if (isEditing && version.freecad != _originalFreecadVersion) {
        versionError.value =
            'Incompatible App. The profile requires FreeCAD $_originalFreecadVersion '
            '(same major version).';
        isLoadingVersion.value = false;
        return;
      }
      selectedAppId.value = app.id;
      freecadVersion.value = version.freecad;
      pythonVersion.value = version.python;
    } finally {
      isLoadingVersion.value = false;
    }
  }

  ProfileFormResult? submit() {
    if (!formKey.currentState!.validate()) return null;
    return ProfileFormResult(
      name: name.value.trim(),
      args: args.value.trim(),
      appId: selectedAppId.value,
      freecadVersion: freecadVersion.value.trim(),
      pythonVersion: pythonVersion.value.trim(),
    );
  }
}

class ProfileFormDialog extends StatelessWidget {
  final ProfileFormController controller;
  static const double spacing = 12;
  const ProfileFormDialog({super.key, required this.controller});

  static Future<ProfileFormResult?> show(
    BuildContext context, {
    required ProfileController profileController,
    Profile? profile,
  }) {
    final ctrl = ProfileFormController(profileController: profileController, profile: profile);
    final size = MediaQuery.sizeOf(context);
    return showDialog<ProfileFormResult>(
      context: context,
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width * 0.99,
          maxHeight: (size.height - 64) * 0.99,
        ),
        child: ProfileFormDialog(controller: ctrl),
      ),
    );
  }

  void _submit(BuildContext context) {
    final result = controller.submit();
    if (result != null) Navigator.of(context).pop(result);
  }

  List<Widget> freecadVersionInput() {
    if (controller.isEditing) {
      return [
        const SizedBox(height: spacing),
        formFieldRow(
          label: 'FreeCAD Version',
          field: Watch(
            (_) => TextFormField(
              initialValue: controller.freecadVersion.value,
              readOnly: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            ),
          ),
        ),
      ];
    }
    return [];
  }

  List<Widget> pythonVersionInput() {
    if (controller.isEditing) {
      return [
        const SizedBox(height: spacing),
        formFieldRow(
          label: 'Python Version',
          field: Watch(
            (_) => TextFormField(
              initialValue: controller.pythonVersion.value,
              readOnly: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            ),
          ),
        ),
      ];
    }
    return [];
  }

  Widget appSelectionError() {
    return Watch((ctx) {
      final err = controller.versionError.value;
      if (err != null) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            err,
            style: Theme.of(
              ctx,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).colorScheme.error),
          ),
        );
      }
      if (controller.isLoadingVersion.value) {
        return const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator());
      }
      return const SizedBox.shrink();
    });
  }

  List<Widget> appSelectInput(BuildContext context) {
    final apps = controller.profileController.apps.watch(context);
    return [
      const SizedBox(height: spacing),
      formFieldRow(
        label: 'App',
        field: apps.map(
          data: (list) => DropdownButtonFormField<int>(
            initialValue: controller.selectedAppId.value,
            validator: (v) => v == null ? 'Application is required' : null,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            hint: const Text('Select FreeCAD App'),
            items: list
                .map(
                  (app) => DropdownMenuItem(
                    value: app.id,
                    child: Text(app.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (appId) async {
              if (appId == null) return;
              final app = list.firstWhere((a) => a.id == appId);
              await controller.selectApp(app);
            },
          ),
          loading: () => CircularProgressIndicator(),
          error: () => Text("Error loading applications"),
        ),
      ),
      appSelectionError(),
    ];
  }

  List<Widget> cliArgumentsInput() {
    return [
      const SizedBox(height: spacing),
      formFieldRow(
        label: 'Cli arguments',
        field: TextFormFieldExt(value: controller.args, hintText: 'e.g. -P path/to/x'),
      ),
    ];
  }

  List<Widget> nameInput() {
    return [
      formFieldRow(
        label: 'Name',
        field: TextFormFieldExt(
          value: controller.name,
          hintText: 'e.g. My FreeCAD Profile',
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),
      ),
    ];
  }

  List<Widget> actionButtons(BuildContext context) {
    return [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      FilledButton.icon(
        onPressed: () => _submit(context),
        icon: Icon(controller.isEditing ? Icons.save : Icons.add),
        label: Text(controller.isEditing ? 'Save' : 'Add'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(controller.isEditing ? 'Edit Profile' : 'New Profile'),
      content: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...nameInput(),
            ...appSelectInput(context),
            ...cliArgumentsInput(),
            ...freecadVersionInput(),
            ...pythonVersionInput(),
          ],
        ),
      ),
      actions: actionButtons(context),
    );
  }
}
