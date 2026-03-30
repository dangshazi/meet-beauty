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

  /// A minimal [FaceLandmarks] object with plausible coordinates (400×600 image).
  static FaceLandmarks get fakeLandmarks => FaceLandmarks(
        faceContour: _oval,
        upperLipTop: _lipTop,
        upperLipBottom: _lipTop,
        lowerLipTop: _lipBottom,
        lowerLipBottom: _lipBottom,
        noseBase: const FacePoint(x: 200, y: 340),
        leftEye: const FacePoint(x: 160, y: 260),
        rightEye: const FacePoint(x: 240, y: 260),
        boundingBox: const Rect.fromLTWH(100, 100, 200, 300),
        headAngleY: 0,
        headAngleZ: 0,
      );

  static const List<FacePoint> _oval = [
    FacePoint(x: 100, y: 200), FacePoint(x: 150, y: 150),
    FacePoint(x: 200, y: 140), FacePoint(x: 250, y: 150),
    FacePoint(x: 300, y: 200), FacePoint(x: 300, y: 300),
    FacePoint(x: 200, y: 400), FacePoint(x: 100, y: 300),
  ];

  static const List<FacePoint> _lipTop = [
    FacePoint(x: 170, y: 370), FacePoint(x: 190, y: 365),
    FacePoint(x: 200, y: 363), FacePoint(x: 210, y: 365),
    FacePoint(x: 230, y: 370),
  ];

  static const List<FacePoint> _lipBottom = [
    FacePoint(x: 170, y: 390), FacePoint(x: 190, y: 395),
    FacePoint(x: 200, y: 396), FacePoint(x: 210, y: 395),
    FacePoint(x: 230, y: 390),
  ];

  /// Pre-built feature result used by [analyzeFeatures].
  static const FaceFeatureResult fakeFeatureResult = FaceFeatureResult(
    faceShape: FaceShape.oval,
    skinTone: SkinTone.warm,
    lipType: LipType.medium,
    confidenceLevel: ConfidenceLevel.high,
  );

  @override
  InputImage? convertCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) =>
      null; // Not needed — no real image stream in tests.

  @override
  Future<FaceLandmarks?> detectFace(InputImage image) async {
    return simulateFaceDetected ? fakeLandmarks : null;
  }

  @override
  FaceFeatureResult? analyzeFeatures(FaceLandmarks landmarks) =>
      fakeFeatureResult;

  @override
  void dispose() {
    // ML Kit detector never initialised, nothing to close.
  }
}
