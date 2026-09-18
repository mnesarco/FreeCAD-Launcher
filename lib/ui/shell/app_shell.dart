import 'package:flutter/material.dart';

import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/ui/addons/addons_view.dart';
import 'package:freecad_launcher/ui/builds/builds_view.dart';
import 'package:freecad_launcher/ui/home/home_view.dart';
import 'package:freecad_launcher/ui/macros/macros_view.dart';
import 'package:freecad_launcher/ui/profiles/profiles_view.dart';
import 'package:freecad_launcher/ui/settings/settings_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = [
      _Section(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: l10n.navHome,
        view: const HomeView(),
      ),
      _Section(
        icon: Icons.workspaces_outlined,
        selectedIcon: Icons.workspaces,
        label: l10n.navProfiles,
        view: const ProfilesView(),
      ),
      _Section(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: l10n.navVersions,
        view: const BuildsView(),
      ),
      _Section(
        icon: Icons.extension_outlined,
        selectedIcon: Icons.extension,
        label: l10n.navAddons,
        view: const AddonsView(),
      ),
      _Section(
        icon: Icons.auto_fix_high_outlined,
        selectedIcon: Icons.auto_fix_high,
        label: l10n.navMacros,
        view: const MacrosView(),
      ),
      _Section(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.navSettings,
        view: const SettingsView(),
      ),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final section in sections)
                NavigationRailDestination(
                  icon: Icon(section.icon),
                  selectedIcon: Icon(section.selectedIcon),
                  label: Text(section.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [for (final section in sections) section.view],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _StatusBar(),
    );
  }
}

class _Section {
  const _Section({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.view,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget view;
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(l10n.appTitle, style: theme.textTheme.labelSmall),
          const Spacer(),
          Text(appVersion, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
