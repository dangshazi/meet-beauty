import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:meet_beauty/services/facemesh/face_mesh_service.dart';
import 'package:meet_beauty/shared/models/face_feature_result.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';
import 'package:meet_beauty/shared/models/face_point.dart';

/// A stub [FaceMeshService] that returns pre-built data without ML Kit.
///
/// By default [detectFace] returns null (no face detected).
/// Set [simulateFaceDetected] to true to have it return [fakeLandmarks].
class MockFaceMeshService extends FaceMeshService {
  bool simulateFaceDetected;

  MockFaceMeshService({this.simulateFaceDetected = false});

  /// A complete [FaceLandmarks] object with plausible coordinates (400×600 image).
  ///
  /// Includes all new contour and landmark fields added in the expanded model.
  static FaceLandmarks get fakeLandmarks => FaceLandmarks(
        // ── Face oval (8-point approximation) ─────────────────────────────
        faceContour: _oval,

        // ── Lip contours ──────────────────────────────────────────────────
        upperLipTop: _lipTop,
        upperLipBottom: _lipInnerTop,
        lowerLipTop: _lipInnerBottom,
        lowerLipBottom: _lipBottom,

        // ── Eyebrow contours ──────────────────────────────────────────────
        leftEyebrowTop: _leftEyebrowTop,
        leftEyebrowBottom: _leftEyebrowBottom,
        rightEyebrowTop: _rightEyebrowTop,
        rightEyebrowBottom: _rightEyebrowBottom,

        // ── Eye contours ──────────────────────────────────────────────────
        leftEyeContour: _leftEye,
        rightEyeContour: _rightEye,

        // ── Nose contours ─────────────────────────────────────────────────
        noseBridge: _noseBridge,
        noseBottom: _noseBottom,

        // ── Cheek contours ────────────────────────────────────────────────
        leftCheekContour: [const FacePoint(x: 120, y: 310)],
        rightCheekContour: [const FacePoint(x: 280, y: 310)],

        // ── Named landmarks ───────────────────────────────────────────────
        noseBase: const FacePoint(x: 200, y: 340),
        leftEye: const FacePoint(x: 160, y: 260),
        rightEye: const FacePoint(x: 240, y: 260),
        bottomMouth: const FacePoint(x: 200, y: 400),
        leftMouth: const FacePoint(x: 170, y: 385),
        rightMouth: const FacePoint(x: 230, y: 385),
        leftEar: const FacePoint(x: 90, y: 280),
        rightEar: const FacePoint(x: 310, y: 280),
        leftCheekLandmark: const FacePoint(x: 130, y: 310),
        rightCheekLandmark: const FacePoint(x: 270, y: 310),

        boundingBox: const Rect.fromLTWH(100, 100, 200, 300),
        headAngleY: 0,
        headAngleZ: 0,
      );

  // ── Face oval ─────────────────────────────────────────────────────────────

  static const List<FacePoint> _oval = [
    FacePoint(x: 100, y: 200), FacePoint(x: 130, y: 155),
    FacePoint(x: 160, y: 140), FacePoint(x: 200, y: 135),
    FacePoint(x: 240, y: 140), FacePoint(x: 270, y: 155),
    FacePoint(x: 300, y: 200), FacePoint(x: 305, y: 250),
    FacePoint(x: 295, y: 300), FacePoint(x: 260, y: 370),
    FacePoint(x: 200, y: 400), FacePoint(x: 140, y: 370),
    FacePoint(x: 105, y: 300), FacePoint(x: 97, y: 250),
  ];

  // ── Lip contours ─────────────────────────────────────────────────────────

  static const List<FacePoint> _lipTop = [
    FacePoint(x: 170, y: 370), FacePoint(x: 185, y: 365),
    FacePoint(x: 200, y: 363), FacePoint(x: 215, y: 365),
    FacePoint(x: 230, y: 370),
  ];

