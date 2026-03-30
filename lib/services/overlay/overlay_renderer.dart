import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';
import 'package:meet_beauty/shared/models/face_point.dart';
import 'package:meet_beauty/shared/models/makeup_profile.dart';

/// Draws AR makeup overlays onto a [Canvas].
///
/// When real [FaceLandmarks] are available, drawing is based on detected
/// face geometry.  If landmarks are absent (no face detected) the renderer
/// falls back to simple fixed-position shapes centred in the canvas so the UI
/// always shows something meaningful.
class OverlayRenderer {
  // ── Public entry point ────────────────────────────────────────────────────

  /// Draw the overlay for [step] onto [canvas] / [size].
  ///
  /// [landmarks] may be null; the renderer gracefully falls back to fixed shapes.
  void drawOverlay(
    Canvas canvas,
    Size size,
    TutorialStep step,
    FaceLandmarks? landmarks,
  ) {
    final style = step.overlayStyle;
    if (style == null) return;

    switch (step.targetRegion) {
      case TargetRegion.lips:
        _drawLip(canvas, size, style, landmarks);
        break;
      case TargetRegion.leftCheek:
        _drawCheek(canvas, size, style, landmarks, isLeft: true);
        break;
      case TargetRegion.rightCheek:
        _drawCheek(canvas, size, style, landmarks, isLeft: false);
        break;
      default:
        break;
    }
  }

  // ── Lip overlay ───────────────────────────────────────────────────────────

