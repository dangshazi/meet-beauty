import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:meet_beauty/shared/config/app_config.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';
import 'package:meet_beauty/shared/models/face_point.dart';
import 'package:meet_beauty/shared/utils/mlkit_preview_coordinates.dart';

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

  // ── Face detection statistics (used by scoring) ────────────────────────────

  int _totalFramesProcessed = 0;
  int _faceDetectedFrames = 0;

  /// Ratio of frames where a face was detected vs total processed frames.
  ///
  /// Returns `0.0` when no frames have been processed in this session (strict:
  /// do not inflate the tutorial score before any ML Kit work ran).
  double get faceDetectionRate =>
      _totalFramesProcessed == 0
          ? 0.0
          : _faceDetectedFrames / _totalFramesProcessed;

  // ── Public getters ────────────────────────────────────────────────────────

  TrackingState get state => _state;
  bool get isTracking => _state == TrackingState.tracking;
  bool get isFaceDetected => _landmarks != null;
  FaceLandmarks? get landmarks => _landmarks;
  String? get errorMessage => _errorMessage;

  /// Expose the underlying [CameraController] so [CameraPreview] can use it.
  CameraController? get cameraController => _cameraService.controller;

  /// Lens used for tracking (same resolution as [startTracking] / frame pipeline).
  CameraLensDirection get cameraLensDirection {
    if (_cameraService.cameras.isEmpty) {
      return CameraLensDirection.front;
    }
    return _cameraService.cameras
        .firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameraService.cameras.first,
        )
        .lensDirection;
  }

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
      // Fresh stats for each tutorial / camera session (per-round scoring).
      _totalFramesProcessed = 0;
      _faceDetectedFrames = 0;

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
  ///
  /// Note: [faceDetectionRate] remains readable after stop so that
  /// [ScoringController] can read this session's rate; counters reset on the
  /// next successful [startTracking].
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

    final ctrl = _cameraService.controller;
    final deviceOrientation =
        ctrl?.value.deviceOrientation ?? DeviceOrientation.portraitUp;

    final inputImage = _faceMeshService.convertCameraImage(
      image,
      camera,
      deviceOrientation: deviceOrientation,
    );
    if (inputImage == null) return;

    final detected = await _faceMeshService.detectFace(inputImage);
    _totalFramesProcessed++;

    if (detected == null) {
      if (_landmarks != null) {
        _landmarks = null;
        notifyListeners();
      }
      return;
    }

    _faceDetectedFrames++;

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
  /// Same pipeline as [AnalysisController] (official ML Kit translator + cover).
  FaceLandmarks _transformLandmarks(
    FaceLandmarks raw,
    Size imageSize,
    CameraDescription camera,
  ) {
    final widgetSize = _previewWidgetSize;
    if (widgetSize == null) return raw;

    final ctrl = _cameraService.controller;
    final deviceOrientation =
        ctrl?.value.deviceOrientation ?? DeviceOrientation.portraitUp;
    final rotation = inputImageRotationForCamera(camera, deviceOrientation);

    final preview = ctrl?.value.previewSize;
    final useStretchToFill = preview == null ||
        preview.width <= 0 ||
        preview.height <= 0;

    Offset transform(FacePoint p) => mapLandmarkToOverlay(
          p,
          imageSize: imageSize,
          widgetSize: widgetSize,
          rotation: rotation,
          lens: camera.lensDirection,
          useStretchToFill: useStretchToFill,
        );

    Rect transformRect(Rect r) {
      final tl = transform(FacePoint(x: r.left, y: r.top));
      final br = transform(FacePoint(x: r.right, y: r.bottom));
      return Rect.fromPoints(tl, br);
    }

    List<FacePoint> tx(List<FacePoint> pts) =>
        pts.map((p) => _toFacePoint(transform(p))).toList();
    FacePoint? txPt(FacePoint? p) =>
        p != null ? _toFacePoint(transform(p)) : null;

    return FaceLandmarks(
      faceContour: tx(raw.faceContour),
      upperLipTop: tx(raw.upperLipTop),
      upperLipBottom: tx(raw.upperLipBottom),
      lowerLipTop: tx(raw.lowerLipTop),
      lowerLipBottom: tx(raw.lowerLipBottom),
      leftEyebrowTop: tx(raw.leftEyebrowTop),
      leftEyebrowBottom: tx(raw.leftEyebrowBottom),
      rightEyebrowTop: tx(raw.rightEyebrowTop),
      rightEyebrowBottom: tx(raw.rightEyebrowBottom),
      leftEyeContour: tx(raw.leftEyeContour),
      rightEyeContour: tx(raw.rightEyeContour),
      noseBridge: tx(raw.noseBridge),
      noseBottom: tx(raw.noseBottom),
      leftCheekContour: tx(raw.leftCheekContour),
      rightCheekContour: tx(raw.rightCheekContour),
      noseBase: txPt(raw.noseBase),
      leftEye: txPt(raw.leftEye),
      rightEye: txPt(raw.rightEye),
      bottomMouth: txPt(raw.bottomMouth),
      leftMouth: txPt(raw.leftMouth),
      rightMouth: txPt(raw.rightMouth),
      leftEar: txPt(raw.leftEar),
      rightEar: txPt(raw.rightEar),
      leftCheekLandmark: txPt(raw.leftCheekLandmark),
      rightCheekLandmark: txPt(raw.rightCheekLandmark),
      boundingBox: transformRect(raw.boundingBox),
      headAngleY: raw.headAngleY,
      headAngleZ: raw.headAngleZ,
    );
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
