import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:meet_beauty/services/camera/camera_service.dart';
import 'package:meet_beauty/services/facemesh/face_mesh_service.dart';
import 'package:meet_beauty/shared/models/face_feature_result.dart';
import 'package:meet_beauty/shared/models/face_point.dart';

class AnalysisController extends ChangeNotifier {
  final CameraService _cameraService;
  final FaceMeshService _faceMeshService;

  bool _isAnalyzing = false;
  bool _isAnalysisComplete = false;
  FaceFeatureResult? _featureResult;
  String? _errorMessage;
  List<FacePoint>? _currentLandmarks;

  AnalysisController(this._cameraService, this._faceMeshService);

  // Getters
  bool get isCameraInitialized => _cameraService.isInitialized;
  bool get isAnalyzing => _isAnalyzing;
  bool get isAnalysisComplete => _isAnalysisComplete;
  FaceFeatureResult? get featureResult => _featureResult;
  String? get errorMessage => _errorMessage;
  CameraStatus get cameraStatus => _cameraService.status;
  String? get cameraErrorMessage => _cameraService.errorMessage;
  CameraController? get cameraController => _cameraService.controller;
  List<FacePoint>? get currentLandmarks => _currentLandmarks;

  Future<void> startAnalysis() async {
    _errorMessage = null;
    notifyListeners();

    // Initialize camera
    await _cameraService.initialize();

    if (!_cameraService.isInitialized) {
      _errorMessage = _cameraService.errorMessage ?? 'Camera initialization failed';
      notifyListeners();
      return;
    }

    notifyListeners();

    // Start face detection stream
    _startFaceDetection();
  }

  void _startFaceDetection() {
    final camera = _cameraService.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameraService.cameras.first,
    );

    _cameraService.startImageStream((image) async {
      if (_isAnalyzing) return;

      final landmarks = await _faceMeshService.processCameraImage(image, camera);
      if (landmarks != null && landmarks.isNotEmpty) {
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
      final result = _faceMeshService.analyzeFeatures(_currentLandmarks!);
      if (result != null) {
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
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}
