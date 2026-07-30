import 'package:flutter_test/flutter_test.dart';
import 'package:quotes_app/controllers/streak_controller.dart';
import 'package:quotes_app/models/streak_model.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('counts consecutive completed calendar days and resets after a miss',
      () {
    tz_data.initializeTimeZones();
    final location = tz.getLocation('America/Los_Angeles');
    final now = tz.TZDateTime(location, 2026, 7, 27, 10);
    Streak day(int day) =>
        Streak(score: 1, createdAt: tz.TZDateTime(location, 2026, 7, day, 20));

    expect(currentStreakCount([day(25), day(26)], now), 2);
    expect(currentStreakCount([day(25), day(27)], now), 1);
    expect(currentStreakCount([day(24), day(25)], now), 0);
    expect(currentStreakCount([day(26), day(26)], now), 1);
  });

  test('advances streak challenges at completed milestones', () {
    expect(streakChallengeTarget(6), 7);
    expect(streakChallengeTarget(7), 30);
    expect(streakChallengeTarget(29), 30);
    expect(streakChallengeTarget(30), 100);
  });
}
