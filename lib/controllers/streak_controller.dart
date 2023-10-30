import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:quotes_app/models/reminder_model.dart';

import '../models/streak_model.dart';

final streakProvider = FutureProvider<List<Streak>>((ref) {
  StreakController controller = StreakController();
  return controller.fetchStreakList();
});

// controller provider
final streakControllerProvider =
    StateNotifierProvider<StreakController, Reminder?>((ref) {
  return StreakController();
});

class StreakController extends StateNotifier<Reminder?> {
  final String _boxName = 'streakBox';

  StreakController() : super(null);

  Future<List<Streak>> fetchStreakList() async {
    var box = await Hive.openBox(_boxName);
    if (box.length > 0) {
      List<Streak> streakList = [];
      for (int i = 0; i < box.length; i++) {
        var data = box.getAt(i) as Map<dynamic, dynamic>?;
        Streak s = Streak.fromJson(data!);
        streakList.add(s);
      }
      return streakList;
    } else {
      return [];
    }
  }

  Future<void> addStreak(Streak streak) async {
    var box = await Hive.openBox(_boxName);
    await box.add(streak.toJson());
  }
}
