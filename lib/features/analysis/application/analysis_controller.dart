import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:meet_beauty/services/camera/camera_service.dart';
import 'package:meet_beauty/services/facemesh/face_mesh_service.dart';
import 'package:meet_beauty/shared/models/face_feature_result.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';

class AnalysisController extends ChangeNotifier {
  final CameraService _cameraService;
  final FaceMeshService _faceMeshService;

  AnalysisController({
    CameraService? cameraService,
    FaceMeshService? faceMeshService,
  })  : _cameraService = cameraService ?? CameraService(),
        _faceMeshService = faceMeshService ?? FaceMeshService();

  bool _isAnalyzing = false;
  bool _isAnalysisComplete = false;
  FaceFeatureResult? _featureResult;
  String? _errorMessage;
  FaceLandmarks? _currentLandmarks;

  // Stores the most recent raw frame so skin-tone analysis can sample pixels
  CameraImage? _lastCameraImage;
  CameraDescription? _frontCamera;

  // Getters
  bool get isCameraInitialized => _cameraService.isInitialized;
  bool get isAnalyzing => _isAnalyzing;
  bool get isAnalysisComplete => _isAnalysisComplete;
  FaceFeatureResult? get featureResult => _featureResult;
  String? get errorMessage => _errorMessage;
  CameraStatus get cameraStatus => _cameraService.status;
  String? get cameraErrorMessage => _cameraService.errorMessage;
  CameraController? get cameraController => _cameraService.controller;
  FaceLandmarks? get currentLandmarks => _currentLandmarks;

  Future<void> startAnalysis() async {
    _errorMessage = null;
    notifyListeners();

    await _cameraService.initialize();

    if (!_cameraService.isInitialized) {
      _errorMessage =
          _cameraService.errorMessage ?? 'Camera initialization failed';
      notifyListeners();
      return;
    }

    notifyListeners();
    _startFaceDetection();
  }

  void _startFaceDetection() {
    _frontCamera = _cameraService.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameraService.cameras.first,
    );

    _cameraService.startImageStream((image) async {
      if (_isAnalyzing) return;

      _lastCameraImage = image;

      final inputImage =
          _faceMeshService.convertCameraImage(image, _frontCamera!);
      if (inputImage == null) return;

      final landmarks = await _faceMeshService.detectFace(inputImage);
      if (landmarks != null) {
        _currentLandmarks = landmarks;
        notifyListeners();
      }
    });
  }

  Future<void> completeAnalysis() async {
    if (_currentLandmarks == null) return;

    _isAnalyzing = true;
    notifyListeners();

    try {
      var result = _faceMeshService.analyzeFeatures(_currentLandmarks!);
      if (result != null) {
        // Enrich with skin-tone analysis when a camera frame is available
        if (_lastCameraImage != null && _frontCamera != null) {
          final skinTone = _faceMeshService.analyzeSkinTone(
            _lastCameraImage!,
            _currentLandmarks!,
            _frontCamera!,
          );
          result = FaceFeatureResult(
            faceShape: result.faceShape,
            skinTone: skinTone,
            lipType: result.lipType,
            confidenceLevel: result.confidenceLevel,
            ratios: result.ratios,
          );
        }
        _featureResult = result;
        _isAnalysisComplete = true;
      }
    } finally {
      _isAnalyzing = false;
      _cameraService.stopImageStream();
      notifyListeners();
    }
  }

  void reset() {
    _cameraService.stopImageStream();
    _isAnalyzing = false;
    _isAnalysisComplete = false;
    _featureResult = null;
    _errorMessage = null;
    _currentLandmarks = null;
    _lastCameraImage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _faceMeshService.dispose();
    super.dispose();
  }
}
