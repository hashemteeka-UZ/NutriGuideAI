import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/profile.dart';
import 'package:nutriguide/core/network/app_failure.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/profile/data/profile_editor.dart';
import 'package:nutriguide/features/profile/domain/profile_draft.dart';
import 'package:nutriguide/features/profile/domain/profile_result.dart';
import 'package:nutriguide/features/profile/presentation/onboarding_controller.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/onboarding_fakes.dart';
import '../../support/pump_app.dart';

const _profileJson = <String, Object?>{
  'sex': 'FEMALE',
  'birth_date': '1995-04-12',
  'height_cm': 165,
  'latest_weight_kg': 78.5,
  'latest_weight_on': '2026-10-25',
  'activity_level': 'LIGHT',
  'goal_type': 'LOSE',
  'target_weight_kg': 70,
  'weekly_rate_kg': 0.5,
  'conditions': <Object?>[
    <String, Object?>{'code': 'HYPERTENSION', 'severity': null},
    <String, Object?>{'code': 'DIABETES_T2', 'severity': null},
  ],
  'allergens': <Object?>[
    <String, Object?>{'code': 'PEANUT', 'severity': 'SEVERE'},
  ],
  'ingredient_prefs': <Object?>[],
  'cuisines': <Object?>[],
  'wake_time': '06:30',
  'sleep_time': '22:45',
  'timezone': 'Africa/Tripoli',
  'water_goal_ml': 1800,
};

EditableProfile _editable() {
  final raw = Map<String, Object?>.of(_profileJson)
    ..['ingredient_prefs'] = <Object?>[
      <String, Object?>{'ingredient_id': 7, 'stance': 'LIKE'},
    ]
    ..['cuisines'] = <Object?>['LIBYAN'];
  return EditableProfile(
    draft: draftFromProfile(Profile.fromJson(_profileJson)),
    raw: raw,
  );
}

class _FakeEditor implements ProfileEditor {
  _FakeEditor({this.loadError, this.result});

  final Object? loadError;
  final ProfileResult? result;
  ProfileDraft? saved;
  int saves = 0;

  @override
  Future<EditableProfile> load() async {
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return _editable();
  }

  @override
  Future<ProfileResult> save(ProfileDraft draft, EditableProfile from) async {
    saves += 1;
    saved = draft;
    return result ?? sampleResult();
  }
}

void main() {
  test('the saved profile fills the draft (#309)', () {
    final draft = _editable().draft;
    expect(draft.sex, 'FEMALE');
    expect(draft.birthDate, DateTime(1995, 4, 12));
    expect(draft.heightCm, 165);
    expect(draft.weightKg, 78.5);
    expect(draft.goal, 'LOSE');
    expect(draft.targetWeightKg, 70);
    expect(draft.weeklyRateKg, 0.5);
    expect(draft.activity, 'LIGHT');
    expect(draft.conditionCodes, <String>['HYPERTENSION', 'DIABETES_T2']);
    expect(draft.insulin, isFalse);
    expect(draft.allergens, <String, String>{'PEANUT': 'SEVERE'});
    expect(draft.wakeMinutes, 6 * 60 + 30);
    expect(draft.sleepMinutes, 22 * 60 + 45);
    expect(draft.doctorSetWater, isNull); // no fluid-limited condition
  });

  test(
    'the edit body sends the change, never the weight, and keeps the rest',
    () {
      final from = _editable();
      final body = editBody(from.draft.copyWith(activity: 'MODERATE'), from);
      expect(body['activity_level'], 'MODERATE');
      expect(body.containsKey('current_weight_kg'), isFalse);
      expect(body['timezone'], 'Africa/Tripoli');
      expect(body['cuisines'], <Object?>['LIBYAN']);
      expect((body['ingredient_prefs']! as List<Object?>), hasLength(1));
      expect(body['water_goal_ml'], 1800);
      expect(body['sex'], 'FEMALE');
    },
  );

  Future<_FakeEditor> open(WidgetTester tester, {_FakeEditor? editor}) async {
    final fake = editor ?? _FakeEditor();
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      extra: <Override>[profileEditorProvider.overrideWithValue(fake)],
    );
    await tester.tap(find.byKey(const Key('tab-me')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-edit')));
    await tester.pumpAndSettle();
    return fake;
  }

  testNutriguide('edit: prefilled list, change activity, save, result', (
    tester,
  ) async {
    final fake = await open(tester);
    expect(find.byKey(const Key('edit-step-list')), findsOneWidget);
    expect(find.text('النشاط'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('edit-profile-screen'))),
    );
    expect(
      container.read(onboardingControllerProvider).draft.activity,
      'LIGHT',
    );

    await tester.tap(find.byKey(const Key('edit-step-activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onb-activity-MODERATE')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-step-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-save')));
    await tester.pumpAndSettle();
    expect(fake.saves, 1);
    expect(fake.saved!.activity, 'MODERATE');
    expect(fake.saved!.weightKg, 78.5);
    expect(find.byKey(const Key('edit-saved-note')), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-screen')), findsOneWidget);
    expect(find.text('الخطط القادمة ستُبنى بهدفك الجديد'), findsOneWidget);
  });

  testNutriguide('edit: weight is not edited here', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('edit-step-measure')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-weight-hint')), findsOneWidget);
  });

  testNutriguide('edit: an ineligible result shows the general mode', (
    tester,
  ) async {
    await open(
      tester,
      editor: _FakeEditor(result: sampleResult(eligible: false)),
    );
    await tester.tap(find.byKey(const Key('edit-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onb-general')), findsOneWidget);
  });

  testNutriguide('edit: offline leaves nothing to save', (tester) async {
    await open(
      tester,
      editor: _FakeEditor(loadError: const NetworkUnavailable()),
    );
    expect(find.byKey(const Key('edit-offline')), findsOneWidget);
    expect(find.text('دون اتصال · تعرض آخر نسخة محفوظة'), findsOneWidget);
    expect(find.byKey(const Key('edit-save')), findsNothing);
  });
}

FakeAuthRepository _signedIn() {
  return FakeAuthRepository(
    restored: const SignedIn(
      account: AccountInfo(hasProfile: true, email: 'a@b.co'),
    ),
  );
}
