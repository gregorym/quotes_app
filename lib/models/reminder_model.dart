import 'package:timezone/timezone.dart' as tz;

class Reminder {
  final String id;
  final int count;
  final int startAt;
  final int endAt;
  final List<bool> days;
  final List<Notification> notifications;
  Reminder({
    required this.id,
    required this.count,
    required this.startAt,
    required this.endAt,
    required this.days,
    this.notifications = const [],
  });

  factory Reminder.fromJson(Map<dynamic, dynamic> json) {
    return Reminder(
      id: json['id'],
      count: json['count'],
      startAt: json['startAt'],
      endAt: json['endAt'],
      days: json['days'],
      notifications: (json['notifications'] as List? ?? []).map((e) => Notification.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'count': count,
      'startAt': startAt,
      'endAt': endAt,
      'days': days,
      'notifications': notifications.map((e) => e.toJson()).toList(),
    };
  }
}

class Notification {
  final int id;
  final tz.TZDateTime? scheduledAt;

  Notification({
    required this.id,
    required this.scheduledAt,
  });

    factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      scheduledAt: tz.TZDateTime.parse(tz.local, json['scheduledAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduledAt': scheduledAt.toString(),
    };
  }
}