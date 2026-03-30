import 'package:flutter/material.dart';

/// Target region for makeup application
enum TargetRegion {
  lips,
  leftCheek,
  rightCheek,
  leftEye,
  rightEye,
  eyebrows,
  nose,
  forehead,
}

/// Overlay style configuration
class OverlayStyle {
  final Color color;
  final double opacity;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;

  const OverlayStyle({
    required this.color,
    this.opacity = 0.5,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth,
  });

  factory OverlayStyle.fromMap(Map<String, dynamic> map) {
    return OverlayStyle(
      color: Color(map['color'] as int),
      opacity: (map['opacity'] as num?)?.toDouble() ?? 0.5,
      showBorder: map['showBorder'] as bool? ?? false,
      borderColor:
          map['borderColor'] != null ? Color(map['borderColor'] as int) : null,
      borderWidth: (map['borderWidth'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'color': color.toARGB32(),
      'opacity': opacity,
      'showBorder': showBorder,
      if (borderColor != null) 'borderColor': borderColor!.toARGB32(),
      if (borderWidth != null) 'borderWidth': borderWidth,
    };
  }
}

/// Single step in a makeup tutorial
class TutorialStep {
  final String id;
  final String title;
  final String instruction;
  final TargetRegion targetRegion;
  final OverlayStyle? overlayStyle;
  final int order;
  final Duration? estimatedDuration;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.instruction,
    required this.targetRegion,
    this.overlayStyle,
    required this.order,
    this.estimatedDuration,
  });

  factory TutorialStep.fromMap(Map<String, dynamic> map) {
    return TutorialStep(
      id: map['id'] as String,
      title: map['title'] as String,
      instruction: map['instruction'] as String,
      targetRegion: TargetRegion.values.firstWhere(
        (e) => e.name == map['targetRegion'],
        orElse: () => TargetRegion.lips,
      ),
      overlayStyle: map['overlayStyle'] != null
          ? OverlayStyle.fromMap(map['overlayStyle'])
          : null,
      order: map['order'] as int,
      estimatedDuration: map['estimatedDuration'] != null
          ? Duration(milliseconds: map['estimatedDuration'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'instruction': instruction,
      'targetRegion': targetRegion.name,
      if (overlayStyle != null) 'overlayStyle': overlayStyle!.toMap(),
      'order': order,
      if (estimatedDuration != null)
        'estimatedDuration': estimatedDuration!.inMilliseconds,
    };
  }
}

/// Complete makeup profile/template
class MakeupProfile {
  final String id;
  final String name;
  final String description;
  final String category;
  final Color? lipColor;
  final Color? blushColor;
  final List<TutorialStep> tutorialSteps;
  final List<String> recommendationReasons;
  final String? thumbnail;

  const MakeupProfile({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.lipColor,
    this.blushColor,
    this.tutorialSteps = const [],
    this.recommendationReasons = const [],
    this.thumbnail,
  });

  factory MakeupProfile.fromMap(Map<String, dynamic> map) {
    return MakeupProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String,
      lipColor:
          map['lipColor'] != null ? Color(map['lipColor'] as int) : null,
      blushColor:
          map['blushColor'] != null ? Color(map['blushColor'] as int) : null,
      tutorialSteps: (map['tutorialSteps'] as List?)
              ?.map((e) => TutorialStep.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendationReasons:
          List<String>.from(map['recommendationReasons'] ?? []),
      thumbnail: map['thumbnail'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      if (lipColor != null) 'lipColor': lipColor!.toARGB32(),
      if (blushColor != null) 'blushColor': blushColor!.toARGB32(),
      'tutorialSteps': tutorialSteps.map((e) => e.toMap()).toList(),
      'recommendationReasons': recommendationReasons,
      if (thumbnail != null) 'thumbnail': thumbnail,
    };
  }
}
