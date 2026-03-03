import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:file_selector/file_selector.dart';

import '../database.dart';
import 'icons.dart';
import 'widgets.dart';

/// The value returned by [AppFormDialog] on submission.
class AppFormResult {
  final String name;
  final String command;
  final String args;
  final String kind;
  final String cwd;

  const AppFormResult({
    required this.name,
    required this.command,
    required this.args,
    required this.kind,
    required this.cwd,
  });
}

/// Signal-based form state for the [App] model.
class AppFormController {
  static const kinds = ['AppImage', 'Executable', 'Flatpak', 'Snap', 'System'];

  final formKey = GlobalKey<FormState>();

  final name = signal('');
  final command = signal('');
  final args = signal('');
  final kind = signal('AppImage');
  final cwd = signal('');

  /// Bumped only on picker selection to force field rebuild.
  final commandVersion = signal(0);
  final cwdVersion = signal(0);

  final bool isEditing;

  AppFormController({App? app}) : isEditing = app != null {
    if (app != null) {
      name.value = app.name;
      command.value = app.command;
      args.value = app.args;
      kind.value = app.kind;
      cwd.value = app.cwd;
    }
  }

  AppFormResult? submit() {
    if (!formKey.currentState!.validate()) return null;
    return AppFormResult(
      name: name.value.trim(),
      command: command.value.trim(),
      args: args.value.trim(),
      kind: kind.value,
      cwd: cwd.value.trim(),
    );
  }
}

/// A form dialog for creating or editing an [App].
///
/// When [app] is null the form operates in **create** mode;
/// otherwise it pre-fills every field for editing.
class AppFormDialog extends StatelessWidget {
  final AppFormController controller;
  const AppFormDialog({super.key, required this.controller});

  /// Convenience helper – opens the dialog and returns the result.
  static Future<AppFormResult?> show(BuildContext context, {App? app}) {
    final ctrl = AppFormController(app: app);
    return showDialog<AppFormResult>(
      context: context,
      builder: (_) => AppFormDialog(controller: ctrl),
    );
  }

  void _submit(BuildContext context) {
    final result = controller.submit();
    if (result != null) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final selectedKind = controller.kind.watch(context);

    return AlertDialog(
      title: Text(controller.isEditing ? 'Edit Application' : 'New Application'),
      content: SizedBox(
        width: 800,
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                formFieldRow(
                  label: 'Name',
                  field: TextFormFieldExt(
                    value: controller.name,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                ),
                const SizedBox(height: 12),
                formFieldRow(
                  label: 'Kind',
                  field: DropdownButtonFormField<String>(
                    initialValue: selectedKind,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: AppFormController.kinds
                        .map(
                          (k) => DropdownMenuItem(
                            value: k,
                            child: Row(
                              children: [
                                Icon(appKindIcon(k), size: 20),
                                const SizedBox(width: 8),
                                Text(k),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) controller.kind.value = v;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                formFieldRow(
                  label: 'Command',
                  field: PathFormField(
                    value: controller.command,
                    type: PathType.file,
                    hintText: 'e.g. /usr/bin/freecad',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Command is required' : null,
                    acceptedTypeGroups: [
                      XTypeGroup(
                        label: 'Executables',
                        extensions: ['exe', 'AppImage'],
                        mimeTypes: [
                          'application/x-executable',
                          'application/vnd.microsoft.portable-executable',
                        ],
                      ),
                    ],
                    onChanged: (path) {
                      if (path.toLowerCase().contains(".appimage")) {
                        controller.kind.value = "AppImage";
                      } else {
                        controller.kind.value = "Executable";
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                formFieldRow(
                  label: 'Arguments',
                  field: TextFormFieldExt(
                    value: controller.args,
                    hintText: 'e.g. --single-instance',
                  ),
                ),
                const SizedBox(height: 12),
                formFieldRow(
                  label: 'Working Dir',
                  field: PathFormField(
                    value: controller.cwd,
                    type: PathType.dir,
                    hintText: 'e.g. /home/user/projects',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: () => _submit(context),
          icon: Icon(controller.isEditing ? Icons.save : Icons.add),
          label: Text(controller.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
