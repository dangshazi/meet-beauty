import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:meet_beauty/services/camera/camera_service.dart';
import 'package:meet_beauty/services/facemesh/face_mesh_service.dart';
import 'package:meet_beauty/shared/models/face_feature_result.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';
import 'package:meet_beauty/shared/models/face_point.dart';
import 'package:meet_beauty/shared/utils/mlkit_preview_coordinates.dart';

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

  /// Image-space landmarks from ML Kit (for [analyzeFeatures] / [analyzeSkinTone]).
  FaceLandmarks? _rawLandmarksForAnalysis;

  // Stores the most recent raw frame so skin-tone analysis can sample pixels
  CameraImage? _lastCameraImage;
  CameraDescription? _frontCamera;

  /// Preview widget dimensions — set by the UI layer for coordinate scaling.
  Size? _previewWidgetSize;

  DateTime? _lastFaceMeshDebugLogAt;

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

  /// The lens direction of the camera in use (front/back).
  CameraLensDirection get cameraLensDirection =>
      _frontCamera?.lensDirection ?? CameraLensDirection.front;

  /// Call this from the UI once the preview widget size is known.
  void updatePreviewSize(Size size) {
    _previewWidgetSize = size;
  }

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

      final ctrl = _cameraService.controller;
      final deviceOrientation =
          ctrl?.value.deviceOrientation ?? DeviceOrientation.portraitUp;

      final inputImage = _faceMeshService.convertCameraImage(
        image,
        _frontCamera!,
        deviceOrientation: deviceOrientation,
      );
      if (inputImage == null) return;

      final landmarks = await _faceMeshService.detectFace(inputImage);
      if (landmarks != null) {
        _rawLandmarksForAnalysis = landmarks;
        final imageSize =
            Size(image.width.toDouble(), image.height.toDouble());
        _currentLandmarks =
            _transformLandmarks(landmarks, imageSize, _frontCamera!);
        notifyListeners();
      }
    });
  }

  Future<void> completeAnalysis() async {
    if (_currentLandmarks == null || _rawLandmarksForAnalysis == null) return;

    _isAnalyzing = true;
    notifyListeners();

    try {
      var result =
          _faceMeshService.analyzeFeatures(_rawLandmarksForAnalysis!);
      if (result != null) {
        // Enrich with skin-tone analysis when a camera frame is available
        if (_lastCameraImage != null && _frontCamera != null) {
          final skinTone = _faceMeshService.analyzeSkinTone(
            _lastCameraImage!,
            _rawLandmarksForAnalysis!,
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
    _rawLandmarksForAnalysis = null;
    _lastCameraImage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _faceMeshService.dispose();
    super.dispose();
  }

  // ── Coordinate transform (image-space → widget-space) ─────────────────────

  /// Transform [raw] landmarks from ML Kit image-space to Flutter widget-space.
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

    final rotatedImageSize = rotatedImageSizeForAnalysis(imageSize, rotation);

    if (kDebugMode && raw.faceContour.isNotEmpty) {
      final now = DateTime.now();
      if (_lastFaceMeshDebugLogAt == null ||
          now.difference(_lastFaceMeshDebugLogAt!).inMilliseconds >= 500) {
        _lastFaceMeshDebugLogAt = now;
        final s = raw.faceContour.first;
        debugPrint(
          '[FaceMesh] imageSize=$imageSize rotatedImageSize=$rotatedImageSize '
          'widgetSize=$widgetSize rotation=$rotation lens=${camera.lensDirection} '
          'preview=$preview stretch=$useStretchToFill '
          'sample=(${s.x.toStringAsFixed(1)}, ${s.y.toStringAsFixed(1)})',
        );
      }
    }

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

    return FaceLandmarks(
      faceContour:
          raw.faceContour.map((p) => _toFacePoint(transform(p))).toList(),
      upperLipTop:
          raw.upperLipTop.map((p) => _toFacePoint(transform(p))).toList(),
      upperLipBottom:
          raw.upperLipBottom.map((p) => _toFacePoint(transform(p))).toList(),
      lowerLipTop:
          raw.lowerLipTop.map((p) => _toFacePoint(transform(p))).toList(),
      lowerLipBottom:
          raw.lowerLipBottom.map((p) => _toFacePoint(transform(p))).toList(),
      leftEyebrowTop:
          raw.leftEyebrowTop.map((p) => _toFacePoint(transform(p))).toList(),
      leftEyebrowBottom: raw.leftEyebrowBottom
          .map((p) => _toFacePoint(transform(p)))
          .toList(),
      rightEyebrowTop:
          raw.rightEyebrowTop.map((p) => _toFacePoint(transform(p))).toList(),
      rightEyebrowBottom: raw.rightEyebrowBottom
          .map((p) => _toFacePoint(transform(p)))
          .toList(),
      leftEyeContour:
          raw.leftEyeContour.map((p) => _toFacePoint(transform(p))).toList(),
      rightEyeContour:
          raw.rightEyeContour.map((p) => _toFacePoint(transform(p))).toList(),
      noseBridge:
          raw.noseBridge.map((p) => _toFacePoint(transform(p))).toList(),
      noseBottom:
          raw.noseBottom.map((p) => _toFacePoint(transform(p))).toList(),
      leftCheekContour:
          raw.leftCheekContour.map((p) => _toFacePoint(transform(p))).toList(),
      rightCheekContour: raw.rightCheekContour
          .map((p) => _toFacePoint(transform(p)))
          .toList(),
      noseBase:
          raw.noseBase != null ? _toFacePoint(transform(raw.noseBase!)) : null,
      leftEye:
          raw.leftEye != null ? _toFacePoint(transform(raw.leftEye!)) : null,
      rightEye: raw.rightEye != null
          ? _toFacePoint(transform(raw.rightEye!))
          : null,
      bottomMouth: raw.bottomMouth != null
          ? _toFacePoint(transform(raw.bottomMouth!))
          : null,
      leftMouth: raw.leftMouth != null
          ? _toFacePoint(transform(raw.leftMouth!))
          : null,
      rightMouth: raw.rightMouth != null
          ? _toFacePoint(transform(raw.rightMouth!))
          : null,
      leftEar: raw.leftEar != null
          ? _toFacePoint(transform(raw.leftEar!))
          : null,
      rightEar: raw.rightEar != null
          ? _toFacePoint(transform(raw.rightEar!))
          : null,
      leftCheekLandmark: raw.leftCheekLandmark != null
          ? _toFacePoint(transform(raw.leftCheekLandmark!))
          : null,
      rightCheekLandmark: raw.rightCheekLandmark != null
          ? _toFacePoint(transform(raw.rightCheekLandmark!))
          : null,
      boundingBox: transformRect(raw.boundingBox),
      headAngleY: raw.headAngleY,
      headAngleZ: raw.headAngleZ,
    );
  }

  FacePoint _toFacePoint(Offset o) => FacePoint(x: o.dx, y: o.dy);
}
