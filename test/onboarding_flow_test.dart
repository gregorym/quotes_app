import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:quotes_app/controllers/subscription_controller.dart';
import 'package:quotes_app/repositories/onboarding_repository.dart';
import 'package:quotes_app/views/templates/onboarding_template.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('onboarding_flow');
    Hive.init(hiveDirectory.path);
  });

  setUp(() async {
    for (final name in ['onboardingBox', 'reminderBox', 'userBox']) {
      await (await Hive.openBox(name)).clear();
    }
  });

  tearDownAll(() async {
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('collects a focused profile and completes before the paywall',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.runAsync(
      () async => (await Hive.openBox('onboardingBox'))
          .put('completedAt', DateTime.now().toIso8601String()),
    );
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingTemplate(),
        ),
        GoRoute(
          path: '/subscription',
          builder: (_, __) => const Scaffold(
            body: Text('Subscription destination'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [subscribedProvider.overrideWithValue(false)],
        child: MaterialApp.router(
          theme: ThemeData.dark(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: const TextScaler.linear(2),
            ),
            child: child!,
          ),
        ),
      ),
    );
    await _waitForText(tester, 'I can handle it');
    expect(find.text('NO EXCUSES.'), findsOneWidget);
    expect(find.bySemanticsLabel('NO EXCUSES.'), findsOneWidget);
    expect(
      find.text(
        'No gentle affirmations. No empty hype. You’ll get hard, no-BS '
        'quotes and reminders that call out your excuses and push you back '
        'to work.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('10 quick steps'), findsNothing);
    expect(tester.takeException(), isNull);

    await _tapText(tester, 'I can handle it');
    await tester.enterText(find.byKey(const Key('onboarding-name')), 'Ada');
    await _tapText(tester, 'Continue');

    await _waitForText(tester, 'Business & Entrepreneurship');
    expect(find.text('Business & Entrepreneurship'), findsOneWidget);
    expect(find.text('Relationships'), findsNothing);
    expect(find.text('Other'), findsOneWidget);
    await _tapText(tester, 'Career');
    await _tapText(tester, 'Education & Skills');
    await _tapText(tester, 'Continue');

    await _waitForText(tester, 'What exactly are you going after?');

    await tester.enterText(
      find.byKey(const Key('onboarding-goal')),
      'Finish the first product release',
    );
    await _tapText(tester, 'That’s the goal');
    await _waitForText(tester, 'How many days are you giving yourself?');
    final goalDaysSlider = tester.widget<Slider>(
      find.byKey(const Key('onboarding-goal-days-slider')),
    );
    expect(goalDaysSlider.min, 5);
    expect(goalDaysSlider.max, 100);
    await tester.enterText(
      find.byKey(const Key('onboarding-goal-days')),
      '365',
    );
    await _tapText(tester, 'Commit to 365 days');
    await _tapText(tester, 'Procrastination');
    await _tapText(tester, 'Something else');
    await tester.enterText(
      find.byKey(const Key('onboarding-custom-friction')),
      'Avoiding the hard part',
    );
    await _tapText(tester, 'Continue');
    await _waitForText(tester, 'Extra Hard');
    expect(find.text('Firm'), findsNothing);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Extra Hard'), findsOneWidget);
    await _tapText(tester, 'Extra Hard');
    await _tapText(tester, 'Use Extra Hard');

    expect(find.text('DELIVERY MAP'), findsNothing);
    await _tapText(tester, 'Save my schedule');
    await _waitForText(tester, 'Ready to be held to it?');
    expect(
      find.text('Ada, nobody is coming to save you. Get to work.'),
      findsOneWidget,
    );
    await _tapText(tester, 'Not now');

    await _waitForText(tester, 'Ada, this is the deal.');
    expect(
      find.text('The plan is set. Now earn the result.'),
      findsOneWidget,
    );
    await _tapText(tester, 'See what this is worth');

    await _waitForText(tester, 'Your time is worth more than this app.');
    expect(find.text('121.7 HOURS'), findsOneWidget);
    expect(
      find.text('FOCUSED TIME BACK ON YOUR GOAL'),
      findsOneWidget,
    );
    await _tapText(tester, 'Put that in perspective');

    await _waitForText(tester, 'Another 365 days of drift costs more.');
    expect(
      find.textContaining('The price on the next screen is high.'),
      findsOneWidget,
    );
    await _tapText(tester, 'Show me the price');

    await _waitForText(tester, 'Subscription destination');
    final repository = OnboardingRepository();
    expect(await repository.hasCompleted(), isTrue);
    expect(
      await repository.fetchAnswers(),
      containsPair('primary_goal', 'Finish the first product release'),
    );
    expect(await repository.fetchAnswers(), containsPair('goal_days', 365));
    expect(
      await repository.fetchAnswers(),
      containsPair('categories', ['Education & Skills']),
    );
    expect(
      await repository.fetchAnswers(),
      containsPair(
        'frictions',
        ['Procrastination', 'Avoiding the hard part'],
      ),
    );
    expect(await repository.fetchAnswers(), isNot(contains('motivation')));
    expect(
      await repository.fetchAnswers(),
      isNot(contains('pace_frustration')),
    );
    expect(await repository.fetchAnswers(), containsPair('tone', 'extra hard'));
    expect(
        await repository.fetchAnswers(), containsPair('onboarding_version', 5));
    debugDefaultTargetPlatformOverride = null;
  });
}

Future<void> _tapText(WidgetTester tester, String label) async {
  await _waitForText(tester, label);
  final finder = find.text(label);
  await tester.ensureVisible(finder.last);
  await tester.tap(finder.last);
  await _pumpFrames(tester);
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _waitForText(WidgetTester tester, String label) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text(label).evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  final visibleText = find
      .byType(Text)
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .join(' | ');
  fail('Timed out waiting for "$label". Visible text: $visibleText');
}
