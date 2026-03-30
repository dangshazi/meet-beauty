import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:meet_beauty/shared/config/app_config.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';
import 'package:meet_beauty/shared/models/face_point.dart';

import 'camera/camera_service.dart';
import 'facemesh/face_mesh_service.dart';

/// Tracking state reported to the UI.
enum TrackingState {
  idle,
  initializing,
  tracking,
  paused,
  error,
}

/// Orchestrates [CameraService] and [FaceMeshService] into a single
/// [ChangeNotifier] that the UI can observe.
///
/// Responsibilities:
///  - Start / stop / pause camera and ML Kit pipeline
///  - Frame throttle: only process one frame per [AppConfig.analysisIntervalMs]
///  - Coordinate transform: image-space → widget-space (rotation + mirror + scale)
///  - EMA smoothing on landmark positions
class FaceTrackingController extends ChangeNotifier {
  final CameraService _cameraService;
  final FaceMeshService _faceMeshService;

  FaceTrackingController({
    CameraService? cameraService,
    FaceMeshService? faceMeshService,
  })  : _cameraService = cameraService ?? CameraService(),
        _faceMeshService = faceMeshService ?? FaceMeshService();

  TrackingState _state = TrackingState.idle;
  FaceLandmarks? _landmarks;
  String? _errorMessage;

  /// Timestamp of the last frame we actually processed through ML Kit.
  DateTime? _lastProcessedAt;

  /// Preview widget dimensions — set by the UI layer for coordinate scaling.
  Size? _previewWidgetSize;

  // ── Public getters ────────────────────────────────────────────────────────

  TrackingState get state => _state;
  bool get isTracking => _state == TrackingState.tracking;
  bool get isFaceDetected => _landmarks != null;
  FaceLandmarks? get landmarks => _landmarks;
  String? get errorMessage => _errorMessage;

  /// Expose the underlying [CameraController] so [CameraPreview] can use it.
  CameraController? get cameraController => _cameraService.controller;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Initialise the camera and start the detection pipeline.
  Future<void> startTracking() async {
    if (_state == TrackingState.tracking ||
        _state == TrackingState.initializing) {
      return;
    }

    _setState(TrackingState.initializing);
    _errorMessage = null;

    try {
      await _cameraService.initialize();
      _cameraService.startImageStream(_onCameraFrame);
      _setState(TrackingState.tracking);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(TrackingState.error);
      debugPrint('FaceTrackingController: startTracking error: $e');
    }
  }

  /// Pause image processing without releasing the camera (e.g. app goes to background).
  void pauseTracking() {
    if (_state != TrackingState.tracking) return;
    _cameraService.stopImageStream();
    _setState(TrackingState.paused);
  }

  /// Resume after [pauseTracking].
  void resumeTracking() {
    if (_state != TrackingState.paused) return;
    if (_cameraService.isInitialized) {
      _cameraService.startImageStream(_onCameraFrame);
      _setState(TrackingState.tracking);
    }
  }

  /// Fully stop and release all resources.
  void stopTracking() {
    _cameraService.stopImageStream();
    _cameraService.dispose();
    _faceMeshService.dispose();
    _landmarks = null;
    _setState(TrackingState.idle);
  }

  /// Call this from the UI once the preview widget size is known (e.g. in
  /// [LayoutBuilder] or [initState] after the first frame).
  void updatePreviewSize(Size size) {
    _previewWidgetSize = size;
  }

  // ── Frame processing ──────────────────────────────────────────────────────

  void _onCameraFrame(CameraImage image) {
    // Throttle: skip frames that arrive too soon after the last one processed.
    final now = DateTime.now();
    if (_lastProcessedAt != null) {
      final elapsed = now.difference(_lastProcessedAt!).inMilliseconds;
      if (elapsed < AppConfig.analysisIntervalMs) return;
    }
    _lastProcessedAt = now;

    // Schedule async processing without blocking the camera thread.
    _processFrame(image);
  }

  Future<void> _processFrame(CameraImage image) async {
    final camera = _cameraService.cameras.isNotEmpty
        ? _cameraService.cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => _cameraService.cameras.first,
          )
        : null;

    if (camera == null) return;

    final inputImage =
        _faceMeshService.convertCameraImage(image, camera);
    if (inputImage == null) return;

    final detected = await _faceMeshService.detectFace(inputImage);

