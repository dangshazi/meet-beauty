import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meet_beauty/app/theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    'Meet Beauty',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI Makeup Coach',
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
                    title: 'Face Analysis',
                    description: 'Get personalized makeup recommendations',
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.video_camera_front,
                    title: 'AR Tutorial',
                    description: 'Learn with real-time AR guidance',
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.auto_awesome,
                    title: 'Smart Scoring',
                    description: 'Track your progress with instant feedback',
                  ),
                ],
              ),
              const Spacer(flex: 2),
              // Start Button
              ElevatedButton(
                onPressed: () => context.go('/analysis'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Start Learning',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              // Secondary options
              TextButton(
                onPressed: () {
                  // TODO: Navigate to tutorial selection
                },
                child: const Text('Choose a Tutorial Style'),
              ),
            ],
          ),
        ),
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
