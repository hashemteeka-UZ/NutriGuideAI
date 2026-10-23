// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NutriGuide';

  @override
  String get serverCheckLoading => 'Checking the server';

  @override
  String get serverCheckConnected => 'Server connected';

  @override
  String get serverCheckNeedsUpdate => 'The app needs an update';

  @override
  String get serverCheckRetry => 'Retry';

  @override
  String get serverCheckApiVersionLabel => 'API version';

  @override
  String get serverCheckDatasetVersionLabel => 'Catalog version';

  @override
  String get serverCheckPlannerLabel => 'Planner';

  @override
  String get serverCheckUnknownValue => 'Unknown';

  @override
  String get failureRateLimited => 'Too many requests. Try again shortly.';

  @override
  String get failurePlannerBusy => 'The planner is busy. Try again shortly.';

  @override
  String get failurePlannerTimeout =>
      'The plan could not be built right now. Try again.';

  @override
  String get failureUnauthorized => 'The session has ended. Sign in again.';

  @override
  String get failureTokenReused =>
      'The session ended for security reasons. Sign in again.';

  @override
  String get failureValidation => 'Some of the data is not valid.';

  @override
  String get failureServiceUnavailable =>
      'The service is unavailable right now. Try later.';

  @override
  String get failureInternal => 'The server ran into an error. Try later.';

  @override
  String get failureNetwork => 'Cannot reach the server.';

  @override
  String get failureTimeout => 'The connection to the server timed out.';

  @override
  String get failureUnexpectedResponse =>
      'The server response could not be read.';

  @override
  String get failureGeneric => 'Something unexpected went wrong.';
}
