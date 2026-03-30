/// Face shape classification
enum FaceShape {
  round,
  long,
  oval,
  square,
  heart,
  unknown,
}

/// Skin tone classification
enum SkinTone {
  cool,
  warm,
  neutral,
  unknown,
}

/// Lip type classification
enum LipType {
  thin,
  medium,
  full,
  unknown,
}

/// Confidence level for feature detection
enum ConfidenceLevel {
  low,
  medium,
  high,
}

/// Result of facial feature analysis
class FaceFeatureResult {
  final FaceShape faceShape;
  final SkinTone skinTone;
  final LipType lipType;
  final ConfidenceLevel confidenceLevel;
  final Map<String, double> ratios;

  const FaceFeatureResult({
    this.faceShape = FaceShape.unknown,
    this.skinTone = SkinTone.unknown,
    this.lipType = LipType.unknown,
    this.confidenceLevel = ConfidenceLevel.low,
    this.ratios = const {},
  });

  factory FaceFeatureResult.fromMap(Map<String, dynamic> map) {
    return FaceFeatureResult(
      faceShape: FaceShape.values.firstWhere(
        (e) => e.name == map['faceShape'],
        orElse: () => FaceShape.unknown,
      ),
      skinTone: SkinTone.values.firstWhere(
        (e) => e.name == map['skinTone'],
        orElse: () => SkinTone.unknown,
      ),
      lipType: LipType.values.firstWhere(
        (e) => e.name == map['lipType'],
        orElse: () => LipType.unknown,
      ),
      confidenceLevel: ConfidenceLevel.values.firstWhere(
        (e) => e.name == map['confidenceLevel'],
        orElse: () => ConfidenceLevel.low,
      ),
      ratios: Map<String, double>.from(map['ratios'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'faceShape': faceShape.name,
      'skinTone': skinTone.name,
      'lipType': lipType.name,
      'confidenceLevel': confidenceLevel.name,
      'ratios': ratios,
    };
  }

  @override
  String toString() =>
      'FaceFeatureResult(faceShape: $faceShape, skinTone: $skinTone, lipType: $lipType, confidenceLevel: $confidenceLevel)';
}
