import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../controller/main.dart';

class ProfileManagerView extends StatelessWidget {
  final ProfileController controller;
  const ProfileManagerView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final search = controller.searchFilter.watch(context);
    final state = controller.items.watch(context);

    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Filter by name...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (val) => controller.searchFilter.value = val,
        ),
        Expanded(
          child: state.map(
            data: (list) => ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(list[i].name),
                subtitle: Text("profile_${list[i].id}"),
                leading: Icon(Icons.folder),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => controller.db.deleteProfile(list[i].id),
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
              onPressed: () =>
                  controller.add("Profile ${DateTime.now().second}", "Auto-comment", "", "", ""),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}
