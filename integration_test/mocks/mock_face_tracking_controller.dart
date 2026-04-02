import 'package:meet_beauty/services/face_tracking_controller.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';

import 'mock_camera_service.dart';
import 'mock_face_mesh_service.dart';

/// A [FaceTrackingController] that skips real camera and ML Kit.
///
/// After [startTracking], the controller immediately enters
/// [TrackingState.tracking].  Set [withFace] to true to also publish a fake
/// [FaceLandmarks] so tests can verify face-detected behaviour.
class MockFaceTrackingController extends FaceTrackingController {
  final bool withFace;

  MockFaceTrackingController({this.withFace = false})
      : super(
          cameraService: MockCameraService(),
          faceMeshService: MockFaceMeshService(),
        );

  @override
  Future<void> startTracking() async {
    // Jump straight to tracking — no camera, no permissions.
    if (withFace) {
      // Publish fake landmarks so the overlay painter has data.
      // We reach into the parent's landmark field via the exposed setter path:
      // call the internal state setter directly.
      _setFakeLandmarks();
    }
    // Use parent's _setState via public method indirection isn't possible,
    // so we notify listeners by calling the internal helper via super's
    // notifyListeners — instead we just override state completely via a
    // lightweight reset trick:
    //
    // Because _state is private in the parent, we expose it via a thin
    // override: call stopTracking first (idle) then re-enter tracking.
    // Actually the cleanest way here is to override the state getter too.
    _tracking = true;
    notifyListeners();
  }

  bool _tracking = false;
  FaceLandmarks? _fakeLandmarks;

  void _setFakeLandmarks() {
    _fakeLandmarks = MockFaceMeshService.fakeLandmarks;
  }

  // Override public API that the UI queries.
  @override
  TrackingState get state =>
      _tracking ? TrackingState.tracking : TrackingState.idle;

  @override
  bool get isTracking => _tracking;

  @override
  FaceLandmarks? get landmarks => _fakeLandmarks;

  @override
  bool get isFaceDetected => _fakeLandmarks != null;

  /// Parent counters stay at 0 because [startTracking] does not run the real
  /// camera stream. Expose a stable rate so [ScoringController] matches
  /// integration-test expectations (face present vs absent).
  @override
  double get faceDetectionRate => withFace ? 1.0 : 0.0;

  @override
  String? get errorMessage => null;

  @override
  void stopTracking() {
    _tracking = false;
    _fakeLandmarks = null;
    notifyListeners();
  }

  @override
  void pauseTracking() {
    _tracking = false;
    notifyListeners();
  }

  @override
  void resumeTracking() {
    _tracking = true;
    notifyListeners();
  }
}
