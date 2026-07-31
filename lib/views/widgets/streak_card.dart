import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../controllers/streak_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/streak_model.dart';
import '../themes/typography.dart';

const _flameAsset = 'assets/images/streak_flame.svg';

class StreakCard extends ConsumerStatefulWidget {
  const StreakCard({super.key});

  @override
  ConsumerState<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends ConsumerState<StreakCard>
    with SingleTickerProviderStateMixin {
  bool _saving = false;
  late final _flameAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1650),
  )..repeat();

  @override
  void dispose() {
    _flameAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final state = ref.watch(streakProvider);
    final installedAt = ref.watch(userProvider).maybeWhen(
          data: (user) => user.createdAt,
          orElse: () => null,
        );
    final streaks = state.maybeWhen(
      data: (streaks) => streaks,
      orElse: () => const <Streak>[],
    );
    final now = DateTime.now();
    final completedDays =
        streaks.map((streak) => streakDateKey(streak.createdAt)).toSet();
    final topThreeDays = streaks
        .where((streak) => streak.topThreeCompleted)
        .map((streak) => streakDateKey(streak.createdAt))
        .toSet();
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
              installedAt: installedAt,
              topThreeDays: topThreeDays,
              flameAnimation: _flameAnimation,
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
    required this.installedAt,
    required this.topThreeDays,
    required this.flameAnimation,
    required this.streakCount,
    required this.todayComplete,
    required this.loading,
    required this.onComplete,
  });

  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  final List<Streak> streaks;
  final DateTime now;
  final Set<int> completedDays;
  final DateTime? installedAt;
  final Set<int> topThreeDays;
  final Animation<double> flameAnimation;
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
              final missed = isMissedStreakDay(
                date,
                today,
                installedAt,
                complete,
              );
              return _DayFlame(
                label: _labels[index],
                complete: complete,
                topThreeComplete: topThreeDays.contains(streakDateKey(date)),
                flameAnimation: flameAnimation,
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
    required this.topThreeComplete,
    required this.flameAnimation,
    required this.missed,
    required this.today,
  });

  final String label;
  final bool complete;
  final bool topThreeComplete;
  final Animation<double> flameAnimation;
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
            child: _flame(color, context),
          ),
        ],
      ),
    );
  }

  Widget _flame(Color color, BuildContext context) {
    final animate = topThreeComplete &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context);
    final fixedFlame = SvgPicture.asset(
      _flameAsset,
      width: 33,
      height: 33,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
    Widget? animatedFlame;
    if (animate) {
      animatedFlame = AnimatedBuilder(
        key: const Key('animated-top-three-flame'),
        animation: flameAnimation,
        child: SvgPicture.asset(
          _flameAsset,
          width: 33,
          height: 33,
          colorFilter: const ColorFilter.mode(
            Color.fromARGB(255, 186, 55, 23),
            BlendMode.srcIn,
          ),
        ),
        builder: (_, child) {
          final phase = flameAnimation.value * math.pi * 1.5;
          final stretch = 1 + math.sin(phase * 2) * 0.05;
          return Opacity(
            opacity: 0.5 + (math.sin(phase * 3 + 0.8) + 1) * 0.05,
            child: Transform.translate(
              offset: Offset(
                math.sin(phase * 2) * 0.6 + math.sin(phase * 3) * 0.2,
                (1 - stretch) * 6,
              ),
              child: Transform.rotate(
                angle: math.sin(phase) * 0.045 + math.sin(phase * 3) * 0.015,
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  scaleX: 1.1 * stretch,
                  scaleY: 1.1 * stretch,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              ),
            ),
          );
        },
      );
    }
    final flame = Stack(
      alignment: Alignment.center,
      children: [
        if (animatedFlame != null) animatedFlame,
        fixedFlame,
        if (complete)
          Transform.translate(
            offset: const Offset(0, 2),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        if (missed)
          Transform.translate(
            offset: const Offset(0, 4),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
      ],
    );
    final key = ValueKey('$complete-$missed-$today-$topThreeComplete');
    return KeyedSubtree(key: key, child: flame);
  }
}
