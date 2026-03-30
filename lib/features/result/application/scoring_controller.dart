import 'package:flutter/material.dart';
import 'package:meet_beauty/shared/models/score_result.dart';
import 'package:meet_beauty/features/tutorial/application/tutorial_controller.dart';

class ScoringController extends ChangeNotifier {
  ScoreResult? _scoreResult;
  bool _isCalculating = false;

  ScoreResult? get scoreResult => _scoreResult;
  bool get isCalculating => _isCalculating;

  void calculateScore(TutorialController tutorialController) {
    _isCalculating = true;
    notifyListeners();

    // MVP: Calculate score based on completion rate
    final completedSteps = tutorialController.completedStepsCount;
    final totalSteps = tutorialController.totalSteps;
    final skippedSteps = tutorialController.skippedStepsCount;

    // Calculate base score
    final completionRate = totalSteps > 0 ? completedSteps / totalSteps : 0.0;
    final skipPenalty = skippedSteps * 5;
    final baseScore = (completionRate * 100).round() - skipPenalty;
    final score = baseScore.clamp(0, 100);

    // Calculate stars (1-5)
    int stars;
    if (score >= 90) {
      stars = 5;
    } else if (score >= 75) {
      stars = 4;
    } else if (score >= 60) {
      stars = 3;
    } else if (score >= 40) {
      stars = 2;
    } else {
      stars = 1;
    }

    // Generate feedback
    final feedbackTags = <String>[];
    String encouragement;
    String? suggestion;

    if (score >= 80) {
      encouragement = 'Excellent work! Your makeup application looks great!';
      feedbackTags.add('great_coverage');
      if (skippedSteps == 0) {
        feedbackTags.add('all_steps_completed');
      }
    } else if (score >= 60) {
      encouragement = 'Good job! You\'re making nice progress.';
      suggestion = 'Try to complete all steps for a better result.';
      feedbackTags.add('good_effort');
    } else {
      encouragement = 'Keep practicing! You\'ll get better with time.';
      suggestion = 'Take your time with each step for better results.';
      feedbackTags.add('needs_practice');
    }

    if (skippedSteps > 0) {
      feedbackTags.add('steps_skipped');
    }

    _scoreResult = ScoreResult(
      score: score,
      stars: stars,
      feedbackTags: feedbackTags,
      encouragement: encouragement,
      suggestion: suggestion,
      details: {
        'completedSteps': completedSteps,
        'totalSteps': totalSteps,
        'skippedSteps': skippedSteps,
        'duration': tutorialController.tutorialDuration?.inSeconds ?? 0,
      },
    );

    _isCalculating = false;
    notifyListeners();
  }

  void reset() {
    _scoreResult = null;
    _isCalculating = false;
    notifyListeners();
  }
}