  static const List<FacePoint> _lipInnerTop = [
    FacePoint(x: 172, y: 375), FacePoint(x: 186, y: 372),
    FacePoint(x: 200, y: 370), FacePoint(x: 214, y: 372),
    FacePoint(x: 228, y: 375),
  ];

  static const List<FacePoint> _lipInnerBottom = [
    FacePoint(x: 172, y: 382), FacePoint(x: 186, y: 385),
    FacePoint(x: 200, y: 386), FacePoint(x: 214, y: 385),
    FacePoint(x: 228, y: 382),
  ];

  static const List<FacePoint> _lipBottom = [
    FacePoint(x: 170, y: 390), FacePoint(x: 185, y: 395),
    FacePoint(x: 200, y: 396), FacePoint(x: 215, y: 395),
    FacePoint(x: 230, y: 390),
  ];

  // ── Eyebrow contours ─────────────────────────────────────────────────────

  static const List<FacePoint> _leftEyebrowTop = [
    FacePoint(x: 130, y: 232), FacePoint(x: 148, y: 228),
    FacePoint(x: 165, y: 230), FacePoint(x: 180, y: 234),
  ];

  static const List<FacePoint> _leftEyebrowBottom = [
    FacePoint(x: 132, y: 240), FacePoint(x: 150, y: 236),
    FacePoint(x: 167, y: 238), FacePoint(x: 180, y: 242),
  ];

  static const List<FacePoint> _rightEyebrowTop = [
    FacePoint(x: 220, y: 234), FacePoint(x: 235, y: 228),
    FacePoint(x: 252, y: 228), FacePoint(x: 268, y: 234),
  ];

  static const List<FacePoint> _rightEyebrowBottom = [
    FacePoint(x: 220, y: 242), FacePoint(x: 235, y: 236),
    FacePoint(x: 252, y: 236), FacePoint(x: 268, y: 242),
  ];

  // ── Eye contours ─────────────────────────────────────────────────────────

  static const List<FacePoint> _leftEye = [
    FacePoint(x: 140, y: 260), FacePoint(x: 152, y: 254),
    FacePoint(x: 165, y: 254), FacePoint(x: 177, y: 260),
    FacePoint(x: 165, y: 266), FacePoint(x: 152, y: 266),
  ];

  static const List<FacePoint> _rightEye = [
    FacePoint(x: 223, y: 260), FacePoint(x: 235, y: 254),
    FacePoint(x: 248, y: 254), FacePoint(x: 260, y: 260),
    FacePoint(x: 248, y: 266), FacePoint(x: 235, y: 266),
  ];

  // ── Nose contours ─────────────────────────────────────────────────────────

  static const List<FacePoint> _noseBridge = [
    FacePoint(x: 200, y: 280), FacePoint(x: 200, y: 300),
    FacePoint(x: 200, y: 320),
  ];

  static const List<FacePoint> _noseBottom = [
    FacePoint(x: 180, y: 340), FacePoint(x: 190, y: 345),
    FacePoint(x: 200, y: 346), FacePoint(x: 210, y: 345),
    FacePoint(x: 220, y: 340),
  ];

  // ── Pre-built feature result ──────────────────────────────────────────────

  static const FaceFeatureResult fakeFeatureResult = FaceFeatureResult(
    faceShape: FaceShape.oval,
    skinTone: SkinTone.warm,
    lipType: LipType.medium,
    confidenceLevel: ConfidenceLevel.high,
  );

  // ── FaceMeshService overrides ─────────────────────────────────────────────

  @override
  InputImage? convertCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) =>
      null;

  @override
  Future<FaceLandmarks?> detectFace(InputImage image) async =>
      simulateFaceDetected ? fakeLandmarks : null;

  @override
  FaceFeatureResult? analyzeFeatures(FaceLandmarks landmarks) =>
      fakeFeatureResult;

  @override
  SkinTone analyzeSkinTone(
    CameraImage image,
    FaceLandmarks landmarks,
    CameraDescription camera,
  ) =>
      SkinTone.warm;

  @override
  void dispose() {
    // ML Kit detector never initialised, nothing to close.
  }
}
