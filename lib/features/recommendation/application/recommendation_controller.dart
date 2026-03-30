import 'package:flutter/material.dart';
import 'package:meet_beauty/shared/models/face_feature_result.dart';
import 'package:meet_beauty/shared/models/makeup_profile.dart';

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

    // MVP: Rule-based recommendations
    _recommendations = _getDefaultRecommendations(features);

    // Select first recommendation by default
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

  List<MakeupProfile> _getDefaultRecommendations(FaceFeatureResult features) {
    // MVP: Simple rule-based recommendations
    final recommendations = <MakeupProfile>[];

    // Add recommendations based on face shape
    if (features.faceShape == FaceShape.round) {
      recommendations.add(const MakeupProfile(
        id: 'contour_round',
        name: 'Sculpt & Define',
        category: 'Contouring',
        description: 'Enhance your natural bone structure with subtle contouring',
        recommendationReasons: [
          'Great for round face shapes',
          'Creates definition',
          'Natural-looking results',
        ],
        tutorialSteps: [
          TutorialStep(
            id: 'contour1',
            title: 'Apply Contour',
            instruction: 'Apply contour along your jawline and temples',
            targetRegion: TargetRegion.forehead,
            order: 1,
          ),
        ],
      ));
    }

    // Always include a natural daily look
    recommendations.add(const MakeupProfile(
      id: 'natural_daily',
      name: 'Natural Daily Look',
      category: 'Daily',
      description: 'A fresh, natural look perfect for everyday',
      lipColor: Color(0xFFE57373),
      blushColor: Color(0xFFFFB6C1),
      recommendationReasons: [
        'Perfect for everyday wear',
        'Enhances your natural features',
        'Quick and easy application',
      ],
      tutorialSteps: [
        TutorialStep(
          id: 'step1',
          title: 'Apply Lip Color',
          instruction: 'Start from the center of your lips and work outward',
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
          instruction: 'Smile and apply blush to the apples of your cheeks',
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
          instruction: 'Apply the same technique to your right cheek',
          targetRegion: TargetRegion.rightCheek,
          overlayStyle: OverlayStyle(
            color: Color(0xFFFFB6C1),
            opacity: 0.3,
          ),
          order: 3,
        ),
      ],
    ));

    return recommendations;
  }

  void reset() {
    _recommendations = [];
    _selectedProfile = null;
    _isLoading = false;
    notifyListeners();
  }
}
