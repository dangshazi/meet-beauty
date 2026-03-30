import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:meet_beauty/features/analysis/application/analysis_controller.dart';
import 'package:meet_beauty/features/tutorial/application/tutorial_controller.dart';
import 'package:meet_beauty/features/recommendation/application/recommendation_controller.dart';
import 'package:meet_beauty/features/result/application/scoring_controller.dart';
import 'package:meet_beauty/services/face_tracking_controller.dart';

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

  // Providers for state management - return a static list to avoid recreating
  static final List<ChangeNotifierProvider<ChangeNotifier>> providers = [
    ChangeNotifierProvider(create: (_) => AnalysisController()),
    ChangeNotifierProvider(create: (_) => TutorialController()),
    ChangeNotifierProvider(create: (_) => RecommendationController()),
    ChangeNotifierProvider(create: (_) => ScoringController()),
    ChangeNotifierProvider(create: (_) => FaceTrackingController()),
  ];
}
