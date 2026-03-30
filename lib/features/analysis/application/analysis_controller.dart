import 'package:flutter/material.dart';
import 'package:meet_beauty/shared/models/face_feature_result.dart';

class AnalysisController extends ChangeNotifier {
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  bool _isAnalysisComplete = false;
  FaceFeatureResult? _featureResult;
  String? _errorMessage;

  bool get isCameraInitialized => _isCameraInitialized;
  bool get isAnalyzing => _isAnalyzing;
  bool get isAnalysisComplete => _isAnalysisComplete;
  FaceFeatureResult? get featureResult => _featureResult;
  String? get errorMessage => _errorMessage;

  Future<void> startAnalysis() async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      // TODO: Initialize camera and face detection
      await Future.delayed(const Duration(seconds: 1));
      _isCameraInitialized = true;
      notifyListeners();

      // TODO: Perform actual face analysis
      await Future.delayed(const Duration(seconds: 2));

      // Mock result for MVP
      _featureResult = const FaceFeatureResult(
        faceShape: FaceShape.oval,
        skinTone: SkinTone.warm,
        lipType: LipType.medium,
        confidenceLevel: ConfidenceLevel.high,
      );
      _isAnalysisComplete = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void reset() {
    _isCameraInitialized = false;
    _isAnalyzing = false;
    _isAnalysisComplete = false;
    _featureResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}
