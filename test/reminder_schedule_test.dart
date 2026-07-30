import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:quotes_app/controllers/reminder_controller.dart';
import 'package:quotes_app/controllers/subscription_controller.dart';
import 'package:quotes_app/models/reminder_model.dart';
import 'package:quotes_app/widgets/reminder.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    tz_data.initializeTimeZones();
    hiveDirectory = await Directory.systemTemp.createTemp('reminder_schedule');
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    if (Hive.isBoxOpen('reminderBox')) {
      await Hive.box('reminderBox').close();
    }
    await hiveDirectory.delete(recursive: true);
  });

  test('builds valid evenly spaced weekly reminder slots across DST', () {
    const reminder = Reminder(
      count: 3,
      startMinute: 9 * 60,
      endMinute: 18 * 60,
      weekdays: [DateTime.monday, DateTime.friday],
    );

    expect(reminder.validationError, isNull);
    expect(reminder.promptMinutes, [675, 810, 945]);
    expect(reminderNotificationId(DateTime.monday, 0), 10000);
    expect(reminderNotificationId(DateTime.sunday, 5), 10041);

    final location = tz.getLocation('America/Los_Angeles');
    final beforeDst = tz.TZDateTime(location, 2026, 3, 7, 12);
    final monday = nextReminderOccurrence(
      location: location,
      now: beforeDst,
      weekday: DateTime.monday,
      minuteOfDay: 9 * 60,
    );

    expect(monday.weekday, DateTime.monday);
    expect(monday.hour, 9);
    expect(monday.minute, 0);
    expect(monday.timeZoneOffset, const Duration(hours: -7));

    final exactlyNow = tz.TZDateTime(location, 2026, 3, 9, 9);
    final followingMonday = nextReminderOccurrence(
      location: location,
      now: exactlyNow,
      weekday: DateTime.monday,
      minuteOfDay: 9 * 60,
    );
    expect(followingMonday.day, 16);
  });

  test('migrates Sunday-first HHMM reminder data', () {
    final reminder = Reminder.fromJson({
      'count': 10,
      'startAt': 900,
      'endAt': 2200,
      'days': [false, true, true, true, true, true, false],
    });

    expect(reminder.enabled, isFalse);
    expect(reminder.count, 6);
    expect(reminder.startMinute, 9 * 60);
    expect(reminder.endMinute, 22 * 60);
    expect(reminder.weekdays, [1, 2, 3, 4, 5]);
  });

  test('personalizes direct reminders without degrading the person', () {
    final bodies = motivationalNotificationBodies({
      'name': 'Ada Lovelace',
      'primary_goal': 'ship the first release',
      'frictions': ['Perfectionism', 'Procrastination'],
      'tone': 'extra hard',
    });

    expect(bodies, hasLength(6));
    expect(bodies.first, contains('Ada'));
    expect(bodies.first, contains('ship the first release'));
    expect(
      bodies[1],
      startsWith('Perfectionism and Procrastination are here.'),
    );
  });

  test('unicode personalization never splits emoji', () {
    final bodies = motivationalNotificationBodies({
      'name': 'Ada',
      'primary_goal': List.filled(100, '💪').join(),
      'tone': 'hard',
    });

    expect(bodies.expand((body) => body.runes), isNot(contains(0xFFFD)));
  });

  test('does not persist an enabled schedule without permission', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await ReminderController.initialize();
    final controller = ReminderController();

    final saved = await controller.saveSchedule(
      const Reminder(enabled: true),
    );

    expect(saved.enabled, isFalse);
    expect((await controller.fetchReminder()).enabled, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  test('keeps an unpaid reminder schedule dormant', () async {
    var entitlementChecks = 0;
    final controller = ReminderController(
      hasActiveSubscription: () async {
        entitlementChecks++;
        return false;
      },
    );

    final saved = await controller.saveSchedule(
      const Reminder(enabled: true),
    );

    expect(entitlementChecks, 1);
    expect(saved.enabled, isTrue);
    expect((await controller.fetchReminder()).enabled, isTrue);
  });

  testWidgets('settings reminder opens the paywall when unpaid',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(
            body: ReminderWidget(
              initialValue: Reminder(),
              requiresSubscription: true,
            ),
          ),
        ),
        GoRoute(
          path: '/subscription',
          builder: (_, __) => const Scaffold(body: Text('Premium paywall')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [subscribedProvider.overrideWithValue(false)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Premium paywall'), findsOneWidget);
  });
}
