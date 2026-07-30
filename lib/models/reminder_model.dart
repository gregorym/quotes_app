class Reminder {
  static const schemaVersion = 2;

  const Reminder({
    this.enabled = false,
    this.count = 3,
    this.startMinute = 9 * 60,
    this.endMinute = 18 * 60,
    this.weekdays = const [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ],
    this.timezoneId = '',
  });

  final bool enabled;
  final int count;
  final int startMinute;
  final int endMinute;
  final List<int> weekdays;
  final String timezoneId;

  /// Sunday-first compatibility for the existing streak UI.
  List<bool> get days => List.generate(7, (index) {
        final weekday = index == 0 ? DateTime.sunday : index;
        return weekdays.contains(weekday);
      });

  List<int> get promptMinutes => List.generate(
        count,
        (index) =>
            startMinute +
            ((endMinute - startMinute) * (index + 1) / (count + 1)).round(),
      );

  String? get validationError {
    if (weekdays.isEmpty) return 'Choose at least one day.';
    if (count < 1 || count > 6) return 'Choose between 1 and 6 calls per day.';
    if (startMinute < 0 ||
        startMinute >= 24 * 60 ||
        endMinute < 0 ||
        endMinute >= 24 * 60) {
      return 'Choose valid start and end times.';
    }
    if (endMinute - startMinute < 60) {
      return 'Give the pressure window at least one hour.';
    }
    if (weekdays.any((day) => day < DateTime.monday || day > DateTime.sunday)) {
      return 'Choose valid weekdays.';
    }
    return null;
  }

  Reminder copyWith({
    bool? enabled,
    int? count,
    int? startMinute,
    int? endMinute,
    List<int>? weekdays,
    String? timezoneId,
  }) {
    return Reminder(
      enabled: enabled ?? this.enabled,
      count: count ?? this.count,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      weekdays: weekdays ?? this.weekdays,
      timezoneId: timezoneId ?? this.timezoneId,
    );
  }

  factory Reminder.fromJson(Map<dynamic, dynamic> json) {
    if (json['version'] != schemaVersion) return _fromLegacyJson(json);

    final weekdays = (json['weekdays'] as List? ?? const [])
        .whereType<num>()
        .map((day) => day.toInt())
        .toSet()
        .toList()
      ..sort();

    return Reminder(
      enabled: json['enabled'] == true,
      count: (json['count'] as num?)?.toInt() ?? 3,
      startMinute: (json['startMinute'] as num?)?.toInt() ?? 9 * 60,
      endMinute: (json['endMinute'] as num?)?.toInt() ?? 18 * 60,
      weekdays: weekdays,
      timezoneId: json['timezoneId']?.toString() ?? '',
    );
  }

  static Reminder _fromLegacyJson(Map<dynamic, dynamic> json) {
    final legacyDays = (json['days'] as List? ?? const []).cast<dynamic>();
    final weekdays = <int>[];
    for (var index = 0; index < legacyDays.length && index < 7; index++) {
      if (legacyDays[index] == true) {
        weekdays.add(index == 0 ? DateTime.sunday : index);
      }
    }

    int fromHhmm(Object? value, int fallback) {
      final hhmm = value is num ? value.toInt() : fallback;
      final hour = hhmm ~/ 100;
      final minute = hhmm % 100;
      return hour.clamp(0, 23) * 60 + minute.clamp(0, 59);
    }

    return Reminder(
      count: ((json['count'] as num?)?.toInt() ?? 3).clamp(1, 6),
      startMinute: fromHhmm(json['startAt'], 900),
      endMinute: fromHhmm(json['endAt'], 1800),
      weekdays: weekdays.isEmpty
          ? const [
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
            ]
          : weekdays,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': schemaVersion,
        'enabled': enabled,
        'count': count,
        'startMinute': startMinute,
        'endMinute': endMinute,
        'weekdays': weekdays,
        'timezoneId': timezoneId,
      };
}
