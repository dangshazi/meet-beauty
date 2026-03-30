import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meet_beauty/app/theme/app_colors.dart';
import 'package:meet_beauty/features/tutorial/application/tutorial_controller.dart';
import 'package:meet_beauty/shared/models/makeup_profile.dart';
import 'package:provider/provider.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutorialController>().startTutorial();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TutorialController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              // Camera with AR overlay
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Camera preview
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                          Icons.face,
                          size: 150,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                    // AR overlay will be rendered here
                    if (controller.currentStep != null)
                      _buildOverlay(controller.currentStep!),
                    // Close button
                    Positioned(
                      top: 48,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => context.go('/'),
                      ),
                    ),
                    // Progress indicator
                    Positioned(
                      top: 48,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${controller.currentStepIndex + 1}/${controller.totalSteps}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tutorial instructions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.currentStep != null) ...[
                      Text(
                        controller.currentStep!.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.currentStep!.instruction,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Step progress dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        controller.totalSteps,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index <= controller.currentStepIndex
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      children: [
                        if (controller.currentStepIndex > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: controller.previousStep,
                              child: const Text('Previous'),
                            ),
                          ),
                        if (controller.currentStepIndex > 0)
                          const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: controller.isLastStep
                                ? () => _completeTutorial(controller)
                                : controller.nextStep,
                            child: Text(
                              controller.isLastStep ? 'Complete' : 'Next',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverlay(TutorialStep step) {
    // TODO: Implement actual AR overlay rendering
    return Positioned.fill(
      child: CustomPaint(
        painter: _OverlayPainter(step: step),
      ),
    );
  }

  void _completeTutorial(TutorialController controller) {
    controller.completeTutorial();
    context.go('/result');
  }
}

class _OverlayPainter extends CustomPainter {
  final TutorialStep step;

  _OverlayPainter({required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: Implement actual overlay rendering based on face landmarks
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    switch (step.targetRegion) {
      case TargetRegion.lips:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + 50),
            width: 100,
            height: 40,
          ),
          paint,
        );
        break;
      case TargetRegion.leftCheek:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx - 80, center.dy + 20),
            width: 60,
            height: 40,
          ),
          paint,
        );
        break;
      case TargetRegion.rightCheek:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx + 80, center.dy + 20),
            width: 60,
            height: 40,
          ),
          paint,
        );
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.step != step;
  }
}
