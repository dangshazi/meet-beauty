import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meet_beauty/app/theme/app_colors.dart';
import 'package:meet_beauty/features/analysis/application/analysis_controller.dart';
import 'package:meet_beauty/features/analysis/presentation/face_mesh_painter.dart';
import 'package:meet_beauty/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analysisTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
                        _CameraErrorWidget(
                          message: controller.errorMessage ?? l10n.analysisCameraError,
                          onRetry: () => context.read<AnalysisController>().startAnalysis(),
                        )
                      else
                        Container(
                          color: Colors.grey[900],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: Colors.white),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.analysisInitializing,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Analysis overlay
                      if (controller.isAnalyzing)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: AppColors.primary),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.analysisAnalyzing,
                                  style: const TextStyle(color: Colors.white),
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
                        l10n.analysisYourFeatures,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      if (controller.featureResult != null) ...[
                        _FeatureBadge(
                          label: l10n.analysisFaceShape,
                          value: controller.featureResult!.faceShape.name,
                        ),
                        const SizedBox(height: 8),
                        _FeatureBadge(
                          label: l10n.analysisSkinTone,
                          value: controller.featureResult!.skinTone.name,
                        ),
                        const SizedBox(height: 8),
                        _FeatureBadge(
                          label: l10n.analysisLipType,
                          value: controller.featureResult!.lipType.name,
                        ),
                      ] else if (controller.currentLandmarks != null)
                        Text(
                          l10n.analysisFaceDetected,
                          style: const TextStyle(color: AppColors.textSecondary),
                        )
                      else
                        Text(
                          l10n.analysisPositionFace,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.isAnalysisComplete
                              ? () => context.push('/recommendation', extra: controller.featureResult)
                              : (controller.currentLandmarks != null && !controller.isAnalyzing)
                                  ? () => controller.completeAnalysis()
                                  : null,
                          child: Text(
                            controller.isAnalysisComplete
                                ? l10n.analysisGetRecommendations
                                : controller.isAnalyzing
                                    ? l10n.analysisAnalyzingBtn
                                    : l10n.analysisCaptureAnalyze,
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

class _CameraErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CameraErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            l10n.analysisCameraError,
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
            child: Text(l10n.analysisRetry),
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
        const SizedBox(height: 16),
        Text(
          l10n.analysisCameraPermission,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry,
          child: Text(l10n.analysisGrantPermission),
        ),
      ],
    );
  }
}
