import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quotes_app/repositories/onboarding_repository.dart';
import 'package:quotes_app/views/templates/subscription_page_template.dart';
import 'package:quotes_app/views/themes/theme.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    await (FontLoader('Anton')
          ..addFont(rootBundle.load('assets/fonts/Anton-Regular.ttf')))
        .load();
    await (FontLoader('Nunito Sans')
          ..addFont(rootBundle.load('assets/fonts/NunitoSans-Regular.ttf')))
        .load();
    hiveDirectory = await Directory.systemTemp.createTemp('subscription_page');
    Hive.init(hiveDirectory.path);
  });

  setUp(() async {
    await (await Hive.openBox('onboardingBox')).clear();
    await OnboardingRepository().complete({
      'primary_goal': 'Finish the first product release',
      'goal_days': 90,
      'frictions': ['Procrastination', 'Perfectionism'],
      'tone': 'extra hard',
    });
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('paywall lays out inside a phone-sized scroll view',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: MyTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 47, bottom: 34),
              viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: child!,
          ),
          home: const SubscriptionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NO EXCUSES.'), findsOneWidget);
    expect(
      find.text('Back your goal with hours, not intentions.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Every extra hour on “Finish the first product'),
      findsOneWidget,
    );
    expect(
      find.text('Expensive by design. Cheap if you use it.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Procrastination and Perfectionism'),
      findsOneWidget,
    );
    expect(find.textContaining('You chose Extra Hard'), findsOneWidget);
    expect(find.text('WEEKLY'), findsOneWidget);
    expect(find.text('ANNUAL'), findsOneWidget);
    expect(find.text('Enter No Excuses'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.byKey(const Key('subscription-plans'))).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('subscription-footer'))).dy,
      ),
    );
  });
}
