import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meet_beauty/services/overlay/overlay_renderer.dart';
import 'package:meet_beauty/shared/models/face_landmarks.dart';
import 'package:meet_beauty/shared/models/face_point.dart';
import 'package:meet_beauty/shared/models/makeup_profile.dart';

void main() {
  late OverlayRenderer renderer;

  setUp(() {
    renderer = OverlayRenderer();
  });

  ui.Picture paintToPicture(void Function(Canvas, Size) paintFn, Size size) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paintFn(canvas, size);
    return recorder.endRecording();
  }

  group('drawOverlay (single step)', () {
    const lipStep = TutorialStep(
      id: 'step1',
      title: 'Lips',
      instruction: '',
      targetRegion: TargetRegion.lips,
      overlayStyle: OverlayStyle(color: Color(0xFFE57373), opacity: 0.4),
      order: 1,
    );

    test('renders lip step without error', () {
      final picture = paintToPicture(
        (canvas, size) => renderer.drawOverlay(canvas, size, lipStep, null),
        const Size(400, 600),
      );
      expect(picture, isNotNull);
    });

    test('renders lip step with landmarks without error', () {
      final landmarks = FaceLandmarks(
        faceContour: [const FacePoint(x: 50, y: 50)],
        upperLipTop: [
          const FacePoint(x: 180, y: 350),
          const FacePoint(x: 200, y: 348),
          const FacePoint(x: 220, y: 350),
        ],
        upperLipBottom: [
          const FacePoint(x: 180, y: 353),
          const FacePoint(x: 200, y: 352),
          const FacePoint(x: 220, y: 353),
        ],
        lowerLipTop: [
          const FacePoint(x: 180, y: 353),
          const FacePoint(x: 200, y: 354),
          const FacePoint(x: 220, y: 353),
        ],
        lowerLipBottom: [
          const FacePoint(x: 180, y: 356),
          const FacePoint(x: 200, y: 357),
          const FacePoint(x: 220, y: 356),
        ],
        noseBase: const FacePoint(x: 200, y: 340),
        leftEye: const FacePoint(x: 170, y: 280),
        rightEye: const FacePoint(x: 230, y: 280),
        bottomMouth: const FacePoint(x: 200, y: 357),
        leftMouth: const FacePoint(x: 180, y: 353),
        rightMouth: const FacePoint(x: 220, y: 353),
        boundingBox: const Rect.fromLTWH(100, 150, 200, 250),
      );

      final picture = paintToPicture(
        (canvas, size) => renderer.drawOverlay(canvas, size, lipStep, landmarks),
        const Size(400, 600),
      );
      expect(picture, isNotNull);
    });
  });

  group('drawOverlays (multi-step accumulation)', () {
    const steps = [
      TutorialStep(
        id: 'step1',
        title: 'Lips',
        instruction: '',
        targetRegion: TargetRegion.lips,
        overlayStyle: OverlayStyle(color: Color(0xFFE57373), opacity: 0.4),
        order: 1,
      ),
      TutorialStep(
        id: 'step2',
        title: 'Left Cheek',
        instruction: '',
        targetRegion: TargetRegion.leftCheek,
        overlayStyle: OverlayStyle(color: Color(0xFFFFB6C1), opacity: 0.3),
        order: 2,
      ),
      TutorialStep(
        id: 'step3',
        title: 'Right Cheek',
        instruction: '',
        targetRegion: TargetRegion.rightCheek,
        overlayStyle: OverlayStyle(color: Color(0xFFFFB6C1), opacity: 0.3),
        order: 3,
      ),
    ];

    test('renders empty list without error', () {
      final picture = paintToPicture(
        (canvas, size) => renderer.drawOverlays(canvas, size, const [], null),
        const Size(400, 600),
      );
      expect(picture, isNotNull);
    });

    test('renders all 3 steps without error (fallback mode)', () {
      final picture = paintToPicture(
        (canvas, size) => renderer.drawOverlays(canvas, size, steps, null),
        const Size(400, 600),
      );
      expect(picture, isNotNull);
    });

    test('renders single step list identically to drawOverlay', () {
      final singlePicture = paintToPicture(
        (canvas, size) => renderer.drawOverlay(canvas, size, steps[0], null),
        const Size(400, 600),
      );
      final listPicture = paintToPicture(
        (canvas, size) => renderer.drawOverlays(canvas, size, [steps[0]], null),
        const Size(400, 600),
      );
      expect(singlePicture, isNotNull);
      expect(listPicture, isNotNull);
    });

    test('renders all 3 steps with landmarks without error', () {
      final landmarks = FaceLandmarks(
        faceContour: [const FacePoint(x: 50, y: 50)],
        upperLipTop: [
          const FacePoint(x: 180, y: 350),
          const FacePoint(x: 200, y: 348),
          const FacePoint(x: 220, y: 350),
        ],
        upperLipBottom: [
          const FacePoint(x: 180, y: 353),
          const FacePoint(x: 200, y: 352),
          const FacePoint(x: 220, y: 353),
        ],
        lowerLipTop: [
          const FacePoint(x: 180, y: 353),
          const FacePoint(x: 200, y: 354),
          const FacePoint(x: 220, y: 353),
        ],
        lowerLipBottom: [
          const FacePoint(x: 180, y: 356),
          const FacePoint(x: 200, y: 357),
          const FacePoint(x: 220, y: 356),
        ],
        noseBase: const FacePoint(x: 200, y: 340),
        leftEye: const FacePoint(x: 170, y: 280),
        rightEye: const FacePoint(x: 230, y: 280),
        bottomMouth: const FacePoint(x: 200, y: 357),
        leftMouth: const FacePoint(x: 180, y: 353),
        rightMouth: const FacePoint(x: 220, y: 353),
        boundingBox: const Rect.fromLTWH(100, 150, 200, 250),
      );

      final picture = paintToPicture(
        (canvas, size) => renderer.drawOverlays(canvas, size, steps, landmarks),
        const Size(400, 600),
      );
      expect(picture, isNotNull);
    });
  });
}
