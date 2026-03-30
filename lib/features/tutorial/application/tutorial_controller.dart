import 'package:flutter/material.dart';
import 'package:meet_beauty/shared/models/makeup_profile.dart';

enum TutorialState {
  idle,
  initializing,
  running,
  paused,
  completed,
}

enum StepStatus {
  notStarted,
  active,
  completed,
  skipped,
}

class TutorialController extends ChangeNotifier {
  TutorialState _state = TutorialState.idle;
  MakeupProfile? _currentProfile;
  int _currentStepIndex = 0;
  Map<String, StepStatus> _stepStatuses = {};
  DateTime? _startTime;

  TutorialState get state => _state;
  MakeupProfile? get currentProfile => _currentProfile;
  int get currentStepIndex => _currentStepIndex;
  int get totalSteps => _currentProfile?.tutorialSteps.length ?? 0;
  bool get isLastStep => _currentStepIndex >= totalSteps - 1;
  TutorialStep? get currentStep {
    if (_currentProfile == null || _currentStepIndex >= totalSteps) {
      return null;
    }
    return _currentProfile!.tutorialSteps[_currentStepIndex];
  }

  void startTutorial({MakeupProfile? profile}) {
    // Use provided profile or create default for MVP
    _currentProfile = profile ?? _getDefaultProfile();
    _currentStepIndex = 0;
    _state = TutorialState.running;
    _startTime = DateTime.now();

    // Initialize all steps as not started
    _stepStatuses = {
      for (var step in _currentProfile!.tutorialSteps)
        step.id: StepStatus.notStarted
    };

    // Mark first step as active
    if (_currentProfile!.tutorialSteps.isNotEmpty) {
      _stepStatuses[_currentProfile!.tutorialSteps.first.id] = StepStatus.active;
    }

    notifyListeners();
  }

  void nextStep() {
    if (_currentProfile == null || isLastStep) return;

    // Mark current step as completed
    final currentStepId = _currentProfile!.tutorialSteps[_currentStepIndex].id;
    _stepStatuses[currentStepId] = StepStatus.completed;

    // Move to next step
    _currentStepIndex++;

    // Mark new step as active
    if (_currentStepIndex < totalSteps) {
      final nextStepId = _currentProfile!.tutorialSteps[_currentStepIndex].id;
      _stepStatuses[nextStepId] = StepStatus.active;
    }

    notifyListeners();
  }

  void previousStep() {
    if (_currentProfile == null || _currentStepIndex == 0) return;

    // Mark current step as not started
    final currentStepId = _currentProfile!.tutorialSteps[_currentStepIndex].id;
    _stepStatuses[currentStepId] = StepStatus.notStarted;

    // Move to previous step
    _currentStepIndex--;

    // Mark new step as active
    final prevStepId = _currentProfile!.tutorialSteps[_currentStepIndex].id;
    _stepStatuses[prevStepId] = StepStatus.active;

    notifyListeners();
  }

  void skipStep() {
    if (_currentProfile == null || isLastStep) return;

    // Mark current step as skipped
    final currentStepId = _currentProfile!.tutorialSteps[_currentStepIndex].id;
    _stepStatuses[currentStepId] = StepStatus.skipped;

    nextStep();
  }

  void pauseTutorial() {
    _state = TutorialState.paused;
    notifyListeners();
  }

  void resumeTutorial() {
    _state = TutorialState.running;
    notifyListeners();
  }

  void completeTutorial() {
    // Mark current step as completed if not already
    if (currentStep != null) {
      _stepStatuses[currentStep!.id] = StepStatus.completed;
    }

    _state = TutorialState.completed;
    notifyListeners();
  }

  void reset() {
    _state = TutorialState.idle;
    _currentProfile = null;
    _currentStepIndex = 0;
    _stepStatuses = {};
    _startTime = null;
    notifyListeners();
  }

  Duration? get tutorialDuration {
    if (_startTime == null) return null;
    return DateTime.now().difference(_startTime!);
  }

  int get completedStepsCount {
    return _stepStatuses.values
        .where((s) => s == StepStatus.completed)
        .length;
  }

  int get skippedStepsCount {
    return _stepStatuses.values.where((s) => s == StepStatus.skipped).length;
  }

  MakeupProfile _getDefaultProfile() {
    // Default natural makeup tutorial for MVP
    return const MakeupProfile(
      id: 'natural_daily',
      name: 'Natural Daily Look',
      category: 'Daily',
      lipColor: Color(0xFFE57373),
      blushColor: Color(0xFFFFB6C1),
      tutorialSteps: [
        TutorialStep(
          id: 'step1',
          title: 'Apply Lip Color',
          instruction: 'Start from the center of your lips and work outward. Use gentle strokes for a natural look.',
          targetRegion: TargetRegion.lips,
          overlayStyle: OverlayStyle(
            color: Color(0xFFE57373),
            opacity: 0.4,
          ),
          order: 1,
        ),
        TutorialStep(
          id: 'step2',
          title: 'Add Blush - Left Cheek',
          instruction: 'Smile gently and apply blush to the apples of your cheeks. Blend upward toward your temples.',
          targetRegion: TargetRegion.leftCheek,
          overlayStyle: OverlayStyle(
            color: Color(0xFFFFB6C1),
            opacity: 0.3,
          ),
          order: 2,
        ),
        TutorialStep(
          id: 'step3',
          title: 'Add Blush - Right Cheek',
          instruction: 'Apply the same technique to your right cheek for a balanced look.',
          targetRegion: TargetRegion.rightCheek,
          overlayStyle: OverlayStyle(
            color: Color(0xFFFFB6C1),
            opacity: 0.3,
          ),
          order: 3,
        ),
      ],
      recommendationReasons: [
        'Perfect for everyday wear',
        'Enhances your natural features',
        'Quick and easy application',
      ],
    );
  }
}
