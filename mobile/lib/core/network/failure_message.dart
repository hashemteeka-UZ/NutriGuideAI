import '../l10n/app_localizations.dart';
import 'app_failure.dart';

String failureMessage(AppLocalizations l10n, AppFailure failure) {
  return switch (failure) {
    NetworkUnavailable() => l10n.failureNetwork,
    Timeout() => l10n.failureTimeout,
    UnexpectedResponse() => l10n.failureUnexpectedResponse,
    ApiProblem(:final code, :final retryAfter) => switch (code) {
      'RATE_LIMITED' when retryAfter != null => l10n.failureRateLimitedSeconds(
        retryAfter,
      ),
      'RATE_LIMITED' => l10n.failureRateLimited,
      'EMAIL_TAKEN' => l10n.failureEmailTaken,
      'INVALID_CREDENTIALS' => l10n.failureInvalidCredentials,
      'TOKEN_INVALID' => l10n.failureTokenInvalid,
      'PLANNER_BUSY' => l10n.failurePlannerBusy,
      'PLANNER_TIMEOUT' => l10n.failurePlannerTimeout,
      'NOT_ELIGIBLE' => l10n.failureNotEligible,
      'NO_TARGET' => l10n.failureNoTarget,
      'CONDITION_CONFLICT' => l10n.failureConditionConflict,
      'NO_FEASIBLE_PLAN' => l10n.failureNoFeasiblePlan,
      'SWAP_REJECTED' => l10n.failureSwapRejected,
      'PLAN_ITEM_NOT_FOUND' => l10n.failurePlanItemNotFound,
      'PLAN_ITEM_ALREADY_LOGGED' => l10n.failurePlanItemAlreadyLogged,
      'UNAUTHORIZED' => l10n.failureUnauthorized,
      'TOKEN_REUSED' => l10n.failureTokenReused,
      'VALIDATION_ERROR' => l10n.failureValidation,
      'TARGET_VALIDATION' => l10n.failureTargetValidation,
      'NO_WEIGHT' => l10n.failureNoWeight,
      'INVALID_TIMEZONE' => l10n.failureInvalidTimezone,
      'UNKNOWN_CODE' => l10n.failureUnknownCode,
      'PROFILE_NOT_FOUND' => l10n.failureProfileNotFound,
      'MEAL_NOT_FOUND' => l10n.failureMealNotFound,
      'SERVICE_UNAVAILABLE' => l10n.failureServiceUnavailable,
      'INTERNAL_ERROR' => l10n.failureInternal,
      _ => l10n.failureGeneric,
    },
  };
}
