import '../l10n/app_localizations.dart';
import 'app_failure.dart';

String failureMessage(AppLocalizations l10n, AppFailure failure) {
  return switch (failure) {
    NetworkUnavailable() => l10n.failureNetwork,
    Timeout() => l10n.failureTimeout,
    UnexpectedResponse() => l10n.failureUnexpectedResponse,
    ApiProblem(:final code) => switch (code) {
      'RATE_LIMITED' => l10n.failureRateLimited,
      'PLANNER_BUSY' => l10n.failurePlannerBusy,
      'PLANNER_TIMEOUT' => l10n.failurePlannerTimeout,
      'UNAUTHORIZED' => l10n.failureUnauthorized,
      'TOKEN_REUSED' => l10n.failureTokenReused,
      'VALIDATION_ERROR' => l10n.failureValidation,
      'SERVICE_UNAVAILABLE' => l10n.failureServiceUnavailable,
      'INTERNAL_ERROR' => l10n.failureInternal,
      _ => l10n.failureGeneric,
    },
  };
}
