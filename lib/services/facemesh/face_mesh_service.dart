import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Size;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:meet_beauty/shared/models/face_feature_result.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';
import 'package:meet_beauty/shared/models/face_point.dart';

class FaceMeshService {
  final FaceDetector _detector;
  bool _isProcessing = false;

  FaceMeshService()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            enableContours: true,
            enableLandmarks: true,
            enableClassification: true,
            enableTracking: true,
            performanceMode: FaceDetectorMode.accurate,
          ),
        );

  // ── CameraImage -> InputImage conversion ─────────────────────────────────

  /// Convert a raw [CameraImage] frame into an [InputImage] suitable for ML Kit.
  /// Returns null when the image format is unsupported.
  InputImage? convertCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    try {
      final rotation = _sensorToInputRotation(camera.sensorOrientation);

      if (Platform.isAndroid) {
        // Android delivers NV21 (YUV 4:2:0 semi-planar) in a single plane
        final plane = image.planes[0];
        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      } else if (Platform.isIOS) {
        // iOS delivers BGRA8888 in a single plane
        final plane = image.planes[0];
        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      }
      return null;
    } catch (e) {
      debugPrint('FaceMeshService: convertCameraImage error: $e');
      return null;
    }
  }

  /// Map sensor orientation degrees to the nearest [InputImageRotation] value.
  InputImageRotation _sensorToInputRotation(int sensorOrientation) {
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

  // ── Detection ─────────────────────────────────────────────────────────────

  /// Process an [InputImage] and return structured [FaceLandmarks], or null
  /// when no face is detected or another call is already in flight.
  Future<FaceLandmarks?> detectFace(InputImage image) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final faces = await _detector.processImage(image);
      if (faces.isEmpty) return null;

      // Use the face with the largest bounding box (most prominent)
      final face = faces.reduce(
        (a, b) =>
            a.boundingBox.width * a.boundingBox.height >
                    b.boundingBox.width * b.boundingBox.height
                ? a
                : b,
      );

      return _extractLandmarks(face);
    } catch (e) {
      debugPrint('FaceMeshService: detectFace error: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  FaceLandmarks _extractLandmarks(Face face) {
    // Face oval contour
    final faceContour = _extractContour(face, FaceContourType.face);

    // All four lip contour groups
    final upperLipTop =
        _extractContour(face, FaceContourType.upperLipTop);
    final upperLipBottom =
        _extractContour(face, FaceContourType.upperLipBottom);
    final lowerLipTop =
        _extractContour(face, FaceContourType.lowerLipTop);
    final lowerLipBottom =
        _extractContour(face, FaceContourType.lowerLipBottom);

    // Named landmarks
    final noseBase = _extractLandmark(face, FaceLandmarkType.noseBase);
    final leftEye = _extractLandmark(face, FaceLandmarkType.leftEye);
    final rightEye = _extractLandmark(face, FaceLandmarkType.rightEye);

    return FaceLandmarks(
      faceContour: faceContour,
      upperLipTop: upperLipTop,
      upperLipBottom: upperLipBottom,
      lowerLipTop: lowerLipTop,
      lowerLipBottom: lowerLipBottom,
      noseBase: noseBase,
      leftEye: leftEye,
      rightEye: rightEye,
      boundingBox: face.boundingBox,
      headAngleY: face.headEulerAngleY,
      headAngleZ: face.headEulerAngleZ,
    );
  }

  List<FacePoint> _extractContour(Face face, FaceContourType type) {
    final contour = face.contours[type];
    if (contour == null) return [];
    return contour.points
        .map((p) => FacePoint(x: p.x.toDouble(), y: p.y.toDouble()))
        .toList();
  }

  FacePoint? _extractLandmark(Face face, FaceLandmarkType type) {
    final lm = face.landmarks[type];
    if (lm == null) return null;
    return FacePoint(x: lm.position.x.toDouble(), y: lm.position.y.toDouble());
  }

  // ── Feature analysis ─────────────────────────────────────────────────────

  /// Derive high-level face features from structured [FaceLandmarks].
  FaceFeatureResult? analyzeFeatures(FaceLandmarks landmarks) {
    final contour = landmarks.faceContour;
    if (contour.isEmpty) return null;

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final p in contour) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final width = maxX - minX;
    final height = maxY - minY;
    if (width == 0) return null;

    final aspectRatio = height / width;

    FaceShape faceShape;
    if (aspectRatio > 1.4) {
      faceShape = FaceShape.long;
    } else if (aspectRatio < 1.2) {
      faceShape = FaceShape.round;
    } else {
      faceShape = FaceShape.oval;
    }

    return FaceFeatureResult(
      faceShape: faceShape,
      skinTone: SkinTone.unknown,
      lipType: LipType.medium,
      confidenceLevel: ConfidenceLevel.medium,
      ratios: {'aspectRatio': aspectRatio},
    );
  }

  void dispose() {
    _detector.close();
  }
}
