import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraStatus {
  uninitialized,
  permissionDenied,
  permissionPermanentlyDenied,
  error,
  ready,
}

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  @protected
  CameraStatus cameraStatus = CameraStatus.uninitialized;

  @protected
  String? cameraErrorMessage;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  List<CameraDescription> get cameras => _cameras;
  CameraStatus get status => cameraStatus;
  String? get errorMessage => cameraErrorMessage;

  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      cameraStatus = CameraStatus.permissionPermanentlyDenied;
      cameraErrorMessage =
          'Camera permission permanently denied. Please enable in Settings.';
      return false;
    } else {
      cameraStatus = CameraStatus.permissionDenied;
      cameraErrorMessage = 'Camera permission denied';
      return false;
    }
  }

  Future<void> initialize() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return;

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        cameraStatus = CameraStatus.error;
        cameraErrorMessage = 'No cameras available';
        return;
      }

      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      debugPrint('CameraService: Found ${_cameras.length} cameras');
      debugPrint(
          'CameraService: Using ${frontCamera.name} (${frontCamera.lensDirection})');

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      debugPrint('CameraService: Initializing controller...');
      await _controller!.initialize();
      debugPrint('CameraService: Controller initialized successfully');
      cameraStatus = CameraStatus.ready;
      cameraErrorMessage = null;
    } catch (e, stackTrace) {
      cameraStatus = CameraStatus.error;
      cameraErrorMessage = e.toString();
      debugPrint('Camera initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void startImageStream(Function(CameraImage) onImage) {
    if (_controller == null || !isInitialized) return;
    if (!_controller!.value.isStreamingImages) {
      _controller!.startImageStream((image) => onImage(image));
    }
  }

  void stopImageStream() {
    if (_controller == null || !isInitialized) return;
    if (_controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
  }

  void dispose() {
    stopImageStream();
    _controller?.dispose();
    _controller = null;
    cameraStatus = CameraStatus.uninitialized;
    cameraErrorMessage = null;
  }
}
