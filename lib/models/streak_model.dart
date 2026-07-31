import 'package:timezone/timezone.dart' as tz;

class Streak {
  final int score;
  final tz.TZDateTime createdAt;
  final bool topThreeCompleted;

  const Streak({
    required this.score,
    required this.createdAt,
    this.topThreeCompleted = false,
  });

  Streak copyWith({bool? topThreeCompleted}) => Streak(
        score: score,
        createdAt: createdAt,
        topThreeCompleted: topThreeCompleted ?? this.topThreeCompleted,
      );

  factory Streak.fromJson(Map<dynamic, dynamic> json) {
    return Streak(
      score: (json['score'] as num).toInt(),
      createdAt: tz.TZDateTime.parse(tz.local, json['createdAt'].toString()),
      topThreeCompleted: json['topThreeCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'createdAt': createdAt.toString(),
        if (topThreeCompleted) 'topThreeCompleted': true,
      };
}
