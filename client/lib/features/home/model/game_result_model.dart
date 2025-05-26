import 'dart:convert';

class GameResultModel {
  final String userId;
  final int score;
  final DateTime submittedAt;
  final int level; // Dodano poziom

  GameResultModel({
    required this.userId,
    required this.score,
    required this.submittedAt,
    required this.level, // Dodano poziom
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'score': score,
      'submittedAt': submittedAt.toIso8601String(),
      'level': level,
    };
  }

  factory GameResultModel.fromMap(Map<String, dynamic> map) {
    return GameResultModel(
      userId: map['userId'] ?? map['user_id'] ?? '',
      score: map['score'] ?? 0,
      submittedAt: DateTime.parse(map['submittedAt'] ?? map['submitted_at']),
      level: map['level'] ?? 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory GameResultModel.fromJson(String source) =>
      GameResultModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'GameResultModel(userId: $userId, score: $score, submittedAt: $submittedAt, level: $level)';
}