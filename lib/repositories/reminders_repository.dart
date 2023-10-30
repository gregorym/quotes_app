import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotes_app/models/reminder_model.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final remindersRepositoryProvider =
    Provider<RemindersRepository>((ref) => RemindersRepository());

class RemindersRepository {
  final String _boxName = 'userBox';

  Future<List<Reminder>> getReminders(String query) async {
    return [];
  }

  Future<Reminder> fetchReminder() async {
    return Reminder(
        id: '1',
        count: 10,
        startAt: 900,
        endAt: 2200,
        days: [false, true, true, true, true, true, false]);
  }

  // Create a reminder
  Future<void> createReminders(Reminder reminder) async {
    try {

    } catch (e) {
      rethrow;
    }
  }

  Future<Reminder?> getReminder(String id) async {
    try {
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      rethrow;
    }
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
