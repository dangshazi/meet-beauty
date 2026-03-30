import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:ui' as ui;

/// Converts CameraImage from camera stream to InputImage for ML Kit
InputImage? convertToInputImage(CameraImage image, CameraDescription camera) {
  final cameraRotation = InputImageRotationValue.fromRawValue(
    camera.sensorOrientation,
  );
  if (cameraRotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) return null;

  final plane = image.planes.first;

  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: ui.Size(image.width.toDouble(), image.height.toDouble()),
      rotation: cameraRotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}
