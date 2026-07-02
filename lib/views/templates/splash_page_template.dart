import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../controllers/user_controller.dart';
import '../../models/user_model.dart';
import '../../repositories/onboarding_repository.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _started = false;

  Future<void> _startSplash(User user) async {
    if (_started) return;
    _started = true;

    final now = tz.TZDateTime.now(tz.local);
    final createdAt = user.createdAt ?? now;
    final completedOnboarding =
        await ref.read(onboardingRepositoryProvider).hasCompleted();
    final showOnboarding =
        !completedOnboarding && now.difference(createdAt).inSeconds < 10;

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.go(showOnboarding ? '/onboarding' : '/quotes');
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userProvider).whenData(_startSplash);

    return Scaffold(
      body: Center(child: Image.asset('assets/images/logo.png', width: 90)),
    );
  }
}
