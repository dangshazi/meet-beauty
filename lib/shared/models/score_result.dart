/// Result of makeup application scoring
class ScoreResult {
  final int score;
  final int stars;
  final List<String> feedbackTags;
  final String encouragement;
  final String? suggestion;
  final Map<String, dynamic>? details;

  const ScoreResult({
    required this.score,
    required this.stars,
    this.feedbackTags = const [],
    this.encouragement = '',
    this.suggestion,
    this.details,
  });

  factory ScoreResult.fromMap(Map<String, dynamic> map) {
    return ScoreResult(
      score: map['score'] as int,
      stars: map['stars'] as int,
      feedbackTags: List<String>.from(map['feedbackTags'] ?? []),
      encouragement: map['encouragement'] as String? ?? '',
      suggestion: map['suggestion'] as String?,
      details: map['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'stars': stars,
      'feedbackTags': feedbackTags,
      'encouragement': encouragement,
      if (suggestion != null) 'suggestion': suggestion,
      if (details != null) 'details': details,
    };
  }

  @override
  String toString() =>
      'ScoreResult(score: $score, stars: $stars, tags: $feedbackTags)';
}
