import 'package:flutter/material.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';
import 'package:meet_beauty/shared/models/face_point.dart';

/// Paints real-time face mesh (contours + landmark dots) onto the camera
/// preview so users can see that face detection is actively running.
class FaceMeshPainter extends CustomPainter {
  FaceMeshPainter(this.landmarks);

  final FaceLandmarks? landmarks;

  // ── Paint presets ──────────────────────────────────────────────────────────

  static final _contourPaint = Paint()
    ..color = const Color(0xFF76FF03) // light green
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  static final _lipPaint = Paint()
    ..color = const Color(0xFFFF4081) // pink accent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  static final _eyePaint = Paint()
    ..color = const Color(0xFF00E5FF) // cyan accent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  static final _landmarkPaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..style = PaintingStyle.fill;

  // ── Paint ──────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final lm = landmarks;
    if (lm == null) return;

    // Face oval (closed)
    _drawContourLine(canvas, lm.faceContour, _contourPaint, close: true);

    // Eyebrows
    _drawContourLine(canvas, lm.leftEyebrowTop, _contourPaint);
    _drawContourLine(canvas, lm.leftEyebrowBottom, _contourPaint);
    _drawContourLine(canvas, lm.rightEyebrowTop, _contourPaint);
    _drawContourLine(canvas, lm.rightEyebrowBottom, _contourPaint);

    // Eyes (closed polygons)
    _drawContourLine(canvas, lm.leftEyeContour, _eyePaint, close: true);
    _drawContourLine(canvas, lm.rightEyeContour, _eyePaint, close: true);

    // Nose
    _drawContourLine(canvas, lm.noseBridge, _contourPaint);
    _drawContourLine(canvas, lm.noseBottom, _contourPaint);

    // Lips
    _drawContourLine(canvas, lm.upperLipTop, _lipPaint);
    _drawContourLine(canvas, lm.upperLipBottom, _lipPaint);
    _drawContourLine(canvas, lm.lowerLipTop, _lipPaint);
    _drawContourLine(canvas, lm.lowerLipBottom, _lipPaint);

    // Named landmark dots
    for (final point in [
      lm.noseBase,
      lm.leftEye,
      lm.rightEye,
      lm.bottomMouth,
      lm.leftMouth,
      lm.rightMouth,
      lm.leftEar,
      lm.rightEar,
      lm.leftCheekLandmark,
      lm.rightCheekLandmark,
    ]) {
      if (point != null) {
        canvas.drawCircle(Offset(point.x, point.y), 3, _landmarkPaint);
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _drawContourLine(
    Canvas canvas,
    List<FacePoint> points,
    Paint paint, {
    bool close = false,
  }) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.x, points.first.y);
    for (final p in points.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    if (close) path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FaceMeshPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks;
  }
}
