import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meet_beauty/l10n/app_localizations.dart';
import 'package:meet_beauty/shared/models/score_result.dart';
import 'package:meet_beauty/features/tutorial/application/tutorial_controller.dart';

/// Weights for each scoring dimension (sum to 1.0).
const _kCompletionWeight = 0.50;
const _kFaceTrackingWeight = 0.30;
const _kPacingWeight = 0.20;

/// Minimum seconds per step to be considered "well-paced".
const _kMinSecondsPerStep = 5;

class ScoringController extends ChangeNotifier {
  ScoreResult? _scoreResult;
  bool _isCalculating = false;

  ScoreResult? get scoreResult => _scoreResult;
  bool get isCalculating => _isCalculating;

  /// Seed a [ScoreResult] directly — intended for test mocks only.
  @protected
  void seedResult(ScoreResult result) {
    _scoreResult = result;
  }

  /// Calculate a composite score combining:
  ///  1. Step completion rate (§5.7 完成度)
  ///  2. Face detection / tracking quality (§5.7 覆盖率近似)
  ///  3. Pacing heuristic — did the user spend reasonable time per step
  ///
  /// [faceDetectionRate] is 0.0–1.0, provided by [FaceTrackingController].
  void calculateScore(
    TutorialController tutorialController, {
    double faceDetectionRate = 1.0,
    required AppLocalizations l10n,
  }) {
    _isCalculating = true;
    notifyListeners();

    final completedSteps = tutorialController.completedStepsCount;
    final totalSteps = tutorialController.totalSteps;
    final skippedSteps = tutorialController.skippedStepsCount;
    final duration = tutorialController.tutorialDuration;
    final durationSecs = duration?.inSeconds ?? 0;

    // ── Dimension 1: Completion rate ────────────────────────────────────────
    final completionRate = totalSteps > 0 ? completedSteps / totalSteps : 0.0;
    final skipPenalty = math.min(skippedSteps * 0.05, 0.3);
    final completionScore = (completionRate - skipPenalty).clamp(0.0, 1.0);

    // ── Dimension 2: Face tracking quality ──────────────────────────────────
    // A detection rate below 0.3 is heavily penalised (user probably pointed
    // the camera away); above 0.7 is considered good.
    final trackingScore = faceDetectionRate.clamp(0.0, 1.0);

    // ── Dimension 3: Pacing ─────────────────────────────────────────────────
    // At least _kMinSecondsPerStep per completed step is "ideal".
    final idealSecs = completedSteps * _kMinSecondsPerStep;
    final pacingScore = idealSecs > 0
        ? (durationSecs / idealSecs).clamp(0.0, 1.0)
        : 1.0;

    // ── Composite ───────────────────────────────────────────────────────────
    final raw = completionScore * _kCompletionWeight +
        trackingScore * _kFaceTrackingWeight +
        pacingScore * _kPacingWeight;
    final score = (raw * 100).round().clamp(0, 100);

    // ── Stars ───────────────────────────────────────────────────────────────
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

    // ── Feedback ────────────────────────────────────────────────────────────
    final feedbackTags = <String>[];
    String encouragement;
    String? suggestion;

    if (score >= 80) {
      encouragement = l10n.scoreExcellent;
      feedbackTags.add('great_coverage');
      if (skippedSteps == 0) feedbackTags.add('all_steps_completed');
    } else if (score >= 60) {
      encouragement = l10n.scoreGood;
      suggestion = l10n.scoreGoodSuggestion;
      feedbackTags.add('good_effort');
    } else {
      encouragement = l10n.scoreNeedsWork;
      suggestion = l10n.scoreNeedsWorkSuggestion;
      feedbackTags.add('needs_practice');
    }

    if (skippedSteps > 0) feedbackTags.add('steps_skipped');

    if (faceDetectionRate < 0.5) {
      feedbackTags.add('face_tracking_low');
      final trackingTip = l10n.scoreTrackingTip;
      suggestion = suggestion != null ? '$suggestion $trackingTip' : trackingTip;
    } else if (faceDetectionRate > 0.8) {
      feedbackTags.add('good_tracking');
    }

    if (pacingScore < 0.5) {
      feedbackTags.add('too_fast');
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
        'duration': durationSecs,
        'faceDetectionRate': (faceDetectionRate * 100).round(),
        'completionScore': (completionScore * 100).round(),
        'trackingScore': (trackingScore * 100).round(),
        'pacingScore': (pacingScore * 100).round(),
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
