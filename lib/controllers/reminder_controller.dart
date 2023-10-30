import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:quotes_app/models/reminder_model.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final reminderProvider = FutureProvider<Reminder?>((ref) {
  ReminderController controller =  ReminderController();
  return controller.fetchReminder();
});

class ReminderController extends StateNotifier<Reminder?> {
  final String _boxName = 'reminderBox';

  ReminderController() : super(null);

  Future<List<Reminder>> getReminders(String query) async {
    return [];
  }

  Future<Reminder> fetchReminder() async {
    var box = await Hive.openBox(_boxName);
    if (!box.containsKey(_boxName)) {
      Reminder r = Reminder(
          id: '1',
          count: 10,
          startAt: 900,
          endAt: 2200,
          days: [false, true, true, true, true, true, false]);
      await box.put(_boxName, r.toJson());
    }

    var data = box.get(_boxName) as Map<dynamic, dynamic>?;
    Reminder r = Reminder.fromJson(data!);
    return r;
  }

  Future<void> scheduleAllNotifications() async {
    List<Notification> notifications = [];
    Reminder r = await fetchReminder();
    // Schedule N notifications each day for the next 100 days
    for (int i = 0; i < 100; i++) {
      for (int j = 0; j < r.count; j++) {
        int id = randomId();
        // The time should be evenly spaced between startAt and endAt
        int time = r.startAt + (r.endAt - r.startAt) ~/ r.count * j;
        // Set scheduleAt to the current day at the time
        tz.TZDateTime scheduledAt = tz.TZDateTime(
                tz.local,
                tz.TZDateTime.now(tz.local).year,
                tz.TZDateTime.now(tz.local).month,
                tz.TZDateTime.now(tz.local).day,
                time)
            .add(
          Duration(days: i),
        );

        notifications.add(Notification(id: id, scheduledAt: scheduledAt));
        await scheduleDailyNotifications(id, 'Test', 'Test', scheduledAt);
      }
    }

    Reminder newReminder = Reminder(
      id: r.id,
      count: r.count,
      startAt: r.startAt,
      endAt: r.endAt,
      days: r.days,
      notifications: notifications,
    );
    await saveReminder(newReminder);
  }

  Future<Reminder> saveReminder(Reminder r) async {
    var box = await Hive.openBox(_boxName);
    await box.put(_boxName, r.toJson());
    return r;
  }

  Future<void> cancelAllUpcomingReminders() async {
    Reminder r = await fetchReminder();
    for (Notification n in r.notifications) {
      await flutterLocalNotificationsPlugin.cancel(n.id);
    }
    Reminder newReminder = Reminder(
      id: r.id,
      count: r.count,
      startAt: r.startAt,
      endAt: r.endAt,
      days: r.days,
      notifications: [],
    );
    await saveReminder(newReminder);
  }

  int randomId() {
    int min = 5;
    int max = 10;

    var random = Random();
    return min + random.nextInt(max + 1 - min);
  }

  Future<void> requestLocalNotificationPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> scheduleDailyNotifications(
      int id, String title, String body, tz.TZDateTime time) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'snarky_motivation_channel', 'SnarkyMotivation',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'snarky_motivation_channel', 'SnarkyMotivation',
          importance: Importance.max);

      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    flutterLocalNotificationsPlugin.zonedSchedule(
        id, title, body, time, platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
  }
}
