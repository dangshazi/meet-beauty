import 'package:flutter/material.dart';
import 'package:meet_beauty/shared/models/face_feature_result.dart';
import 'package:meet_beauty/shared/models/makeup_profile.dart';

// ── Internal template definition ─────────────────────────────────────────────

class _MakeupTemplate {
  final String id;
  final String name;
  final String category;
  final String description;
  final Set<FaceShape> applicableFaceShapes; // empty = universal
  final Color warmLipColor;
  final Color coolLipColor;
  final Color warmBlushColor;
  final Color coolBlushColor;
  final List<TutorialStep> tutorialSteps;
  int weight;

  _MakeupTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.applicableFaceShapes,
    required this.warmLipColor,
    required this.coolLipColor,
    required this.warmBlushColor,
    required this.coolBlushColor,
    required this.tutorialSteps,
    this.weight = 1,
  });
}

// ── Controller ────────────────────────────────────────────────────────────────

class RecommendationController extends ChangeNotifier {
  List<MakeupProfile> _recommendations = [];
  MakeupProfile? _selectedProfile;
  bool _isLoading = false;

  List<MakeupProfile> get recommendations => _recommendations;
  MakeupProfile? get selectedProfile => _selectedProfile;
  bool get isLoading => _isLoading;

  void generateRecommendations(FaceFeatureResult features) {
    _isLoading = true;
    notifyListeners();

    _recommendations = _generateRecommendations(features);

    if (_recommendations.isNotEmpty) {
      _selectedProfile = _recommendations.first;
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectProfile(MakeupProfile profile) {
    _selectedProfile = profile;
    notifyListeners();
  }

  // ── 3-layer rule engine ─────────────────────────────────────────────────

  List<MakeupProfile> _generateRecommendations(FaceFeatureResult f) {
    // ── 1. Clone template library with fresh weights ────────────────────────
    final templates = _buildTemplateLibrary();

    // ── 2. Shape filter: remove templates not suited to this face shape ──────
    final shaped = (f.faceShape == FaceShape.unknown)
        ? templates
        : templates
            .where((t) =>
                t.applicableFaceShapes.isEmpty ||
                t.applicableFaceShapes.contains(f.faceShape))
            .toList();

    // ── 3. Lip type weight adjustment ────────────────────────────────────────
    for (final t in shaped) {
      if (f.lipType == LipType.full && t.id == 'bold_lip') t.weight += 2;
      if (f.lipType == LipType.thin) {
        if (t.id == 'minimal_clean') t.weight += 2;
        if (t.id == 'bold_lip') t.weight -= 1;
      }
    }

    // ── 4. Skin-tone colour selection & profile construction ─────────────────
    final profiles = shaped.map((t) {
      final lipColor =
          (f.skinTone == SkinTone.cool) ? t.coolLipColor : t.warmLipColor;
      final blushColor =
          (f.skinTone == SkinTone.cool) ? t.coolBlushColor : t.warmBlushColor;

      final reasons = _buildReasons(f, t);

      // Re-colour the tutorial steps that carry an overlay
      final steps = t.tutorialSteps.map((step) {
        if (step.overlayStyle == null) return step;
        final isLip = step.targetRegion == TargetRegion.lips;
        final isCheck = step.targetRegion == TargetRegion.leftCheek ||
            step.targetRegion == TargetRegion.rightCheek;
        if (!isLip && !isCheck) return step;
        return TutorialStep(
          id: step.id,
          title: step.title,
          instruction: step.instruction,
          targetRegion: step.targetRegion,
          overlayStyle: OverlayStyle(
            color: isLip ? lipColor : blushColor,
            opacity: step.overlayStyle!.opacity,
          ),
          order: step.order,
        );
      }).toList();

      return _WeightedProfile(
        weight: t.weight,
        profile: MakeupProfile(
          id: t.id,
          name: t.name,
          category: t.category,
          description: t.description,
          lipColor: lipColor,
          blushColor: blushColor,
          recommendationReasons: reasons,
          tutorialSteps: steps,
        ),
      );
    }).toList();

    // ── 5. Sort by weight (descending) and return top 3 ─────────────────────
    profiles.sort((a, b) => b.weight.compareTo(a.weight));
    return profiles.take(3).map((wp) => wp.profile).toList();
  }

  // ── Dynamic recommendation reasons ───────────────────────────────────────

  List<String> _buildReasons(FaceFeatureResult f, _MakeupTemplate t) {
    final reasons = <String>[];

    if (f.faceShape != FaceShape.unknown) {
      reasons.add('Ideal for your ${_shapeLabel(f.faceShape)} face shape');
    }

    if (f.skinTone != SkinTone.unknown) {
      reasons.add('Colors matched to your ${f.skinTone.name} undertone');
    }

    switch (f.lipType) {
      case LipType.full:
        if (t.id == 'bold_lip') {
          reasons.add('Designed to highlight your full lips');
        }
        break;
      case LipType.thin:
        if (t.id == 'minimal_clean') {
          reasons.add('Gentle shades that complement your refined lips');
        }
        break;
      default:
        break;
    }

    // Fallback generic reason
    if (reasons.isEmpty) reasons.add('A versatile look for any occasion');

    return reasons;
  }

  String _shapeLabel(FaceShape shape) => switch (shape) {
        FaceShape.round => 'round',
        FaceShape.oval => 'oval',
        FaceShape.long => 'long',
        FaceShape.square => 'square',
        FaceShape.heart => 'heart-shaped',
        FaceShape.unknown => '',
      };

  // ── Template library ─────────────────────────────────────────────────────

  List<_MakeupTemplate> _buildTemplateLibrary() => [
        // ── Natural Daily ────────────────────────────────────────────────────
        _MakeupTemplate(
          id: 'natural_daily',
          name: 'Natural Daily Look',
          category: 'Daily',
          description: 'A fresh, natural look perfect for everyday',
          applicableFaceShapes: {},
          warmLipColor: const Color(0xFFE57373), // coral
          coolLipColor: const Color(0xFFE91E8C), // rose pink
          warmBlushColor: const Color(0xFFFFB6C1), // peach
          coolBlushColor: const Color(0xFFF48FB1), // pink
          tutorialSteps: [
            const TutorialStep(
              id: 'nd_step1',
              title: 'Apply Lip Color',
              instruction: 'Start from the center of your lips and work outward',
              targetRegion: TargetRegion.lips,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFE57373), opacity: 0.4),
              order: 1,
            ),
            const TutorialStep(
              id: 'nd_step2',
              title: 'Add Blush – Left Cheek',
              instruction:
                  'Smile and apply blush to the apples of your cheeks',
              targetRegion: TargetRegion.leftCheek,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFFFB6C1), opacity: 0.3),
              order: 2,
            ),
            const TutorialStep(
              id: 'nd_step3',
              title: 'Add Blush – Right Cheek',
              instruction: 'Apply the same technique to your right cheek',
              targetRegion: TargetRegion.rightCheek,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFFFB6C1), opacity: 0.3),
              order: 3,
            ),
          ],
          weight: 2,
        ),

        // ── Sculpt & Define ──────────────────────────────────────────────────
        _MakeupTemplate(
          id: 'contour_sculpt',
          name: 'Sculpt & Define',
          category: 'Contouring',
          description:
              'Enhance your bone structure with subtle contouring and rich tones',
          applicableFaceShapes: {FaceShape.round, FaceShape.square},
          warmLipColor: const Color(0xFFB71C1C), // brick
          coolLipColor: const Color(0xFF6A1B9A), // berry
          warmBlushColor: const Color(0xFF8D4E35), // terracotta
          coolBlushColor: const Color(0xFF9C6B8A), // mauve
          tutorialSteps: [
            const TutorialStep(
              id: 'cs_step1',
              title: 'Contour Jawline',
              instruction:
                  'Apply contour along your jawline and temples using light strokes',
              targetRegion: TargetRegion.forehead,
              order: 1,
            ),
            const TutorialStep(
              id: 'cs_step2',
              title: 'Apply Lip Color',
              instruction: 'Fill lips fully for a bold, defined look',
              targetRegion: TargetRegion.lips,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFB71C1C), opacity: 0.45),
              order: 2,
            ),
            const TutorialStep(
              id: 'cs_step3',
              title: 'Blend Cheek Colour',
              instruction: 'Sweep blush diagonally from cheekbone toward ear',
              targetRegion: TargetRegion.leftCheek,
              overlayStyle: OverlayStyle(
                  color: Color(0xFF8D4E35), opacity: 0.3),
              order: 3,
            ),
          ],
          weight: 1,
        ),

        // ── Soft Glam ────────────────────────────────────────────────────────
        _MakeupTemplate(
          id: 'soft_glam',
          name: 'Soft Glam',
          category: 'Glam',
          description: 'Romantic and luminous for an elegant everyday glam',
          applicableFaceShapes: {FaceShape.oval, FaceShape.heart},
          warmLipColor: const Color(0xFFD4A5A5), // dusty rose
          coolLipColor: const Color(0xFF9C6B8A), // mauve
          warmBlushColor: const Color(0xFFFFCCBC), // soft peach
          coolBlushColor: const Color(0xFFF8BBD9), // rose
          tutorialSteps: [
            const TutorialStep(
              id: 'sg_step1',
              title: 'Lip Colour',
              instruction: 'Apply softly, blending slightly beyond the lip line',
              targetRegion: TargetRegion.lips,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFD4A5A5), opacity: 0.4),
              order: 1,
            ),
            const TutorialStep(
              id: 'sg_step2',
              title: 'Rosy Cheeks',
              instruction: 'Dust blush lightly for a natural flush',
              targetRegion: TargetRegion.leftCheek,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFFFCCBC), opacity: 0.3),
              order: 2,
            ),
            const TutorialStep(
              id: 'sg_step3',
              title: 'Eye Highlight',
              instruction: 'Apply a sheer shimmer on the inner corners',
              targetRegion: TargetRegion.leftEye,
              order: 3,
            ),
          ],
          weight: 1,
        ),

        // ── Fresh & Dewy ─────────────────────────────────────────────────────
        _MakeupTemplate(
          id: 'fresh_dewy',
          name: 'Fresh & Dewy',
          category: 'Everyday',
          description: 'Lightweight, skin-forward look with a luminous finish',
          applicableFaceShapes: {FaceShape.long, FaceShape.oval},
          warmLipColor: const Color(0xFFFF8A65), // sheer coral
          coolLipColor: const Color(0xFFF48FB1), // sheer pink
          warmBlushColor: const Color(0xFFFFCC80), // warm apricot
          coolBlushColor: const Color(0xFFF8BBD9), // cool pink
          tutorialSteps: [
            const TutorialStep(
              id: 'fd_step1',
              title: 'Sheer Lip Tint',
              instruction:
                  'Press lip tint gently with a fingertip for a diffused effect',
              targetRegion: TargetRegion.lips,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFFF8A65), opacity: 0.3),
              order: 1,
            ),
            const TutorialStep(
              id: 'fd_step2',
              title: 'Dewy Blush',
              instruction: 'Tap a cream blush onto the high points of cheeks',
              targetRegion: TargetRegion.leftCheek,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFFFCC80), opacity: 0.25),
              order: 2,
            ),
          ],
          weight: 1,
        ),

        // ── Statement Lip ────────────────────────────────────────────────────
        _MakeupTemplate(
          id: 'bold_lip',
          name: 'Statement Lip',
          category: 'Bold',
          description: 'Make a statement with a striking, confident lip colour',
          applicableFaceShapes: {},
          warmLipColor: const Color(0xFFB71C1C), // deep red
          coolLipColor: const Color(0xFF4A148C), // wine
          warmBlushColor: const Color(0xFFBCAAA4), // subtle blush
          coolBlushColor: const Color(0xFFCE93D8), // lavender blush
          tutorialSteps: [
            const TutorialStep(
              id: 'bl_step1',
              title: 'Bold Lip',
              instruction: 'Line and fill lips precisely for maximum impact',
              targetRegion: TargetRegion.lips,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFB71C1C), opacity: 0.5),
              order: 1,
            ),
            const TutorialStep(
              id: 'bl_step2',
              title: 'Soft Blush',
              instruction: 'Keep cheeks minimal to let the lip take centre stage',
              targetRegion: TargetRegion.leftCheek,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFBCAAA4), opacity: 0.2),
              order: 2,
            ),
          ],
          weight: 1,
        ),

        // ── Clean Minimal ────────────────────────────────────────────────────
        _MakeupTemplate(
          id: 'minimal_clean',
          name: 'Clean Minimal',
          category: 'Minimal',
          description: 'Barely-there makeup for a polished, effortless finish',
          applicableFaceShapes: {},
          warmLipColor: const Color(0xFFD7B8A0), // nude beige
          coolLipColor: const Color(0xFFE8C0C0), // nude pink
          warmBlushColor: const Color(0xFFFFE0CC), // barely-there warm
          coolBlushColor: const Color(0xFFFCE4EC), // barely-there cool
          tutorialSteps: [
            const TutorialStep(
              id: 'mc_step1',
              title: 'Nude Lip',
              instruction: 'Apply nude liner first, then fill with balm or tint',
              targetRegion: TargetRegion.lips,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFD7B8A0), opacity: 0.35),
              order: 1,
            ),
            const TutorialStep(
              id: 'mc_step2',
              title: 'Barely-There Blush',
              instruction: 'Dust the faintest touch of blush for a healthy glow',
              targetRegion: TargetRegion.leftCheek,
              overlayStyle: OverlayStyle(
                  color: Color(0xFFFFE0CC), opacity: 0.2),
              order: 2,
            ),
          ],
          weight: 1,
        ),
      ];

  void reset() {
    _recommendations = [];
    _selectedProfile = null;
    _isLoading = false;
    notifyListeners();
  }
}

class _WeightedProfile {
  final int weight;
  final MakeupProfile profile;
  const _WeightedProfile({required this.weight, required this.profile});
}
