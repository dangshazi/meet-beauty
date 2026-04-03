import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @tutorialPreviousStep.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get tutorialPreviousStep;

  /// No description provided for @tutorialNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNextStep;

  /// No description provided for @tutorialComplete.
  ///
  /// In en, this message translates to:
  /// **'Finish Tutorial'**
  String get tutorialComplete;

  /// No description provided for @tutorialFaceHint.
  ///
  /// In en, this message translates to:
  /// **'Please align your face with the screen'**
  String get tutorialFaceHint;

  /// No description provided for @tutorialCameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera initialization failed, please retry'**
  String get tutorialCameraError;

  /// No description provided for @tutorialCameraErrorDefault.
  ///
  /// In en, this message translates to:
  /// **'Camera initialization failed, please retry'**
  String get tutorialCameraErrorDefault;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get permissionRequired;

  /// No description provided for @permissionDescription.
  ///
  /// In en, this message translates to:
  /// **'AR makeup tutorial needs the front camera to detect your face. Please grant camera permission to continue.'**
  String get permissionDescription;

  /// No description provided for @permissionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get permissionOpenSettings;

  /// No description provided for @permissionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get permissionRetry;

  /// No description provided for @resultOutOf.
  ///
  /// In en, this message translates to:
  /// **'Out of 100'**
  String get resultOutOf;

  /// No description provided for @resultStepsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Steps Completed'**
  String get resultStepsCompleted;

  /// No description provided for @resultDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get resultDuration;

  /// No description provided for @resultFaceTracking.
  ///
  /// In en, this message translates to:
  /// **'Face Tracking'**
  String get resultFaceTracking;

  /// No description provided for @resultBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get resultBackHome;

  /// No description provided for @resultPracticeAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice Again'**
  String get resultPracticeAgain;

  /// No description provided for @scoreExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent! Your makeup looks amazing!'**
  String get scoreExcellent;

  /// No description provided for @scoreGood.
  ///
  /// In en, this message translates to:
  /// **'Good job! Keep practicing and you\'ll get even better.'**
  String get scoreGood;

  /// No description provided for @scoreGoodSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Try completing all steps for better results.'**
  String get scoreGoodSuggestion;

  /// No description provided for @scoreNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing! Practice makes perfect.'**
  String get scoreNeedsWork;

  /// No description provided for @scoreNeedsWorkSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Slow down and follow each step carefully.'**
  String get scoreNeedsWorkSuggestion;

  /// No description provided for @scoreTrackingTip.
  ///
  /// In en, this message translates to:
  /// **'Keep your face toward the camera for better guidance.'**
  String get scoreTrackingTip;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsLanguageZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get settingsLanguageZh;

  /// No description provided for @settingsAccumulateOverlays.
  ///
  /// In en, this message translates to:
  /// **'Accumulate Makeup Effects'**
  String get settingsAccumulateOverlays;

  /// No description provided for @settingsAccumulateOverlaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep previous step\'s makeup overlay when advancing to next step'**
  String get settingsAccumulateOverlaysDesc;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Meet Beauty'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI Makeup Coach'**
  String get homeSubtitle;

  /// No description provided for @homeFeatureAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Face Analysis'**
  String get homeFeatureAnalysis;

  /// No description provided for @homeFeatureAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'Get personalized makeup recommendations'**
  String get homeFeatureAnalysisDesc;

  /// No description provided for @homeFeatureTutorial.
  ///
  /// In en, this message translates to:
  /// **'AR Tutorial'**
  String get homeFeatureTutorial;

  /// No description provided for @homeFeatureTutorialDesc.
  ///
  /// In en, this message translates to:
  /// **'Learn with real-time AR guidance'**
  String get homeFeatureTutorialDesc;

  /// No description provided for @homeFeatureScoring.
  ///
  /// In en, this message translates to:
  /// **'Smart Scoring'**
  String get homeFeatureScoring;

  /// No description provided for @homeFeatureScoringDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your progress with instant feedback'**
  String get homeFeatureScoringDesc;

  /// No description provided for @homeStartLearning.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get homeStartLearning;

  /// No description provided for @homeChooseStyle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Tutorial Style'**
  String get homeChooseStyle;

  /// No description provided for @analysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Face Analysis'**
  String get analysisTitle;

  /// No description provided for @analysisInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing camera...'**
  String get analysisInitializing;

  /// No description provided for @analysisAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your face...'**
  String get analysisAnalyzing;

  /// No description provided for @analysisYourFeatures.
  ///
  /// In en, this message translates to:
  /// **'Your Features'**
  String get analysisYourFeatures;

  /// No description provided for @analysisFaceShape.
  ///
  /// In en, this message translates to:
  /// **'Face Shape'**
  String get analysisFaceShape;

  /// No description provided for @analysisSkinTone.
  ///
  /// In en, this message translates to:
  /// **'Skin Tone'**
  String get analysisSkinTone;

  /// No description provided for @analysisLipType.
  ///
  /// In en, this message translates to:
  /// **'Lip Type'**
  String get analysisLipType;

  /// No description provided for @analysisFaceDetected.
  ///
  /// In en, this message translates to:
  /// **'Face detected! Tap \"Capture & Analyze\" to continue.'**
  String get analysisFaceDetected;

  /// No description provided for @analysisPositionFace.
  ///
  /// In en, this message translates to:
  /// **'Position your face in the camera view'**
  String get analysisPositionFace;

  /// No description provided for @analysisGetRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Get Recommendations'**
  String get analysisGetRecommendations;

  /// No description provided for @analysisAnalyzingBtn.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analysisAnalyzingBtn;

  /// No description provided for @analysisCaptureAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Capture & Analyze'**
  String get analysisCaptureAnalyze;

  /// No description provided for @analysisCameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera Error'**
  String get analysisCameraError;

  /// No description provided for @analysisRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get analysisRetry;

  /// No description provided for @analysisCameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get analysisCameraPermission;

  /// No description provided for @analysisGrantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get analysisGrantPermission;

  /// No description provided for @recTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Recommendations'**
  String get recTitle;

  /// No description provided for @recNoData.
  ///
  /// In en, this message translates to:
  /// **'No recommendations available'**
  String get recNoData;

  /// No description provided for @recStartLearning.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get recStartLearning;

  /// No description provided for @recBasedOnFeatures.
  ///
  /// In en, this message translates to:
  /// **'Based on Your Features'**
  String get recBasedOnFeatures;

  /// No description provided for @recSteps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String recSteps(int count);
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
