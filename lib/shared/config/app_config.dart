import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:meet_beauty/features/analysis/application/analysis_controller.dart';
import 'package:meet_beauty/features/tutorial/application/tutorial_controller.dart';
import 'package:meet_beauty/features/recommendation/application/recommendation_controller.dart';
import 'package:meet_beauty/features/result/application/scoring_controller.dart';
import 'package:meet_beauty/services/face_tracking_controller.dart';
import 'package:meet_beauty/shared/providers/locale_provider.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'Meet Beauty';
  static const String appVersion = '1.0.0';

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Camera settings
  static const int cameraFps = 30;
  static const int analysisIntervalMs = 200; // Analyze every 200ms

  // Face detection settings
  static const double minFaceConfidence = 0.5;

  /// Providers for state management.
  static final List<SingleChildWidget> providers = [
    ChangeNotifierProvider<LocaleProvider>(
        create: (_) => LocaleProvider()),
    ChangeNotifierProvider<AnalysisController>(
        create: (_) => AnalysisController()),
    ChangeNotifierProvider<TutorialController>(
        create: (_) => TutorialController()),
    ChangeNotifierProvider<RecommendationController>(
        create: (_) => RecommendationController()),
    ChangeNotifierProvider<ScoringController>(
        create: (_) => ScoringController()),
    ChangeNotifierProvider<FaceTrackingController>(
        create: (_) => FaceTrackingController()),
  ];
}
