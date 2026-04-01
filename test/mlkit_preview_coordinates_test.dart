import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:meet_beauty/shared/models/face_point.dart';
import 'package:meet_beauty/shared/utils/mlkit_preview_coordinates.dart';

void main() {
  group('rotatedImageSizeForAnalysis', () {
    test('swaps dimensions for 90 and 270', () {
      const s = Size(1920, 1080);
      expect(
        rotatedImageSizeForAnalysis(s, InputImageRotation.rotation90deg),
        const Size(1080, 1920),
      );
      expect(
        rotatedImageSizeForAnalysis(s, InputImageRotation.rotation0deg),
        s,
      );
    });
  });

  group('mapLandmarkToOverlay', () {
    test('useStretchToFill scales to widget corners', () {
      const image = Size(1920, 1080);
      const widget = Size(400, 600);
      final p = const FacePoint(x: 0, y: 0);
      final o = mapLandmarkToOverlay(
        p,
        imageSize: image,
        widgetSize: widget,
        rotation: InputImageRotation.rotation270deg,
        lens: CameraLensDirection.front,
        useStretchToFill: true,
      );
      expect(o.dx, greaterThanOrEqualTo(0));
      expect(o.dy, greaterThanOrEqualTo(0));
    });
  });

  group('applyBoxFitCoverToPoint', () {
    test('center point stays centered after cover scale', () {
      const portrait = Size(1080, 1920);
      const widget = Size(400, 600);
      final center = Offset(portrait.width / 2, portrait.height / 2);
      final mapped = applyBoxFitCoverToPoint(center, portrait, widget);
      expect(mapped.dx, closeTo(widget.width / 2, 0.5));
      expect(mapped.dy, closeTo(widget.height / 2, 0.5));
    });
  });
}
