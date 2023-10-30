import 'package:timezone/timezone.dart' as tz;

class Streak {
  final int score;
  final tz.TZDateTime createdAt;

  Streak({
    required this.score,
    required this.createdAt
  });

  factory Streak.fromJson(Map<dynamic, dynamic> json) {
    return Streak(
      score: json['score'],
      createdAt: tz.TZDateTime.parse(tz.local, json['createdAt']),
    );
  }

    Map<String, dynamic> toJson() {
    return {
      'score': score,
      'createdAt': createdAt.toString(),
    };
  }
}