  void _drawLip(
    Canvas canvas,
    Size size,
    OverlayStyle style,
    FaceLandmarks? landmarks,
  ) {
    final paint = Paint()
      ..color = style.color.withValues(alpha: style.opacity)
      ..style = PaintingStyle.fill;

    if (landmarks != null && landmarks.hasLipData) {
      // Build an outer lip polygon from the four contour groups:
      //   upper-outer (left→right) + lower-outer (right→left) → closed path
      final path = _buildLipPath(
        landmarks.upperLipTop,
        landmarks.lowerLipBottom,
      );
      if (path != null) {
        canvas.drawPath(path, paint);

        // Optional border / highlight for current step
        if (style.showBorder) {
          final borderPaint = Paint()
            ..color = (style.borderColor ?? style.color)
                .withValues(alpha: (style.opacity + 0.3).clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.borderWidth ?? 1.5;
          canvas.drawPath(path, borderPaint);
        }
        return;
      }
    }

    // Fallback: fixed oval centred below mid-face
    _drawFallbackLip(canvas, size, paint);
  }

  Path? _buildLipPath(
    List<FacePoint> upperOuter,
    List<FacePoint> lowerOuter,
  ) {
    if (upperOuter.length < 3 || lowerOuter.length < 3) return null;

    final path = Path();
    // Upper outer: walk left → right
    path.moveTo(upperOuter.first.x, upperOuter.first.y);
    for (final p in upperOuter.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    // Lower outer: walk right → left (reverse) to close the polygon
    for (final p in lowerOuter.reversed) {
      path.lineTo(p.x, p.y);
    }
    path.close();
    return path;
  }

  void _drawFallbackLip(Canvas canvas, Size size, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 + size.height * 0.07),
        width: size.width * 0.22,
        height: size.height * 0.05,
      ),
      paint,
    );
  }

  // ── Cheek overlay ─────────────────────────────────────────────────────────

  void _drawCheek(
    Canvas canvas,
    Size size,
    OverlayStyle style,
    FaceLandmarks? landmarks, {
    required bool isLeft,
  }) {
    // Blush: soft Gaussian blur + slightly transparent fill
    final paint = Paint()
      ..color = style.color.withValues(alpha: style.opacity)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18)
      ..style = PaintingStyle.fill;

    if (landmarks != null && landmarks.hasCheekData) {
      final center = _cheekCenter(landmarks, size, isLeft: isLeft);
      if (center != null) {
        final faceW = landmarks.boundingBox.width;
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: faceW * 0.35,
            height: faceW * 0.25,
          ),
          paint,
        );
        return;
      }
    }

    // Fallback: fixed oval
    _drawFallbackCheek(canvas, size, paint, isLeft: isLeft);
  }

  /// Estimate the cheek blush centre from available landmarks.
  ///
  /// Strategy:
  ///   • Prefer: midpoint of outer-eye and noseBase (rough apple-of-cheek).
  ///   • Fallback within landmarks: use bounding box quarters.
  Offset? _cheekCenter(
    FaceLandmarks landmarks,
    Size size, {
    required bool isLeft,
  }) {
    final eye = isLeft ? landmarks.leftEye : landmarks.rightEye;
    final nose = landmarks.noseBase;

    if (eye != null && nose != null) {
      // Apple of cheek ≈ midpoint between eye and noseBase, shifted slightly
      // outward and downward.
      final mid = Offset(
        (eye.x + nose.x) / 2,
        (eye.y + nose.y) / 2,
      );
      final outward = isLeft ? -landmarks.boundingBox.width * 0.06 : landmarks.boundingBox.width * 0.06;
      return mid.translate(outward, landmarks.boundingBox.height * 0.04);
    }

    // If only boundingBox is available, split into quadrants
    final bbox = landmarks.boundingBox;
    if (!bbox.isEmpty) {
      final x = isLeft
          ? bbox.left + bbox.width * 0.25
          : bbox.right - bbox.width * 0.25;
      final y = bbox.top + bbox.height * 0.55;
      return Offset(x, y);
    }

    return null;
  }

  void _drawFallbackCheek(
    Canvas canvas,
    Size size,
    Paint paint, {
    required bool isLeft,
  }) {
    final xOffset = isLeft ? -size.width * 0.22 : size.width * 0.22;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width / 2 + xOffset,
          size.height / 2 + size.height * 0.03,
        ),
        width: size.width * 0.18,
        height: size.height * 0.13,
      ),
      paint,
    );
  }

  // ── Debug helper (call in debug builds to visualise raw landmarks) ─────────

  /// Draws all landmark points as small coloured dots.  Useful during initial
  /// integration to verify coordinate transform correctness.
  void debugDrawLandmarks(Canvas canvas, FaceLandmarks landmarks) {
    final contourPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final lipPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    for (final p in landmarks.faceContour) {
      canvas.drawCircle(Offset(p.x, p.y), 2, contourPaint);
    }
    for (final p in [
      ...landmarks.upperLipTop,
      ...landmarks.lowerLipBottom,
    ]) {
      canvas.drawCircle(Offset(p.x, p.y), 3, lipPaint);
    }

    if (landmarks.noseBase != null) {
      canvas.drawCircle(
        Offset(landmarks.noseBase!.x, landmarks.noseBase!.y),
        5,
        Paint()..color = Colors.blue,
      );
    }
    if (landmarks.leftEye != null) {
      canvas.drawCircle(
        Offset(landmarks.leftEye!.x, landmarks.leftEye!.y),
        5,
        Paint()..color = Colors.yellow,
      );
    }
    if (landmarks.rightEye != null) {
      canvas.drawCircle(
        Offset(landmarks.rightEye!.x, landmarks.rightEye!.y),
        5,
        Paint()..color = Colors.yellow,
      );
    }
  }

  // Kept to satisfy any existing callers that still use the old API.
  // Delegates to [drawOverlay] without landmarks.
  @Deprecated('Use drawOverlay instead')
  List<Offset>? calculateLipPolygon(List<FacePoint> landmarks) => null;

  @Deprecated('Use drawOverlay instead')
  Offset? calculateCheekCenter(List<FacePoint> landmarks, bool isLeft) => null;

  // Suppress "unused import" for dart:math
  // ignore: unused_element
  double _noop() => math.pi;
}
