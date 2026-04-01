import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meet_beauty/shared/utils/mlkit_preview_coordinates.dart';

void main() {
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
