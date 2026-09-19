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

  /// No description provided for @settingsDataDirectory.
  ///
  /// In en, this message translates to:
  /// **'Data directory'**
  String get settingsDataDirectory;

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
