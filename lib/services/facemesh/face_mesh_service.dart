import 'dart:io';
import 'dart:math' as math;

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

  Future<FaceLandmarks?> detectFace(InputImage image) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final faces = await _detector.processImage(image);
      if (faces.isEmpty) return null;

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

  // ── Landmark extraction (all 15 contours + 10 landmarks) ─────────────────

  FaceLandmarks _extractLandmarks(Face face) {
    return FaceLandmarks(
      // ── Face oval ─────────────────────────────────────────────────────────
      faceContour: _extractContour(face, FaceContourType.face),

      // ── Lip contours ──────────────────────────────────────────────────────
      upperLipTop: _extractContour(face, FaceContourType.upperLipTop),
      upperLipBottom: _extractContour(face, FaceContourType.upperLipBottom),
      lowerLipTop: _extractContour(face, FaceContourType.lowerLipTop),
      lowerLipBottom: _extractContour(face, FaceContourType.lowerLipBottom),

      // ── Eyebrow contours ──────────────────────────────────────────────────
      leftEyebrowTop: _extractContour(face, FaceContourType.leftEyebrowTop),
      leftEyebrowBottom:
          _extractContour(face, FaceContourType.leftEyebrowBottom),
      rightEyebrowTop: _extractContour(face, FaceContourType.rightEyebrowTop),
      rightEyebrowBottom:
          _extractContour(face, FaceContourType.rightEyebrowBottom),

      // ── Eye contours ──────────────────────────────────────────────────────
      leftEyeContour: _extractContour(face, FaceContourType.leftEye),
      rightEyeContour: _extractContour(face, FaceContourType.rightEye),

      // ── Nose contours ─────────────────────────────────────────────────────
      noseBridge: _extractContour(face, FaceContourType.noseBridge),
      noseBottom: _extractContour(face, FaceContourType.noseBottom),

      // ── Cheek contours ────────────────────────────────────────────────────
      leftCheekContour: _extractContour(face, FaceContourType.leftCheek),
      rightCheekContour: _extractContour(face, FaceContourType.rightCheek),

      // ── Named landmarks ───────────────────────────────────────────────────
      noseBase: _extractLandmark(face, FaceLandmarkType.noseBase),
      leftEye: _extractLandmark(face, FaceLandmarkType.leftEye),
      rightEye: _extractLandmark(face, FaceLandmarkType.rightEye),
      bottomMouth: _extractLandmark(face, FaceLandmarkType.bottomMouth),
      leftMouth: _extractLandmark(face, FaceLandmarkType.leftMouth),
      rightMouth: _extractLandmark(face, FaceLandmarkType.rightMouth),
      leftEar: _extractLandmark(face, FaceLandmarkType.leftEar),
      rightEar: _extractLandmark(face, FaceLandmarkType.rightEar),
      leftCheekLandmark: _extractLandmark(face, FaceLandmarkType.leftCheek),
      rightCheekLandmark: _extractLandmark(face, FaceLandmarkType.rightCheek),

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
    return FacePoint(
        x: lm.position.x.toDouble(), y: lm.position.y.toDouble());
  }

  // ── Feature analysis ─────────────────────────────────────────────────────

  /// Derive high-level face features from structured [FaceLandmarks].
  ///
  /// Runs synchronously; call after face detection stabilises.
  FaceFeatureResult? analyzeFeatures(FaceLandmarks landmarks) {
    final contour = landmarks.faceContour;
    if (contour.isEmpty) return null;

    // Bounding box metrics
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in contour) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    final faceWidth = maxX - minX;
    final faceHeight = maxY - minY;
    if (faceWidth == 0 || faceHeight == 0) return null;

    final faceRatio = faceHeight / faceWidth;

    // Horizontal width at different vertical zones
    final cheekWidth = _widthAtFraction(contour, minY, faceHeight, 0.45, 0.55);
    final jawWidth = _widthAtFraction(contour, minY, faceHeight, 0.75, 0.90);
    final foreheadWidth =
        _widthAtFraction(contour, minY, faceHeight, 0.05, 0.20);

    final jawRatio =
        (cheekWidth > 0) ? jawWidth / cheekWidth : 1.0;
    final foreheadRatio =
        (cheekWidth > 0) ? foreheadWidth / cheekWidth : 1.0;

    // Jaw angle: angle at the lowest contour point using its two neighbours
    final jawAngle = _computeJawAngle(contour, minY, faceHeight);

    final faceShape = _classifyFaceShape(
      faceRatio: faceRatio,
      jawRatio: jawRatio,
      foreheadRatio: foreheadRatio,
      jawAngle: jawAngle,
    );

    // Lip type analysis
    final lipResult = _analyzeLipType(landmarks, faceHeight);

    final ratios = <String, double>{
      'faceRatio': faceRatio,
      'jawRatio': jawRatio,
      'foreheadRatio': foreheadRatio,
      'jawAngle': jawAngle,
      'cheekWidth': cheekWidth,
      'jawWidth': jawWidth,
      'foreheadWidth': foreheadWidth,
      ...lipResult.ratios,
    };

    final confidence = _computeConfidence(landmarks);

    return FaceFeatureResult(
      faceShape: faceShape,
      skinTone: SkinTone.unknown,
      lipType: lipResult.lipType,
      confidenceLevel: confidence,
      ratios: ratios,
    );
  }

  // ── Face shape helpers ────────────────────────────────────────────────────

  /// Compute the horizontal span of contour points whose y coordinate falls
  /// within [yFracLow, yFracHigh] of the total face height band.
  double _widthAtFraction(
    List<FacePoint> contour,
    double minY,
    double height,
    double yFracLow,
    double yFracHigh,
  ) {
    final yLow = minY + height * yFracLow;
    final yHigh = minY + height * yFracHigh;
    final band = contour.where((p) => p.y >= yLow && p.y <= yHigh).toList();
    if (band.isEmpty) return 0.0;
    final xMin = band.map((p) => p.x).reduce(math.min);
    final xMax = band.map((p) => p.x).reduce(math.max);
    return xMax - xMin;
  }

  /// Estimate the jaw angle (degrees) at the lowest contour vertex.
  /// Uses the 3 bottom-most distinct x-coordinates.
  double _computeJawAngle(
    List<FacePoint> contour,
    double minY,
    double height,
  ) {
    // Take bottom 15% of contour points
    final bottomBand =
        contour.where((p) => p.y >= minY + height * 0.85).toList();
    if (bottomBand.length < 3) return 140.0; // fallback = oval

    // Sort by y (descending), take bottom tip and two flanking points
    bottomBand.sort((a, b) => b.y.compareTo(a.y));
    final tip = bottomBand.first;

    // Leftmost and rightmost among the lower band
    final left = bottomBand.reduce((a, b) => a.x < b.x ? a : b);
    final right = bottomBand.reduce((a, b) => a.x > b.x ? a : b);

    if ((left.x - tip.x).abs() < 1 || (right.x - tip.x).abs() < 1) {
      return 140.0;
    }

    // Angle at `tip` formed by vectors tip->left and tip->right
    final dx1 = left.x - tip.x;
    final dy1 = left.y - tip.y;
    final dx2 = right.x - tip.x;
    final dy2 = right.y - tip.y;
    final dot = dx1 * dx2 + dy1 * dy2;
    final mag = math.sqrt(dx1 * dx1 + dy1 * dy1) *
        math.sqrt(dx2 * dx2 + dy2 * dy2);
    if (mag == 0) return 140.0;
    final cosA = (dot / mag).clamp(-1.0, 1.0);
    return math.acos(cosA) * 180.0 / math.pi;
  }

  FaceShape _classifyFaceShape({
    required double faceRatio,
    required double jawRatio,
    required double foreheadRatio,
    required double jawAngle,
  }) {
    if (faceRatio > 1.45) return FaceShape.long;
    if (foreheadRatio > 1.05 && jawRatio < 0.85) return FaceShape.heart;
    if (faceRatio < 1.25 && jawAngle <= 140) return FaceShape.square;
    if (faceRatio < 1.2 && jawAngle > 140) return FaceShape.round;
    return FaceShape.oval;
  }

  // ── Lip type analysis ─────────────────────────────────────────────────────

  _LipAnalysisResult _analyzeLipType(
      FaceLandmarks landmarks, double faceHeight) {
    final ulTop = landmarks.upperLipTop;
    final ulBottom = landmarks.upperLipBottom;
    final llTop = landmarks.lowerLipTop;
    final llBottom = landmarks.lowerLipBottom;

    if (ulTop.isEmpty || ulBottom.isEmpty || llTop.isEmpty || llBottom.isEmpty) {
      return _LipAnalysisResult(LipType.unknown, const {});
    }

    double meanY(List<FacePoint> pts) =>
        pts.map((p) => p.y).reduce((a, b) => a + b) / pts.length;

    final upperThickness = (meanY(ulBottom) - meanY(ulTop)).abs();
    final lowerThickness = (meanY(llBottom) - meanY(llTop)).abs();
    final totalThickness = upperThickness + lowerThickness;

    final relativeThickness =
        faceHeight > 0 ? totalThickness / faceHeight : 0.0;

    LipType lipType;
    if (relativeThickness < 0.06) {
      lipType = LipType.thin;
    } else if (relativeThickness < 0.09) {
      lipType = LipType.medium;
    } else {
      lipType = LipType.full;
    }

    return _LipAnalysisResult(lipType, {
      'upperLipThickness': upperThickness,
      'lowerLipThickness': lowerThickness,
      'lipThicknessRatio': relativeThickness,
    });
  }

  // ── Skin tone analysis ────────────────────────────────────────────────────

  /// Analyse skin tone from a live [CameraImage] frame using cheek/forehead
  /// pixel sampling in YCbCr colour space.
  ///
  /// Returns [SkinTone.unknown] when there is insufficient data.
  SkinTone analyzeSkinTone(
    CameraImage image,
    FaceLandmarks landmarks,
    CameraDescription camera,
  ) {
    try {
      final samples = _collectSkinSamples(image, landmarks);
      if (samples.isEmpty) return SkinTone.unknown;

      double totalCb = 0, totalCr = 0;
      for (final rgb in samples) {
        final ycbcr = _rgbToYCbCr(rgb[0], rgb[1], rgb[2]);
        totalCb += ycbcr[1];
        totalCr += ycbcr[2];
      }
      final avgCb = totalCb / samples.length;
      final avgCr = totalCr / samples.length;

      const threshold = 5.0;
      if (avgCr > avgCb + threshold) return SkinTone.warm;
      if (avgCb > avgCr + threshold) return SkinTone.cool;
      return SkinTone.neutral;
    } catch (e) {
      debugPrint('FaceMeshService: analyzeSkinTone error: $e');
      return SkinTone.unknown;
    }
  }

  List<List<int>> _collectSkinSamples(
    CameraImage image,
    FaceLandmarks landmarks,
  ) {
    final samples = <List<int>>[];
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final bb = landmarks.boundingBox;

    // Anchor points: left cheek, right cheek, forehead
    final anchorPoints = <FacePoint>[];

    if (landmarks.leftCheekAnchor != null) {
      anchorPoints.add(landmarks.leftCheekAnchor!);
    }
    if (landmarks.rightCheekAnchor != null) {
      anchorPoints.add(landmarks.rightCheekAnchor!);
    }
    // Forehead: top-centre of bounding box (25% down from top)
    anchorPoints.add(FacePoint(
      x: bb.left + bb.width * 0.5,
      y: bb.top + bb.height * 0.25,
    ));

    for (final anchor in anchorPoints) {
      // Clamp to image bounds with a 5-px margin
      final cx = anchor.x.clamp(5.0, imgW - 5.0).round();
      final cy = anchor.y.clamp(5.0, imgH - 5.0).round();

      for (var dy = -2; dy <= 2; dy++) {
        for (var dx = -2; dx <= 2; dx++) {
          final px = cx + dx;
          final py = cy + dy;
          if (px < 0 || py < 0 || px >= image.width || py >= image.height) {
            continue;
          }
          final rgb = _getPixelRgb(image, px, py);
          if (rgb != null) samples.add(rgb);
        }
      }
    }
    return samples;
  }

  /// Extract RGB from a [CameraImage] pixel at (px, py).
  /// Handles BGRA8888 (iOS) and NV21 (Android).
  List<int>? _getPixelRgb(CameraImage image, int px, int py) {
    try {
      if (Platform.isIOS) {
        // BGRA8888: 4 bytes per pixel, single plane
        final plane = image.planes[0];
        final offset = py * plane.bytesPerRow + px * 4;
        if (offset + 3 >= plane.bytes.length) return null;
        final b = plane.bytes[offset];
        final g = plane.bytes[offset + 1];
        final r = plane.bytes[offset + 2];
        return [r, g, b];
      } else {
        // NV21: Y plane + interleaved VU plane
        // Y plane
        final yPlane = image.planes[0];
        final yOffset = py * yPlane.bytesPerRow + px;
        if (yOffset >= yPlane.bytes.length) return null;
        final yVal = yPlane.bytes[yOffset].toDouble();

        // UV plane (NV21 has V before U)
        final uvPlane = image.planes.length > 1 ? image.planes[1] : null;
        if (uvPlane == null) {
          // Fallback: approximate grey pixel
          final grey = yVal.round().clamp(0, 255);
          return [grey, grey, grey];
        }
        final uvRow = py ~/ 2;
        final uvCol = (px ~/ 2) * 2;
        final uvOffset = uvRow * uvPlane.bytesPerRow + uvCol;
        if (uvOffset + 1 >= uvPlane.bytes.length) return null;
        final vVal = uvPlane.bytes[uvOffset].toDouble() - 128;
        final uVal = uvPlane.bytes[uvOffset + 1].toDouble() - 128;

        final r = (yVal + 1.402 * vVal).round().clamp(0, 255);
        final g = (yVal - 0.344136 * uVal - 0.714136 * vVal)
            .round()
            .clamp(0, 255);
        final b = (yVal + 1.772 * uVal).round().clamp(0, 255);
        return [r, g, b];
      }
    } catch (_) {
      return null;
    }
  }

  /// Convert RGB (0–255) to YCbCr.  Returns [Y, Cb, Cr].
  List<double> _rgbToYCbCr(int r, int g, int b) {
    final rd = r.toDouble();
    final gd = g.toDouble();
    final bd = b.toDouble();
    final y = 0.299 * rd + 0.587 * gd + 0.114 * bd;
    final cb = 128 - 0.168736 * rd - 0.331264 * gd + 0.5 * bd;
    final cr = 128 + 0.5 * rd - 0.418688 * gd - 0.081312 * bd;
    return [y, cb, cr];
  }

  // ── Confidence ────────────────────────────────────────────────────────────

  ConfidenceLevel _computeConfidence(FaceLandmarks landmarks) {
    int score = 0;
    if (landmarks.faceContour.length >= 30) score++;
    if (landmarks.hasLipData) score++;
    if (landmarks.hasEyebrowData) score++;
    if (landmarks.noseBase != null) score++;
    if (!landmarks.isSideFacing) score++;

    if (score >= 4) return ConfidenceLevel.high;
    if (score >= 2) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  void dispose() {
    _detector.close();
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _LipAnalysisResult {
  final LipType lipType;
  final Map<String, double> ratios;
  const _LipAnalysisResult(this.lipType, this.ratios);
}
