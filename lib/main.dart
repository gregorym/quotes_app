import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_frame/flutter_web_frame.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quotes_app/controllers/reminder_controller.dart';
import 'package:quotes_app/controllers/subscription_controller.dart';
import 'package:quotes_app/views/menu.dart';
import 'package:quotes_app/views/templates/onboarding_template.dart';
import 'package:quotes_app/views/templates/subscription_page_template.dart';
import 'package:quotes_app/views/templates/splash_page_template.dart';
import 'package:quotes_app/views/themes/theme.dart';
import 'package:quotes_app/views/widgets/app_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  try {
    await ReminderController.initialize();
  } catch (error) {
    debugPrint('Unable to initialize reminders: $error');
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  static final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingTemplate(),
      ),
      GoRoute(
          path: '/subscription',
          builder: (context, state) => const SubscriptionPage()),
      GoRoute(path: '/quotes', builder: (context, state) => const Menu()),
    ],
  );

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool? _lastReminderEntitlement;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual<SubscriptionController>(
      subscriptionProvider,
      (_, subscription) {
        // ponytail: local reminders revoke on app activity; use server push if
        // subscription expiry must stop delivery while the app stays closed.
        if (!subscription.entitlementChecked ||
            _lastReminderEntitlement == subscription.isEntitled) {
          return;
        }
        _lastReminderEntitlement = subscription.isEntitled;
        _reconcileReminders();
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _reconcileReminders();
  }

  void _reconcileReminders() {
    unawaited(
      ref.read(reminderControllerProvider).reconcileSavedSchedule().catchError(
        (Object error) {
          debugPrint('Unable to reconcile reminders: $error');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterWebFrame(
      enabled: kIsWeb,
      maximumSize: const Size(390, 844),
      builder: (context) {
        return AppBackground(
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'No Excuses',
            themeMode: ThemeMode.light,
            darkTheme: MyTheme.darkTheme,
            theme: MyTheme.lightTheme,
            routerConfig: MyApp._router,
          ),
        );
      },
    );
  }
}
