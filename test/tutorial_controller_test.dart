import 'package:flutter_test/flutter_test.dart';
import 'package:meet_beauty/features/tutorial/application/tutorial_controller.dart';

void main() {
  group('TutorialController', () {
    late TutorialController controller;

    setUp(() {
      controller = TutorialController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('completedSteps is empty before tutorial starts', () {
      expect(controller.completedSteps, isEmpty);
    });

    test('completedSteps is empty after startTutorial (first step active)', () {
      controller.startTutorial();

      expect(controller.completedSteps, isEmpty);
      expect(controller.currentStepIndex, equals(0));
    });

    test('completedSteps returns step1 after advancing to step 2', () {
      controller.startTutorial();
      controller.nextStep();

      final completed = controller.completedSteps;
      expect(completed.length, equals(1));
      expect(completed.first.id, equals('step1'));
      expect(controller.currentStepIndex, equals(1));
    });

    test('completedSteps returns step1 and step2 after advancing to step 3', () {
      controller.startTutorial();
      controller.nextStep();
      controller.nextStep();

      final completed = controller.completedSteps;
      expect(completed.length, equals(2));
      expect(completed[0].id, equals('step1'));
      expect(completed[1].id, equals('step2'));
    });

    test('completedSteps returns step1 after completeTutorial', () {
      controller.startTutorial();
      controller.completeTutorial();

      final completed = controller.completedSteps;
      expect(completed.length, equals(1));
      expect(completed.first.id, equals('step1'));
    });

    test('skipStep marks step as completed (skipStep calls nextStep internally)', () {
      controller.startTutorial();
      controller.skipStep();

      final completed = controller.completedSteps;
      // skipStep sets step1 to skipped, then calls nextStep() which
      // overwrites it with completed — this is current behavior.
      expect(completed.length, equals(1));
      expect(completed.first.id, equals('step1'));
      expect(controller.currentStepIndex, equals(1));
    });

    test('completedSteps is empty after reset', () {
      controller.startTutorial();
      controller.nextStep();
      controller.reset();

      expect(controller.completedSteps, isEmpty);
    });
  });
}
