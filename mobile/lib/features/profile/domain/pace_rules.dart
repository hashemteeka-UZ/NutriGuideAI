import 'dart:math' as math;

class RateChoice {
  const RateChoice({required this.rateKg, required this.enabled});

  final double rateKg;
  final bool enabled;
}

class TargetBounds {
  const TargetBounds({required this.minKg, required this.maxKg});

  final double minKg;
  final double maxKg;

  bool contains(double kg) => kg + 1e-9 >= minKg && kg <= maxKg + 1e-9;
}

const loseRatesKg = <double>[0.25, 0.5, 0.75, 1];
const gainRatesKg = <double>[0.25, 0.5];

bool paceApplies(String? goal) => goal == 'LOSE' || goal == 'GAIN';

double roundUpToHalf(double value) {
  final scaled = value * 2;
  final nearest = scaled.roundToDouble();
  if ((scaled - nearest).abs() < 1e-6) {
    return nearest / 2;
  }
  return scaled.ceilToDouble() / 2;
}

double roundDownToHalf(double value) {
  final scaled = value * 2;
  final nearest = scaled.roundToDouble();
  if ((scaled - nearest).abs() < 1e-6) {
    return nearest / 2;
  }
  return scaled.floorToDouble() / 2;
}

double roundToHalf(double value) => (value * 2).roundToDouble() / 2;

/// Lowest weight at BMI 18.5 for [heightCm], rounded up to the next 0.5 kg.
double minimumHealthyWeightKg(double heightCm) {
  final meters = heightCm / 100;
  return roundUpToHalf(18.5 * meters * meters);
}

bool loseIsOffered({required double heightCm, required double weightKg}) {
  return weightKg > minimumHealthyWeightKg(heightCm) + 1e-9;
}

bool gainIsOffered({required double weightKg}) => weightKg < 300 - 1e-9;

List<RateChoice> rateChoices({
  required String? goal,
  required double weightKg,
}) {
  if (goal == 'GAIN') {
    return <RateChoice>[
      for (final rate in gainRatesKg)
        RateChoice(rateKg: rate, enabled: rate <= 0.5 + 1e-9),
    ];
  }
  if (goal == 'LOSE') {
    final cap = weightKg * 0.01;
    return <RateChoice>[
      for (final rate in loseRatesKg)
        RateChoice(rateKg: rate, enabled: rate <= cap + 1e-9),
    ];
  }
  return const <RateChoice>[];
}

bool rateIsAllowed({
  required String? goal,
  required double weightKg,
  required double rateKg,
}) {
  for (final choice in rateChoices(goal: goal, weightKg: weightKg)) {
    if ((choice.rateKg - rateKg).abs() < 1e-9) {
      return choice.enabled;
    }
  }
  return false;
}

double? defaultRateKg({required String? goal, required double weightKg}) {
  final choices = rateChoices(goal: goal, weightKg: weightKg);
  if (choices.isEmpty) {
    return null;
  }
  final preferred = goal == 'GAIN' ? 0.25 : 0.5;
  for (final choice in choices) {
    if ((choice.rateKg - preferred).abs() < 1e-9 && choice.enabled) {
      return choice.rateKg;
    }
  }
  for (final choice in choices.reversed) {
    if (choice.enabled) {
      return choice.rateKg;
    }
  }
  return null;
}

TargetBounds? targetWeightBounds({
  required String? goal,
  required double heightCm,
  required double weightKg,
}) {
  if (goal == 'LOSE') {
    if (!loseIsOffered(heightCm: heightCm, weightKg: weightKg)) {
      return null;
    }
    final minKg = math.max(30, minimumHealthyWeightKg(heightCm)).toDouble();
    final maxKg = math.min(300, roundDownToHalf(weightKg - 0.5)).toDouble();
    if (minKg > maxKg + 1e-9) {
      return null;
    }
    return TargetBounds(minKg: minKg, maxKg: maxKg);
  }
  if (goal == 'GAIN') {
    if (!gainIsOffered(weightKg: weightKg)) {
      return null;
    }
    final minKg = math.max(30, roundUpToHalf(weightKg + 0.5)).toDouble();
    const maxKg = 300.0;
    if (minKg > maxKg + 1e-9) {
      return null;
    }
    return TargetBounds(minKg: minKg, maxKg: maxKg);
  }
  return null;
}

double? defaultTargetKg({
  required String? goal,
  required double heightCm,
  required double weightKg,
}) {
  final bounds = targetWeightBounds(
    goal: goal,
    heightCm: heightCm,
    weightKg: weightKg,
  );
  if (bounds == null) {
    return null;
  }
  final preferred = goal == 'LOSE' ? weightKg - 5 : weightKg + 5;
  return roundToHalf(preferred).clamp(bounds.minKg, bounds.maxKg).toDouble();
}

int estimatedWeeks({
  required double currentKg,
  required double targetKg,
  required double weeklyRateKg,
}) {
  if (weeklyRateKg <= 0) {
    throw ArgumentError.value(weeklyRateKg, 'weeklyRateKg');
  }
  return ((currentKg - targetKg).abs() / weeklyRateKg).ceil();
}

DateTime estimatedArrival(DateTime today, int weeks) {
  final start = DateTime.utc(today.year, today.month, today.day);
  return start.add(Duration(days: weeks * 7));
}
