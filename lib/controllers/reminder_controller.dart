import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive/hive.dart';
import 'package:quotes_app/controllers/subscription_controller.dart';
import 'package:quotes_app/models/reminder_model.dart';
import 'package:quotes_app/repositories/onboarding_repository.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final reminderControllerProvider = Provider<ReminderController>(
  (ref) => ReminderController(
    hasActiveSubscription: () =>
        ref.read(subscriptionProvider).refreshEntitlement(),
  ),
);

final reminderProvider = FutureProvider<Reminder?>((ref) {
  return ref.watch(reminderControllerProvider).fetchReminder();
});

const _firstReminderId = 10000;
const _slotsPerDay = 6;
const _reminderSlotCount = DateTime.daysPerWeek * _slotsPerDay;

const _notificationBodies = [
  'The work is still waiting. So are your excuses.',
  'You do not need more motivation. You need to move.',
  'Comfort is expensive. Get back to work.',
  'Your goal does not care how you feel today.',
  'Stop negotiating with the task you already chose.',
  'Nobody is coming. Do the work.',
  'Your future is being built by what you do next.',
  'Discipline starts where your excuses stop.',
  'You said this mattered. Prove it.',
  'One focused hour beats another day of intention.',
  'The gap is not talent. It is repetition.',
  'Do the hard thing before comfort talks you out of it.',
];

List<String> motivationalNotificationBodies(Map<String, dynamic> answers) {
  String clean(Object? value, [int max = 90]) {
    final text = value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    final runes = text.runes.toList();
    return runes.length <= max
        ? text
        : '${String.fromCharCodes(runes.take(max - 1))}…';
  }

  final fullName = clean(answers['name'], 24);
  final name = fullName.isEmpty ? null : fullName.split(' ').first;
  final goal = clean(answers['primary_goal']);
  final frictions = onboardingFrictions(answers);
  final friction = clean(frictions.join(' and '), 40);
  final categories = (answers['categories'] as List? ?? const [])
      .map((value) => clean(value, 32))
      .where((value) => value.isNotEmpty)
      .take(3)
      .join(' · ');
  if (name == null || goal.isEmpty) return _notificationBodies;

  final extraHard = answers['tone'] == 'extra hard';
  return [
    extraHard
        ? '$name, stop negotiating. Work the plan: $goal'
        : '$name, start before you feel ready. Move $goal forward now.',
    friction.isEmpty
        ? 'Your goal does not care how you feel today. Do the work.'
        : '$friction ${frictions.length == 1 ? 'is' : 'are'} here. '
            '${frictions.length == 1 ? 'It does' : 'They do'} not get the next hour.',
    'You said this mattered: $goal. Prove it with the next action.',
    if (categories.isNotEmpty)
      '$categories. Raise the standard with one focused action now.',
    extraHard
        ? 'Comfort is expensive, $name. Get back to work.'
        : 'One focused block, $name. That is all the next step needs.',
    'Your future is being built by what you do next.',
    'Discipline starts where your excuses stop.',
  ];
}

int reminderNotificationId(int weekday, int slot) =>
    _firstReminderId + (weekday - DateTime.monday) * _slotsPerDay + slot;

tz.TZDateTime nextReminderOccurrence({
  required tz.Location location,
  required tz.TZDateTime now,
  required int weekday,
  required int minuteOfDay,
}) {
  final daysAhead =
      (weekday - now.weekday + DateTime.daysPerWeek) % DateTime.daysPerWeek;
  var next = tz.TZDateTime(
    location,
    now.year,
    now.month,
    now.day + daysAhead,
    minuteOfDay ~/ 60,
    minuteOfDay % 60,
  );
  if (!next.isAfter(now)) {
    next = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day + daysAhead + DateTime.daysPerWeek,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
  }
  return next;
}

class ReminderController {
  ReminderController({
    Future<bool> Function()? hasActiveSubscription,
  }) : _hasActiveSubscription = hasActiveSubscription ?? (() async => true);

  static const _boxName = 'reminderBox';
  static const _reminderKey = 'reminderBox';
  static bool _initialized = false;
  static bool _timezoneReady = false;
  static Future<void> _operationTail = Future.value();

  final Future<bool> Function() _hasActiveSubscription;

  static bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    if (!_isSupported) return;

