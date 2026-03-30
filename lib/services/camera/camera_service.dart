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
  CameraStatus _status = CameraStatus.uninitialized;
  String? _errorMessage;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  List<CameraDescription> get cameras => _cameras;
  CameraStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _status = CameraStatus.permissionPermanentlyDenied;
      _errorMessage = 'Camera permission permanently denied. Please enable in Settings.';
      return false;
    } else {
      _status = CameraStatus.permissionDenied;
      _errorMessage = 'Camera permission denied';
      return false;
    }
  }

  Future<void> initialize() async {
    try {
      // Check and request permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _status = CameraStatus.error;
        _errorMessage = 'No cameras available';
        return;
      }

      // Find front camera
      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      debugPrint('CameraService: Found ${_cameras.length} cameras');
      debugPrint('CameraService: Using ${frontCamera.name} (${frontCamera.lensDirection})');

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      debugPrint('CameraService: Initializing controller...');
      await _controller!.initialize();
      debugPrint('CameraService: Controller initialized successfully');
      _status = CameraStatus.ready;
      _errorMessage = null;
    } catch (e, stackTrace) {
      _status = CameraStatus.error;
      _errorMessage = e.toString();
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
    _status = CameraStatus.uninitialized;
    _errorMessage = null;
  }
}
