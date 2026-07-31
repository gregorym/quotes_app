import 'package:hive/hive.dart';

class TopTask {
  const TopTask({
    required this.id,
    required this.text,
    this.completed = false,
    this.completedAt,
  });

  final String id;
  final String text;
  final bool completed;
  final DateTime? completedAt;

  TopTask copyWith({
    String? text,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) =>
      TopTask(
        id: id,
        text: text ?? this.text,
        completed: completed ?? this.completed,
        completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'text': text,
        'completed': completed,
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  factory TopTask.fromJson(Map<dynamic, dynamic> json) => TopTask(
        id: json['id'] as String,
        text: json['text'] as String,
        completed: json['completed'] as bool? ?? false,
        completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      );
}

List<TopTask> orderTopTasks(Iterable<TopTask> tasks) => [
      ...tasks.where((task) => !task.completed),
      ...tasks.where((task) => task.completed),
    ];

class TopTasksRepository {
  static const _boxName = 'topTasksBox';
  static const _activeKey = 'active';
  static const _historyKey = 'history';
  static const _visibleKey = 'visible';

  Future<bool> fetchVisible() async =>
      (await Hive.openBox(_boxName)).get(_visibleKey) as bool? ?? true;

  Future<void> saveVisible(bool visible) async =>
      (await Hive.openBox(_boxName)).put(_visibleKey, visible);

  Future<List<TopTask>> fetchActive({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final box = await Hive.openBox(_boxName);
    final active = await _readActive(box, current);
    return _archiveBeforeSix(box, active, current);
  }

  Future<List<TopTask>> saveActive(
    List<TopTask> tasks, {
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final box = await Hive.openBox(_boxName);
    final active = orderTopTasks(tasks.take(3).map((task) {
      if (!task.completed || task.completedAt != null) return task;
      return task.copyWith(completedAt: current);
    }));
    return _archiveBeforeSix(box, active, current, persist: true);
  }

  Future<List<TopTask>> fetchHistory({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final box = await Hive.openBox(_boxName);
    final active = await _readActive(box, current);
    final kept = await _archiveBeforeSix(box, active, current);
    final history = _decode(box.get(_historyKey));
    final tasksById = <String, TopTask>{
      for (final task in history) task.id: task,
      for (final task in kept.where((task) => task.completed)) task.id: task,
    };
    final tasks = tasksById.values
        .where((task) => task.completedAt != null)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return tasks;
  }

  Future<List<TopTask>> _readActive(Box<dynamic> box, DateTime now) async {
    if (box.containsKey(_activeKey)) {
      final stored = _decode(box.get(_activeKey));
      final active = _withCompletionDates(stored, now);
      if (stored.any((task) => task.completed && task.completedAt == null)) {
        await box.put(_activeKey, active.map((task) => task.toJson()).toList());
      }
      return active;
    }

    String? latestKey;
    DateTime? latestDate;
    for (final key in box.keys.whereType<String>()) {
      final date = _legacyDate(key);
      if (date != null && (latestDate == null || date.isAfter(latestDate))) {
        latestDate = date;
        latestKey = key;
      }
    }
    if (latestKey == null) return const [];
    final active = _withCompletionDates(
      _decode(box.get(latestKey)),
      now,
    );
    await box.put(_activeKey, active.map((task) => task.toJson()).toList());
    return active;
  }

  Future<List<TopTask>> _archiveBeforeSix(
    Box<dynamic> box,
    List<TopTask> tasks,
    DateTime now, {
    bool persist = false,
  }) async {
    final cutoff = _latestSixAm(now);
    final archived = tasks
        .where((task) =>
            task.completed &&
            task.completedAt != null &&
            task.completedAt!.isBefore(cutoff))
        .toList();
    final active = orderTopTasks(
      tasks.where((task) => !archived.any((old) => old.id == task.id)).take(3),
    );
    if (archived.isNotEmpty) {
      final history = <String, TopTask>{
        for (final task in _decode(box.get(_historyKey))) task.id: task,
        for (final task in archived) task.id: task,
      }.values.toList();
      await box.put(_historyKey, history.map((task) => task.toJson()).toList());
    }
    if (persist || archived.isNotEmpty) {
      await box.put(_activeKey, active.map((task) => task.toJson()).toList());
    }
    return active;
  }

  List<TopTask> _decode(dynamic value) => (value as List? ?? const [])
      .whereType<Map<dynamic, dynamic>>()
      .map(TopTask.fromJson)
      .toList();

  List<TopTask> _withCompletionDates(List<TopTask> tasks, DateTime now) => tasks
      .map((task) => task.completed && task.completedAt == null
          ? task.copyWith(completedAt: now)
          : task)
      .toList();

  DateTime _latestSixAm(DateTime now) {
    final today = DateTime(now.year, now.month, now.day, 6);
    return now.isBefore(today)
        ? today.subtract(const Duration(days: 1))
        : today;
  }

  DateTime? _legacyDate(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }
}
