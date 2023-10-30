import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotes_app/views/templates/quotes_page_template.dart';
import 'package:quotes_app/views/templates/welcome_template.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../controllers/user_controller.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  void startSplash(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    // Check if the user was created less than 10 seconds ago
    if (user.value != null) {
      final now = tz.TZDateTime.now(tz.local);
      final userCreated = user.value!.createdAt;
      final difference = now.difference(userCreated!).inSeconds;
      // Wait 2 seconds before navigating to the welcome page
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => difference < 10 ?  WelcomePage() : QuotesPage()
            ),
          );
        });
      }
    }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    startSplash(context, ref);

    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 90,
        ),
      ),
    );
  }
}
