import 'package:flutter/material.dart';
import 'package:freecad_launcher/service/database.dart';
import 'package:freecad_launcher/view/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// The value returned by [ProfileFormDialog] on submission.
class ProfileFormResult {
  final String name;
  final String args;
  final String cwd;

  const ProfileFormResult({required this.name, required this.args, required this.cwd});
}

/// Signal-based form state for the [Profile] model.
class ProfileFormController {
  final formKey = GlobalKey<FormState>();

  final name = signal('');
  final args = signal('');
  final cwd = signal('');

  final bool isEditing;

  ProfileFormController({Profile? profile}) : isEditing = profile != null {
    if (profile != null) {
      name.value = profile.name;
      args.value = profile.args;
      cwd.value = profile.cwd;
    }
  }

  ProfileFormResult? submit() {
    if (!formKey.currentState!.validate()) return null;
    return ProfileFormResult(
      name: name.value.trim(),
      args: args.value.trim(),
      cwd: cwd.value.trim(),
    );
  }
}

/// A form dialog for creating or editing a [Profile].
///
/// When [profile] is null the form operates in **create** mode;
/// otherwise it pre-fills every field for editing.
class ProfileFormDialog extends StatelessWidget {
  final ProfileFormController controller;
  const ProfileFormDialog({super.key, required this.controller});

  /// Convenience helper – opens the dialog and returns the result.
  static Future<ProfileFormResult?> show(BuildContext context, {Profile? profile}) {
    final ctrl = ProfileFormController(profile: profile);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(controller.isEditing ? 'Edit Profile' : 'New Profile'),
      content: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            formFieldRow(
              label: 'Name',
              field: TextFormFieldExt(
                value: controller.name,
                hintText: 'e.g. FreeCAD Dev',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
            ),
            const SizedBox(height: 12),
            formFieldRow(
              label: 'Arguments',
              field: TextFormFieldExt(value: controller.args, hintText: 'e.g. --single-instance'),
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
