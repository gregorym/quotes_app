import 'package:timezone/timezone.dart' as tz;

class Streak {
  final int score;
  final tz.TZDateTime createdAt;

  const Streak({required this.score, required this.createdAt});

  factory Streak.fromJson(Map<dynamic, dynamic> json) {
    return Streak(
      score: (json['score'] as num).toInt(),
      createdAt: tz.TZDateTime.parse(tz.local, json['createdAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'createdAt': createdAt.toString(),
      };
}
