import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:meet_beauty/services/camera/camera_service.dart';

/// A no-op [CameraService] for integration tests.
///
/// - [initialize] succeeds immediately without touching real hardware.
/// - [startImageStream] is silent (no frames will arrive).
/// - [isInitialized] returns true after [initialize] is called.
/// - [status] reports [CameraStatus.ready] after [initialize].
class MockCameraService extends CameraService {
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  CameraStatus get status =>
      _initialized ? CameraStatus.ready : cameraStatus;

  @override
  Future<void> initialize() async {
    debugPrint('MockCameraService: initialize() called (no-op)');
    _initialized = true;
    cameraStatus = CameraStatus.ready;
    cameraErrorMessage = null;
  }

  @override
  void startImageStream(Function(CameraImage) onImage) {
    // No real camera — silently ignore.
    debugPrint('MockCameraService: startImageStream() called (no-op)');
  }

  @override
  void stopImageStream() {
    debugPrint('MockCameraService: stopImageStream() called (no-op)');
  }

  @override
  void dispose() {
    _initialized = false;
    debugPrint('MockCameraService: dispose() called (no-op)');
  }
}
