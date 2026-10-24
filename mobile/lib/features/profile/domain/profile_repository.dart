import 'profile_draft.dart';
import 'profile_result.dart';

class ProfileSaveOutcome {
  const ProfileSaveOutcome({
    required this.result,
    required this.usedUtcFallback,
  });

  final ProfileResult result;
  final bool usedUtcFallback;
}

abstract interface class ProfileRepository {
  Future<ProfileSaveOutcome> save(
    ProfileDraft draft, {
    required String timezone,
  });
}
