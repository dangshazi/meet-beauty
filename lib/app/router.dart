import 'package:go_router/go_router.dart';
import 'package:meet_beauty/features/home/presentation/home_page.dart';
import 'package:meet_beauty/features/analysis/presentation/analysis_page.dart';
import 'package:meet_beauty/features/tutorial/presentation/tutorial_page.dart';
import 'package:meet_beauty/features/result/presentation/result_page.dart';

final appRouter = GoRouter(
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
      path: '/tutorial',
      name: 'tutorial',
      builder: (context, state) => const TutorialPage(),
    ),
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) => const ResultPage(),
    ),
  ],
);
