/// Represents a single face landmark point detected by Face Mesh
class FacePoint {
  final double x;
  final double y;
  final double? z;

  const FacePoint({
    required this.x,
    required this.y,
    this.z,
  });

  factory FacePoint.fromMap(Map<String, dynamic> map) {
    return FacePoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      z: map['z'] != null ? (map['z'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      if (z != null) 'z': z,
    };
  }

  @override
  String toString() => 'FacePoint(x: $x, y: $y, z: $z)';
}
