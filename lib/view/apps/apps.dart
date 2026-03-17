import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../icons.dart';
import 'form.dart';
import '../widgets.dart';

import '../../controller/main.dart';
import '../../service/database.dart';

class AppManagerView extends StatelessWidget {
  final AppController controller;
  const AppManagerView({super.key, required this.controller});

  Future<void> _openAddDialog(BuildContext context) async {
    final result = await AppFormDialog.show(context);
    if (result == null) return;
    controller.add(result.name, result.kind, result.command, result.args, result.cwd);
  }

  Future<void> _openEditDialog(BuildContext context, App app) async {
    final result = await AppFormDialog.show(context, app: app);
    if (result == null) return;
    controller.db.updateApp(
      App(
        id: app.id,
        name: result.name,
        command: result.command,
        args: result.args,
        kind: result.kind,
        cwd: result.cwd,
      ),
    );
  }

  Widget _grid(BuildContext context) {
    final state = controller.items.watch(context);
    final theme = Theme.of(context);
    return Expanded(
      child: state.map(
        data: (list) => ResponsiveGrid(
          cellWidth: 200,
          cellHeight: 220,
          padding: EdgeInsets.all(12),
          data: list,
          builder: (context, app) {
            return InkWell(
              onTap: () => _openEditDialog(context, app),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(appKindIcon(app.kind), size: 48),
                  const SizedBox(height: 8),
                  Text(
                    app.name,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(app.kind, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
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
