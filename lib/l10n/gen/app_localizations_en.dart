// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FreeCAD Launcher';

  @override
  String get navHome => 'Home';

  @override
  String get navProfiles => 'Profiles';

  @override
  String get navVersions => 'Versions';

  @override
  String get navAddons => 'Addons';

  @override
  String get navMacros => 'Macros';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeEmptyTitle => 'Welcome to FreeCAD Launcher';

  @override
  String get homeEmptyMessage =>
      'Install a FreeCAD version and create a profile to get started.';

  @override
  String get profilesEmptyTitle => 'No profiles yet';

  @override
  String get profilesEmptyMessage =>
      'Create a profile to launch FreeCAD with its own settings, addons and Python packages.';

  @override
  String get versionsEmptyTitle => 'No FreeCAD versions installed';

  @override
  String get versionsEmptyMessage =>
      'Install a stable, weekly or custom FreeCAD build to get started.';

  @override
  String get addonsEmptyTitle => 'No addons installed';

  @override
  String get addonsEmptyMessage =>
      'Browse the official catalog and install workbenches into a profile.';

  @override
  String get macrosEmptyTitle => 'No macros';

  @override
  String get macrosEmptyMessage =>
      'Install macros from the official catalog into a profile.';

  @override
  String get settingsDataDirectory => 'Data directory';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicense => 'License';

  @override
  String get settingsDiagnostics => 'Diagnostics';

  @override
  String get diagnosticsRun => 'Run diagnostics';

  @override
  String get diagnosticsRunning => 'Running…';

  @override
  String get diagnosticDataDirectory => 'Data directory writable';

  @override
  String get diagnosticFuse => 'AppImage support (FUSE)';

  @override
  String get diagnosticGatekeeper => 'macOS Gatekeeper';

  @override
  String get diagnosticDiskSpace => 'Disk space';

  @override
  String get diagnosticsStatusOk => 'OK';

  @override
  String get diagnosticsStatusWarning => 'Warning';

  @override
  String get diagnosticsStatusError => 'Error';

  @override
  String get diagnosticsStatusNotApplicable => 'Not applicable';
}
