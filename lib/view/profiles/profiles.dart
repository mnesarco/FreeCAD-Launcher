import 'dart:math';

import 'package:flutter/material.dart';
import 'package:freecad_launcher/view/widgets.dart';
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
        SearchField(value: controller.searchFilter, hintText: 'Filter by name...'),
        Expanded(
          child: state.map(
            data: (list) => GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) => Hero(
                tag: 'profile-${list[i].id}',
                child: Card(
                  child: InkWell(
                    onTap: () {},
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder,
                          size: 40,
                          color: Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          list[i].name,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Text(
                        //   "profile_${list[i].id}",
                        //   textAlign: TextAlign.center,
                        //   style: Theme.of(context).textTheme.bodySmall,
                        // ),
                        // IconButton(
                        //   icon: const Icon(Icons.delete, size: 18),
                        //   onPressed: () => controller.db.deleteProfile(list[i].id),
                        // ),
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
