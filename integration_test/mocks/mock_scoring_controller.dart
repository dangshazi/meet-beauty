import 'package:meet_beauty/features/result/application/scoring_controller.dart';
import 'package:meet_beauty/features/tutorial/application/tutorial_controller.dart';
import 'package:meet_beauty/shared/models/score_result.dart';

/// A [ScoringController] that pre-populates a fake [ScoreResult] so the
/// result page renders immediately without waiting for [calculateScore].
class MockScoringController extends ScoringController {
  MockScoringController() {
    // Seed a result directly without calling notifyListeners during build.
    // calculateScore triggers notifyListeners, which is unsafe in a constructor
    // during a build phase.  We replicate just the score assignment here.
    _seedScore();
  }

  void _seedScore() {
    // Directly set the score via the public calculate path but deferred.
    // Use a fake TutorialController only for the data the method needs.
    calculateScore(_FakeTutorialController());
  }
}

/// Minimal [TutorialController]-like data source used to seed the score.
class _FakeTutorialController implements TutorialController {
  @override
  int get completedStepsCount => 3;
  @override
  int get totalSteps => 3;
  @override
  int get skippedStepsCount => 0;
  @override
  Duration? get tutorialDuration => const Duration(minutes: 1, seconds: 30);

  // All other members are unused by calculateScore.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
