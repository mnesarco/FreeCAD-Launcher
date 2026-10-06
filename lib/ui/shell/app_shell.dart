// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/ui/addons/addons_view.dart';
import 'package:freecad_launcher/ui/builds/builds_view.dart';
import 'package:freecad_launcher/ui/home/home_view.dart';
import 'package:freecad_launcher/ui/icons.dart';
import 'package:freecad_launcher/ui/jobs/jobs_dialog.dart';
import 'package:freecad_launcher/ui/macros/macros_view.dart';
import 'package:freecad_launcher/ui/profiles/profiles_view.dart';
import 'package:freecad_launcher/ui/settings/settings_view.dart';
import 'package:freecad_launcher/ui/updates/updates_status_chip.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/shell_controller.dart';
import 'package:freecad_launcher/ui/theme/app_colors.dart';

class AppShell extends SignalStatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _started = false;

  final _profilesKey = GlobalKey<ProfilesViewState>();
  final _buildsKey = GlobalKey<BuildsViewState>();
  final _addonsKey = GlobalKey<AddonsViewState>();
  final _macrosKey = GlobalKey<MacrosViewState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final services = AppScope.of(context);
    services.updates.start();
    unawaited(
      services.updates.checkIfDue(services.settings.updateCadence.value),
    );
    unawaited(services.cache.prune(services.settings.cacheRetention.value));
  }

  void _newProfile() {
    final shell = AppScope.of(context).shell;
    shell.select(AppSection.profiles);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profilesKey.currentState?.createProfile();
    });
  }

  void _refreshActiveSection() {
    switch (AppScope.of(context).shell.section.value) {
      case AppSection.home:
        break;
      case AppSection.profiles:
        _profilesKey.currentState?.refresh();
      case AppSection.versions:
        _buildsKey.currentState?.refresh();
      case AppSection.addons:
        _addonsKey.currentState?.refresh();
      case AppSection.macros:
        _macrosKey.currentState?.refresh();
      case AppSection.settings:
        break;
    }
  }

  void _focusActiveSearch() {
    switch (AppScope.of(context).shell.section.value) {
      case AppSection.home:
      case AppSection.profiles:
      case AppSection.versions:
      case AppSection.settings:
        break;
      case AppSection.addons:
        _addonsKey.currentState?.focusSearch();
      case AppSection.macros:
        _macrosKey.currentState?.focusSearch();
    }
  }

  Map<ShortcutActivator, VoidCallback> _shortcutBindings() {
    const digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
    ];
    final bindings = <ShortcutActivator, VoidCallback>{};
    for (var index = 0; index < digits.length; index++) {
      bindings[SingleActivator(digits[index], control: true)] =
          () => AppScope.of(context).shell.selectIndex(index);
      bindings[SingleActivator(digits[index], meta: true)] =
          () => AppScope.of(context).shell.selectIndex(index);
    }
    bindings[const SingleActivator(LogicalKeyboardKey.keyN, control: true)] =
        _newProfile;
    bindings[const SingleActivator(LogicalKeyboardKey.keyN, meta: true)] =
        _newProfile;
    bindings[const SingleActivator(LogicalKeyboardKey.f5)] =
        _refreshActiveSection;
    bindings[const SingleActivator(LogicalKeyboardKey.keyF, control: true)] =
        _focusActiveSearch;
    bindings[const SingleActivator(LogicalKeyboardKey.keyF, meta: true)] =
        _focusActiveSearch;
    return bindings;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shell = AppScope.of(context).shell;
    final section = shell.section.value;
    final sections = [
      _Section(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: l10n.navHome,
        view: HomeView(
          onOpenProfile: (profileId) {
            shell.select(AppSection.profiles);
            _profilesKey.currentState?.openProfile(profileId);
          },
        ),
      ),
      _Section(
        icon: Icons.workspaces_outlined,
        selectedIcon: Icons.workspaces,
        label: l10n.navProfiles,
        view: ProfilesView(key: _profilesKey),
      ),
      _Section(
        icon: FreeCADIcons.freecad,
        selectedIcon: FreeCADIcons.freecad,
        label: l10n.navVersions,
        view: BuildsView(key: _buildsKey),
      ),
      _Section(
        icon: Icons.extension_outlined,
        selectedIcon: Icons.extension,
        label: l10n.navAddons,
        view: AddonsView(key: _addonsKey),
      ),
      _Section(
        icon: Icons.auto_fix_high_outlined,
        selectedIcon: Icons.auto_fix_high,
        label: l10n.navMacros,
        view: MacrosView(key: _macrosKey),
      ),
      _Section(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.navSettings,
        view: const SettingsView(),
      ),
    ];

    return CallbackShortcuts(
      bindings: _shortcutBindings(),
      child: Focus(
        autofocus: true,
        child: Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: AppSection.values.indexOf(section),
            onDestinationSelected: shell.selectIndex,
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
              index: AppSection.values.indexOf(section),
              children: [for (final section in sections) section.view],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _StatusBar(),
        ),
      ),
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

class _StatusBar extends SignalWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = AppStatusColors.of(context);
    final l10n = AppLocalizations.of(context);
    final jobs = AppScope.of(context).jobs.jobs.value;
    final active = jobs.where((job) => job.isActive).toList();

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            l10n.appTitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (active.isNotEmpty) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => showJobsDialog(context),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: status.info,
                iconSize: 14,
                textStyle: theme.textTheme.labelSmall,
              ),
              icon: const _JobsActivityIcon(key: ValueKey('statusBarJobsIndicator')),
              label: Text('${active.length}  ·  ${active.first.label}'),
            ),
          ],
          const UpdatesStatusChip(),
          const Spacer(),
          Text(
            appVersion,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rotating sync icon shown next to the active-jobs label in the status bar so
/// running work is visible at a glance. Honors the OS "disable animations"
/// accessibility setting with a static icon.
class _JobsActivityIcon extends StatefulWidget {
  const _JobsActivityIcon({super.key});

  @override
  State<_JobsActivityIcon> createState() => _JobsActivityIconState();
}

class _JobsActivityIconState extends State<_JobsActivityIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.sync);
    if (MediaQuery.disableAnimationsOf(context)) {
      return icon;
    }
    return RotationTransition(turns: _controller, child: icon);
  }
}
