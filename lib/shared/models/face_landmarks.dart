import 'package:flutter/material.dart';
import 'face_point.dart';

/// Structured face landmarks extracted from ML Kit FaceDetector.
///
/// Contours (15 types, all now extracted):
///   face, leftEyebrowTop/Bottom, rightEyebrowTop/Bottom,
///   leftEye/rightEye (contour polygons), upperLipTop/Bottom,
///   lowerLipTop/Bottom, noseBridge, noseBottom, leftCheek, rightCheek
///
/// Landmarks (up to 10 types, all now extracted):
///   noseBase, leftEye, rightEye, bottomMouth, leftMouth, rightMouth,
///   leftEar, rightEar, leftCheek, rightCheek
class FaceLandmarks {
  // ── Existing lip contours ──────────────────────────────────────────────────

  /// Face oval contour points (~36 pts), used for face shape analysis
  final List<FacePoint> faceContour;

  /// Upper lip outer edge points (~11 pts), top boundary of lip polygon
  final List<FacePoint> upperLipTop;

  /// Upper lip inner edge points (~9 pts)
  final List<FacePoint> upperLipBottom;

  /// Lower lip inner edge points (~9 pts)
  final List<FacePoint> lowerLipTop;

  /// Lower lip outer edge points (~9 pts), bottom boundary of lip polygon
  final List<FacePoint> lowerLipBottom;

  // ── Eyebrow contours (new) ─────────────────────────────────────────────────

  /// Top outline of the left eyebrow
  final List<FacePoint> leftEyebrowTop;

  /// Bottom outline of the left eyebrow
  final List<FacePoint> leftEyebrowBottom;

  /// Top outline of the right eyebrow
  final List<FacePoint> rightEyebrowTop;

  /// Bottom outline of the right eyebrow
  final List<FacePoint> rightEyebrowBottom;

  // ── Eye contours (new) ────────────────────────────────────────────────────

  /// Outline polygon of the left eye
  final List<FacePoint> leftEyeContour;

  /// Outline polygon of the right eye
  final List<FacePoint> rightEyeContour;

  // ── Nose contours (new) ───────────────────────────────────────────────────

  /// Outline of the nose bridge
  final List<FacePoint> noseBridge;

  /// Outline of the nose bottom / nostrils
  final List<FacePoint> noseBottom;

  // ── Cheek center contour points (new) ─────────────────────────────────────

  /// Center point(s) of the left cheek contour — used for blush anchor and
  /// skin-tone pixel sampling
  final List<FacePoint> leftCheekContour;

  /// Center point(s) of the right cheek contour
  final List<FacePoint> rightCheekContour;

  // ── Named landmarks ───────────────────────────────────────────────────────

  /// Nose base landmark, anchor point for cheek center calculation
  final FacePoint? noseBase;

  /// Left eye center landmark
  final FacePoint? leftEye;

  /// Right eye center landmark
  final FacePoint? rightEye;

  /// Bottom of the mouth (chin-side lip centre)
  final FacePoint? bottomMouth;

  /// Left mouth corner landmark
  final FacePoint? leftMouth;

  /// Right mouth corner landmark
  final FacePoint? rightMouth;

  /// Left ear tragion landmark
  final FacePoint? leftEar;

  /// Right ear tragion landmark
  final FacePoint? rightEar;

  /// Left cheek centre landmark (distinct from contour)
  final FacePoint? leftCheekLandmark;

  /// Right cheek centre landmark (distinct from contour)
  final FacePoint? rightCheekLandmark;

  // ── Metadata ──────────────────────────────────────────────────────────────

  /// Bounding box of detected face in image coordinates
  final Rect boundingBox;

  /// Head yaw angle in degrees; large values indicate side-facing
  final double? headAngleY;

  /// Head roll angle in degrees
  final double? headAngleZ;

  const FaceLandmarks({
    required this.faceContour,
    required this.upperLipTop,
    required this.upperLipBottom,
    required this.lowerLipTop,
    required this.lowerLipBottom,
    this.leftEyebrowTop = const [],
    this.leftEyebrowBottom = const [],
    this.rightEyebrowTop = const [],
    this.rightEyebrowBottom = const [],
    this.leftEyeContour = const [],
    this.rightEyeContour = const [],
    this.noseBridge = const [],
    this.noseBottom = const [],
    this.leftCheekContour = const [],
    this.rightCheekContour = const [],
    this.noseBase,
    this.leftEye,
    this.rightEye,
    this.bottomMouth,
    this.leftMouth,
    this.rightMouth,
    this.leftEar,
    this.rightEar,
    this.leftCheekLandmark,
    this.rightCheekLandmark,
    required this.boundingBox,
    this.headAngleY,
    this.headAngleZ,
  });

  // ── Helper getters ────────────────────────────────────────────────────────

  /// Whether this landmarks object has enough data to render a lip overlay
  bool get hasLipData =>
      upperLipTop.length >= 3 && lowerLipBottom.length >= 3;

  /// Whether this landmarks object has enough data to render cheek overlays
  bool get hasCheekData =>
      (noseBase != null || leftEye != null || rightEye != null) &&
      faceContour.length >= 6;