    if (detected == null) {
      // Face lost
      if (_landmarks != null) {
        _landmarks = null;
        notifyListeners();
      }
      return;
    }

    // Apply coordinate transform then EMA smoothing.
    final imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final transformed = _transformLandmarks(detected, imageSize, camera);
    final smoothed = transformed.smoothWith(_landmarks, alpha: 0.4);

    _landmarks = smoothed;
    notifyListeners();
  }

  // ── Coordinate transform ──────────────────────────────────────────────────

  /// Transform [raw] landmarks from ML Kit image-space to Flutter widget-space.
  ///
  /// ML Kit returns coordinates in the camera image's native frame:
  ///  - For Android: image is often 90° rotated relative to screen
  ///  - For front cameras: image is mirrored on the X axis
  ///
  /// We produce widget-space coordinates so [CustomPainter] can draw directly.
  FaceLandmarks _transformLandmarks(
    FaceLandmarks raw,
    Size imageSize,
    CameraDescription camera,
  ) {
    final widgetSize = _previewWidgetSize;
    if (widgetSize == null) return raw;

    final isFront = camera.lensDirection == CameraLensDirection.front;
    final rotation = _resolveRotation(camera.sensorOrientation);

    Offset transform(FacePoint p) =>
        _imageToWidget(p, imageSize, widgetSize, rotation, isFront);

    Rect transformRect(Rect r) {
      final tl = transform(FacePoint(x: r.left, y: r.top));
      final br = transform(FacePoint(x: r.right, y: r.bottom));
      return Rect.fromPoints(tl, br);
    }

    return FaceLandmarks(
      faceContour: raw.faceContour.map((p) => _toFacePoint(transform(p))).toList(),
      upperLipTop: raw.upperLipTop.map((p) => _toFacePoint(transform(p))).toList(),
      upperLipBottom:
          raw.upperLipBottom.map((p) => _toFacePoint(transform(p))).toList(),
      lowerLipTop:
          raw.lowerLipTop.map((p) => _toFacePoint(transform(p))).toList(),
      lowerLipBottom:
          raw.lowerLipBottom.map((p) => _toFacePoint(transform(p))).toList(),
      noseBase: raw.noseBase != null
          ? _toFacePoint(transform(raw.noseBase!))
          : null,
      leftEye: raw.leftEye != null
          ? _toFacePoint(transform(raw.leftEye!))
          : null,
      rightEye: raw.rightEye != null
          ? _toFacePoint(transform(raw.rightEye!))
          : null,
      boundingBox: transformRect(raw.boundingBox),
      headAngleY: raw.headAngleY,
      headAngleZ: raw.headAngleZ,
    );
  }

  /// Convert a single [FacePoint] from image coordinates to widget coordinates.
  Offset _imageToWidget(
    FacePoint p,
    Size imageSize,
    Size widgetSize,
    InputImageRotation rotation,
    bool isFrontCamera,
  ) {
    double x = p.x;
    double y = p.y;

    // Step 1 – rotate to match screen orientation.
    // After this step, (rotW, rotH) are the effective image dimensions.
    double rotW, rotH;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        // (x, y) in rotated image → (imageH - y, x)
        final tmp = x;
        x = imageSize.height - y;
        y = tmp;
        rotW = imageSize.height;
        rotH = imageSize.width;
        break;
      case InputImageRotation.rotation270deg:
        // (x, y) in rotated image → (y, imageW - x)
        final tmp = y;
        y = imageSize.width - x;
        x = tmp;
        rotW = imageSize.height;
        rotH = imageSize.width;
        break;
      case InputImageRotation.rotation180deg:
        x = imageSize.width - x;
        y = imageSize.height - y;
        rotW = imageSize.width;
        rotH = imageSize.height;
        break;
      default:
        rotW = imageSize.width;
        rotH = imageSize.height;
    }

    // Step 2 – scale to widget size.
    x = x * widgetSize.width / rotW;
    y = y * widgetSize.height / rotH;

    // Step 3 – mirror horizontally for front cameras (selfie view).
    if (isFrontCamera) {
      x = widgetSize.width - x;
    }

    return Offset(x, y);
  }

  InputImageRotation _resolveRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  FacePoint _toFacePoint(Offset o) => FacePoint(x: o.dx, y: o.dy);

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setState(TrackingState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
