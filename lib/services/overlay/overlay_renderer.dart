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

  /// Draw overlays for multiple [steps] onto [canvas] / [size].
  ///
  /// Each step's overlay is drawn sequentially so effects accumulate.
  void drawOverlays(
    Canvas canvas,
    Size size,
    List<TutorialStep> steps,
    FaceLandmarks? landmarks,
  ) {
    for (final step in steps) {
      drawOverlay(canvas, size, step, landmarks);
    }
  }

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

    switch (step.targetRegion) {
      case TargetRegion.lips:
        if (style == null) return;
        _drawLip(canvas, size, style, landmarks);
        break;
      case TargetRegion.leftCheek:
        if (style == null) return;
        _drawCheek(canvas, size, style, landmarks, isLeft: true);
        break;
      case TargetRegion.rightCheek:
        if (style == null) return;
        _drawCheek(canvas, size, style, landmarks, isLeft: false);
        break;
      case TargetRegion.eyebrows:
        _drawEyebrows(canvas, size, style, landmarks);
        break;
      case TargetRegion.leftEye:
        _drawEyeShadow(canvas, size, style, landmarks, isLeft: true);
        break;
      case TargetRegion.rightEye:
        _drawEyeShadow(canvas, size, style, landmarks, isLeft: false);
        break;
      case TargetRegion.forehead:
        _drawForehead(canvas, size, style, landmarks);
        break;
      case TargetRegion.nose:
        _drawNoseContour(canvas, size, style, landmarks);
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
    // Soft feathered edge for natural lip look
    final paint = Paint()
      ..color = style.color.withValues(alpha: style.opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);

    if (landmarks != null && landmarks.hasLipData) {
      // Draw upper lip and lower lip as separate polygons so the mouth
      // interior is never filled when the mouth is open.
      final upperPath = _buildSingleLipPath(
        landmarks.upperLipTop,
        landmarks.upperLipBottom,
      );
      final lowerPath = _buildSingleLipPath(
        landmarks.lowerLipBottom,
        landmarks.lowerLipTop,
      );

      if (upperPath != null && lowerPath != null) {
        canvas.drawPath(upperPath, paint);
        canvas.drawPath(lowerPath, paint);

        if (style.showBorder) {
          final borderPaint = Paint()
            ..color = (style.borderColor ?? style.color)
                .withValues(alpha: (style.opacity + 0.3).clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.borderWidth ?? 1.5;
          canvas.drawPath(upperPath, borderPaint);
          canvas.drawPath(lowerPath, borderPaint);
        }
        return;
      }

      // If split paths fail, fall back to full outer polygon
      final path = _buildLipPath(
        landmarks.upperLipTop,
        landmarks.lowerLipBottom,
      );
      if (path != null) {
        canvas.drawPath(path, paint);

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

  /// Build a single lip polygon from outer + inner contour.
  ///
  /// Walks [outer] left→right, then [inner] right→left to close.
  Path? _buildSingleLipPath(
    List<FacePoint> outer,
    List<FacePoint> inner,
  ) {
    if (outer.length < 3 || inner.length < 3) return null;

    final path = Path();
    path.moveTo(outer.first.x, outer.first.y);
    for (final p in outer.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    for (final p in inner.reversed) {
      path.lineTo(p.x, p.y);
    }
    path.close();
    return path;
  }

  /// Build a full outer lip polygon (fallback when split paths unavailable).
  Path? _buildLipPath(
    List<FacePoint> upperOuter,
    List<FacePoint> lowerOuter,
  ) {
    if (upperOuter.length < 3 || lowerOuter.length < 3) return null;

    final path = Path();
    path.moveTo(upperOuter.first.x, upperOuter.first.y);
    for (final p in upperOuter.skip(1)) {
      path.lineTo(p.x, p.y);
    }
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
  /// Strategy (in priority order):
  ///   1. ML Kit cheek landmark (most accurate — directly on apple of cheek)
  ///   2. Midpoint of eye + mouth corner, shifted outward & downward
  ///   3. Bounding box quadrant fallback
  Offset? _cheekCenter(
    FaceLandmarks landmarks,
    Size size, {
    required bool isLeft,
  }) {
    // 1. Best: use ML Kit's dedicated cheek landmark
    final cheekAnchor =
        isLeft ? landmarks.leftCheekAnchor : landmarks.rightCheekAnchor;
    if (cheekAnchor != null) {
      // Shift slightly outward for blush spread
      final outward = isLeft
          ? -landmarks.boundingBox.width * 0.04
          : landmarks.boundingBox.width * 0.04;
      return Offset(cheekAnchor.x + outward, cheekAnchor.y);
    }

    // 2. Midpoint of eye + mouth corner, with generous outward offset
    final eye = isLeft ? landmarks.leftEye : landmarks.rightEye;
    final mouth = isLeft ? landmarks.leftMouth : landmarks.rightMouth;
    if (eye != null && mouth != null) {
      final mid = Offset(
        (eye.x + mouth.x) / 2,
        (eye.y + mouth.y) / 2,
      );
      final outward = isLeft
          ? -landmarks.boundingBox.width * 0.15
          : landmarks.boundingBox.width * 0.15;
      return mid.translate(outward, landmarks.boundingBox.height * 0.08);
    }

    // 3. Fallback: bounding box quadrant
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

  // ── Eyebrow overlay ──────────────────────────────────────────────────────

  static const _kDefaultHighlightColor = Color(0xFFB0BEC5);
  static const _kDefaultHighlightOpacity = 0.35;

  void _drawEyebrows(
    Canvas canvas,
    Size size,
    OverlayStyle? style,
    FaceLandmarks? landmarks,
  ) {
    final color = style?.color ?? _kDefaultHighlightColor;
    final opacity = style?.opacity ?? _kDefaultHighlightOpacity;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);

    if (landmarks != null && landmarks.hasEyebrowData) {
      _drawEyebrowContour(canvas, landmarks.leftEyebrowTop,
          landmarks.leftEyebrowBottom, paint);
      _drawEyebrowContour(canvas, landmarks.rightEyebrowTop,
          landmarks.rightEyebrowBottom, paint);
      return;
    }

    // Fallback
    _drawFallbackEyebrows(canvas, size, paint);
  }

  void _drawEyebrowContour(
    Canvas canvas,
    List<FacePoint> top,
    List<FacePoint> bottom,
    Paint paint,
  ) {
    if (top.length < 2 || bottom.length < 2) return;
    final path = Path();
    path.moveTo(top.first.x, top.first.y);
    for (final p in top.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    for (final p in bottom.reversed) {
      path.lineTo(p.x, p.y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawFallbackEyebrows(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Left eyebrow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.16, cy - size.height * 0.12),
        width: size.width * 0.18,
        height: size.height * 0.025,
      ),
      paint,
    );
    // Right eyebrow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + size.width * 0.16, cy - size.height * 0.12),
        width: size.width * 0.18,
        height: size.height * 0.025,
      ),
      paint,
    );
  }

  // ── Eye shadow overlay ──────────────────────────────────────────────────

  void _drawEyeShadow(
    Canvas canvas,
    Size size,
    OverlayStyle? style,
    FaceLandmarks? landmarks, {
    required bool isLeft,
  }) {
    final color = style?.color ?? _kDefaultHighlightColor;
    final opacity = style?.opacity ?? _kDefaultHighlightOpacity;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);

    if (landmarks != null && landmarks.hasEyeContourData) {
      final contour =
          isLeft ? landmarks.leftEyeContour : landmarks.rightEyeContour;
      if (contour.length >= 4) {
        // Draw a blurred region covering the eyelid area (above eye contour).
        final bbox = _contourBoundingBox(contour);
        final lidRect = Rect.fromLTRB(
          bbox.left - bbox.width * 0.08,
          bbox.top - bbox.height * 0.6,
          bbox.right + bbox.width * 0.08,
          bbox.top + bbox.height * 0.3,
        );
        canvas.drawOval(lidRect, paint);
        return;
      }
    }

    _drawFallbackEyeShadow(canvas, size, paint, isLeft: isLeft);
  }

  void _drawFallbackEyeShadow(
    Canvas canvas,
    Size size,
    Paint paint, {
    required bool isLeft,
  }) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final xOffset = isLeft ? -size.width * 0.16 : size.width * 0.16;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + xOffset, cy - size.height * 0.06),
        width: size.width * 0.14,
        height: size.height * 0.04,
      ),
      paint,
    );
  }

  // ── Forehead / contour overlay ──────────────────────────────────────────

  void _drawForehead(
    Canvas canvas,
    Size size,
    OverlayStyle? style,
    FaceLandmarks? landmarks,
  ) {
    final color = style?.color ?? const Color(0xFF8D6E63);
    final opacity = style?.opacity ?? 0.25;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 14);

    if (landmarks != null && !landmarks.boundingBox.isEmpty) {
      final bbox = landmarks.boundingBox;
      // Forehead region: top of bounding box, above the eyebrows
      final foreheadRect = Rect.fromLTRB(
        bbox.left + bbox.width * 0.1,
        bbox.top,
        bbox.right - bbox.width * 0.1,
        bbox.top + bbox.height * 0.25,
      );
      canvas.drawOval(foreheadRect, paint);

      // Jawline contour strips on both sides
      final jawPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12);

      // Left jawline
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bbox.left + bbox.width * 0.12,
              bbox.bottom - bbox.height * 0.15),
          width: bbox.width * 0.15,
          height: bbox.height * 0.2,
        ),
        jawPaint,
      );
      // Right jawline
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bbox.right - bbox.width * 0.12,
              bbox.bottom - bbox.height * 0.15),
          width: bbox.width * 0.15,
          height: bbox.height * 0.2,
        ),
        jawPaint,
      );
      return;
    }

    _drawFallbackForehead(canvas, size, paint);
  }

  void _drawFallbackForehead(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - size.height * 0.16),
        width: size.width * 0.4,
        height: size.height * 0.08,
      ),
      paint,
    );
  }

  // ── Nose contour overlay ────────────────────────────────────────────────

  void _drawNoseContour(
    Canvas canvas,
    Size size,
    OverlayStyle? style,
    FaceLandmarks? landmarks,
  ) {
    final color = style?.color ?? const Color(0xFF8D6E63);
    final opacity = style?.opacity ?? 0.25;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

    if (landmarks != null && landmarks.hasNoseData) {
      if (landmarks.noseBridge.length >= 2) {
        final path = Path();
        path.moveTo(
            landmarks.noseBridge.first.x, landmarks.noseBridge.first.y);
        for (final p in landmarks.noseBridge.skip(1)) {
          path.lineTo(p.x, p.y);
        }
        canvas.drawPath(path, paint);
      }
      if (landmarks.noseBottom.length >= 2) {
        final path = Path();
        path.moveTo(
            landmarks.noseBottom.first.x, landmarks.noseBottom.first.y);
        for (final p in landmarks.noseBottom.skip(1)) {
          path.lineTo(p.x, p.y);
        }
        canvas.drawPath(path, paint);
      }
      return;
    }

    _drawFallbackNose(canvas, size, paint);
  }

  void _drawFallbackNose(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.06),
      Offset(cx, cy + size.height * 0.04),
      paint,
    );
  }

  // ── Utility ─────────────────────────────────────────────────────────────

  Rect _contourBoundingBox(List<FacePoint> contour) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in contour) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  // Kept to satisfy any existing callers that still use the old API.
  @Deprecated('Use drawOverlay instead')
  List<Offset>? calculateLipPolygon(List<FacePoint> landmarks) => null;

  @Deprecated('Use drawOverlay instead')
  Offset? calculateCheekCenter(List<FacePoint> landmarks, bool isLeft) => null;

  // Suppress "unused import" for dart:math
  // ignore: unused_element
  double _noop() => math.pi;
}
