import 'package:meet_beauty/features/analysis/application/analysis_controller.dart';
import 'package:meet_beauty/services/camera/camera_service.dart';
import 'package:meet_beauty/shared/models/face_feature_result.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';

import 'mock_camera_service.dart';
import 'mock_face_mesh_service.dart';

/// A [AnalysisController] that skips real camera and returns fake results.
///
/// [startAnalysis] immediately publishes a fake [FaceLandmarks] as if a face
/// were detected, unblocking the "Capture & Analyze" button.
/// [completeAnalysis] synchronously sets a fixed [FaceFeatureResult].
class MockAnalysisController extends AnalysisController {
  MockAnalysisController()
      : super(
          cameraService: MockCameraService(),
          faceMeshService: MockFaceMeshService(),
        );

  @override
  Future<void> startAnalysis() async {
    // Simulate: camera ready + face detected immediately.
    // We bypass the real camera init and image stream by directly
    // mutating the accessible state via the parent's protected fields.
    // Since the parent fields are private, we use notifyListeners after
    // updating via the backing mock service.
    //
    // Simplest approach: override the public getters directly.
    _fakeLandmarks = MockFaceMeshService.fakeLandmarks;
    _initialized = true;
    notifyListeners();
  }

  bool _initialized = false;
  FaceLandmarks? _fakeLandmarks;
  FaceFeatureResult? _fakeFeatureResult;
  bool _analysisComplete = false;

  @override
  bool get isCameraInitialized => _initialized;

  @override
  CameraStatus get cameraStatus => _initialized
      ? CameraStatus.ready
      : CameraStatus.uninitialized;

  @override
  FaceLandmarks? get currentLandmarks => _fakeLandmarks;

  @override
  FaceFeatureResult? get featureResult => _fakeFeatureResult;

  @override
  bool get isAnalysisComplete => _analysisComplete;

  @override
  bool get isAnalyzing => false;

  @override
  Future<void> completeAnalysis() async {
    _fakeFeatureResult = MockFaceMeshService.fakeFeatureResult;
    _analysisComplete = true;
    notifyListeners();
  }

  @override
  void reset() {
    _initialized = false;
    _fakeLandmarks = null;
    _fakeFeatureResult = null;
    _analysisComplete = false;
    notifyListeners();
  }

}