    await _refreshTimezone();

    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: darwin,
        macOS: darwin,
      ),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'no_excuses_motivation_v2',
              'No Excuses reminders',
              description: 'Direct reminders inside your pressure window.',
              importance: Importance.high,
            ),
          );
    }
    _initialized = true;
  }

  static Future<void> _refreshTimezone() async {
    _timezoneReady = false;
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
      _timezoneReady = true;
    } catch (error) {
      debugPrint('Unable to configure the local timezone: $error');
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _operationTail = _operationTail.catchError((_) {}).then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  Future<Reminder> fetchReminder() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_reminderKey);
    if (raw is! Map) {
      final reminder = Reminder(timezoneId: tz.local.name);
      await box.put(_reminderKey, reminder.toJson());
      return reminder;
    }

    if (raw['version'] != Reminder.schemaVersion && _initialized) {
      for (final notification in raw['notifications'] as List? ?? const []) {
        if (notification is Map && notification['id'] is num) {
          await flutterLocalNotificationsPlugin.cancel(
            id: (notification['id'] as num).toInt(),
          );
        }
      }
    }

    final reminder = Reminder.fromJson(raw);
    if (raw['version'] != Reminder.schemaVersion) {
      await box.put(_reminderKey, reminder.toJson());
    }
    return reminder;
  }

  Future<Reminder> saveSchedule(Reminder reminder) =>
      _serialize(() => _saveSchedule(reminder));

  Future<Reminder> _saveSchedule(Reminder reminder) async {
    final error = reminder.validationError;
    if (error != null) throw ArgumentError(error);

    var normalized = reminder.copyWith(
      weekdays: reminder.weekdays.toSet().toList()..sort(),
      timezoneId: _timezoneReady ? tz.local.name : reminder.timezoneId,
    );
    final box = await Hive.openBox(_boxName);

    if (!normalized.enabled) {
      await _cancelReminderSlots();
    } else if (!await _hasActiveSubscription()) {
      await _cancelReminderSlots();
    } else if (!await hasPermission()) {
      await _cancelReminderSlots();
      normalized = normalized.copyWith(enabled: false);
    } else {
      try {
        await _replaceScheduledNotifications(normalized);
      } catch (_) {
        await box.put(
          _reminderKey,
          normalized.copyWith(enabled: false).toJson(),
        );
        rethrow;
      }
    }
    await box.put(_reminderKey, normalized.toJson());
    return normalized;
  }

  /// The only API that requests the operating system notification permission.
  Future<bool> enableNotifications() => _serialize(() async {
        final granted = await requestNotificationPermission();
        if (!granted) {
          final reminder = await fetchReminder();
          await _saveSchedule(reminder.copyWith(enabled: false));
          return false;
        }

        final reminder = (await fetchReminder()).copyWith(enabled: true);
        return (await _saveSchedule(reminder)).enabled;
      });

  Future<void> disableNotifications() => _serialize(() async {
        final reminder = await fetchReminder();
        await _saveSchedule(reminder.copyWith(enabled: false));
      });

  Future<bool> openSystemSettings() async {
    if (!_isSupported) return false;
    return await const MethodChannel('com.mars6.noexcuse/settings')
            .invokeMethod<bool>('openSystemSettings') ??
        false;
  }

  Future<bool> requestNotificationPermission() async {
    if (!_initialized || !_isSupported) return false;

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return await flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      case TargetPlatform.macOS:
        return await flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    MacOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      case TargetPlatform.android:
        final android = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ??
            await android?.areNotificationsEnabled() ??
            false;
      default:
        return false;
    }
  }

  Future<bool> hasPermission() async {
    if (!_initialized || !_isSupported) return false;

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return (await flutterLocalNotificationsPlugin
                    .resolvePlatformSpecificImplementation<
                        IOSFlutterLocalNotificationsPlugin>()
                    ?.checkPermissions())
                ?.isEnabled ??
            false;
      case TargetPlatform.macOS:
        return (await flutterLocalNotificationsPlugin
                    .resolvePlatformSpecificImplementation<
                        MacOSFlutterLocalNotificationsPlugin>()
                    ?.checkPermissions())
                ?.isEnabled ??
            false;
      case TargetPlatform.android:
        return await flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.areNotificationsEnabled() ??
            false;
      default:
        return false;
    }
  }

  Future<void> reconcileSavedSchedule() => _serialize(() async {
        if (!_initialized) return;
        await _refreshTimezone();
        if (!_timezoneReady) return;

        final reminder = await fetchReminder();
        if (!reminder.enabled) return;
        final box = await Hive.openBox(_boxName);
        if (!await _hasActiveSubscription()) {
          await _cancelReminderSlots();
          return;
        }
        if (!await hasPermission()) {
          await _cancelReminderSlots();
          await box.put(
            _reminderKey,
            reminder.copyWith(enabled: false).toJson(),
          );
          return;
        }

        final localized = reminder.copyWith(timezoneId: tz.local.name);
        try {
          await _replaceScheduledNotifications(localized);
          await box.put(_reminderKey, localized.toJson());
        } catch (_) {
          await box.put(
            _reminderKey,
            localized.copyWith(enabled: false).toJson(),
          );
          rethrow;
        }
      });

  Future<void> _replaceScheduledNotifications(Reminder reminder) async {
    if (!_timezoneReady) {
      throw StateError('The device timezone is unavailable.');
    }
    await _cancelReminderSlots();

    try {
      var bodies = _notificationBodies;
      try {
        bodies = motivationalNotificationBodies(
          await OnboardingRepository().fetchAnswers(),
        );
      } catch (error) {
        debugPrint('Unable to personalize reminders: $error');
      }
      final now = tz.TZDateTime.now(tz.local);
      for (final weekday in reminder.weekdays) {
        for (var slot = 0; slot < reminder.promptMinutes.length; slot++) {
          final id = reminderNotificationId(weekday, slot);
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id: id,
            title: 'No Excuses',
            body: bodies[id % bodies.length],
            scheduledDate: nextReminderOccurrence(
              location: tz.local,
              now: now,
              weekday: weekday,
              minuteOfDay: reminder.promptMinutes[slot],
            ),
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'no_excuses_motivation_v2',
                'No Excuses reminders',
                channelDescription:
                    'Direct reminders inside your pressure window.',
                importance: Importance.high,
                priority: Priority.high,
                category: AndroidNotificationCategory.reminder,
              ),
              iOS: DarwinNotificationDetails(
                threadIdentifier: 'motivation',
              ),
              macOS: DarwinNotificationDetails(
                threadIdentifier: 'motivation',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: 'motivation',
          );
        }
      }
    } catch (_) {
      await _cancelReminderSlots();
      rethrow;
    }
  }

  Future<void> _cancelReminderSlots() async {
    if (!_initialized) return;
    for (var id = _firstReminderId;
        id < _firstReminderId + _reminderSlotCount;
        id++) {
      await flutterLocalNotificationsPlugin.cancel(id: id);
    }
  }
}
