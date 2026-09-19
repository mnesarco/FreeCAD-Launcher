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
  String get profilesNew => 'New profile';

  @override
  String get profilesCreateTitle => 'Create profile';

  @override
  String get profilesEditTitle => 'Edit profile';

  @override
  String get profilesName => 'Name';

  @override
  String get profilesBuild => 'Build';

  @override
  String get profilesChannel => 'Channel';

  @override
  String get profilesPythonVersion => 'Python';

  @override
  String get profilesCreate => 'Create';

  @override
  String get profilesSave => 'Save';

  @override
  String get profilesCreateFailed => 'Could not create the profile';

  @override
  String get profilesEditFailed => 'Could not update the profile';

  @override
  String get profilesBuildChangedWarning =>
      'The new build uses a different Python version; addons and packages may need reinstalling.';

  @override
  String get profilesDuplicate => 'Duplicate';

  @override
  String get profilesDuplicateTitle => 'Duplicate profile';

  @override
  String get profilesDuplicateConfig => 'Config only';

  @override
  String get profilesDuplicatePayload => 'Full payload';

  @override
  String get profilesDuplicatePayloadHint =>
      'Also copy Mod, Python packages and macros';

  @override
  String get profilesDuplicateFailed => 'Could not duplicate the profile';

  @override
  String get profilesDelete => 'Delete';

  @override
  String get profilesDeleteTitle => 'Delete this profile?';

  @override
  String get profilesDeleteMessage =>
      'The profile directory and all of its data will be deleted. Shared builds are not affected.';

  @override
  String get profilesDeleteFailed => 'Could not delete the profile';

  @override
  String get profilesLaunch => 'Launch';

  @override
  String get profilesRunning => 'Running';

  @override
  String get profilesLaunchFailed => 'Launch failed';

  @override
  String get profilesQuarantineTitle => 'Remove quarantine?';

  @override
  String get profilesQuarantineMessage =>
      'macOS flagged this app as downloaded. Removing the quarantine attribute is needed to launch it. Only continue if you trust this build.';

  @override
  String get profilesQuarantineRemove => 'Remove and launch';

  @override
  String get profilesLastUsed => 'Last used';

  @override
  String get profilesNeverUsed => 'Never';

  @override
  String get profilesSize => 'Size';

  @override
  String get profilesAddons => 'Addons';

  @override
  String get profilesPackages => 'Packages';

  @override
  String get profilesHealth => 'Health';

  @override
  String get profilesLoading => 'Loading profiles…';

  @override
  String get profilesLoadFailed => 'Could not load profiles';

  @override
  String get profilesBack => 'Back';

  @override
  String get profilesNoBuildsTitle => 'No usable build';

  @override
  String get profilesNoBuildsMessage =>
      'Install a FreeCAD version with a detected Python interpreter before creating a profile.';

  @override
  String get profilesTabOverview => 'Overview';

  @override
  String get profilesTabAddons => 'Addons';

  @override
  String get profilesTabPython => 'Python';

  @override
  String get profilesTabMacros => 'Macros';

  @override
  String get profilesTabConfig => 'Config';

  @override
  String get profilesTabBackups => 'Backups';

  @override
  String get profilesComingSoon => 'This section arrives in a later milestone.';

  @override
  String get profilesPaths => 'Paths';

  @override
  String get profilesProfileHome => 'Profile home';

  @override
  String get profilesConfigFiles => 'Config files';

  @override
  String get profilesConfigMissing => 'Created on first launch';

  @override
  String get profilesStatusMissing => 'Build missing';

  @override
  String get profilesStatusBroken => 'Build broken';

  @override
  String get profilesShowCommand => 'Show launch command';

  @override
  String get profilesCommandTitle => 'Launch command';

  @override
  String get profilesCommandCopied => 'Command copied';

  @override
  String get profilesCommandEnvironment => 'Environment overrides';

  @override
  String get profilesCommandRemoved => 'Removed variables';

  @override
  String get profilesCommandFailed => 'Could not build the launch command';

  @override
  String get profilesClose => 'Close';

  @override
  String get profilesCopy => 'Copy';

  @override
  String get versionsEmptyTitle => 'No FreeCAD versions installed';

  @override
  String get versionsEmptyMessage =>
      'Install a stable, weekly or custom FreeCAD build to get started.';

  @override
  String get versionsTabInstalled => 'Installed';

  @override
  String get versionsTabAvailable => 'Available';

  @override
  String get versionsTabCustom => 'Custom';

  @override
  String get versionsRefresh => 'Check for updates';

  @override
  String get versionsInstall => 'Install';

  @override
  String get versionsHashing => 'Hashing file…';

  @override
  String get versionsDetectingPython => 'Detecting Python…';

  @override
  String get versionsDownloading => 'Downloading…';

  @override
  String get versionsInstalling => 'Installing…';

  @override
  String get versionsCancel => 'Cancel';

  @override
  String get versionsAvailableEmptyTitle => 'No versions available';

  @override
  String get versionsAvailableEmptyMessage =>
      'Check your connection and refresh the catalog.';

  @override
  String get versionsStaleCatalog =>
      'Using a cached catalog; newer versions may be missing.';

  @override
  String get versionsCatalogError => 'Could not load available versions.';

  @override
  String get versionsRetry => 'Retry';

  @override
  String get versionsInstallFailed => 'Install failed';

  @override
  String get versionsRemove => 'Remove';

  @override
  String get versionsVerify => 'Verify files';

  @override
  String get versionsRemoveFailed => 'Could not remove the build';

  @override
  String get versionsStatusMissing => 'Missing';

  @override
  String get versionsStatusBroken => 'Broken';

  @override
  String get versionsVerifyOk => 'Files verified';

  @override
  String get versionsVerifyMissing => 'Build files are missing';

  @override
  String get versionsVerifyBroken => 'Build files are broken or corrupted';

  @override
  String get versionsRemoveTitle => 'Remove this build?';

  @override
  String get versionsRemoveMessage =>
      'The files will be deleted from disk. Profiles using it will stop working.';

  @override
  String get versionsRemoveConfirm => 'Remove';

  @override
  String get versionsCustomEmptyTitle => 'Custom builds';

  @override
  String get versionsCustomEmptyMessage =>
      'Add a local archive or URL, or select a FreeCAD executable (self-compiled or installed by other means) to reference in place.';

  @override
  String get versionsCustomSource => 'File path or URL';

  @override
  String get versionsCustomLabel => 'Version label (optional)';

  @override
  String get versionsCustomChecksum => 'SHA-256 (optional)';

  @override
  String get versionsCustomChooseFile => 'Choose file…';

  @override
  String get versionsCustomImport => 'Import';

  @override
  String get versionsCustomTrustTitle => 'Import this build?';

  @override
  String get versionsCustomTrustMessage =>
      'Custom builds are not verified against the official catalog. Executables are run once, headless, to detect their Python version. Only import files you trust.';

  @override
  String get versionsCustomTrustConfirm => 'Import';

  @override
  String get versionsCustomImported => 'Build imported';

  @override
  String get versionsCustomFailed => 'Import failed';

  @override
  String get versionsCustomAllFiles => 'All files';

  @override
  String get versionsCustomBuilds => 'FreeCAD builds';

  @override
  String get versionsCustomPythonMissingTitle =>
      'Python interpreter not detected';

  @override
  String get versionsCustomPythonMissingMessage =>
      'The build was imported, but its Python interpreter could not be detected. Addons and Python packages need it; select the interpreter this build uses, or skip for now.';

  @override
  String get versionsCustomPythonChoose => 'Choose Python…';

  @override
  String get versionsCustomPythonSkip => 'Skip';

  @override
  String get versionsCustomPythonSaved => 'Python interpreter saved';

  @override
  String get versionsCustomPythonFailed => 'Could not use that Python';

  @override
  String get versionsPython => 'Python';

  @override
  String get versionsSize => 'Size';

  @override
  String get addonsEmptyTitle => 'No addons installed';

  @override
  String get addonsEmptyMessage =>
      'Browse the official catalog and install workbenches into a profile.';

  @override
  String get addonsTabCatalog => 'Catalog';

  @override
  String get addonsTabCollections => 'Collections';

  @override
  String get addonsCollectionsSoon =>
      'Collections arrive in a later milestone.';

  @override
  String get addonsSearchHint => 'Search addons, use #tag';

  @override
  String get addonsFilterAll => 'All';

  @override
  String get addonsFilterContent => 'Content';

  @override
  String get addonsContentWorkbench => 'Workbench';

  @override
  String get addonsContentMacro => 'Macro';

  @override
  String get addonsContentPreferencePack => 'Preference pack';

  @override
  String get addonsContentBundle => 'Bundle';

  @override
  String get addonsContentOther => 'Other';

  @override
  String get addonsFilterInstalled => 'Installed';

  @override
  String get addonsFilterNotInstalled => 'Not installed';

  @override
  String get addonsFilterInstalledState => 'Installed state';

  @override
  String get addonsFilters => 'Filters';

  @override
  String get addonsFilterClear => 'Clear filters';

  @override
  String get addonsClearSearch => 'Clear search';

  @override
  String get addonsFilterFreecad => 'FreeCAD';

  @override
  String get addonsFilterAnyVersion => 'Any version';

  @override
  String get addonsRefresh => 'Refresh';

  @override
  String get addonsStale =>
      'Using a cached catalog; newer addons may be missing.';

  @override
  String get addonsLoadFailed => 'Could not load the addon catalog.';

  @override
  String get addonsCatalogEmptyTitle => 'Catalog is empty';

  @override
  String get addonsCatalogEmptyMessage =>
      'Refresh to download the addon catalog.';

  @override
  String get addonsFilteredEmpty => 'No addons match the current filters.';

  @override
  String addonsInstalledIn(int count) {
    return 'Installed in $count profile(s)';
  }

  @override
  String get addonsInstalledBadge => 'Installed';

  @override
  String get addonsVersion => 'Version';

  @override
  String get addonsLicense => 'License';

  @override
  String get addonsAuthors => 'Authors';

  @override
  String get addonsRepository => 'Repository';

  @override
  String get addonsOpenRepository => 'Open repository';

  @override
  String get addonsFreecadRange => 'FreeCAD range';

  @override
  String get addonsLastUpdate => 'Last update';

  @override
  String get addonsContent => 'Content';

  @override
  String get addonsTags => 'Tags';

  @override
  String get addonsBranches => 'Branches';

  @override
  String get addonsRequirements => 'Python requirements';

  @override
  String get addonsRequirementsYes => 'Found';

  @override
  String get addonsRequirementsNo => 'None';

  @override
  String get addonsInstall => 'Install';

  @override
  String get addonsInstallTarget => 'Install into';

  @override
  String get addonsInstallFailed => 'Install failed';

  @override
  String get addonsInstalledMessage => 'Addon installed';

  @override
  String get addonsUpdate => 'Update';

  @override
  String get addonsUpdateAvailable =>
      'A newer version is available in the catalog.';

  @override
  String get addonsUpdatedMessage => 'Addon updated';

  @override
  String get addonsUpdateFailed => 'Update failed';

  @override
  String get addonsRemove => 'Remove';

  @override
  String get addonsRemoveTitle => 'Remove this addon?';

  @override
  String get addonsRemoveMessage =>
      'The addon files are deleted from this profile. Existing backups are kept.';

  @override
  String get addonsRemovedMessage => 'Addon removed';

  @override
  String get addonsRemoveFailed => 'Could not remove the addon';

  @override
  String get addonsNoProfiles => 'Create a profile first to install addons.';

  @override
  String get addonsInstallSoon =>
      'The install engine arrives in the next milestone.';

  @override
  String get addonsBack => 'Back';

  @override
  String get addonsNone => 'None';

  @override
  String get addonsAny => 'Any';

  @override
  String get macrosEmptyTitle => 'No macros';

  @override
  String get macrosEmptyMessage =>
      'Install macros from the official catalog into a profile.';

  @override
  String get settingsDataDirectory => 'Data directory';

  @override
  String get settingsCliWrapper => 'Command-line launcher';

  @override
  String get settingsCliWrapperInstalled => 'Installed';

  @override
  String get settingsCliWrapperNotInstalled => 'Not installed';

  @override
  String get settingsCliWrapperOnPath => 'Available on PATH';

  @override
  String settingsCliWrapperNotOnPath(String directory) {
    return 'Not on PATH — add $directory to PATH to use it from a fresh shell';
  }

  @override
  String get settingsCliWrapperInstall => 'Install wrapper';

  @override
  String get settingsCliWrapperRemove => 'Remove wrapper';

  @override
  String get settingsCliWrapperInstalledMessage => 'Wrapper installed';

  @override
  String get settingsCliWrapperRemovedMessage => 'Wrapper removed';

  @override
  String get settingsCliWrapperFailed => 'Could not update the wrapper';

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
