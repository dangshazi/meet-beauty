import 'package:meet_beauty/features/result/application/scoring_controller.dart';
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
    // Directly assign the result without calling calculateScore (which now
    // requires an AppLocalizations instance not available at construction time).
    seedResult(ScoreResult(
      score: 85,
      stars: 4,
      feedbackTags: ['great_coverage', 'all_steps_completed', 'good_tracking'],
      encouragement: 'Mock encouragement',
      suggestion: null,
      details: {
        'completedSteps': 3,
        'totalSteps': 3,
        'skippedSteps': 0,
        'duration': 90,
        'faceDetectionRate': 95,
        'completionScore': 100,
        'trackingScore': 95,
        'pacingScore': 100,
      },
    ));
  }
}
