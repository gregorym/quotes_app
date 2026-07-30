import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/subscription_controller.dart';
import '../../controllers/user_controller.dart';
import '../../repositories/onboarding_repository.dart';
import '../themes/colors.dart';
import '../themes/typography.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _started = false;

  Future<void> _startSplash() async {
    if (_started) return;
    _started = true;

    final completedOnboarding =
        await ref.read(onboardingRepositoryProvider).hasCompleted();
    final entitled = completedOnboarding
        ? await ref.read(subscriptionProvider).refreshEntitlement()
        : false;

    if (!mounted) return;
    context.go(
      !completedOnboarding
          ? '/onboarding'
          : entitled
              ? '/quotes'
              : '/subscription',
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userProvider).whenData((_) => _startSplash());

    return Scaffold(
      backgroundColor: MyColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/onboarding/mascot_effort.png',
              width: 112,
              height: 112,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 14),
            Text(
              'NO EXCUSES',
              style: MyTypography.h2.copyWith(letterSpacing: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
