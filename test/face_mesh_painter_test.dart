import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meet_beauty/features/analysis/presentation/face_mesh_painter.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';
import 'package:meet_beauty/shared/models/face_point.dart';

void main() {
  group('FaceMeshPainter', () {
    FaceLandmarks buildLandmarks() {
      return FaceLandmarks(
        faceContour: [
          const FacePoint(x: 10, y: 10),
          const FacePoint(x: 90, y: 10),
          const FacePoint(x: 100, y: 50),
          const FacePoint(x: 90, y: 90),
          const FacePoint(x: 10, y: 90),
          const FacePoint(x: 0, y: 50),
        ],
        upperLipTop: [
          const FacePoint(x: 40, y: 60),
          const FacePoint(x: 50, y: 58),
          const FacePoint(x: 60, y: 60),
        ],
        upperLipBottom: [
          const FacePoint(x: 40, y: 63),
          const FacePoint(x: 50, y: 62),
          const FacePoint(x: 60, y: 63),
        ],
        lowerLipTop: [
          const FacePoint(x: 40, y: 63),
          const FacePoint(x: 50, y: 64),
          const FacePoint(x: 60, y: 63),
        ],
        lowerLipBottom: [
          const FacePoint(x: 40, y: 66),
          const FacePoint(x: 50, y: 67),
          const FacePoint(x: 60, y: 66),
        ],
        leftEyeContour: [
          const FacePoint(x: 30, y: 35),
          const FacePoint(x: 35, y: 32),
          const FacePoint(x: 40, y: 35),
          const FacePoint(x: 35, y: 37),
        ],
        rightEyeContour: [
          const FacePoint(x: 60, y: 35),
          const FacePoint(x: 65, y: 32),
          const FacePoint(x: 70, y: 35),
          const FacePoint(x: 65, y: 37),
        ],
        leftEyebrowTop: [
          const FacePoint(x: 25, y: 28),
          const FacePoint(x: 30, y: 26),
          const FacePoint(x: 38, y: 27),
        ],
        leftEyebrowBottom: [
          const FacePoint(x: 25, y: 30),
          const FacePoint(x: 30, y: 29),
          const FacePoint(x: 38, y: 30),
        ],
        rightEyebrowTop: [
          const FacePoint(x: 62, y: 27),
          const FacePoint(x: 70, y: 26),
          const FacePoint(x: 75, y: 28),
        ],
        rightEyebrowBottom: [
          const FacePoint(x: 62, y: 30),
          const FacePoint(x: 70, y: 29),
          const FacePoint(x: 75, y: 30),
        ],
        noseBridge: [
          const FacePoint(x: 50, y: 35),
          const FacePoint(x: 50, y: 45),
          const FacePoint(x: 50, y: 55),
        ],
        noseBottom: [
          const FacePoint(x: 42, y: 55),
          const FacePoint(x: 50, y: 57),
          const FacePoint(x: 58, y: 55),
        ],
        noseBase: const FacePoint(x: 50, y: 55),
        leftEye: const FacePoint(x: 35, y: 35),
        rightEye: const FacePoint(x: 65, y: 35),
        bottomMouth: const FacePoint(x: 50, y: 67),
        leftMouth: const FacePoint(x: 40, y: 63),
        rightMouth: const FacePoint(x: 60, y: 63),
        boundingBox: const Rect.fromLTWH(0, 0, 100, 100),
      );
    }

    ui.Picture paintToPicture(FaceMeshPainter painter, Size size) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      return recorder.endRecording();
    }

    test('paints without error when landmarks are provided', () {
      final painter = FaceMeshPainter(buildLandmarks());
      final picture = paintToPicture(painter, const Size(200, 300));
      expect(picture, isNotNull);
    });

    test('paints without error when landmarks are null', () {
      final painter = FaceMeshPainter(null);
      final picture = paintToPicture(painter, const Size(200, 300));
      expect(picture, isNotNull);
    });

    test('shouldRepaint returns true when landmarks change', () {
      final painterA = FaceMeshPainter(buildLandmarks());
      final painterB = FaceMeshPainter(buildLandmarks());
      expect(painterA.shouldRepaint(painterB), isTrue);
    });

    test('shouldRepaint returns false when same reference', () {
      final landmarks = buildLandmarks();
      final painterA = FaceMeshPainter(landmarks);
      final painterB = FaceMeshPainter(landmarks);
      expect(painterA.shouldRepaint(painterB), isFalse);
    });

    test('shouldRepaint returns true when null to non-null', () {
      final painterNull = FaceMeshPainter(null);
      final painterWith = FaceMeshPainter(buildLandmarks());
      expect(painterWith.shouldRepaint(painterNull), isTrue);
    });
  });
}
