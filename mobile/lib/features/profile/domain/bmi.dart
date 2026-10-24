enum BmiBand { under, normal, over, high }

double bmiValue({required double heightCm, required double weightKg}) {
  final meters = heightCm / 100;
  return weightKg / (meters * meters);
}

BmiBand bmiBand(double bmi) {
  if (bmi < 18.5) {
    return BmiBand.under;
  }
  if (bmi < 25) {
    return BmiBand.normal;
  }
  if (bmi < 30) {
    return BmiBand.over;
  }
  return BmiBand.high;
}

/// Position of [bmi] on a scale drawn from 15 to 40.
double bmiMarker(double bmi) {
  final raw = (bmi - 15) / (40 - 15);
  if (raw < 0) {
    return 0;
  }
  if (raw > 1) {
    return 1;
  }
  return raw;
}
