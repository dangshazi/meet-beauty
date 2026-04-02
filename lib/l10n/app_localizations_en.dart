// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tutorialPreviousStep => 'Previous';

  @override
  String get tutorialNextStep => 'Next';

  @override
  String get tutorialComplete => 'Finish Tutorial';

  @override
  String get tutorialFaceHint => 'Please align your face with the screen';

  @override
  String get tutorialCameraError =>
      'Camera initialization failed, please retry';

  @override
  String get tutorialCameraErrorDefault =>
      'Camera initialization failed, please retry';

  @override
  String get permissionRequired => 'Camera permission required';

  @override
  String get permissionDescription =>
      'AR makeup tutorial needs the front camera to detect your face. Please grant camera permission to continue.';

  @override
  String get permissionOpenSettings => 'Open Settings';

  @override
  String get permissionRetry => 'Retry';

  @override
  String get resultOutOf => 'Out of 100';

  @override
  String get resultStepsCompleted => 'Steps Completed';

  @override
  String get resultDuration => 'Duration';

  @override
  String get resultFaceTracking => 'Face Tracking';

  @override
  String get resultBackHome => 'Back to Home';

  @override
  String get resultPracticeAgain => 'Practice Again';

  @override
  String get scoreExcellent => 'Excellent! Your makeup looks amazing!';

  @override
  String get scoreGood =>
      'Good job! Keep practicing and you\'ll get even better.';

  @override
  String get scoreGoodSuggestion =>
      'Try completing all steps for better results.';

  @override
  String get scoreNeedsWork => 'Keep practicing! Practice makes perfect.';

  @override
  String get scoreNeedsWorkSuggestion =>
      'Slow down and follow each step carefully.';

  @override
  String get scoreTrackingTip =>
      'Keep your face toward the camera for better guidance.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System Default';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get homeTitle => 'Meet Beauty';

  @override
  String get homeSubtitle => 'AI Makeup Coach';

  @override
  String get homeFeatureAnalysis => 'Face Analysis';

  @override
  String get homeFeatureAnalysisDesc =>
      'Get personalized makeup recommendations';

  @override
  String get homeFeatureTutorial => 'AR Tutorial';

  @override
  String get homeFeatureTutorialDesc => 'Learn with real-time AR guidance';

  @override
  String get homeFeatureScoring => 'Smart Scoring';

  @override
  String get homeFeatureScoringDesc =>
      'Track your progress with instant feedback';

  @override
  String get homeStartLearning => 'Start Learning';

  @override
  String get homeChooseStyle => 'Choose a Tutorial Style';

  @override
  String get analysisTitle => 'Face Analysis';

  @override
  String get analysisInitializing => 'Initializing camera...';

  @override
  String get analysisAnalyzing => 'Analyzing your face...';

  @override
  String get analysisYourFeatures => 'Your Features';

  @override
  String get analysisFaceShape => 'Face Shape';

  @override
  String get analysisSkinTone => 'Skin Tone';

  @override
  String get analysisLipType => 'Lip Type';

  @override
  String get analysisFaceDetected =>
      'Face detected! Tap \"Capture & Analyze\" to continue.';

  @override
  String get analysisPositionFace => 'Position your face in the camera view';

  @override
  String get analysisGetRecommendations => 'Get Recommendations';

  @override
  String get analysisAnalyzingBtn => 'Analyzing...';

  @override
  String get analysisCaptureAnalyze => 'Capture & Analyze';

  @override
  String get analysisCameraError => 'Camera Error';

  @override
  String get analysisRetry => 'Retry';

  @override
  String get analysisCameraPermission => 'Camera permission required';

  @override
  String get analysisGrantPermission => 'Grant Permission';

  @override
  String get recTitle => 'Your Recommendations';

  @override
  String get recNoData => 'No recommendations available';

  @override
  String get recStartLearning => 'Start Learning';

  @override
  String get recBasedOnFeatures => 'Based on Your Features';

  @override
  String recSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }
}
