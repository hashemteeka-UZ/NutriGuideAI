import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/profile/data/profile_editor.dart';
import 'package:nutriguide/features/profile/data/profile_update_body.dart';
import 'package:nutriguide/features/profile/domain/onboarding_steps.dart';
import 'package:nutriguide/features/profile/domain/profile_draft.dart';

void main() {
  final draft = ProfileDraft(
    sex: 'FEMALE',
    birthDate: DateTime(1990, 5, 1),
    goal: 'MAINTAIN',
    activity: 'LIGHT',
    declinedConditions: true,
    cuisines: const <String>['LIBYAN', 'EGYPTIAN'],
  );

  test('onboarding sends the chosen cuisines', () {
    final body = profileUpdateBody(draft, timezone: 'Africa/Tripoli');
    expect(body['cuisines'], <String>['LIBYAN', 'EGYPTIAN']);
  });

  test('an edit sends the edited cuisines, not the saved ones', () {
    final body = editBody(
      draft.copyWith(cuisines: const <String>['LEVANTINE']),
      EditableProfile(
        draft: draft,
        raw: <String, Object?>{
          'timezone': 'Africa/Tripoli',
          'cuisines': <Object?>['LIBYAN'],
          'ingredient_prefs': <Object?>[],
        },
      ),
    );
    expect(body['cuisines'], <String>['LEVANTINE']);
  });

  test('the cuisine step is optional and comes before the day rhythm', () {
    final steps = onboardingSteps(const ProfileDraft());
    expect(
      steps.indexOf(OnboardingStep.cuisine),
      steps.indexOf(OnboardingStep.rhythm) - 1,
    );
    expect(stepIsValid(OnboardingStep.cuisine, const ProfileDraft()), isTrue);
  });
}
