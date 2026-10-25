const _supportedConditions = <String>{
  'DIABETES_T2',
  'HYPERTENSION',
  'HEART_DISEASE',
};

const _labels = <String, ({String ar, String en})>{
  'FITS_KCAL_TARGET': (ar: 'مناسبة لسعراتك', en: 'Fits your calories'),
  'HIGH_PROTEIN': (ar: 'غنية بالبروتين', en: 'High in protein'),
  'LOW_SODIUM': (ar: 'قليلة الصوديوم', en: 'Low in sodium'),
  'LOW_SUGAR': (ar: 'قليلة السكر', en: 'Low in sugar'),
  'LOW_SATURATED_FAT': (ar: 'قليلة الدهون المشبعة', en: 'Low in saturated fat'),
  'HIGH_FIBER': (ar: 'غنية بالألياف', en: 'High in fiber'),
  'MATCHES_LIKED_INGREDIENT': (
    ar: 'فيها مكون تحبه',
    en: 'Contains something you like',
  ),
  'NEW_FOR_VARIETY': (ar: 'تنويع جديد', en: 'A new variety'),
};

/// A known reason in [languageCode], or null when the code should stay hidden.
String? reasonLabel(
  String code, {
  required String languageCode,
  String? conditionName,
}) {
  final known = _labels[code];
  if (known != null) {
    return languageCode == 'ar' ? known.ar : known.en;
  }
  const prefix = 'SUITS_CONDITION_';
  if (!code.startsWith(prefix)) {
    return null;
  }
  final condition = code.substring(prefix.length);
  if (!_supportedConditions.contains(condition)) {
    return null;
  }
  final name = conditionName?.trim();
  if (name == null || name.isEmpty) {
    return null;
  }
  return languageCode == 'ar' ? 'مناسبة لـ$name' : 'Suits $name';
}
