import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../controllers/user_controller.dart';
import '../../models/user_model.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _started = false;

  void _startSplash(User user) {
    if (_started) return;
    _started = true;

    final now = tz.TZDateTime.now(tz.local);
    final createdAt = user.createdAt ?? now;
    final showWelcome = now.difference(createdAt).inSeconds < 10;

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.go(showWelcome ? '/welcome' : '/quotes');
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
