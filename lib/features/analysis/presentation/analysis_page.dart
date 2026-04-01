import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meet_beauty/app/theme/app_colors.dart';
import 'package:meet_beauty/features/analysis/application/analysis_controller.dart';
import 'package:meet_beauty/features/analysis/presentation/face_mesh_painter.dart';
import 'package:meet_beauty/services/camera/camera_service.dart';
import 'package:provider/provider.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

/// Camera preview with portrait [BoxFit.cover]. Does **not** mirror; front
/// mirroring wraps preview + overlay together in [AnalysisPage].
Widget _buildCameraPreviewOnly(CameraController cameraController) {
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

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisController>().startAnalysis();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Consumer<AnalysisController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              // Camera preview area
              Expanded(
                flex: 3,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Pass preview size to controller for coordinate transform
                    controller.updatePreviewSize(constraints.biggest);
                    return Container(
                      width: double.infinity,
                      color: Colors.black,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Camera preview or placeholder
                          if (controller.isCameraInitialized && controller.cameraController != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child:
                                  controller.cameraLensDirection ==
                                      CameraLensDirection.front
                                  ? Transform.flip(
                                      flipX: true,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _buildCameraPreviewOnly(
                                            controller.cameraController!,
                                          ),
                                          if (controller.currentLandmarks !=
                                              null)
                                            Positioned.fill(
                                              child: CustomPaint(
                                                painter: FaceMeshPainter(
                                                  controller.currentLandmarks,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                  : Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        _buildCameraPreviewOnly(
                                          controller.cameraController!,
                                        ),
                                        if (controller.currentLandmarks !=
                                            null)
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: FaceMeshPainter(
                                                controller.currentLandmarks,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                          ] else if (controller.cameraStatus == CameraStatus.permissionDenied ||
                          controller.cameraStatus == CameraStatus.permissionPermanentlyDenied)
                        _PermissionDeniedWidget(
                          onRetry: () => context.read<AnalysisController>().startAnalysis(),
                        )
                      else if (controller.cameraStatus == CameraStatus.error)
                        _ErrorWidget(
                          message: controller.errorMessage ?? 'Camera error',
                          onRetry: () => context.read<AnalysisController>().startAnalysis(),
                        )
                      else
                        Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  'Initializing camera...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Analysis overlay
                      if (controller.isAnalyzing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppColors.primary),
                                SizedBox(height: 16),
                                Text(
                                  'Analyzing your face...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Features',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      if (controller.featureResult != null) ...[
                        _FeatureBadge(
                          label: 'Face Shape',
                          value: controller.featureResult!.faceShape.name,
                        ),
                        const SizedBox(height: 8),
                        _FeatureBadge(
                          label: 'Skin Tone',
                          value: controller.featureResult!.skinTone.name,
                        ),
                        const SizedBox(height: 8),
                        _FeatureBadge(
                          label: 'Lip Type',
                          value: controller.featureResult!.lipType.name,
                        ),
                      ] else if (controller.currentLandmarks != null)
                        Text(
                          'Face detected! Tap "Capture & Analyze" to continue.',
                          style: const TextStyle(color: AppColors.textSecondary),
                        )
                      else
                        const Text(
                          'Position your face in the camera view',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.isAnalysisComplete
                              ? () => context.go('/recommendation', extra: controller.featureResult)
                              : (controller.currentLandmarks != null && !controller.isAnalyzing)
                                  ? () => controller.completeAnalysis()
                                  : null,
                          child: Text(
                            controller.isAnalysisComplete
                                ? 'Get Recommendations'
                                : controller.isAnalyzing
                                    ? 'Analyzing...'
                                    : 'Capture & Analyze',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final String label;
  final String value;

  const _FeatureBadge({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            'Camera Error',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PermissionDeniedWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const _PermissionDeniedWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
        const SizedBox(height: 16),
        const Text(
          'Camera permission required',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text('Grant Permission'),
        ),
      ],
    );
  }
}
