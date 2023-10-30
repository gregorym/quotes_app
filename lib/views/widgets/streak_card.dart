import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotes_app/controllers/streak_controller.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../controllers/reminder_controller.dart';
import '../../controllers/subscription_controller.dart';
import '../../models/streak_model.dart';
import '../themes/colors.dart';

class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSubState = ref.watch(subscribedProvider);
    final reminderState = ref.watch(reminderProvider);
    final streakState = ref.watch(streakProvider);

    bool isStreakCreatedToday = streakState.maybeWhen(
      data: (streakList) {
        print(streakList);
        tz.TZDateTime now = tz.TZDateTime.now(tz.local);
        if (now.hour < 17) {
          return true;
        }

        if (streakList.isEmpty) {
          return false;
        }
        tz.TZDateTime lastStreakCreatedAt = streakList[0].createdAt;

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
            Text("Streak",
                style: GoogleFonts.getFont("Nunito Sans",
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            SizedBox(
              width: 8,
            ),
            Icon(Icons.lock, color: MyColors.primaryDark, size: 24)
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
                  child: Icon(Icons.local_fire_department,
                      color: Colors.deepOrangeAccent.withOpacity(0.5),
                      size: 120)), // Flame icon

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
                                children: const [
                                  Text(
                                    '5',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          48, // Large font size for the number
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('days',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12)),
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
                  )
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _listWeekStreak(WidgetRef ref) {
    final reminderState = ref.watch(reminderProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) => index)
          .map((dayIndex) => _buildDayCircle(
                ['S', 'M', 'T', 'W', 'T', 'F', 'S'][dayIndex],
                isToday: tz.TZDateTime.now(tz.local).weekday == dayIndex,
                score: 0,
                isAfterToday: tz.TZDateTime.now(tz.local).weekday < dayIndex,
                isSkipped: reminderState.maybeWhen(
                  data: (r) => r != null ? !r.days[dayIndex] : false,
                  orElse: () => false,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildTodayScore(WidgetRef ref) {
    final streakProvider = ref.watch(streakControllerProvider.notifier);
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
              GestureDetector(
                onTap: () {
                  Streak s =
                      Streak(score: 0, createdAt: tz.TZDateTime.now(tz.local));
                  streakProvider.addStreak(s);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 16.0), // Adjust padding as needed
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                        30.0), // Makes the container rounded
                  ),
                  child: Text(
                    parser.emojify('Poor :thumbsdown:'),
                    style: TextStyle(
                      color: MyColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                  width: 16), // Adjust this for spacing between buttons
              GestureDetector(
                onTap: () {
                  // Handle button press here
                },
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16.0), // Adjust padding as needed
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          30.0), // Makes the container rounded
                    ),
                    child: Text(
                      parser.emojify('Good :thumbsup:'),
                      style: TextStyle(
                        color: MyColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    )),
              ),
              const SizedBox(
                  width: 16), // Adjust this for spacing between buttons
              GestureDetector(
                onTap: () {
                  // Handle button press here
                },
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16.0), // Adjust padding as needed
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          30.0), // Makes the container rounded
                    ),
                    child: Text(
                      parser.emojify('Great :fire:'),
                      style: TextStyle(
                        color: MyColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCircle(String day,
      {bool isSkipped = false,
      bool isAfterToday = false,
      bool isToday = false,
      int score = 0}) {
    Color foregroundColor = MyColors.primaryDark;
    Color backgroundColor = MyColors.primaryDark;

    if (isToday) {
      foregroundColor = MyColors.primaryDark;
      backgroundColor = Colors.white;
    }

    if (isAfterToday) {
      foregroundColor = Colors.white;
      backgroundColor = MyColors.primaryDark.withOpacity(0.3);
    }

    if (isSkipped && !isToday) {
      foregroundColor = MyColors.primaryDark.withOpacity(0.3);
      backgroundColor = MyColors.primaryDark.withOpacity(0.1);
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: MyColors.primaryDark.withOpacity(0.1), // Set border color
              width: 1.0, // Set border width
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
