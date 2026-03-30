import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:meet_beauty/shared/models/face_point.dart';
import 'package:meet_beauty/shared/models/face_feature_result.dart';

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
          ),
        );

  Future<List<FacePoint>?> detectFace(InputImage image) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final faces = await _detector.processImage(image);
      if (faces.isEmpty) return null;

      // Get the first face (most prominent)
      final face = faces.first;

      // Extract landmarks
      final landmarks = <FacePoint>[];

      // Face contour
      final faceContour = face.contours[FaceContourType.face];
      if (faceContour != null) {
        for (final point in faceContour.points) {
          landmarks.add(FacePoint(
            x: point.x.toDouble(),
            y: point.y.toDouble(),
          ));
        }
      }

      // Lip contour
      final upperLipTop = face.contours[FaceContourType.upperLipTop];
      final lowerLipBottom = face.contours[FaceContourType.lowerLipBottom];
      if (upperLipTop != null && lowerLipBottom != null) {
        for (final point in upperLipTop.points) {
          landmarks.add(FacePoint(x: point.x.toDouble(), y: point.y.toDouble()));
        }
        for (final point in lowerLipBottom.points) {
          landmarks.add(FacePoint(x: point.x.toDouble(), y: point.y.toDouble()));
        }
      }

      return landmarks;
    } catch (e) {
      debugPrint('Face detection error: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  FaceFeatureResult? analyzeFeatures(List<FacePoint> landmarks) {
    if (landmarks.isEmpty) return null;

    // MVP: Simple rule-based feature analysis
    // In a real implementation, this would use proper geometric calculations

    // Calculate face dimensions
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final point in landmarks) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }

    final width = maxX - minX;
    final height = maxY - minY;
    final aspectRatio = height / width;

    // Determine face shape based on aspect ratio
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
      skinTone: SkinTone.unknown, // Would need color analysis
      lipType: LipType.medium, // Would need lip measurement
      confidenceLevel: ConfidenceLevel.medium,
      ratios: {'aspectRatio': aspectRatio},
    );
  }

  void dispose() {
    _detector.close();
  }
}
