import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FreeCAD Launcher'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navProfiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get navProfiles;

  /// No description provided for @navVersions.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get navVersions;

  /// No description provided for @navAddons.
  ///
  /// In en, this message translates to:
  /// **'Addons'**
  String get navAddons;

  /// No description provided for @navMacros.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get navMacros;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FreeCAD Launcher'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Install a FreeCAD version and create a profile to get started.'**
  String get homeEmptyMessage;

  /// No description provided for @profilesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No profiles yet'**
  String get profilesEmptyTitle;

  /// No description provided for @profilesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a profile to launch FreeCAD with its own settings, addons and Python packages.'**
  String get profilesEmptyMessage;

  /// No description provided for @profilesNew.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get profilesNew;

  /// No description provided for @profilesCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get profilesCreateTitle;

  /// No description provided for @profilesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profilesEditTitle;

  /// No description provided for @profilesName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profilesName;

  /// No description provided for @profilesBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get profilesBuild;

  /// No description provided for @profilesChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get profilesChannel;

  /// No description provided for @profilesPythonVersion.
  ///
  /// In en, this message translates to:
  /// **'Python'**
  String get profilesPythonVersion;

  /// No description provided for @profilesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get profilesCreate;

  /// No description provided for @profilesSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profilesSave;

  /// No description provided for @profilesCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the profile'**
  String get profilesCreateFailed;

  /// No description provided for @profilesEditFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the profile'**
  String get profilesEditFailed;

  /// No description provided for @profilesBuildChangedWarning.
  ///
  /// In en, this message translates to:
  /// **'The new build uses a different Python version; addons and packages may need reinstalling.'**
  String get profilesBuildChangedWarning;

  /// No description provided for @profilesDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get profilesDuplicate;

  /// No description provided for @profilesDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate profile'**
  String get profilesDuplicateTitle;

  /// No description provided for @profilesDuplicateConfig.
  ///
  /// In en, this message translates to:
  /// **'Config only'**
  String get profilesDuplicateConfig;

  /// No description provided for @profilesDuplicatePayload.
  ///
  /// In en, this message translates to:
  /// **'Full payload'**
  String get profilesDuplicatePayload;

  /// No description provided for @profilesDuplicatePayloadHint.
  ///
  /// In en, this message translates to:
  /// **'Also copy Mod, Python packages and macros'**
  String get profilesDuplicatePayloadHint;

  /// No description provided for @profilesDuplicateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not duplicate the profile'**
  String get profilesDuplicateFailed;

  /// No description provided for @profilesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profilesDelete;

  /// No description provided for @profilesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this profile?'**
  String get profilesDeleteTitle;

  /// No description provided for @profilesDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'The profile directory and all of its data will be deleted. Shared builds are not affected.'**
  String get profilesDeleteMessage;

  /// No description provided for @profilesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the profile'**
  String get profilesDeleteFailed;

  /// No description provided for @profilesLaunch.
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get profilesLaunch;

  /// No description provided for @profilesRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get profilesRunning;

  /// No description provided for @profilesLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Launch failed'**
  String get profilesLaunchFailed;

  /// No description provided for @profilesQuarantineTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove quarantine?'**
  String get profilesQuarantineTitle;

  /// No description provided for @profilesQuarantineMessage.
  ///
  /// In en, this message translates to:
  /// **'macOS flagged this app as downloaded. Removing the quarantine attribute is needed to launch it. Only continue if you trust this build.'**
  String get profilesQuarantineMessage;

  /// No description provided for @profilesQuarantineRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove and launch'**
  String get profilesQuarantineRemove;

  /// No description provided for @profilesLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get profilesLastUsed;

  /// No description provided for @profilesNeverUsed.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get profilesNeverUsed;

  /// No description provided for @profilesSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get profilesSize;

  /// No description provided for @profilesAddons.
  ///
  /// In en, this message translates to:
  /// **'Addons'**
  String get profilesAddons;

  /// No description provided for @profilesPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get profilesPackages;

  /// No description provided for @profilesHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get profilesHealth;

  /// No description provided for @profilesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading profiles…'**
  String get profilesLoading;

  /// No description provided for @profilesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load profiles'**
  String get profilesLoadFailed;

  /// No description provided for @profilesBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get profilesBack;

  /// No description provided for @profilesNoBuildsTitle.
  ///
  /// In en, this message translates to:
  /// **'No usable build'**
  String get profilesNoBuildsTitle;

  /// No description provided for @profilesNoBuildsMessage.
  ///
  /// In en, this message translates to:
  /// **'Install a FreeCAD version with a detected Python interpreter before creating a profile.'**
  String get profilesNoBuildsMessage;

  /// No description provided for @profilesTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get profilesTabOverview;

  /// No description provided for @profilesTabAddons.
  ///
  /// In en, this message translates to:
  /// **'Addons'**
  String get profilesTabAddons;

  /// No description provided for @profilesTabPython.
  ///
  /// In en, this message translates to:
  /// **'Python'**
  String get profilesTabPython;

  /// No description provided for @pythonEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Python packages'**
  String get pythonEmptyTitle;

  /// No description provided for @pythonEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Install packages into this profile\'s AdditionalPythonPackages; system Python is untouched.'**
  String get pythonEmptyMessage;

  /// No description provided for @pythonInstall.
  ///
  /// In en, this message translates to:
  /// **'Install packages'**
  String get pythonInstall;

  /// No description provided for @pythonInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Install Python packages'**
  String get pythonInstallTitle;

  /// No description provided for @pythonSpecs.
  ///
  /// In en, this message translates to:
  /// **'One package per line, e.g. numpy==1.26.4'**
  String get pythonSpecs;

  /// No description provided for @pythonInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Install failed'**
  String get pythonInstallFailed;

  /// No description provided for @pythonInstalledMessage.
  ///
  /// In en, this message translates to:
  /// **'Packages installed'**
  String get pythonInstalledMessage;

  /// No description provided for @pythonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get pythonRemove;

  /// No description provided for @pythonRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this package?'**
  String get pythonRemoveTitle;

  /// No description provided for @pythonRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'The package files are removed from this profile. System Python is untouched.'**
  String get pythonRemoveMessage;

  /// No description provided for @pythonRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Package removed'**
  String get pythonRemovedMessage;

  /// No description provided for @pythonRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the package'**
  String get pythonRemoveFailed;

  /// No description provided for @pythonSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get pythonSource;

  /// No description provided for @profilesTabMacros.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get profilesTabMacros;

  /// No description provided for @profilesTabConfig.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get profilesTabConfig;

  /// No description provided for @profilesTabBackups.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get profilesTabBackups;

  /// No description provided for @profilesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This section arrives in a later milestone.'**
  String get profilesComingSoon;

  /// No description provided for @profilesPaths.
  ///
  /// In en, this message translates to:
  /// **'Paths'**
  String get profilesPaths;

  /// No description provided for @profilesProfileHome.
  ///
  /// In en, this message translates to:
  /// **'Profile home'**
  String get profilesProfileHome;

  /// No description provided for @profilesConfigFiles.
  ///
  /// In en, this message translates to:
  /// **'Config files'**
  String get profilesConfigFiles;

  /// No description provided for @profilesConfigMissing.
  ///
  /// In en, this message translates to:
  /// **'Created on first launch'**
  String get profilesConfigMissing;

  /// No description provided for @profilesStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'Build missing'**
  String get profilesStatusMissing;

  /// No description provided for @profilesStatusBroken.
  ///
  /// In en, this message translates to:
  /// **'Build broken'**
  String get profilesStatusBroken;

  /// No description provided for @profilesShowCommand.
  ///
  /// In en, this message translates to:
  /// **'Show launch command'**
  String get profilesShowCommand;

  /// No description provided for @profilesCommandTitle.
  ///
  /// In en, this message translates to:
  /// **'Launch command'**
  String get profilesCommandTitle;

  /// No description provided for @profilesCommandCopied.
  ///
  /// In en, this message translates to:
  /// **'Command copied'**
  String get profilesCommandCopied;

  /// No description provided for @profilesCommandEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment overrides'**
  String get profilesCommandEnvironment;

  /// No description provided for @profilesCommandRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed variables'**
  String get profilesCommandRemoved;

  /// No description provided for @profilesCommandFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not build the launch command'**
  String get profilesCommandFailed;

  /// No description provided for @profilesClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get profilesClose;

  /// No description provided for @profilesCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get profilesCopy;

  /// No description provided for @versionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No FreeCAD versions installed'**
  String get versionsEmptyTitle;

  /// No description provided for @versionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Install a stable, weekly or custom FreeCAD build to get started.'**
  String get versionsEmptyMessage;

  /// No description provided for @versionsTabInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get versionsTabInstalled;

  /// No description provided for @versionsTabAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get versionsTabAvailable;

  /// No description provided for @versionsTabCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get versionsTabCustom;

  /// No description provided for @versionsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get versionsRefresh;

  /// No description provided for @versionsInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get versionsInstall;

  /// No description provided for @versionsHashing.
  ///
  /// In en, this message translates to:
  /// **'Hashing file…'**
  String get versionsHashing;

  /// No description provided for @versionsDetectingPython.
  ///
  /// In en, this message translates to:
  /// **'Detecting Python…'**
  String get versionsDetectingPython;

  /// No description provided for @versionsDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get versionsDownloading;

  /// No description provided for @versionsInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get versionsInstalling;

  /// No description provided for @versionsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get versionsCancel;

  /// No description provided for @versionsAvailableEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No versions available'**
  String get versionsAvailableEmptyTitle;

  /// No description provided for @versionsAvailableEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and refresh the catalog.'**
  String get versionsAvailableEmptyMessage;

  /// No description provided for @versionsStaleCatalog.
  ///
  /// In en, this message translates to:
  /// **'Using a cached catalog; newer versions may be missing.'**
  String get versionsStaleCatalog;

  /// No description provided for @versionsCatalogError.
  ///
  /// In en, this message translates to:
  /// **'Could not load available versions.'**
  String get versionsCatalogError;

  /// No description provided for @versionsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get versionsRetry;

  /// No description provided for @versionsInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Install failed'**
  String get versionsInstallFailed;

  /// No description provided for @versionsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get versionsRemove;

  /// No description provided for @versionsVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify files'**
  String get versionsVerify;

  /// No description provided for @versionsRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the build'**
  String get versionsRemoveFailed;

  /// No description provided for @versionsStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get versionsStatusMissing;

  /// No description provided for @versionsStatusBroken.
  ///
  /// In en, this message translates to:
  /// **'Broken'**
  String get versionsStatusBroken;

  /// No description provided for @versionsVerifyOk.
  ///
  /// In en, this message translates to:
  /// **'Files verified'**
  String get versionsVerifyOk;

  /// No description provided for @versionsVerifyMissing.
  ///
  /// In en, this message translates to:
  /// **'Build files are missing'**
  String get versionsVerifyMissing;

  /// No description provided for @versionsVerifyBroken.
  ///
  /// In en, this message translates to:
  /// **'Build files are broken or corrupted'**
  String get versionsVerifyBroken;

  /// No description provided for @versionsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this build?'**
  String get versionsRemoveTitle;

  /// No description provided for @versionsRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'The files will be deleted from disk. Profiles using it will stop working.'**
  String get versionsRemoveMessage;

  /// No description provided for @versionsRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get versionsRemoveConfirm;

  /// No description provided for @versionsCustomEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom builds'**
  String get versionsCustomEmptyTitle;

  /// No description provided for @versionsCustomEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a local archive or URL, or select a FreeCAD executable (self-compiled or installed by other means) to reference in place.'**
  String get versionsCustomEmptyMessage;

  /// No description provided for @versionsCustomSource.
  ///
  /// In en, this message translates to:
  /// **'File path or URL'**
  String get versionsCustomSource;

  /// No description provided for @versionsCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Version label (optional)'**
  String get versionsCustomLabel;

  /// No description provided for @versionsCustomChecksum.
  ///
  /// In en, this message translates to:
  /// **'SHA-256 (optional)'**
  String get versionsCustomChecksum;

  /// No description provided for @versionsCustomChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file…'**
  String get versionsCustomChooseFile;

  /// No description provided for @versionsCustomImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get versionsCustomImport;

  /// No description provided for @versionsCustomTrustTitle.
  ///
  /// In en, this message translates to:
  /// **'Import this build?'**
  String get versionsCustomTrustTitle;

  /// No description provided for @versionsCustomTrustMessage.
  ///
  /// In en, this message translates to:
  /// **'Custom builds are not verified against the official catalog. Executables are run once, headless, to detect their Python version. Only import files you trust.'**
  String get versionsCustomTrustMessage;

  /// No description provided for @versionsCustomTrustConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get versionsCustomTrustConfirm;

  /// No description provided for @versionsCustomImported.
  ///
  /// In en, this message translates to:
  /// **'Build imported'**
  String get versionsCustomImported;

  /// No description provided for @versionsCustomFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get versionsCustomFailed;

  /// No description provided for @versionsCustomAllFiles.
  ///
  /// In en, this message translates to:
  /// **'All files'**
  String get versionsCustomAllFiles;

  /// No description provided for @versionsCustomBuilds.
  ///
  /// In en, this message translates to:
  /// **'FreeCAD builds'**
  String get versionsCustomBuilds;

  /// No description provided for @versionsCustomPythonMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Python interpreter not detected'**
  String get versionsCustomPythonMissingTitle;

  /// No description provided for @versionsCustomPythonMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'The build was imported, but its Python interpreter could not be detected. Addons and Python packages need it; select the interpreter this build uses, or skip for now.'**
  String get versionsCustomPythonMissingMessage;

  /// No description provided for @versionsCustomPythonChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose Python…'**
  String get versionsCustomPythonChoose;

  /// No description provided for @versionsCustomPythonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get versionsCustomPythonSkip;

  /// No description provided for @versionsCustomPythonSaved.
  ///
  /// In en, this message translates to:
  /// **'Python interpreter saved'**
  String get versionsCustomPythonSaved;

  /// No description provided for @versionsCustomPythonFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not use that Python'**
  String get versionsCustomPythonFailed;

  /// No description provided for @versionsPython.
  ///
  /// In en, this message translates to:
  /// **'Python'**
  String get versionsPython;

  /// No description provided for @versionsSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get versionsSize;

  /// No description provided for @addonsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No addons installed'**
  String get addonsEmptyTitle;

  /// No description provided for @addonsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Browse the official catalog and install workbenches into a profile.'**
  String get addonsEmptyMessage;

  /// No description provided for @addonsTabCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get addonsTabCatalog;

  /// No description provided for @addonsTabCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get addonsTabCollections;

  /// No description provided for @bundlesCreate.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get bundlesCreate;

  /// No description provided for @bundlesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No collections yet'**
  String get bundlesEmptyTitle;

  /// No description provided for @bundlesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a collection to save a set of addons and apply it to a profile.'**
  String get bundlesEmptyMessage;

  /// No description provided for @bundlesName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get bundlesName;

  /// No description provided for @bundlesDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get bundlesDescription;

  /// No description provided for @bundlesFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Start from profile'**
  String get bundlesFromProfile;

  /// No description provided for @bundlesFromProfileNone.
  ///
  /// In en, this message translates to:
  /// **'Empty collection'**
  String get bundlesFromProfileNone;

  /// No description provided for @bundlesItems.
  ///
  /// In en, this message translates to:
  /// **'Addons'**
  String get bundlesItems;

  /// No description provided for @bundlesItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} addon(s)'**
  String bundlesItemCount(int count);

  /// No description provided for @bundlesNoItems.
  ///
  /// In en, this message translates to:
  /// **'No addons in this collection yet.'**
  String get bundlesNoItems;

  /// No description provided for @bundlesAddAddon.
  ///
  /// In en, this message translates to:
  /// **'Add addon'**
  String get bundlesAddAddon;

  /// No description provided for @bundlesAddAddonTitle.
  ///
  /// In en, this message translates to:
  /// **'Add addon to collection'**
  String get bundlesAddAddonTitle;

  /// No description provided for @bundlesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search addons, use #tag'**
  String get bundlesSearchHint;

  /// No description provided for @bundlesNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching addons.'**
  String get bundlesNoMatches;

  /// No description provided for @bundlesBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get bundlesBranch;

  /// No description provided for @bundlesRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get bundlesRemoveItem;

  /// No description provided for @bundlesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit collection'**
  String get bundlesEdit;

  /// No description provided for @bundlesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete collection'**
  String get bundlesDeleteTitle;

  /// No description provided for @bundlesDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'The collection is removed. Addons installed from it are not affected.'**
  String get bundlesDeleteMessage;

  /// No description provided for @bundlesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get bundlesDelete;

  /// No description provided for @bundlesSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get bundlesSave;

  /// No description provided for @bundlesCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bundlesCancel;

  /// No description provided for @bundlesCreated.
  ///
  /// In en, this message translates to:
  /// **'Collection created'**
  String get bundlesCreated;

  /// No description provided for @bundlesSaved.
  ///
  /// In en, this message translates to:
  /// **'Collection saved'**
  String get bundlesSaved;

  /// No description provided for @bundlesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Collection deleted'**
  String get bundlesDeleted;

  /// No description provided for @bundlesCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the collection'**
  String get bundlesCreateFailed;

  /// No description provided for @bundlesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the collection'**
  String get bundlesSaveFailed;

  /// No description provided for @bundlesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the collection'**
  String get bundlesDeleteFailed;

  /// No description provided for @bundlesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the collections.'**
  String get bundlesLoadFailed;

  /// No description provided for @bundlesNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get bundlesNameEmpty;

  /// No description provided for @bundlesNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name is too long (max 64 characters).'**
  String get bundlesNameTooLong;

  /// No description provided for @bundlesNameTaken.
  ///
  /// In en, this message translates to:
  /// **'A collection with this name already exists.'**
  String get bundlesNameTaken;

  /// No description provided for @bundlesUnknownAddon.
  ///
  /// In en, this message translates to:
  /// **'Not in catalog'**
  String get bundlesUnknownAddon;

  /// No description provided for @bundlesApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get bundlesApply;

  /// No description provided for @bundlesApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply collection'**
  String get bundlesApplyTitle;

  /// No description provided for @bundlesApplyProfile.
  ///
  /// In en, this message translates to:
  /// **'Target profile'**
  String get bundlesApplyProfile;

  /// No description provided for @bundlesApplyNoProfiles.
  ///
  /// In en, this message translates to:
  /// **'Create a profile first.'**
  String get bundlesApplyNoProfiles;

  /// No description provided for @bundlesApplyPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get bundlesApplyPreview;

  /// No description provided for @bundlesApplyActionInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get bundlesApplyActionInstall;

  /// No description provided for @bundlesApplyActionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get bundlesApplyActionUpdate;

  /// No description provided for @bundlesApplyActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get bundlesApplyActionSkip;

  /// No description provided for @bundlesApplyActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get bundlesApplyActionUnavailable;

  /// No description provided for @bundlesApplyAddonMissing.
  ///
  /// In en, this message translates to:
  /// **'Not in catalog'**
  String get bundlesApplyAddonMissing;

  /// No description provided for @bundlesApplyBranchMissing.
  ///
  /// In en, this message translates to:
  /// **'Branch {branch} is missing'**
  String bundlesApplyBranchMissing(String branch);

  /// No description provided for @bundlesApplyInstallRequirements.
  ///
  /// In en, this message translates to:
  /// **'Also install declared Python requirements'**
  String get bundlesApplyInstallRequirements;

  /// No description provided for @bundlesApplyNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to apply.'**
  String get bundlesApplyNothing;

  /// No description provided for @bundlesApplyRunning.
  ///
  /// In en, this message translates to:
  /// **'Applying…'**
  String get bundlesApplyRunning;

  /// No description provided for @bundlesApplySummary.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get bundlesApplySummary;

  /// No description provided for @bundlesApplyInstalledCount.
  ///
  /// In en, this message translates to:
  /// **'{count} installed'**
  String bundlesApplyInstalledCount(int count);

  /// No description provided for @bundlesApplyUpdatedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} updated'**
  String bundlesApplyUpdatedCount(int count);

  /// No description provided for @bundlesApplySkippedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} skipped'**
  String bundlesApplySkippedCount(int count);

  /// No description provided for @bundlesApplyFailedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String bundlesApplyFailedCount(int count);

  /// No description provided for @bundlesApplyClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get bundlesApplyClose;

  /// No description provided for @bundlesExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get bundlesExport;

  /// No description provided for @bundlesExported.
  ///
  /// In en, this message translates to:
  /// **'Collection exported'**
  String get bundlesExported;

  /// No description provided for @bundlesExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export the collection'**
  String get bundlesExportFailed;

  /// No description provided for @bundlesImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get bundlesImport;

  /// No description provided for @bundlesImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import collection'**
  String get bundlesImportTitle;

  /// No description provided for @bundlesImportName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get bundlesImportName;

  /// No description provided for @bundlesImportAddons.
  ///
  /// In en, this message translates to:
  /// **'Addons: {count}'**
  String bundlesImportAddons(int count);

  /// No description provided for @bundlesImportUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Not in catalog: {count}'**
  String bundlesImportUnresolved(int count);

  /// No description provided for @bundlesImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import the collection'**
  String get bundlesImportFailed;

  /// No description provided for @bundlesImported.
  ///
  /// In en, this message translates to:
  /// **'Collection imported'**
  String get bundlesImported;

  /// No description provided for @bundlesImportedUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Imported, but {count} addons are not in the catalog'**
  String bundlesImportedUnresolved(int count);

  /// No description provided for @bundlesImportFile.
  ///
  /// In en, this message translates to:
  /// **'Bundle JSON file'**
  String get bundlesImportFile;

  /// No description provided for @bundlesJsonFiles.
  ///
  /// In en, this message translates to:
  /// **'JSON files'**
  String get bundlesJsonFiles;

  /// No description provided for @addonsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search addons, use #tag'**
  String get addonsSearchHint;

  /// No description provided for @addonsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get addonsFilterAll;

  /// No description provided for @addonsFilterContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get addonsFilterContent;

  /// No description provided for @addonsContentWorkbench.
  ///
  /// In en, this message translates to:
  /// **'Workbench'**
  String get addonsContentWorkbench;

  /// No description provided for @addonsContentMacro.
  ///
  /// In en, this message translates to:
  /// **'Macro'**
  String get addonsContentMacro;

  /// No description provided for @addonsContentPreferencePack.
  ///
  /// In en, this message translates to:
  /// **'Preference pack'**
  String get addonsContentPreferencePack;

  /// No description provided for @addonsContentBundle.
  ///
  /// In en, this message translates to:
  /// **'Bundle'**
  String get addonsContentBundle;

  /// No description provided for @addonsContentOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addonsContentOther;

  /// No description provided for @addonsFilterInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get addonsFilterInstalled;

  /// No description provided for @addonsFilterNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get addonsFilterNotInstalled;

  /// No description provided for @addonsFilterInstalledState.
  ///
  /// In en, this message translates to:
  /// **'Installed state'**
  String get addonsFilterInstalledState;

  /// No description provided for @addonsFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get addonsFilters;

  /// No description provided for @addonsFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get addonsFilterClear;

  /// No description provided for @addonsClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get addonsClearSearch;

  /// No description provided for @addonsFilterFreecad.
  ///
  /// In en, this message translates to:
  /// **'FreeCAD'**
  String get addonsFilterFreecad;

  /// No description provided for @addonsFilterAnyVersion.
  ///
  /// In en, this message translates to:
  /// **'Any version'**
  String get addonsFilterAnyVersion;

  /// No description provided for @addonsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get addonsRefresh;

  /// No description provided for @addonsStale.
  ///
  /// In en, this message translates to:
  /// **'Using a cached catalog; newer addons may be missing.'**
  String get addonsStale;

  /// No description provided for @addonsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the addon catalog.'**
  String get addonsLoadFailed;

  /// No description provided for @addonsCatalogEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog is empty'**
  String get addonsCatalogEmptyTitle;

  /// No description provided for @addonsCatalogEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Refresh to download the addon catalog.'**
  String get addonsCatalogEmptyMessage;

  /// No description provided for @addonsFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'No addons match the current filters.'**
  String get addonsFilteredEmpty;

  /// No description provided for @addonsInstalledIn.
  ///
  /// In en, this message translates to:
  /// **'Installed in {count} profile(s)'**
  String addonsInstalledIn(int count);

  /// No description provided for @addonsInstalledBadge.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get addonsInstalledBadge;

  /// No description provided for @addonsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get addonsVersion;

  /// No description provided for @addonsLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get addonsLicense;

  /// No description provided for @addonsAuthors.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get addonsAuthors;

  /// No description provided for @addonsRepository.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get addonsRepository;

  /// No description provided for @addonsOpenRepository.
  ///
  /// In en, this message translates to:
  /// **'Open repository'**
  String get addonsOpenRepository;

  /// No description provided for @addonsFreecadRange.
  ///
  /// In en, this message translates to:
  /// **'FreeCAD range'**
  String get addonsFreecadRange;

  /// No description provided for @addonsLastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get addonsLastUpdate;

  /// No description provided for @addonsContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get addonsContent;

  /// No description provided for @addonsTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get addonsTags;

  /// No description provided for @addonsBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get addonsBranches;

  /// No description provided for @addonsRequirements.
  ///
  /// In en, this message translates to:
  /// **'Python requirements'**
  String get addonsRequirements;

  /// No description provided for @addonsRequirementsYes.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get addonsRequirementsYes;

  /// No description provided for @addonsRequirementsNo.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get addonsRequirementsNo;

  /// No description provided for @addonsInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get addonsInstall;

  /// No description provided for @addonsInstallTarget.
  ///
  /// In en, this message translates to:
  /// **'Install into'**
  String get addonsInstallTarget;

  /// No description provided for @addonsInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Install failed'**
  String get addonsInstallFailed;

  /// No description provided for @addonsInstalledMessage.
  ///
  /// In en, this message translates to:
  /// **'Addon installed'**
  String get addonsInstalledMessage;

  /// No description provided for @addonsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get addonsUpdate;

  /// No description provided for @addonsUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A newer version is available in the catalog.'**
  String get addonsUpdateAvailable;

  /// No description provided for @addonsUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Addon updated'**
  String get addonsUpdatedMessage;

  /// No description provided for @addonsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get addonsUpdateFailed;

  /// No description provided for @addonsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get addonsRemove;

  /// No description provided for @addonsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this addon?'**
  String get addonsRemoveTitle;

  /// No description provided for @addonsRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'The addon files are deleted from this profile. Existing backups are kept.'**
  String get addonsRemoveMessage;

  /// No description provided for @addonsRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Addon removed'**
  String get addonsRemovedMessage;

  /// No description provided for @addonsRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the addon'**
  String get addonsRemoveFailed;

  /// No description provided for @addonsNoProfiles.
  ///
  /// In en, this message translates to:
  /// **'Create a profile first to install addons.'**
  String get addonsNoProfiles;

  /// No description provided for @addonsRequirementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Python packages required'**
  String get addonsRequirementsTitle;

  /// No description provided for @addonsRequirementsMessage.
  ///
  /// In en, this message translates to:
  /// **'This addon declares Python dependencies. Install them into the profile with pip? Packages go under the profile\'s AdditionalPythonPackages; system Python is untouched.'**
  String get addonsRequirementsMessage;

  /// No description provided for @addonsRequirementsInstall.
  ///
  /// In en, this message translates to:
  /// **'Install packages'**
  String get addonsRequirementsInstall;

  /// No description provided for @addonsRequirementsAddonOnly.
  ///
  /// In en, this message translates to:
  /// **'Addon only'**
  String get addonsRequirementsAddonOnly;

  /// No description provided for @addonsRequirementsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Cannot parse'**
  String get addonsRequirementsInvalid;

  /// No description provided for @addonsRequirementsFailed.
  ///
  /// In en, this message translates to:
  /// **'Python packages failed'**
  String get addonsRequirementsFailed;

  /// No description provided for @addonsInstallSoon.
  ///
  /// In en, this message translates to:
  /// **'The install engine arrives in the next milestone.'**
  String get addonsInstallSoon;

  /// No description provided for @addonsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get addonsBack;

  /// No description provided for @addonsNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get addonsNone;

  /// No description provided for @addonsAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get addonsAny;

  /// No description provided for @macrosEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No macros'**
  String get macrosEmptyTitle;

  /// No description provided for @macrosEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Install macros from the official catalog into a profile.'**
  String get macrosEmptyMessage;

  /// No description provided for @macrosSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search macros'**
  String get macrosSearchHint;

  /// No description provided for @macrosRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get macrosRefresh;

  /// No description provided for @macrosInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get macrosInstall;

  /// No description provided for @macrosInstalledMessage.
  ///
  /// In en, this message translates to:
  /// **'Macro installed'**
  String get macrosInstalledMessage;

  /// No description provided for @macrosInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not install the macro'**
  String get macrosInstallFailed;

  /// No description provided for @macrosLicenseUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown license'**
  String get macrosLicenseUnknown;

  /// No description provided for @macrosNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No macros match the current search.'**
  String get macrosNoMatches;

  /// No description provided for @macrosCatalogEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog is empty'**
  String get macrosCatalogEmptyTitle;

  /// No description provided for @macrosCatalogEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Refresh to download the macro catalog.'**
  String get macrosCatalogEmptyMessage;

  /// No description provided for @macrosLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the macro catalog.'**
  String get macrosLoadFailed;

  /// No description provided for @macrosStale.
  ///
  /// In en, this message translates to:
  /// **'Using a cached catalog; newer macros may be missing.'**
  String get macrosStale;

  /// No description provided for @macrosAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get macrosAuthor;

  /// No description provided for @macrosVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get macrosVersion;

  /// No description provided for @macrosUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get macrosUpdated;

  /// No description provided for @macrosClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get macrosClearSearch;

  /// No description provided for @macrosTabInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get macrosTabInstalled;

  /// No description provided for @macrosTabCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get macrosTabCatalog;

  /// No description provided for @macrosOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get macrosOpen;

  /// No description provided for @macrosReveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal in folder'**
  String get macrosReveal;

  /// No description provided for @macrosDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get macrosDelete;

  /// No description provided for @macrosDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete macro'**
  String get macrosDeleteTitle;

  /// No description provided for @macrosDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'The macro file is deleted from this profile.'**
  String get macrosDeleteMessage;

  /// No description provided for @macrosDeleted.
  ///
  /// In en, this message translates to:
  /// **'Macro deleted'**
  String get macrosDeleted;

  /// No description provided for @macrosDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the macro'**
  String get macrosDeleteFailed;

  /// No description provided for @macrosActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not run the system action'**
  String get macrosActionFailed;

  /// No description provided for @jobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobsTitle;

  /// No description provided for @jobsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No jobs yet.'**
  String get jobsEmpty;

  /// No description provided for @jobsQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get jobsQueued;

  /// No description provided for @jobsRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get jobsRunning;

  /// No description provided for @jobsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get jobsCompleted;

  /// No description provided for @jobsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get jobsFailed;

  /// No description provided for @jobsCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get jobsCancelled;

  /// No description provided for @jobsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get jobsCancel;

  /// No description provided for @jobsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get jobsRetry;

  /// No description provided for @jobsClearFinished.
  ///
  /// In en, this message translates to:
  /// **'Clear finished'**
  String get jobsClearFinished;

  /// No description provided for @jobsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get jobsClose;

  /// No description provided for @jobsLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get jobsLog;

  /// No description provided for @settingsDataDirectory.
  ///
  /// In en, this message translates to:
  /// **'Data directory'**
  String get settingsDataDirectory;

  /// No description provided for @settingsCliWrapper.
  ///
  /// In en, this message translates to:
  /// **'Command-line launcher'**
  String get settingsCliWrapper;

  /// No description provided for @settingsCliWrapperInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get settingsCliWrapperInstalled;

  /// No description provided for @settingsCliWrapperNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get settingsCliWrapperNotInstalled;

  /// No description provided for @settingsCliWrapperOnPath.
  ///
  /// In en, this message translates to:
  /// **'Available on PATH'**
  String get settingsCliWrapperOnPath;

  /// No description provided for @settingsCliWrapperNotOnPath.
  ///
  /// In en, this message translates to:
  /// **'Not on PATH — add {directory} to PATH to use it from a fresh shell'**
  String settingsCliWrapperNotOnPath(String directory);

  /// No description provided for @settingsCliWrapperInstall.
  ///
  /// In en, this message translates to:
  /// **'Install wrapper'**
  String get settingsCliWrapperInstall;

  /// No description provided for @settingsCliWrapperRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove wrapper'**
  String get settingsCliWrapperRemove;

  /// No description provided for @settingsCliWrapperInstalledMessage.
  ///
  /// In en, this message translates to:
  /// **'Wrapper installed'**
  String get settingsCliWrapperInstalledMessage;

  /// No description provided for @settingsCliWrapperRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wrapper removed'**
  String get settingsCliWrapperRemovedMessage;

  /// No description provided for @settingsCliWrapperFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the wrapper'**
  String get settingsCliWrapperFailed;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get settingsLicense;

  /// No description provided for @settingsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settingsDiagnostics;

  /// No description provided for @diagnosticsRun.
  ///
  /// In en, this message translates to:
  /// **'Run diagnostics'**
  String get diagnosticsRun;

  /// No description provided for @diagnosticsRunning.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get diagnosticsRunning;

  /// No description provided for @diagnosticDataDirectory.
  ///
  /// In en, this message translates to:
  /// **'Data directory writable'**
  String get diagnosticDataDirectory;

  /// No description provided for @diagnosticFuse.
  ///
  /// In en, this message translates to:
  /// **'AppImage support (FUSE)'**
  String get diagnosticFuse;

  /// No description provided for @diagnosticGatekeeper.
  ///
  /// In en, this message translates to:
  /// **'macOS Gatekeeper'**
  String get diagnosticGatekeeper;

  /// No description provided for @diagnosticDiskSpace.
  ///
  /// In en, this message translates to:
  /// **'Disk space'**
  String get diagnosticDiskSpace;

  /// No description provided for @diagnosticsStatusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get diagnosticsStatusOk;

  /// No description provided for @diagnosticsStatusWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get diagnosticsStatusWarning;

  /// No description provided for @diagnosticsStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get diagnosticsStatusError;

  /// No description provided for @diagnosticsStatusNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get diagnosticsStatusNotApplicable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
