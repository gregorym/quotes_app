import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quotes_app/controllers/streak_controller.dart';
import 'package:quotes_app/models/streak_model.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('streak_test');
    Hive.init(hiveDirectory.path);
    await Hive.openBox('streakBox');
  });

  setUp(() => Hive.box('streakBox').clear());

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

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

  test('marks missed days only on or after installation', () {
    final installedAt = DateTime(2026, 7, 25, 18);
    final today = DateTime(2026, 7, 27);

    expect(
      isMissedStreakDay(DateTime(2026, 7, 24), today, installedAt, false),
      isFalse,
    );
    expect(
      isMissedStreakDay(DateTime(2026, 7, 25), today, installedAt, false),
      isTrue,
    );
    expect(
      isMissedStreakDay(DateTime(2026, 7, 26), today, installedAt, true),
      isFalse,
    );
    expect(
      isMissedStreakDay(today, today, installedAt, false),
      isFalse,
    );
  });

  test('upgrades an existing streak day when all top three are completed',
      () async {
    final controller = StreakController();

    expect(await controller.completeToday(), isTrue);
    expect(
      await controller.completeToday(topThreeCompleted: true),
      isTrue,
    );

    final streaks = await controller.fetchStreakList();
    expect(streaks, hasLength(1));
    expect(streaks.single.topThreeCompleted, isTrue);
  });
}
