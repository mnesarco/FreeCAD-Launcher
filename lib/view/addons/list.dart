import 'package:flutter/material.dart';
import 'package:freecad_launcher/model/addons.dart';
import 'package:freecad_launcher/view/addons/detail.dart';
import 'package:freecad_launcher/view/addons/tile.dart';
import 'package:freecad_launcher/view/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AddonList extends StatelessWidget {
  final AddonCatalog catalog;
  final Signal<String> searchFilter;

  const AddonList({required this.catalog, required this.searchFilter, super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final query = searchFilter.watch(context);
    final filtered = catalog.search(query);

    return Column(
      children: [
        SearchField(value: searchFilter, hintText: 'Filter addons by name or description...'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${filtered.length} addon${filtered.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No addons found.'))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) => AddonTile(
                    addon: filtered[i],
                    detailWidgetBuilder: (a) => AddonDetailSheet(addon: a),
                  ),
                ),
        ),
      ],
    );
  }
}
