import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quotes_app/repositories/onboarding_repository.dart';

void main() {
  test('reads multiple frictions and legacy single-friction answers', () {
    expect(
      onboardingFrictions({
        'frictions': ['Procrastination', 'Distraction', 'Procrastination'],
      }),
      ['Procrastination', 'Distraction'],
    );
    expect(
      onboardingFrictionSummary({'friction': 'Perfectionism'}),
      'Perfectionism',
    );
  });

  test('stores and removes onboarding answers locally', () async {
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);

    final repository = OnboardingRepository();
    await repository.saveAnswer('age', '25-34 years old');
    expect(await repository.fetchAnswers(), {'age': '25-34 years old'});

    await repository.saveAnswer('age', '');
    expect(await repository.fetchAnswers(), isEmpty);

    await Hive.close();
    await dir.delete(recursive: true);
  });
}
