import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meet_beauty/app/theme/app_colors.dart';
import 'package:meet_beauty/features/result/application/scoring_controller.dart';
import 'package:meet_beauty/features/tutorial/application/tutorial_controller.dart';
import 'package:meet_beauty/l10n/app_localizations.dart';
import 'package:meet_beauty/services/face_tracking_controller.dart';
import 'package:meet_beauty/services/overlay/overlay_renderer.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';
import 'package:meet_beauty/shared/models/makeup_profile.dart';
import 'package:meet_beauty/shared/providers/settings_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage>
    with WidgetsBindingObserver {
  // Cache controller reference so dispose() can call it without context.
  late FaceTrackingController _tracker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tracker = context.read<FaceTrackingController>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<TutorialController>().startTutorial();
      // Camera permission + init is handled inside FaceTrackingController
      await _tracker.startTracking();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // FaceTrackingController.dispose() (called by Provider) handles
    // stopTracking() — no need to call it here.
    super.dispose();
  }

  // ── App lifecycle ─────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _tracker.pauseTracking();
        break;
      case AppLifecycleState.resumed:
        _tracker.resumeTracking();
        break;
      default:
        break;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<TutorialController, FaceTrackingController>(
        builder: (context, tutorial, tracker, _) {
          // Show permission-denied UI when tracker reports a permission error
          if (tracker.state == TrackingState.error &&
              (tracker.errorMessage?.contains('permission') == true ||
                  tracker.errorMessage?.contains('denied') == true)) {
            return _PermissionDeniedView(
              onRetry: () => tracker.startTracking(),
            );
          }

          return Column(
            children: [
              Expanded(
                flex: 3,
                child: _CameraSection(
                  tutorial: tutorial,
                  tracker: tracker,
                  accumulateOverlays:
                      context.watch<SettingsProvider>().accumulateOverlays,
                  onClose: () {
                    _tracker.stopTracking();
                    context.go('/');
                  },
                ),
              ),
              _StepPanel(
                tutorial: tutorial,
                onComplete: () => _completeTutorial(tutorial),
              ),
            ],
          );
        },
      ),
    );
  }

  void _completeTutorial(TutorialController controller) {
    _tracker.stopTracking();
    controller.completeTutorial();

    final scoring = context.read<ScoringController>();
    scoring.calculateScore(
      controller,
      faceDetectionRate: _tracker.faceDetectionRate,
      l10n: AppLocalizations.of(context)!,
    );

    context.push('/result');
  }
}

// ── Camera section ─────────────────────────────────────────────────────────

class _CameraSection extends StatelessWidget {
  const _CameraSection({
    required this.tutorial,
    required this.tracker,
    required this.accumulateOverlays,
    required this.onClose,
  });

  final TutorialController tutorial;
  final FaceTrackingController tracker;
  final bool accumulateOverlays;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          tracker.updatePreviewSize(
            Size(constraints.maxWidth, constraints.maxHeight),
          );
        });

        final front =
            tracker.cameraLensDirection == CameraLensDirection.front;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: front
                  ? Transform.flip(
                      flipX: true,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildCameraPreview(context),
                          if (tutorial.currentStep != null)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ArOverlayPainter(
                                  steps: _buildOverlaySteps(tutorial),
                                  landmarks: tracker.landmarks,
                                  debugLandmarks: tracker.landmarks,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildCameraPreview(context),
                        if (tutorial.currentStep != null)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ArOverlayPainter(
                                steps: _buildOverlaySteps(tutorial),
                                landmarks: tracker.landmarks,
                                debugLandmarks: tracker.landmarks,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            if (tracker.isTracking && !tracker.isFaceDetected)
              const Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: _FaceHint(),
              ),

            if (tracker.state == TrackingState.initializing)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            if (tracker.state == TrackingState.error)
              _ErrorBanner(message: tracker.errorMessage),

            Positioned(
              top: 48,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
              ),
            ),

            Positioned(
              top: 48,
              right: 16,
              child: _StepBadge(
                current: tutorial.currentStepIndex + 1,
                total: tutorial.totalSteps,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCameraPreview(BuildContext context) {
    final cameraController = tracker.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.face, size: 100, color: Colors.white24),
        ),
      );
    }

    final previewSize = cameraController.value.previewSize;
    final preview = CameraPreview(cameraController);
    if (previewSize == null) {
      return preview;
    }
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: preview,
          ),
        ),
      ),
    );
  }

  List<TutorialStep> _buildOverlaySteps(TutorialController tutorial) {
    if (tutorial.currentStep == null) return const [];
    if (accumulateOverlays) {
      return [...tutorial.completedSteps, tutorial.currentStep!];
    }
    return [tutorial.currentStep!];
  }
}

// ── AR overlay painter ─────────────────────────────────────────────────────

class _ArOverlayPainter extends CustomPainter {
  _ArOverlayPainter({
    required this.steps,
    this.landmarks,
    this.debugLandmarks,
  });

  final List<TutorialStep> steps;
  final FaceLandmarks? landmarks;
  final FaceLandmarks? debugLandmarks;

  static final OverlayRenderer _renderer = OverlayRenderer();

  @override
  void paint(Canvas canvas, Size size) {
    _renderer.drawOverlays(canvas, size, steps, landmarks);
    // Debug: draw raw landmark points to verify coordinate mapping
    assert(() {
      if (debugLandmarks != null) {
        _renderer.debugDrawLandmarks(canvas, debugLandmarks!);
      }
      return true;
    }());
  }

  @override
  bool shouldRepaint(covariant _ArOverlayPainter oldDelegate) {
    return !_listEquals(oldDelegate.steps, steps) ||
        oldDelegate.landmarks != landmarks ||
        oldDelegate.debugLandmarks != debugLandmarks;
  }

  static bool _listEquals(List<TutorialStep> a, List<TutorialStep> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ── Step panel ─────────────────────────────────────────────────────────────

class _StepPanel extends StatelessWidget {
  const _StepPanel({required this.tutorial, required this.onComplete});

  final TutorialController tutorial;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final step = tutorial.currentStep;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step != null) ...[
            Text(
              step.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              step.instruction,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              tutorial.totalSteps,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == tutorial.currentStepIndex ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i <= tutorial.currentStepIndex
                      ? AppColors.primary
                      : AppColors.textHint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              if (tutorial.currentStepIndex > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: tutorial.previousStep,
                    child: Text(AppLocalizations.of(context)!.tutorialPreviousStep),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                      tutorial.isLastStep ? onComplete : tutorial.nextStep,
                  child: Text(tutorial.isLastStep
                        ? AppLocalizations.of(context)!.tutorialComplete
                        : AppLocalizations.of(context)!.tutorialNextStep),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _FaceHint extends StatelessWidget {
  const _FaceHint();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.face_retouching_natural, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              l10n.tutorialFaceHint,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.red.withValues(alpha: 0.85),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          message ?? l10n.tutorialCameraErrorDefault,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                l10n.permissionRequired,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.permissionDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings),
                label: Text(l10n.permissionOpenSettings),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: Text(l10n.permissionRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
