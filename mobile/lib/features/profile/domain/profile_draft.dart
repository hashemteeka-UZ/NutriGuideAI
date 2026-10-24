import 'clock_time.dart';

class ProfileDraft {
  const ProfileDraft({
    this.sex,
    this.birthDate,
    this.heightCm = 170,
    this.weightKg = 70,
    this.goal,
    this.targetWeightKg,
    this.weeklyRateKg,
    this.activity,
    this.conditionCodes = const <String>[],
    this.declinedConditions = false,
    this.allergens = const <String, String>{},
    this.insulin,
    this.wakeMinutes = 7 * 60,
    this.sleepMinutes = 23 * 60,
    this.doctorSetWater,
    this.waterGoalMl,
  });

  final String? sex;
  final DateTime? birthDate;
  final double heightCm;
  final double weightKg;
  final String? goal;
  final double? targetWeightKg;
  final double? weeklyRateKg;
  final String? activity;
  final List<String> conditionCodes;
  final bool declinedConditions;
  final Map<String, String> allergens;
  final bool? insulin;
  final int wakeMinutes;
  final int sleepMinutes;

  /// Null until the fluid step is answered. False means the clinician set no amount.
  final bool? doctorSetWater;
  final int? waterGoalMl;

  bool get hasDiabetes => conditionCodes.contains('DIABETES_T2');

  ProfileDraft copyWith({
    Object? sex = _unset,
    Object? birthDate = _unset,
    double? heightCm,
    double? weightKg,
    Object? goal = _unset,
    Object? targetWeightKg = _unset,
    Object? weeklyRateKg = _unset,
    Object? activity = _unset,
    List<String>? conditionCodes,
    bool? declinedConditions,
    Map<String, String>? allergens,
    Object? insulin = _unset,
    int? wakeMinutes,
    int? sleepMinutes,
    Object? doctorSetWater = _unset,
    Object? waterGoalMl = _unset,
  }) {
    return ProfileDraft(
      sex: sex == _unset ? this.sex : sex as String?,
      birthDate: birthDate == _unset ? this.birthDate : birthDate as DateTime?,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goal: goal == _unset ? this.goal : goal as String?,
      targetWeightKg: targetWeightKg == _unset
          ? this.targetWeightKg
          : targetWeightKg as double?,
      weeklyRateKg: weeklyRateKg == _unset
          ? this.weeklyRateKg
          : weeklyRateKg as double?,
      activity: activity == _unset ? this.activity : activity as String?,
      conditionCodes: conditionCodes ?? this.conditionCodes,
      declinedConditions: declinedConditions ?? this.declinedConditions,
      allergens: allergens ?? this.allergens,
      insulin: insulin == _unset ? this.insulin : insulin as bool?,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      doctorSetWater: doctorSetWater == _unset
          ? this.doctorSetWater
          : doctorSetWater as bool?,
      waterGoalMl: waterGoalMl == _unset
          ? this.waterGoalMl
          : waterGoalMl as int?,
    );
  }
}

const _unset = Object();

DateTime defaultBirthDate(DateTime today) {
  final year = today.year - 30;
  final month = today.month;
  final day = today.day.clamp(1, daysInMonth(year, month)).toInt();
  return DateTime.utc(year, month, day);
}

int ageInYears(DateTime birth, DateTime today) {
  var age = today.year - birth.year;
  final beforeBirthday =
      today.month < birth.month ||
      (today.month == birth.month && today.day < birth.day);
  if (beforeBirthday) {
    age -= 1;
  }
  return age < 0 ? 0 : age;
}

DateTime clampBirthDate(DateTime value, DateTime today) {
  final latest = DateTime.utc(today.year, today.month, today.day);
  final earlyYear = today.year - 100;
  final earliest = DateTime.utc(
    earlyYear,
    today.month,
    today.day.clamp(1, daysInMonth(earlyYear, today.month)).toInt(),
  );
  final day = value.day.clamp(1, daysInMonth(value.year, value.month)).toInt();
  final candidate = DateTime.utc(value.year, value.month, day);
  if (candidate.isAfter(latest)) {
    return latest;
  }
  if (candidate.isBefore(earliest)) {
    return earliest;
  }
  return candidate;
}

String formatIsoDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
