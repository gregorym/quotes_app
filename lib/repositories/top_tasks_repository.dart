import 'package:hive/hive.dart';

class TopTask {
  const TopTask({
    required this.id,
    required this.text,
    this.completed = false,
  });

  final String id;
  final String text;
  final bool completed;

  TopTask copyWith({String? text, bool? completed}) => TopTask(
        id: id,
        text: text ?? this.text,
        completed: completed ?? this.completed,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'text': text,
        'completed': completed,
      };

  factory TopTask.fromJson(Map<dynamic, dynamic> json) => TopTask(
        id: json['id'] as String,
        text: json['text'] as String,
        completed: json['completed'] as bool? ?? false,
      );
}

List<TopTask> orderTopTasks(Iterable<TopTask> tasks) => [
      ...tasks.where((task) => !task.completed),
      ...tasks.where((task) => task.completed),
    ];

class TopTasksRepository {
  static const _boxName = 'topTasksBox';

  String _todayKey() {
    final today = DateTime.now();
    return '${today.year}-${today.month}-${today.day}';
  }

  Future<List<TopTask>> fetchToday() async {
    final box = await Hive.openBox(_boxName);
    final stored = box.get(_todayKey()) as List? ?? const [];
    return orderTopTasks(
      stored.whereType<Map<dynamic, dynamic>>().map(TopTask.fromJson).take(3),
    );
  }

  Future<void> saveToday(List<TopTask> tasks) async {
    final box = await Hive.openBox(_boxName);
    await box.put(
      _todayKey(),
      orderTopTasks(tasks).take(3).map((task) => task.toJson()).toList(),
    );
  }
}
