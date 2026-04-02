import 'package:go_router/go_router.dart';
import 'package:meet_beauty/features/home/presentation/home_page.dart';
import 'package:meet_beauty/features/analysis/presentation/analysis_page.dart';
import 'package:meet_beauty/features/recommendation/presentation/recommendation_page.dart';
import 'package:meet_beauty/features/tutorial/presentation/tutorial_page.dart';
import 'package:meet_beauty/features/result/presentation/result_page.dart';
import 'package:meet_beauty/features/settings/presentation/settings_page.dart';
import 'package:meet_beauty/shared/models/face_feature_result.dart';

/// Creates a fresh [GoRouter] with all app routes.
/// Call this in tests to avoid shared navigation state between test cases.
GoRouter buildAppRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/analysis',
      name: 'analysis',
      builder: (context, state) => const AnalysisPage(),
    ),
    GoRoute(
      path: '/recommendation',
      name: 'recommendation',
      builder: (context, state) {
        final result = state.extra as FaceFeatureResult?;
        return RecommendationPage(analysisResult: result);
      },
    ),
    GoRoute(
      path: '/tutorial',
      name: 'tutorial',
      builder: (context, state) => const TutorialPage(),
    ),
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) => const ResultPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

/// Singleton router for production use.
final appRouter = buildAppRouter();