  /// Whether eyebrow contour data is available for brow styling overlays
  bool get hasEyebrowData =>
      leftEyebrowTop.length >= 2 && rightEyebrowTop.length >= 2;

  /// Whether eye contour data is available
  bool get hasEyeContourData =>
      leftEyeContour.length >= 4 && rightEyeContour.length >= 4;

  /// Whether nose contour data is available for nose proportion analysis
  bool get hasNoseData => noseBridge.isNotEmpty || noseBottom.isNotEmpty;

  /// Whether mouth corner landmarks are available for lip-width calculation
  bool get hasMouthCorners => leftMouth != null && rightMouth != null;

  /// Whether the face is significantly turned sideways (|yaw| > 25 degrees)
  bool get isSideFacing =>
      headAngleY != null && headAngleY!.abs() > 25.0;

  /// Convenience: left cheek anchor — landmark takes priority over contour
  FacePoint? get leftCheekAnchor =>
      leftCheekLandmark ??
      (leftCheekContour.isNotEmpty ? leftCheekContour.first : null);

  /// Convenience: right cheek anchor — landmark takes priority over contour
  FacePoint? get rightCheekAnchor =>
      rightCheekLandmark ??
      (rightCheekContour.isNotEmpty ? rightCheekContour.first : null);

  // ── Smoothing ─────────────────────────────────────────────────────────────

  /// Apply exponential moving average smoothing against a previous landmarks snapshot.
  /// [alpha] controls how much weight to give new values (0.0 = all old, 1.0 = all new).
  FaceLandmarks smoothWith(FaceLandmarks? previous, {double alpha = 0.5}) {
    if (previous == null) return this;
    return FaceLandmarks(
      faceContour: _smoothPoints(faceContour, previous.faceContour, alpha),
      upperLipTop: _smoothPoints(upperLipTop, previous.upperLipTop, alpha),
      upperLipBottom:
          _smoothPoints(upperLipBottom, previous.upperLipBottom, alpha),
      lowerLipTop: _smoothPoints(lowerLipTop, previous.lowerLipTop, alpha),
      lowerLipBottom:
          _smoothPoints(lowerLipBottom, previous.lowerLipBottom, alpha),
      leftEyebrowTop:
          _smoothPoints(leftEyebrowTop, previous.leftEyebrowTop, alpha),
      leftEyebrowBottom:
          _smoothPoints(leftEyebrowBottom, previous.leftEyebrowBottom, alpha),
      rightEyebrowTop:
          _smoothPoints(rightEyebrowTop, previous.rightEyebrowTop, alpha),
      rightEyebrowBottom:
          _smoothPoints(rightEyebrowBottom, previous.rightEyebrowBottom, alpha),
      leftEyeContour:
          _smoothPoints(leftEyeContour, previous.leftEyeContour, alpha),
      rightEyeContour:
          _smoothPoints(rightEyeContour, previous.rightEyeContour, alpha),
      noseBridge: _smoothPoints(noseBridge, previous.noseBridge, alpha),
      noseBottom: _smoothPoints(noseBottom, previous.noseBottom, alpha),
      leftCheekContour:
          _smoothPoints(leftCheekContour, previous.leftCheekContour, alpha),
      rightCheekContour:
          _smoothPoints(rightCheekContour, previous.rightCheekContour, alpha),
      noseBase: _smoothPoint(noseBase, previous.noseBase, alpha),
      leftEye: _smoothPoint(leftEye, previous.leftEye, alpha),
      rightEye: _smoothPoint(rightEye, previous.rightEye, alpha),
      bottomMouth: _smoothPoint(bottomMouth, previous.bottomMouth, alpha),
      leftMouth: _smoothPoint(leftMouth, previous.leftMouth, alpha),
      rightMouth: _smoothPoint(rightMouth, previous.rightMouth, alpha),
      leftEar: _smoothPoint(leftEar, previous.leftEar, alpha),
      rightEar: _smoothPoint(rightEar, previous.rightEar, alpha),
      leftCheekLandmark:
          _smoothPoint(leftCheekLandmark, previous.leftCheekLandmark, alpha),
      rightCheekLandmark:
          _smoothPoint(rightCheekLandmark, previous.rightCheekLandmark, alpha),
      boundingBox: Rect.lerp(previous.boundingBox, boundingBox, alpha)!,
      headAngleY: headAngleY,
      headAngleZ: headAngleZ,
    );
  }

  static List<FacePoint> _smoothPoints(
    List<FacePoint> current,
    List<FacePoint> previous,
    double alpha,
  ) {
    if (current.length != previous.length) return current;
    return List.generate(
      current.length,
      (i) => _smoothPoint(current[i], previous[i], alpha)!,
    );
  }

  static FacePoint? _smoothPoint(
    FacePoint? current,
    FacePoint? previous,
    double alpha,
  ) {
    if (current == null) return null;
    if (previous == null) return current;
    return FacePoint(
      x: previous.x + alpha * (current.x - previous.x),
      y: previous.y + alpha * (current.y - previous.y),
    );
  }
}
