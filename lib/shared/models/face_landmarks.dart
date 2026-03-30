import 'package:flutter/material.dart';
import 'face_point.dart';

/// Structured face landmarks extracted from ML Kit FaceDetector
class FaceLandmarks {
  /// Face oval contour points (~36 pts), used for cheek position estimation
  final List<FacePoint> faceContour;

  /// Upper lip outer edge points (~11 pts), top boundary of lip polygon
  final List<FacePoint> upperLipTop;

  /// Upper lip inner edge points (~9 pts)
  final List<FacePoint> upperLipBottom;

  /// Lower lip inner edge points (~9 pts)
  final List<FacePoint> lowerLipTop;

  /// Lower lip outer edge points (~9 pts), bottom boundary of lip polygon
  final List<FacePoint> lowerLipBottom;

  /// Nose base landmark, anchor point for cheek center calculation
  final FacePoint? noseBase;

  /// Left eye center landmark
  final FacePoint? leftEye;

  /// Right eye center landmark
  final FacePoint? rightEye;

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
    this.noseBase,
    this.leftEye,
    this.rightEye,
    required this.boundingBox,
    this.headAngleY,
    this.headAngleZ,
  });

  /// Whether this landmarks object has enough data to render a lip overlay
  bool get hasLipData =>
      upperLipTop.length >= 3 && lowerLipBottom.length >= 3;

  /// Whether this landmarks object has enough data to render cheek overlays
  bool get hasCheekData =>
      (noseBase != null || leftEye != null || rightEye != null) &&
      faceContour.length >= 6;

  /// Whether the face is significantly turned sideways (|yaw| > 25 degrees)
  bool get isSideFacing =>
      headAngleY != null && headAngleY!.abs() > 25.0;

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
      noseBase: _smoothPoint(noseBase, previous.noseBase, alpha),
      leftEye: _smoothPoint(leftEye, previous.leftEye, alpha),
      rightEye: _smoothPoint(rightEye, previous.rightEye, alpha),
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
