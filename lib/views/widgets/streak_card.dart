import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../controllers/streak_controller.dart';
import '../../models/streak_model.dart';
import '../themes/typography.dart';

const _flameAsset = 'assets/images/streak_flame.svg';

class StreakCard extends ConsumerStatefulWidget {
  const StreakCard({super.key});

  @override
  ConsumerState<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends ConsumerState<StreakCard> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final state = ref.watch(streakProvider);
    final streaks = state.maybeWhen(
      data: (streaks) => streaks,
      orElse: () => const <Streak>[],
    );
    final now = DateTime.now();
    final completedDays =
        streaks.map((streak) => streakDateKey(streak.createdAt)).toSet();
    final todayComplete = completedDays.contains(streakDateKey(now));
    final streakCount = currentStreakCount(streaks, now);

    return SizedBox(
      height: 301 + topInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _StreakHeader(
            count: streakCount,
            topInset: topInset,
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 0,
            child: _ChallengePanel(
              streaks: streaks,
              now: now,
              completedDays: completedDays,
              streakCount: streakCount,
              todayComplete: todayComplete,
              loading: state.isLoading || _saving,
              onComplete: _completeToday,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeToday() async {
    setState(() => _saving = true);
    try {
      await ref.read(streakControllerProvider).completeToday();
      ref.invalidate(streakProvider);
      await ref.read(streakProvider.future);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save today. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StreakHeader extends StatelessWidget {
  const _StreakHeader({
    required this.count,
    required this.topInset,
  });

  final int count;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 222 + topInset,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6A00), Color(0xFFF04A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: topInset - 24,
            child: SvgPicture.asset(
              _flameAsset,
              width: 190,
              height: 190,
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.10),
                BlendMode.srcIn,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: topInset + 42,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(count),
              tween: Tween(begin: 0, end: count.toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (context, value, _) => Text(
                value.round().toString(),
                textAlign: TextAlign.center,
                style: MyTypography.h3.copyWith(
                  color: Colors.white,
                  fontSize: 56,
                  height: 1,
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 104,
            left: 0,
            right: 0,
            child: Text(
              count == 1 ? 'DAY STREAK' : 'DAYS STREAK',
              textAlign: TextAlign.center,
              style: MyTypography.h3.copyWith(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengePanel extends StatelessWidget {
  const _ChallengePanel({
    required this.streaks,
    required this.now,
    required this.completedDays,
    required this.streakCount,
    required this.todayComplete,
    required this.loading,
    required this.onComplete,
  });

  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  final List<Streak> streaks;
  final DateTime now;
  final Set<int> completedDays;
  final int streakCount;
  final bool todayComplete;
  final bool loading;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final challengeTarget = streakChallengeTarget(streakCount);
    final today = DateTime(now.year, now.month, now.day);
    final weekStart =
        DateTime(today.year, today.month, today.day - now.weekday % 7);
    final firstCompleted = streaks.isEmpty
        ? null
        : streaks.map((streak) => streak.createdAt).reduce(
              (a, b) => a.isBefore(b) ? a : b,
            );

    return Container(
      height: 148,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF17181B),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: todayComplete
            ? MainAxisAlignment.spaceEvenly
            : MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$challengeTarget DAY CHALLENGE',
                style: MyTypography.body2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                'DAY ${streakCount.clamp(0, challengeTarget)} OF $challengeTarget',
                style: MyTypography.body2.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final date = DateTime(
                  weekStart.year, weekStart.month, weekStart.day + index);
              final complete = completedDays.contains(streakDateKey(date));
              final inactive = firstCompleted == null ||
                  date.isBefore(DateTime(
                    firstCompleted.year,
                    firstCompleted.month,
                    firstCompleted.day,
                  ));
              final missed = date.isBefore(today) && !complete && !inactive;
              return _DayFlame(
                label: _labels[index],
                complete: complete,
                missed: missed,
                today: streakDateKey(date) == streakDateKey(today),
              );
            }),
          ),
          if (!todayComplete) ...[
            const Spacer(),
            SizedBox(
              height: 34,
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : onComplete,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  disabledBackgroundColor: Colors.white12,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  loading ? 'SAVING...' : 'COMPLETE TODAY',
                  style: MyTypography.caption1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayFlame extends StatelessWidget {
  const _DayFlame({
    required this.label,
    required this.complete,
    required this.missed,
    required this.today,
  });

  final String label;
  final bool complete;
  final bool missed;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? const Color(0xFFFF6A00)
        : missed
            ? const Color(0xFF58A9FF)
            : Colors.white30;

    return SizedBox(
      width: 34,
      child: Column(
        children: [
          Text(
            label,
            style: MyTypography.caption1.copyWith(
              color: today ? color : Colors.white54,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale:
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              child: child,
            ),
            child: Stack(
              key: ValueKey('$complete-$missed-$today'),
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  _flameAsset,
                  width: 30,
                  height: 30,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                if (complete)
                  const Icon(Icons.check_rounded,
                      color: Colors.white, size: 17),
                if (missed)
                  const Icon(Icons.close_rounded,
                      color: Colors.white, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
