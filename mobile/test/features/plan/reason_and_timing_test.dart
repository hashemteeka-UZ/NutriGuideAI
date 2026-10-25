import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/plan/domain/meal_timing.dart';
import 'package:nutriguide/features/plan/presentation/reason_labels.dart';

void main() {
  test('known reason codes and a hidden unknown', () {
    expect(
      reasonLabel('FITS_KCAL_TARGET', languageCode: 'ar'),
      'مناسبة لسعراتك',
    );
    expect(reasonLabel('HIGH_PROTEIN', languageCode: 'en'), 'High in protein');
    expect(reasonLabel('LOW_SODIUM', languageCode: 'ar'), 'قليلة الصوديوم');
    expect(reasonLabel('LOW_SUGAR', languageCode: 'en'), 'Low in sugar');
    expect(
      reasonLabel('LOW_SATURATED_FAT', languageCode: 'ar'),
      'قليلة الدهون المشبعة',
    );
    expect(reasonLabel('HIGH_FIBER', languageCode: 'en'), 'High in fiber');
    expect(
      reasonLabel('MATCHES_LIKED_INGREDIENT', languageCode: 'ar'),
      'فيها مكون تحبه',
    );
    expect(reasonLabel('NEW_FOR_VARIETY', languageCode: 'en'), 'A new variety');
    expect(reasonLabel('NOT_A_CODE', languageCode: 'ar'), isNull);
  });

  test('SUITS_CONDITION_HYPERTENSION uses the reference name', () {
    expect(
      reasonLabel(
        'SUITS_CONDITION_HYPERTENSION',
        languageCode: 'ar',
        conditionName: 'ارتفاع ضغط الدم',
      ),
      'مناسبة لـارتفاع ضغط الدم',
    );
    expect(
      reasonLabel(
        'SUITS_CONDITION_DIABETES_INSULIN',
        languageCode: 'ar',
        conditionName: 'إنسولين',
      ),
      isNull,
    );
  });

  test('meal state before, inside and after the window', () {
    expect(
      mealWhen(
        logged: false,
        start: '12:00',
        end: '14:00',
        nowMinutes: 11 * 60,
      ),
      MealWhen.upcoming,
    );
    expect(
      mealWhen(
        logged: false,
        start: '12:00',
        end: '14:00',
        nowMinutes: 13 * 60,
      ),
      MealWhen.now,
    );
    expect(
      mealWhen(
        logged: false,
        start: '12:00',
        end: '14:00',
        nowMinutes: 15 * 60,
      ),
      MealWhen.missed,
    );
  });

  test('logged wins and a missing window has no badge', () {
    expect(
      mealWhen(logged: true, start: '12:00', end: '14:00', nowMinutes: 8 * 60),
      MealWhen.logged,
    );
    expect(
      mealWhen(logged: false, start: null, end: null, nowMinutes: 8 * 60),
      MealWhen.untimed,
    );
  });
}
