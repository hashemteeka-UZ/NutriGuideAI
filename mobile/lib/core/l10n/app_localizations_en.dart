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

  @override
  String failureRateLimitedSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Too many attempts. Try again after $seconds seconds.',
      one: 'Too many attempts. Try again after 1 second.',
    );
    return '$_temp0';
  }

  @override
  String get failureEmailTaken =>
      'This email is already registered. Sign in instead.';

  @override
  String get failureInvalidCredentials => 'The email or password is incorrect.';

  @override
  String get failureTokenInvalid => 'The session has ended. Sign in again.';

  @override
  String get splashLoading => 'Opening the app';

  @override
  String get welcomeSlide1Title => 'A plan built for you';

  @override
  String get welcomeSlide1Body =>
      'A smart engine picks meals from our local kitchen for your body, goal and taste.';

  @override
  String get welcomeSlide2Title => 'Fits your day';

  @override
  String get welcomeSlide2Body =>
      'Meal and water times follow when you wake up and sleep.';

  @override
  String get welcomeSlide3Title => 'See your progress';

  @override
  String get welcomeSlide3Body =>
      'Clear charts, a weekly report and badges that keep you going.';

  @override
  String get welcomeStart => 'Get started';

  @override
  String get welcomeHaveAccount => 'I have an account';

  @override
  String get authBack => 'Back';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle => 'One minute, then we build your plan';

  @override
  String get registerSubmit => 'Create account';

  @override
  String get registerFooterPrompt => 'Already have an account?';

  @override
  String get registerFooterAction => 'Sign in';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue your plan';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginFooterPrompt => 'No account?';

  @override
  String get loginFooterAction => 'Create one';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authPasswordHint => 'At least 8 characters';

  @override
  String get authEmailRequired => 'Enter an email address.';

  @override
  String get authEmailInvalid => 'The email address is not valid.';

  @override
  String get authPasswordRequired => 'Enter a password.';

  @override
  String get authPasswordTooShort => 'At least 8 characters.';

  @override
  String get authPasswordTooLong => 'At most 128 characters.';

  @override
  String get authPasswordInvalid => 'The password is not valid.';

  @override
  String get onboardingPlaceholder => 'We\'ll set up your plan here soon';

  @override
  String get homeGreeting => 'Hello';

  @override
  String get logout => 'Sign out';
}
