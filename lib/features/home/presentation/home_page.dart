import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meet_beauty/app/theme/app_colors.dart';
import 'package:meet_beauty/l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  // Logo and Title
                  Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.face_retouching_natural,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.homeTitle,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.homeSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  // Feature highlights
                  Column(
                    children: [
                      _FeatureItem(
                        icon: Icons.face,
                        title: l10n.homeFeatureAnalysis,
                        description: l10n.homeFeatureAnalysisDesc,
                      ),
                      const SizedBox(height: 16),
                      _FeatureItem(
                        icon: Icons.video_camera_front,
                        title: l10n.homeFeatureTutorial,
                        description: l10n.homeFeatureTutorialDesc,
                      ),
                      const SizedBox(height: 16),
                      _FeatureItem(
                        icon: Icons.auto_awesome,
                        title: l10n.homeFeatureScoring,
                        description: l10n.homeFeatureScoringDesc,
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  // Start Button
                  ElevatedButton(
                    onPressed: () => context.push('/analysis'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.homeStartLearning,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Secondary options
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to tutorial selection
                    },
                    child: Text(l10n.homeChooseStyle),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.settings, color: AppColors.textSecondary),
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
