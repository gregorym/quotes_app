import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/streak_model.dart';

final streakControllerProvider = Provider((ref) => StreakController());
final streakProvider = FutureProvider<List<Streak>>(
  (ref) => ref.watch(streakControllerProvider).fetchStreakList(),
);

int streakDateKey(DateTime date) =>
    date.year * 10000 + date.month * 100 + date.day;

int streakChallengeTarget(int count) => count >= 30
    ? 100
    : count >= 7
        ? 30
        : 7;

bool isMissedStreakDay(
  DateTime date,
  DateTime today,
  DateTime? installedAt,
  bool complete,
) =>
    installedAt != null &&
    !date.isBefore(DateTime(
      installedAt.year,
      installedAt.month,
      installedAt.day,
    )) &&
    date.isBefore(today) &&
    !complete;

int currentStreakCount(List<Streak> streaks, DateTime now) {
  final completedDays =
      streaks.map((streak) => streakDateKey(streak.createdAt)).toSet();
  var cursor = DateTime(now.year, now.month, now.day);
  if (!completedDays.contains(streakDateKey(cursor))) {
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }

  var count = 0;
  while (completedDays.contains(streakDateKey(cursor))) {
    count++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return count;
}

class StreakController {
  static const _boxName = 'streakBox';

  Future<List<Streak>> fetchStreakList() async {
    final box = await Hive.openBox(_boxName);
    final streaks = box.values
        .whereType<Map<dynamic, dynamic>>()
        .map(Streak.fromJson)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return streaks;
  }

  Future<bool> completeToday({bool topThreeCompleted = false}) async {
    final now = tz.TZDateTime.now(tz.local);
    final box = await Hive.openBox(_boxName);
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is! Map<dynamic, dynamic>) continue;
      final streak = Streak.fromJson(value);
      if (streakDateKey(streak.createdAt) != streakDateKey(now)) continue;
      if (!topThreeCompleted || streak.topThreeCompleted) return false;
      await box.put(key, streak.copyWith(topThreeCompleted: true).toJson());
      return true;
    }

    await box.add(Streak(
      score: 1,
      createdAt: now,
      topThreeCompleted: topThreeCompleted,
    ).toJson());
    return true;
  }
}
