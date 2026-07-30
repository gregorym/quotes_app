import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final onboardingRepositoryProvider =
    Provider<OnboardingRepository>((ref) => OnboardingRepository());

List<String> onboardingFrictions(Map<String, dynamic> answers) {
  final stored = answers['frictions'];
  final values = stored is List ? stored : [answers['friction']];
  return values
      .map((value) => value?.toString().trim() ?? '')
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
}

String onboardingFrictionSummary(Map<String, dynamic> answers) =>
    onboardingFrictions(answers).join(' · ');

class OnboardingRepository {
  static const _boxName = 'onboardingBox';
  static const _answersKey = 'answers';
  static const _completedAtKey = 'completedAt';

  Future<Map<String, dynamic>> fetchAnswers() async {
    final box = await Hive.openBox(_boxName);
    return Map<String, dynamic>.from(box.get(_answersKey) as Map? ?? {});
  }

  Future<void> saveAnswer(String stepId, Object? answer) async {
    final box = await Hive.openBox(_boxName);
    final answers = Map<String, dynamic>.from(
      box.get(_answersKey) as Map? ?? {},
    );

    if (answer == null ||
        answer is String && answer.trim().isEmpty ||
        answer is List && answer.isEmpty) {
      answers.remove(stepId);
    } else {
      answers[stepId] = answer;
    }

    await box.put(_answersKey, answers);
  }

  Future<void> complete(Map<String, dynamic> answers) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_answersKey, answers);
    await box.put(_completedAtKey, DateTime.now().toIso8601String());
  }

  Future<bool> hasCompleted() async {
    final box = await Hive.openBox(_boxName);
    return box.containsKey(_completedAtKey);
  }
}
