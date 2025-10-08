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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @toolStore.
  ///
  /// In en, this message translates to:
  /// **'Tool Store'**
  String get toolStore;

  /// No description provided for @searchForTools.
  ///
  /// In en, this message translates to:
  /// **'Search for tools'**
  String get searchForTools;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @aiToolbox.
  ///
  /// In en, this message translates to:
  /// **'AI Toolbox'**
  String get aiToolbox;

  /// No description provided for @politicalLeaningAnalyzer.
  ///
  /// In en, this message translates to:
  /// **'Political Leaning Analyzer'**
  String get politicalLeaningAnalyzer;

  /// No description provided for @analyzeYourXPosts.
  ///
  /// In en, this message translates to:
  /// **'Analyze X posts'**
  String get analyzeYourXPosts;

  /// No description provided for @weAnalyzeLocally.
  ///
  /// In en, this message translates to:
  /// **'We analyze locally/securely and do not store your data.'**
  String get weAnalyzeLocally;

  /// No description provided for @socialMediaHandle.
  ///
  /// In en, this message translates to:
  /// **'Social Media Handle (e.g., @username)'**
  String get socialMediaHandle;

  /// No description provided for @analyze2Credits.
  ///
  /// In en, this message translates to:
  /// **'Analyze (2 Credits)'**
  String get analyze2Credits;

  /// No description provided for @analysisInProgress.
  ///
  /// In en, this message translates to:
  /// **'Analysis in Progress'**
  String get analysisInProgress;

  /// No description provided for @analyzingYourSocialMedia.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your social media activity'**
  String get analyzingYourSocialMedia;

  /// No description provided for @thisMayTakeAMoment.
  ///
  /// In en, this message translates to:
  /// **'This may take a moment. Your data remains private and is not stored.'**
  String get thisMayTakeAMoment;

  /// No description provided for @reviewingPosts.
  ///
  /// In en, this message translates to:
  /// **'Reviewing posts...'**
  String get reviewingPosts;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @analysisResults.
  ///
  /// In en, this message translates to:
  /// **'Analysis Results'**
  String get analysisResults;

  /// No description provided for @politicalSpectrum.
  ///
  /// In en, this message translates to:
  /// **'Political Spectrum'**
  String get politicalSpectrum;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @center.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get center;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @keywordClouds.
  ///
  /// In en, this message translates to:
  /// **'Keyword Clouds'**
  String get keywordClouds;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @sharingNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Sharing not implemented in demo.'**
  String get sharingNotImplemented;

  /// No description provided for @shareResult.
  ///
  /// In en, this message translates to:
  /// **'Share Result'**
  String get shareResult;

  /// No description provided for @analyzeAgain.
  ///
  /// In en, this message translates to:
  /// **'Analyze Again'**
  String get analyzeAgain;

  /// No description provided for @seeTopicBreakdown.
  ///
  /// In en, this message translates to:
  /// **'See Topic Breakdown'**
  String get seeTopicBreakdown;

  /// No description provided for @topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topics;

  /// No description provided for @progressive.
  ///
  /// In en, this message translates to:
  /// **'Progressive'**
  String get progressive;

  /// No description provided for @conservative.
  ///
  /// In en, this message translates to:
  /// **'Conservative'**
  String get conservative;

  /// No description provided for @suggestedNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Suggested Next Steps'**
  String get suggestedNextSteps;
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
