import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:meet_beauty/shared/models/face_point.dart';

/// Maps [CameraDescription.sensorOrientation] to [InputImageRotation] (iOS path).
InputImageRotation sensorOrientationToInputRotation(int sensorOrientation) {
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

/// Android + iOS rotation for ML Kit [InputImageMetadata], matching
/// [google_mlkit_flutter example](https://github.com/flutter-ml/google_ml_kit_flutter).
InputImageRotation inputImageRotationForCamera(
  CameraDescription camera,
  DeviceOrientation deviceOrientation,
) {
  if (Platform.isIOS) {
    return sensorOrientationToInputRotation(camera.sensorOrientation);
  }
  final orientDeg = _deviceOrientationToDegrees(deviceOrientation);
  final sensor = camera.sensorOrientation;
  final int compensation;
  if (camera.lensDirection == CameraLensDirection.front) {
    compensation = (sensor + orientDeg) % 360;
  } else {
    compensation = (sensor - orientDeg + 360) % 360;
  }
  return _degreesToInputRotation(compensation);
}

int _deviceOrientationToDegrees(DeviceOrientation orientation) {
  switch (orientation) {
    case DeviceOrientation.portraitUp:
      return 0;
    case DeviceOrientation.landscapeLeft:
      return 90;
    case DeviceOrientation.portraitDown:
      return 180;
    case DeviceOrientation.landscapeRight:
      return 270;
  }
}

InputImageRotation _degreesToInputRotation(int degrees) {
  switch (degrees % 360) {
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

/// Maps one ML Kit landmark to canvas coordinates (same logic as official
/// `coordinates_translator.dart`). Mirroring for front camera is included
/// where the official translator does it — do **not** mirror again afterward.
Offset translateMlKitPointToCanvas(
  FacePoint p,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection lens,
) {
  final x = p.x;
  final y = p.y;

  if (Platform.isAndroid) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return Offset(
          x * canvasSize.width / imageSize.height,
          y * canvasSize.height / imageSize.width,
        );
      case InputImageRotation.rotation270deg:
        return Offset(
          canvasSize.width - x * canvasSize.width / imageSize.height,
          y * canvasSize.height / imageSize.width,
        );
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        if (lens == CameraLensDirection.back) {
          return Offset(
            x * canvasSize.width / imageSize.width,
            y * canvasSize.height / imageSize.height,
          );
        }
        return Offset(
          canvasSize.width - x * canvasSize.width / imageSize.width,
          y * canvasSize.height / imageSize.height,
        );
    }
  }

  // iOS
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return Offset(
        x * canvasSize.width / imageSize.width,
        y * canvasSize.height / imageSize.height,
      );
    case InputImageRotation.rotation270deg:
      return Offset(
        canvasSize.width - x * canvasSize.width / imageSize.width,
        y * canvasSize.height / imageSize.height,
      );
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      if (lens == CameraLensDirection.back) {
        return Offset(
          x * canvasSize.width / imageSize.width,
          y * canvasSize.height / imageSize.height,
        );
      }
      return Offset(
        canvasSize.width - x * canvasSize.width / imageSize.width,
        y * canvasSize.height / imageSize.height,
      );
  }
}

/// Converts a point in portrait-oriented preview pixel space to overlay
/// coordinates when the preview uses [BoxFit.cover] inside [widgetSize].
Offset applyBoxFitCoverToPoint(
  Offset pointInPortraitPreview,
  Size portraitPreviewSize,
  Size widgetSize,
) {
  final scale = math.max(
    widgetSize.width / portraitPreviewSize.width,
    widgetSize.height / portraitPreviewSize.height,
  );
  final dx = (portraitPreviewSize.width * scale - widgetSize.width) / 2;
  final dy = (portraitPreviewSize.height * scale - widgetSize.height) / 2;
  return Offset(
    pointInPortraitPreview.dx * scale - dx,
    pointInPortraitPreview.dy * scale - dy,
  );
}
