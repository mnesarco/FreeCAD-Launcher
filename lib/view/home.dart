import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'icons.dart';

import '../addon_catalog.dart';
import '../controller.dart';
import 'addons.dart';
import 'apps.dart';
import 'profiles.dart';

class HomeView extends StatefulWidget {
  final MainController controller;
  const HomeView({super.key, required this.controller});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _themeMode = signal(ThemeMode.dark);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = _themeMode.watch(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      themeMode: mode,
      home: DefaultTabController(
        animationDuration: Duration.zero,
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            leading: Icon(FreeCADIcons.freecad),
            title: const Text("FreeCAD Launcher"),
            actions: [
              IconButton(
                icon: Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                tooltip: mode == ThemeMode.dark ? 'Switch to light mode' : 'Switch to dark mode',
                onPressed: () {
                  _themeMode.value = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                },
              ),
              const SizedBox(width: 8),
            ],
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
              ProfileManagerView(controller: widget.controller.profiles),
              AppManagerView(controller: widget.controller.apps),
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
