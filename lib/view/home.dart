import 'package:flutter/material.dart';
import 'icons.dart';

import '../addon_catalog.dart';
import '../controller.dart';
import 'addons.dart';
import 'apps.dart';
import 'profiles.dart';

class HomeView extends StatelessWidget {
  final MainController controller;
  const HomeView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blueGrey,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueGrey,
      ),
      themeMode: ThemeMode.dark,
      home: DefaultTabController(
        animationDuration: Duration.zero,
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            leading: Icon(FreeCADIcons.freecad),
            title: const Text("FreeCAD Launcher"),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.rocket_launch), text: "Launchers"),
                Tab(icon: Icon(Icons.folder), text: "Profiles"),
                Tab(icon: Icon(FreeCADIcons.freecad), text: "Applications"),
                Tab(icon: Icon(Icons.extension), text: "Addons"),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Container(),
              ProfileManagerView(controller: controller.profiles),
              AppManagerView(controller: controller.apps),
              AddonCatalogView(
                catalogFuture: AddonCatalog.loadFromFile('addon_catalog_cache.json'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
