import 'package:flutter/material.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';

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
      _Section(icon: Icons.home_outlined, selectedIcon: Icons.home, label: l10n.navHome),
      _Section(
        icon: Icons.workspaces_outlined,
        selectedIcon: Icons.workspaces,
        label: l10n.navProfiles,
      ),
      _Section(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: l10n.navVersions,
      ),
      _Section(icon: Icons.extension_outlined, selectedIcon: Icons.extension, label: l10n.navAddons),
      _Section(
        icon: Icons.auto_fix_high_outlined,
        selectedIcon: Icons.auto_fix_high,
        label: l10n.navMacros,
      ),
      _Section(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: l10n.navSettings),
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
          Expanded(child: _SectionPlaceholder(title: sections[_selectedIndex].label)),
        ],
      ),
      bottomNavigationBar: const _StatusBar(),
    );
  }
}

class _Section {
  const _Section({required this.icon, required this.selectedIcon, required this.label});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Text('FreeCAD Launcher', style: theme.textTheme.labelSmall),
          const Spacer(),
          Text('0.1.0-dev', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
