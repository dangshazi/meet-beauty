import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:meet_beauty/app/app.dart';
import 'package:meet_beauty/app/router.dart' show buildAppRouter;
import 'package:meet_beauty/features/analysis/application/analysis_controller.dart';
import 'package:meet_beauty/features/tutorial/application/tutorial_controller.dart';
import 'package:meet_beauty/features/recommendation/application/recommendation_controller.dart';
import 'package:meet_beauty/features/result/application/scoring_controller.dart';
import 'package:meet_beauty/services/face_tracking_controller.dart';

import '../mocks/mock_analysis_controller.dart';
import '../mocks/mock_face_tracking_controller.dart';
import '../mocks/mock_scoring_controller.dart';

/// Build a [MeetBeautyApp] with mock services injected via Provider.
///
/// A fresh [GoRouter] is created for every call so that navigation state
/// does not leak between test cases.
///
/// [withFace] – if true, the [MockFaceTrackingController] will simulate a
/// detected face with pre-built [FaceLandmarks], enabling overlay painting.
Widget buildTestApp({bool withFace = false}) {
  return MeetBeautyApp(
    routerConfig: buildAppRouter(),
    overrideProviders: [
      ChangeNotifierProvider<AnalysisController>(
        create: (_) => MockAnalysisController(),
      ),
      ChangeNotifierProvider<TutorialController>(
        create: (_) => TutorialController(),
      ),
      ChangeNotifierProvider<RecommendationController>(
        create: (_) => RecommendationController(),
      ),
      ChangeNotifierProvider<ScoringController>(
        create: (_) => MockScoringController(),
      ),
      ChangeNotifierProvider<FaceTrackingController>(
        create: (_) => MockFaceTrackingController(withFace: withFace),
      ),
    ],
  );
}
