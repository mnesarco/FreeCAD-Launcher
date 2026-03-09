import 'package:flutter/material.dart';
import 'package:freecad_launcher/model/addons.dart';
import 'package:freecad_launcher/controller/main.dart';
import 'package:freecad_launcher/view/addons/list.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Displays the addon catalog in a searchable list.
class AddonCatalogView extends StatefulWidget {
  final MainController controller;

  const AddonCatalogView({required this.controller, super.key});

  @override
  State<AddonCatalogView> createState() => _AddonCatalogViewState();
}

class _AddonCatalogViewState extends State<AddonCatalogView> {
  final searchFilter = signal('');

  @override
  void dispose() {
    searchFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AddonCatalog>(
      future: widget.controller.addonsCatalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 8),
                Text("Loading...", style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading addons: ${snapshot.error}'));
        }
        return AddonList(catalog: snapshot.data!, searchFilter: searchFilter);
      },
    );
  }
}
