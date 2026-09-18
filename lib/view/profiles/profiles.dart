import 'package:flutter/material.dart';
import 'package:freecad_launcher/view/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xml/xml_events.dart';

import '../../controller/main.dart';
import '../../service/database.dart';
import 'form.dart';

class ProfileManagerView extends StatelessWidget {
  final ProfileController controller;
  const ProfileManagerView({super.key, required this.controller});

  Future<void> _openAddDialog(BuildContext context) async {
    final result = await ProfileFormDialog.show(context, profileController: controller);
    if (result == null) return;
    controller.add(
      result.name,
      result.args,
      result.appId,
      result.freecadVersion,
      result.pythonVersion,
    );
  }

  Future<void> _openEditDialog(BuildContext context, Profile profile) async {
    final result = await ProfileFormDialog.show(
      context,
      profileController: controller,
      profile: profile,
    );
    if (result == null) return;
    controller.db.updateProfile(
      Profile(
        id: profile.id,
        name: result.name,
        args: result.args,
        freecadVersion: result.freecadVersion,
        pythonVersion: result.pythonVersion,
        appId: result.appId,
      ),
    );
  }

  Widget _grid(BuildContext context) {
    final state = controller.items.watch(context);
    final theme = Theme.of(context);
    final main = MainController.of(context);
    return Expanded(
      child: state.map(
        data: (list) => ResponsiveGrid(
          cellWidth: 200,
          cellHeight: 220,
          padding: const EdgeInsets.all(12),
          data: list,
          builder: (context, profile) {
            final async = main.apps.items.value;
            final appsList = async.hasValue ? (async.value ?? []) : [];
            final app = appsList.where((a) => a.id == profile.appId).firstOrNull;
            return InkWell(
              onTap: () => _openEditDialog(context, profile),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    profile.name,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'FC ${profile.freecadVersion}  Py ${profile.pythonVersion}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (app != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      app.name,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err) => Center(child: Text('Error: $err')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final search = controller.searchFilter.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(child: SearchField(value: controller.searchFilter)),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () => _openAddDialog(context),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
        _grid(context),
      ],
    );
  }
}
