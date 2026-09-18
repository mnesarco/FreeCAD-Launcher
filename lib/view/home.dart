import 'package:flutter/material.dart';
import 'package:freecad_launcher/controller/addons.dart';
import 'package:freecad_launcher/controller/main.dart';
import 'package:freecad_launcher/view/addons/catalog.dart';
import 'package:freecad_launcher/view/apps/apps.dart';
import 'package:freecad_launcher/view/icons.dart';
import 'package:freecad_launcher/view/profiles/profiles.dart';
import 'package:signals_flutter/signals_flutter.dart';

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
    widget.controller.dispose();
    super.dispose();
  }

  AppBar _appBar(ThemeMode mode) {
    return AppBar(
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
          // Tab(icon: Icon(Icons.rocket_launch), text: "Launchers"),
          Tab(icon: Icon(Icons.rocket_launch), text: "Profiles"),
          Tab(icon: Icon(FreeCADIcons.freecad), text: "Applications"),
          Tab(icon: Icon(Icons.extension), text: "Addons"),
          Tab(icon: Icon(Icons.auto_fix_high), text: "Macros"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = _themeMode.watch(context);

    final content = [
      // Container(),
      ProfileManagerView(controller: widget.controller.profiles),
      AppManagerView(controller: widget.controller.apps),
      AddonCatalogView(controller: widget.controller),
      Container(),
    ];

    return MainControllerScope(
      controller: widget.controller,
      child: MaterialApp(
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
          length: content.length,
          child: Scaffold(
            appBar: _appBar(mode),
            body: TabBarView(children: content),
            bottomNavigationBar: _StatusBar(),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = MainController.of(context);
    final dm = controller.downloadManager;
    final downloads = dm.activeDownloads.watch(context);
    final checkingUpdates = controller.addonsUpdateCheck.isChecking.watch(context);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          if (downloads.isNotEmpty) ...[
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Text(
              '${downloads.length} download${downloads.length == 1 ? '' : 's'} in progress: ${downloads.first}',
              style: theme.textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (checkingUpdates) Text('Checking updates...'),
          const Spacer(),
          Text('FreeCAD Launcher', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
