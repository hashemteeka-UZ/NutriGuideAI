import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/profile/domain/pace_rules.dart';

void main() {
  test('60 kg disables rates above 1 percent and 100 kg allows 1.0', () {
    final light = rateChoices(goal: 'LOSE', weightKg: 60);
    expect(_enabled(light, 0.25), isTrue);
    expect(_enabled(light, 0.5), isTrue);
    expect(_enabled(light, 0.75), isFalse);
    expect(_enabled(light, 1), isFalse);

    final heavy = rateChoices(goal: 'LOSE', weightKg: 100);
    expect(_enabled(heavy, 1), isTrue);

    final exact = rateChoices(goal: 'LOSE', weightKg: 50);
    expect(_enabled(exact, 0.5), isTrue);
    expect(_enabled(exact, 0.75), isFalse);
  });

  test('gain offers 0.25 and 0.5 and defaults to 0.25', () {
    final choices = rateChoices(goal: 'GAIN', weightKg: 70);
    expect(choices.map((choice) => choice.rateKg), <double>[0.25, 0.5]);
    expect(choices.every((choice) => choice.enabled), isTrue);
    expect(defaultRateKg(goal: 'GAIN', weightKg: 70), 0.25);
    expect(defaultRateKg(goal: 'LOSE', weightKg: 80), 0.5);
  });

  test('BMI 18.5 rounds up to the next 0.5 kg and hides lose at the bound', () {
    expect(roundUpToHalf(60), 60);
    expect(roundUpToHalf(60.01), 60.5);
    expect(minimumHealthyWeightKg(170), 53.5);

    final floor = minimumHealthyWeightKg(165);
    expect(floor, 50.5);
    expect(loseIsOffered(heightCm: 165, weightKg: floor), isFalse);
    expect(loseIsOffered(heightCm: 165, weightKg: floor + 0.5), isTrue);

    final bounds = targetWeightBounds(
      goal: 'LOSE',
      heightCm: 170,
      weightKg: 80,
    );
    expect(bounds?.minKg, 53.5);
    expect(bounds?.maxKg, lessThan(80));
  });

  test('maintain has no rate or target, and weeks round up', () {
    expect(paceApplies('MAINTAIN'), isFalse);
    expect(rateChoices(goal: 'MAINTAIN', weightKg: 80), isEmpty);
    expect(
      targetWeightBounds(goal: 'MAINTAIN', heightCm: 170, weightKg: 80),
      isNull,
    );
    expect(estimatedWeeks(currentKg: 80, targetKg: 70, weeklyRateKg: 0.5), 20);
    expect(estimatedWeeks(currentKg: 80, targetKg: 70, weeklyRateKg: 0.75), 14);
  });
}

bool _enabled(List<RateChoice> choices, double rate) {
  return choices
      .firstWhere((choice) => (choice.rateKg - rate).abs() < 1e-9)
      .enabled;
}
