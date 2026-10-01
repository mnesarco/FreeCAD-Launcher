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
  String get homeStepVersion => 'Add a FreeCAD version';

  @override
  String get homeStepProfile => 'Create a profile';

  @override
  String get homeStepAddons => 'Install addons';

  @override
  String get homeStatus => 'Status';

  @override
  String get homeStatBuilds => 'Versions';

  @override
  String get homeStatProfiles => 'Profiles';

  @override
  String get homeStatAddons => 'Addons';

  @override
  String get homeStatMacros => 'Macros';

  @override
  String get homeStatPackages => 'Python packages';

  @override
  String get homeLastUsed => 'Last used profile';

  @override
  String get homeLaunch => 'Launch';

  @override
  String get homeNoProfiles => 'No profiles yet';

  @override
  String get homeLastUsedNever => 'Never used';

  @override
  String get homeUpdates => 'Updates';

  @override
  String homeUpdatesAvailable(int count) {
    return '$count updates available';
  }

  @override
  String get homeUpdatesNone => 'Everything is up to date';

  @override
  String get homeUpdatesCheck => 'Check for updates';

  @override
  String get homeUpdatesChecking => 'Checking…';

  @override
  String get homeNews => 'News';

  @override
  String get homeNewsEmpty => 'No news items.';

  @override
  String get homeNewsError => 'Could not load the news feed.';

  @override
  String get homeNewsStale => 'Showing cached news.';

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
  String get pythonEmptyTitle => 'No Python packages';

  @override
  String get pythonEmptyMessage =>
      'Install packages into this profile\'s AdditionalPythonPackages; system Python is untouched.';

  @override
  String get pythonInstall => 'Install packages';

  @override
  String get pythonInstallTitle => 'Install Python packages';

  @override
  String get pythonPackagesLabel => 'Packages';

  @override
  String get pythonSpecs => 'One package per line, e.g. numpy==1.26.4';

  @override
  String get pythonInstallFailed => 'Install failed';

  @override
  String get pythonInstalledMessage => 'Packages installed';

  @override
  String get pythonRemove => 'Remove';

  @override
  String get pythonRemoveTitle => 'Remove this package?';

  @override
  String get pythonRemoveMessage =>
      'The package files are removed from this profile. System Python is untouched.';

  @override
  String get pythonRemovedMessage => 'Package removed';

  @override
  String get pythonRemoveFailed => 'Could not remove the package';

  @override
  String get pythonSource => 'Source';

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
  String get profilesConfigOpenFolder => 'Open profile folder';

  @override
  String get profilesConfigBackup => 'Back up config';

  @override
  String get profilesConfigBackupDone => 'Config backed up';

  @override
  String get profilesConfigNothing =>
      'No user.cfg or system.cfg to back up yet.';

  @override
  String get profilesConfigSnapshots => 'Snapshots';

  @override
  String get profilesConfigSnapshotsEmpty => 'No config snapshots yet.';

  @override
  String get profilesConfigRestore => 'Restore';

  @override
  String get profilesConfigRestoreTitle => 'Restore config snapshot';

  @override
  String get profilesConfigRestoreMessage =>
      'The current user.cfg and system.cfg are replaced by this snapshot.';

  @override
  String get profilesConfigRestored => 'Config restored';

  @override
  String get profilesConfigDeleteSnapshot => 'Delete snapshot';

  @override
  String get profilesConfigSnapshotDeleted => 'Snapshot deleted';

  @override
  String get profilesConfigFailed => 'Config action failed';

  @override
  String get profilesConfigOpenFailed => 'Could not open the folder';

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
  String get profilesExport => 'Export';

  @override
  String get profilesExportManifest => 'Export manifest';

  @override
  String get profilesExportDone => 'Manifest exported';

  @override
  String get profilesExportFailed => 'Could not export the manifest';

  @override
  String get profilesImport => 'Import manifest';

  @override
  String get manifestImportTitle => 'Import profile manifest';

  @override
  String get manifestImportFile => 'Profile manifest (JSON)';

  @override
  String get manifestReading => 'Reading manifest…';

  @override
  String get manifestReadFailed => 'Could not read the manifest file';

  @override
  String manifestSource(String os, String arch) {
    return 'Exported from $os ($arch)';
  }

  @override
  String get manifestSourceUnknown => 'Exported from another machine';

  @override
  String get manifestName => 'Profile name';

  @override
  String get manifestNameRequired => 'Enter a profile name';

  @override
  String manifestNameTooLong(int max) {
    return 'Profile names are limited to $max characters';
  }

  @override
  String get manifestNameControl =>
      'Profile names cannot contain control characters';

  @override
  String get manifestBuildLabel => 'Build';

  @override
  String manifestBuildMissing(String version, String channel) {
    return 'FreeCAD $version ($channel) is not installed. Choose another build or install it first.';
  }

  @override
  String get manifestBuildMissingVersion =>
      'The manifest does not name a build. Choose an installed build.';

  @override
  String get manifestNoBuild =>
      'No installed build with a detected Python is available. Install one first.';

  @override
  String get manifestContents => 'Contents';

  @override
  String manifestAddonsCount(int count) {
    return '$count addons';
  }

  @override
  String manifestPackagesCount(int count) {
    return '$count Python packages';
  }

  @override
  String manifestBundlesCount(int count) {
    return '$count collections';
  }

  @override
  String manifestMacrosCount(int count) {
    return '$count macros';
  }

  @override
  String manifestConfigFiles(String names) {
    return 'Config files: $names';
  }

  @override
  String manifestBundlesMissing(String names) {
    return 'Collections not present on this machine: $names';
  }

  @override
  String get manifestAbsolutePaths =>
      'These absolute paths in the exported config will not be valid here:';

  @override
  String get manifestReinstall => 'Reinstall addons and Python packages';

  @override
  String get manifestInstallRequirements =>
      'Also install declared Python requirements';

  @override
  String get manifestImport => 'Import';

  @override
  String get manifestImporting => 'Importing…';

  @override
  String manifestImportingStep(String name) {
    return 'Installing $name…';
  }

  @override
  String get manifestImported => 'Profile imported';

  @override
  String manifestImportSummary(int addons, int packages) {
    return '$addons addons and $packages Python packages installed';
  }

  @override
  String get manifestImportFailed => 'Could not import the profile';

  @override
  String manifestImportWarnings(String warnings) {
    return 'Warnings: $warnings';
  }

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
  String get versionsChannelStable => 'Stable';

  @override
  String get versionsChannelWeekly => 'Weekly';

  @override
  String versionsWeeklyBuild(String date) {
    return 'Weekly $date';
  }

  @override
  String get versionsWeeklyEmptyTitle => 'No weekly builds available';

  @override
  String get versionsWeeklyEmptyMessage =>
      'Refresh the catalog; weekly builds are published most Wednesdays.';

  @override
  String get versionsWeeklyInstallTitle => 'Install a development build?';

  @override
  String get versionsWeeklyInstallMessage =>
      'Weekly builds are development-quality: features may break and they are not covered by support. Keep a stable build for real work.';

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
  String get versionsRelabel => 'Rename';

  @override
  String get versionsRelabelTitle => 'Rename build';

  @override
  String get versionsRelabelField => 'Display name';

  @override
  String versionsRelabelHint(String version) {
    return 'Leave empty to show $version';
  }

  @override
  String versionsRelabelTooLong(int max) {
    return 'Use at most $max characters';
  }

  @override
  String get versionsRelabelInvalid => 'The label contains invalid characters';

  @override
  String get versionsRelabelSave => 'Save';

  @override
  String get versionsRelabelFailed => 'Could not rename the build';

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
  String get versionsRemoveMessageInPlace =>
      'Only the launcher entry is removed. The file you imported stays where it is.';

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
  String get bundlesCreate => 'New collection';

  @override
  String get bundlesEmptyTitle => 'No collections yet';

  @override
  String get bundlesEmptyMessage =>
      'Create a collection to save a set of addons and apply it to a profile.';

  @override
  String get bundlesName => 'Name';

  @override
  String get bundlesDescription => 'Description';

  @override
  String get bundlesFromProfile => 'Start from profile';

  @override
  String get bundlesFromProfileNone => 'Empty collection';

  @override
  String get bundlesItems => 'Addons';

  @override
  String bundlesItemCount(int count) {
    return '$count addon(s)';
  }

  @override
  String get bundlesNoItems => 'No addons in this collection yet.';

  @override
  String get bundlesAddAddon => 'Add addon';

  @override
  String get bundlesAddAddonTitle => 'Add addon to collection';

  @override
  String get bundlesSearchHint => 'Search addons, use #tag';

  @override
  String get bundlesNoMatches => 'No matching addons.';

  @override
  String get bundlesBranch => 'Branch';

  @override
  String get bundlesRemoveItem => 'Remove';

  @override
  String get bundlesEdit => 'Edit collection';

  @override
  String get bundlesDeleteTitle => 'Delete collection';

  @override
  String get bundlesDeleteMessage =>
      'The collection is removed. Addons installed from it are not affected.';

  @override
  String get bundlesDelete => 'Delete';

  @override
  String get bundlesSave => 'Save';

  @override
  String get bundlesCancel => 'Cancel';

  @override
  String get bundlesCreated => 'Collection created';

  @override
  String get bundlesSaved => 'Collection saved';

  @override
  String get bundlesDeleted => 'Collection deleted';

  @override
  String get bundlesCreateFailed => 'Could not create the collection';

  @override
  String get bundlesSaveFailed => 'Could not save the collection';

  @override
  String get bundlesDeleteFailed => 'Could not delete the collection';

  @override
  String get bundlesLoadFailed => 'Could not load the collections.';

  @override
  String get bundlesNameEmpty => 'Enter a name.';

  @override
  String get bundlesNameTooLong => 'Name is too long (max 64 characters).';

  @override
  String get bundlesNameTaken => 'A collection with this name already exists.';

  @override
  String get bundlesUnknownAddon => 'Not in catalog';

  @override
  String get bundlesApply => 'Apply';

  @override
  String get bundlesApplyTitle => 'Apply collection';

  @override
  String get bundlesApplyProfile => 'Target profile';

  @override
  String get bundlesApplyNoProfiles => 'Create a profile first.';

  @override
  String get bundlesApplyPreview => 'Preview';

  @override
  String get bundlesApplyActionInstall => 'Install';

  @override
  String get bundlesApplyActionUpdate => 'Update';

  @override
  String get bundlesApplyActionSkip => 'Skip';

  @override
  String get bundlesApplyActionUnavailable => 'Unavailable';

  @override
  String get bundlesApplyAddonMissing => 'Not in catalog';

  @override
  String bundlesApplyBranchMissing(String branch) {
    return 'Branch $branch is missing';
  }

  @override
  String get bundlesApplyInstallRequirements =>
      'Also install declared Python requirements';

  @override
  String get bundlesApplyNothing => 'Nothing to apply.';

  @override
  String get bundlesApplyRunning => 'Applying…';

  @override
  String get bundlesApplySummary => 'Result';

  @override
  String bundlesApplyInstalledCount(int count) {
    return '$count installed';
  }

  @override
  String bundlesApplyUpdatedCount(int count) {
    return '$count updated';
  }

  @override
  String bundlesApplySkippedCount(int count) {
    return '$count skipped';
  }

  @override
  String bundlesApplyFailedCount(int count) {
    return '$count failed';
  }

  @override
  String get bundlesApplyClose => 'Close';

  @override
  String get bundlesExport => 'Export';

  @override
  String get bundlesExported => 'Collection exported';

  @override
  String get bundlesExportFailed => 'Could not export the collection';

  @override
  String get bundlesImport => 'Import';

  @override
  String get bundlesImportTitle => 'Import collection';

  @override
  String get bundlesImportName => 'Name';

  @override
  String bundlesImportAddons(int count) {
    return 'Addons: $count';
  }

  @override
  String bundlesImportUnresolved(int count) {
    return 'Not in catalog: $count';
  }

  @override
  String get bundlesImportFailed => 'Could not import the collection';

  @override
  String get bundlesImported => 'Collection imported';

  @override
  String bundlesImportedUnresolved(int count) {
    return 'Imported, but $count addons are not in the catalog';
  }

  @override
  String get bundlesImportFile => 'Bundle JSON file';

  @override
  String get bundlesJsonFiles => 'JSON files';

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
  String get addonsRequirementsTitle => 'Python packages required';

  @override
  String get addonsRequirementsMessage =>
      'This addon declares Python dependencies. Install them into the profile with pip? Packages go under the profile\'s AdditionalPythonPackages; system Python is untouched.';

  @override
  String get addonsRequirementsInstall => 'Install packages';

  @override
  String get addonsRequirementsAddonOnly => 'Addon only';

  @override
  String get addonsRequirementsInvalid => 'Cannot parse';

  @override
  String get addonsRequirementsFailed => 'Python packages failed';

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
  String get macrosSearchHint => 'Search macros';

  @override
  String get macrosRefresh => 'Refresh';

  @override
  String get macrosInstall => 'Install';

  @override
  String get macrosSelectProfile => 'Select the target profile';

  @override
  String get macrosInstalledMessage => 'Macro installed';

  @override
  String get macrosInstallFailed => 'Could not install the macro';

  @override
  String get macrosLicenseUnknown => 'Unknown license';

  @override
  String get macrosNoMatches => 'No macros match the current search.';

  @override
  String get macrosCatalogEmptyTitle => 'Catalog is empty';

  @override
  String get macrosCatalogEmptyMessage =>
      'Refresh to download the macro catalog.';

  @override
  String get macrosLoadFailed => 'Could not load the macro catalog.';

  @override
  String get macrosStale =>
      'Using a cached catalog; newer macros may be missing.';

  @override
  String get macrosAuthor => 'Author';

  @override
  String get macrosVersion => 'Version';

  @override
  String get macrosUpdated => 'Updated';

  @override
  String get macrosClearSearch => 'Clear search';

  @override
  String get macrosTabInstalled => 'Installed';

  @override
  String get macrosTabCatalog => 'Catalog';

  @override
  String get macrosOpen => 'Open';

  @override
  String get macrosReveal => 'Reveal in folder';

  @override
  String get macrosDelete => 'Delete';

  @override
  String get macrosDeleteTitle => 'Delete macro';

  @override
  String get macrosDeleteMessage =>
      'The macro file is deleted from this profile.';

  @override
  String get macrosDeleted => 'Macro deleted';

  @override
  String get macrosDeleteFailed => 'Could not delete the macro';

  @override
  String get macrosActionFailed => 'Could not run the system action';

  @override
  String get jobsTitle => 'Jobs';

  @override
  String get jobsEmpty => 'No jobs yet.';

  @override
  String get jobsQueued => 'Queued';

  @override
  String get jobsRunning => 'Running';

  @override
  String get jobsCompleted => 'Completed';

  @override
  String get jobsFailed => 'Failed';

  @override
  String get jobsCancelled => 'Cancelled';

  @override
  String get jobsCancel => 'Cancel';

  @override
  String get jobsRetry => 'Retry';

  @override
  String get jobsClearFinished => 'Clear finished';

  @override
  String get jobsClose => 'Close';

  @override
  String get jobsLog => 'Log';

  @override
  String get settingsDataDirectory => 'Data directory';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsNewsFeed => 'News feed URL';

  @override
  String get settingsUpdateChecks => 'Update checks';

  @override
  String get settingsCadenceManual => 'Manual';

  @override
  String get settingsCadenceDaily => 'Daily';

  @override
  String get settingsCadenceWeekly => 'Weekly';

  @override
  String get settingsLogs => 'Logs';

  @override
  String get settingsLogLevel => 'Log level';

  @override
  String get settingsLogLevelDebug => 'Debug';

  @override
  String get settingsLogLevelInfo => 'Info';

  @override
  String get settingsLogLevelWarn => 'Warning';

  @override
  String get settingsLogLevelError => 'Error';

  @override
  String get settingsLogsFolder => 'Logs folder';

  @override
  String get settingsDebugBundle => 'Debug bundle';

  @override
  String get settingsDebugBundleDescription =>
      'Logs, versions and diagnostics (redacted)';

  @override
  String get settingsDebugBundleExport => 'Export';

  @override
  String settingsDebugBundleExported(String file) {
    return 'Debug bundle saved: $file';
  }

  @override
  String get settingsDebugBundleFailed => 'Could not export the debug bundle';

  @override
  String get settingsDebugBundleReveal => 'Reveal';

  @override
  String get settingsOpenFolderFailed => 'Could not open the folder';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsOpenFolder => 'Open folder';

  @override
  String get settingsCache => 'Cache';

  @override
  String get settingsCacheDownloads => 'Build downloads';

  @override
  String get settingsCacheGithub => 'GitHub releases';

  @override
  String get settingsCacheAddons => 'Addon catalog';

  @override
  String get settingsCacheMacros => 'Macro catalog';

  @override
  String get settingsCacheNews => 'News feed';

  @override
  String get settingsCacheClear => 'Clear';

  @override
  String get settingsCacheRefresh => 'Refresh sizes';

  @override
  String get settingsCacheCleanUp => 'Clean up now';

  @override
  String get settingsCacheRetention => 'Keep downloads for';

  @override
  String get settingsCacheRetentionForever => 'Forever';

  @override
  String settingsCacheRetentionDays(int days) {
    return '$days days';
  }

  @override
  String settingsCacheCleared(String size) {
    return 'Freed $size';
  }

  @override
  String get settingsCacheClearFailed => 'Could not clear the cache';

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
  String get settingsCopyright =>
      'Copyright 2026 Frank Martínez <mnesarco at gmail>';

  @override
  String get settingsAboutOpen => 'About FreeCAD Launcher';

  @override
  String get aboutTitle => 'About FreeCAD Launcher';

  @override
  String get aboutLogoLabel => 'FreeCAD logo';

  @override
  String get aboutTrademark =>
      'FreeCAD and the FreeCAD logo are trademarks of the FreeCAD Project Association AISBL.';

  @override
  String get aboutProject =>
      'FreeCAD Launcher is an independent, community driven, open source project developed and maintained by Frank D. Martínez <aka mnesarco>.';

  @override
  String get aboutClose => 'Close';

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

  @override
  String get addonsPin => 'Pin version';

  @override
  String get addonsUnpin => 'Unpin version';

  @override
  String get addonsPinned => 'Pinned';

  @override
  String get addonsPinFailed => 'Could not change the pin';

  @override
  String get addonsUpdateBadge => 'Update available';

  @override
  String get updatesCheck => 'Check updates';

  @override
  String get updatesTitle => 'Updates available';

  @override
  String get updatesBuildsSection => 'FreeCAD builds';

  @override
  String get updatesNone => 'No updates found';

  @override
  String get updatesCheckFailed => 'Could not check for updates';

  @override
  String updatesLastChecked(String when) {
    return 'Last checked: $when';
  }

  @override
  String updatesBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count updates',
      one: '1 update',
      zero: 'No updates',
    );
    return '$_temp0';
  }

  @override
  String updatesUpdateSelected(int count) {
    return 'Update selected ($count)';
  }

  @override
  String get updatesSelectAll => 'Select all';

  @override
  String updatesApplyingCount(int completed, int total) {
    return 'Updating $completed/$total…';
  }

  @override
  String updatesSummaryUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count updated',
      one: '1 updated',
    );
    return '$_temp0';
  }

  @override
  String updatesSummaryFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failed',
      one: '1 failed',
    );
    return '$_temp0';
  }

  @override
  String get updatesRetryFailed => 'Retry failed';
}
