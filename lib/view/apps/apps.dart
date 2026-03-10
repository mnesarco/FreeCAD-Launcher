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

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final search = controller.searchFilter.watch(context);
    final state = controller.items.watch(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        SearchField(value: controller.searchFilter),
        Expanded(
          child: state.map(
            data: (list) => GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.16,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) => Hero(
                tag: 'app-${list[i].id}',
                child: Card(
                  child: InkWell(
                    onTap: () => _openEditDialog(context, list[i]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(appKindIcon(list[i].kind), size: 64),
                        const SizedBox(height: 8),
                        Text(
                          list[i].name,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          list[i].kind,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err) => Center(child: Text('Error: $err')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FloatingActionButton(
              onPressed: () => _openAddDialog(context),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}
