class Relationship {
  final int userId;
  final int characterId;
  final int intimacyScore;
  final int currentStage;
  final String currentStageName;
  final int nextStageThreshold;
  final double percentToNextStage;

  const Relationship({
    required this.userId,
    required this.characterId,
    required this.intimacyScore,
    required this.currentStage,
    required this.currentStageName,
    required this.nextStageThreshold,
    required this.percentToNextStage,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) => Relationship(
        userId: (json['userId'] as num).toInt(),
        characterId: (json['characterId'] as num).toInt(),
        intimacyScore: (json['intimacyScore'] as num).toInt(),
        currentStage: (json['currentStage'] as num).toInt(),
        currentStageName: json['currentStageName'] as String,
        nextStageThreshold: (json['nextStageThreshold'] as num).toInt(),
        percentToNextStage: (json['percentToNextStage'] as num).toDouble(),
      );

  Relationship copyWith({
    int? intimacyScore,
    int? currentStage,
    String? currentStageName,
    int? nextStageThreshold,
    double? percentToNextStage,
  }) =>
      Relationship(
        userId: userId,
        characterId: characterId,
        intimacyScore: intimacyScore ?? this.intimacyScore,
        currentStage: currentStage ?? this.currentStage,
        currentStageName: currentStageName ?? this.currentStageName,
        nextStageThreshold: nextStageThreshold ?? this.nextStageThreshold,
        percentToNextStage: percentToNextStage ?? this.percentToNextStage,
      );
}
