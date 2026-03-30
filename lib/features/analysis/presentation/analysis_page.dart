import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meet_beauty/app/theme/app_colors.dart';
import 'package:meet_beauty/features/analysis/application/analysis_controller.dart';
import 'package:provider/provider.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
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
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Placeholder for camera preview
                      if (!controller.isCameraInitialized)
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Initializing camera...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        )
                      else
                        Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(
                              Icons.face,
                              size: 120,
                              color: Colors.white24,
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
                ),
              ),
              // Analysis results
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
                      ] else
                        const Text(
                          'Position your face in the camera view',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.isAnalysisComplete
                              ? () => context.go('/tutorial')
                              : null,
                          child: const Text('Start Tutorial'),
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
