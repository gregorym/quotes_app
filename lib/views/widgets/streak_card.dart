import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotes_app/controllers/streak_controller.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../controllers/reminder_controller.dart';
import '../../models/streak_model.dart';
import '../themes/colors.dart';

class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakState = ref.watch(streakProvider);
    final streakCount = streakState.maybeWhen(
      data: (streakList) => streakList.length,
      orElse: () => 0,
    );

    final isStreakCreatedToday = streakState.maybeWhen(
      data: (streakList) {
        final now = tz.TZDateTime.now(tz.local);
        if (now.hour < 17) {
          return true;
        }

        if (streakList.isEmpty) {
          return false;
        }
        final lastStreakCreatedAt = streakList.last.createdAt;

        return lastStreakCreatedAt.year == now.year &&
            lastStreakCreatedAt.month == now.month &&
            lastStreakCreatedAt.day == now.day;
      },
      orElse: () => false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Streak",
              style: GoogleFonts.getFont(
                "Nunito Sans",
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: MyColors.primary,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -25,
                top: 25,
                child: Icon(
                  Icons.local_fire_department,
                  color: Colors.deepOrangeAccent.withValues(alpha: 0.5),
                  size: 120,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: isStreakCreatedToday
                          ? [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$streakCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'days',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          : [],
                    ),
                  ),
                  Expanded(
                    child: isStreakCreatedToday
                        ? _listWeekStreak(ref)
                        : _buildTodayScore(ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _listWeekStreak(WidgetRef ref) {
    final reminderState = ref.watch(reminderProvider);
    final todayIndex = tz.TZDateTime.now(tz.local).weekday % 7;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) => index)
          .map(
            (dayIndex) => _buildDayCircle(
              ['S', 'M', 'T', 'W', 'T', 'F', 'S'][dayIndex],
              isToday: todayIndex == dayIndex,
              score: 0,
              isAfterToday: todayIndex < dayIndex,
              isSkipped: reminderState.maybeWhen(
                data: (r) => r != null ? !r.days[dayIndex] : false,
                orElse: () => false,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTodayScore(WidgetRef ref) {
    final streakController = ref.watch(streakControllerProvider.notifier);
    final parser = EmojiParser();

    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "How was today?",
            style: GoogleFonts.getFont(
              "Nunito Sans",
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _scoreButton(
                label: parser.emojify('Poor :thumbsdown:'),
                onPressed: () async {
                  await streakController.addStreak(
                    Streak(score: 0, createdAt: tz.TZDateTime.now(tz.local)),
                  );
                  ref.invalidate(streakProvider);
                },
              ),
              const SizedBox(width: 12),
              _scoreButton(
                label: parser.emojify('Good :thumbsup:'),
                onPressed: () async {
                  await streakController.addStreak(
                    Streak(score: 1, createdAt: tz.TZDateTime.now(tz.local)),
                  );
                  ref.invalidate(streakProvider);
                },
              ),
              const SizedBox(width: 12),
              _scoreButton(
                label: parser.emojify('Great :fire:'),
                onPressed: () async {
                  await streakController.addStreak(
                    Streak(score: 2, createdAt: tz.TZDateTime.now(tz.local)),
                  );
                  ref.invalidate(streakProvider);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: MyColors.primaryDark,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDayCircle(
    String day, {
    bool isSkipped = false,
    bool isAfterToday = false,
    bool isToday = false,
    int score = 0,
  }) {
    Color foregroundColor = MyColors.primaryDark;
    Color backgroundColor = MyColors.primaryDark;

    if (isToday) {
      foregroundColor = MyColors.primaryDark;
      backgroundColor = Colors.white;
    }

    if (isAfterToday) {
      foregroundColor = Colors.white;
      backgroundColor = MyColors.primaryDark.withValues(alpha: 0.3);
    }

    if (isSkipped && !isToday) {
      foregroundColor = MyColors.primaryDark.withValues(alpha: 0.3);
      backgroundColor = MyColors.primaryDark.withValues(alpha: 0.1);
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: MyColors.primaryDark.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
          child: CircleAvatar(
            maxRadius: 16.0,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            child: Text(day),
          ),
        ),
      ],
    );
  }
}
