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
  String get homeGreeting => 'Hello';

  @override
  String get logout => 'Sign out';

  @override
  String get failureTargetValidation =>
      'The target weight or pace is not valid.';

  @override
  String get failureNoWeight => 'The weight is missing. Try again.';

  @override
  String get failureInvalidTimezone => 'The timezone was not accepted.';

  @override
  String get failureUnknownCode => 'One of the choices is not recognized.';

  @override
  String get failureProfileNotFound => 'The profile was not found.';

  @override
  String get onbContinue => 'Continue';

  @override
  String get onbBack => 'Back';

  @override
  String get onbRetry => 'Try again';

  @override
  String onbStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onbChecking => 'Checking your account...';

  @override
  String get onbCalculating => 'Calculating your needs...';

  @override
  String get onbReferenceError => 'The setup lists could not be loaded.';

  @override
  String get onbJustForYou => 'Just for you';

  @override
  String get onbBecauseWeight => 'because your goal changes weight';

  @override
  String get onbBecauseHeart =>
      'because heart health needs a fluid plan with your doctor';

  @override
  String get onbAboutTitle => 'Tell us about you';

  @override
  String get onbAboutSubtitle => 'Sex and age change your daily energy needs';

  @override
  String get onbSexMale => 'Male';

  @override
  String get onbSexFemale => 'Female';

  @override
  String onbAge(String age) {
    return 'Age: $age years';
  }

  @override
  String get onbMeasureTitle => 'Height and weight';

  @override
  String get onbMeasureSubtitle => 'Used for your needs and your progress';

  @override
  String get onbHeight => 'Height';

  @override
  String get onbWeight => 'Weight';

  @override
  String get onbCm => 'cm';

  @override
  String get onbKg => 'kg';

  @override
  String get onbBmi => 'Body mass index';

  @override
  String get onbBmiUnder => 'Below normal';

  @override
  String get onbBmiNormal => 'Normal';

  @override
  String get onbBmiOver => 'Above normal';

  @override
  String get onbBmiHigh => 'High';

  @override
  String get onbBmiExplainTitle => 'What is BMI?';

  @override
  String get onbBmiExplainBody =>
      'A rough number from weight and height (kg ÷ m²). We use it only as a general guide; it does not measure fat or muscle.';

  @override
  String onbGoalTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'What is your goal?',
      'other': 'What is your goal?',
    });
    return '$_temp0';
  }

  @override
  String get onbGoalSubtitle => 'We build your daily calories around it';

  @override
  String get onbGoalLose => 'Lose weight';

  @override
  String get onbGoalLoseBody => 'A moderate, safe calorie deficit';

  @override
  String get onbGoalMaintain => 'Keep my weight';

  @override
  String get onbGoalMaintainBody => 'Balanced eating to keep your energy';

  @override
  String get onbGoalGain => 'Gain weight';

  @override
  String get onbGoalGainBody => 'A planned calorie surplus';

  @override
  String get onbLoseUnavailable =>
      'We do not suggest a goal below a healthy weight for your height';

  @override
  String onbPaceLoseTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'Where do you want to get to?',
      'other': 'Where do you want to get to?',
    });
    return '$_temp0';
  }

  @override
  String onbPaceGainTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'How much do you want to gain?',
      'other': 'How much do you want to gain?',
    });
    return '$_temp0';
  }

  @override
  String onbPaceSubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'Pick your target weight and pace',
      'other': 'Pick your target weight and pace',
    });
    return '$_temp0';
  }

  @override
  String get onbTargetWeight => 'Target weight';

  @override
  String get onbPaceHeading => 'Pace';

  @override
  String get onbRateGentle => 'Gentle · easiest to keep';

  @override
  String get onbRateGentleBody => '0.25 kg a week';

  @override
  String get onbRateBalanced => 'Balanced · recommended';

  @override
  String get onbRateBalancedBody => '0.5 kg a week';

  @override
  String get onbRateFaster => 'Faster';

  @override
  String get onbRateFasterBody => '0.75 kg a week';

  @override
  String get onbRateMax => 'Maximum';

  @override
  String get onbRateMaxBody => '1 kg a week';

  @override
  String get onbRateUnavailable =>
      'Not available for your weight (over 1% a week)';

  @override
  String get onbGainCap => 'Safe gain is up to 0.5 kg a week';

  @override
  String onbArrival(String sex, String weight, String weeks, String when) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'You reach $weight kg in about $weeks weeks, around $when',
      'other': 'You reach $weight kg in about $weeks weeks, around $when',
    });
    return '$_temp0';
  }

  @override
  String onbActivityTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'How active is your day?',
      'other': 'How active is your day?',
    });
    return '$_temp0';
  }

  @override
  String onbActivitySubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'Pick what describes a normal week',
      'other': 'Pick what describes a normal week',
    });
    return '$_temp0';
  }

  @override
  String get onbActSedentary => 'Mostly sitting';

  @override
  String get onbActSedentaryBody => 'Desk work, little walking';

  @override
  String get onbActLight => 'Lightly active';

  @override
  String get onbActLightBody => 'Walks or light exercise 1–3 days';

  @override
  String get onbActModerate => 'Moderately active';

  @override
  String get onbActModerateBody => 'Moderate exercise 3–5 days';

  @override
  String get onbActHigh => 'Very active';

  @override
  String get onbActHighBody => 'Hard exercise 6–7 days';

  @override
  String get onbActAthlete => 'Athlete';

  @override
  String get onbActAthleteBody =>
      'Daily intense training or hard physical work';

  @override
  String onbActivityTip(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'Activity sets how much you burn. If unsure between two, pick the lower one.',
      'other': 'Activity sets how much you burn. If unsure between two, pick the lower one.',
    });
    return '$_temp0';
  }

  @override
  String onbCareTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'Anything we should keep in mind?',
      'other': 'Anything we should keep in mind?',
    });
    return '$_temp0';
  }

  @override
  String onbCareSubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'Pick what applies and we choose meals that suit it',
      'other': 'Pick what applies and we choose meals that suit it',
    });
    return '$_temp0';
  }

  @override
  String get onbCareNone => 'Nothing';

  @override
  String get onbCareNoneBody => 'Just healthy, balanced eating';

  @override
  String get onbCareDiabetesBody => 'Less sugar, carbs spread across meals';

  @override
  String get onbCarePressureBody => 'Less salt in your daily meals';

  @override
  String get onbCareHeartBody => 'Healthy fats and less salt';

  @override
  String get onbCareExplainTitle => 'How do we handle this?';

  @override
  String get onbCareExplainBody =>
      'NutriGuide does not treat any condition and does not replace your doctor. It only avoids what may not suit you, like extra salt or sugar, following WHO and health association guidance.';

  @override
  String onbAllergyTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'Any ingredient you avoid?',
      'other': 'Any ingredient you avoid?',
    });
    return '$_temp0';
  }

  @override
  String onbAllergySubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'Tap once to avoid, twice for a severe allergy',
      'other': 'Tap once to avoid, twice for a severe allergy',
    });
    return '$_temp0';
  }

  @override
  String get onbAvoid => 'Avoid';

  @override
  String get onbSevere => 'Severe';

  @override
  String get onbAllergyTip =>
      '“Avoid” keeps it out of your plan. “Severe” also warns you clearly if it appears in any meal you browse.';

  @override
  String get onbSafetyTitle => 'One last check';

  @override
  String onbSafetySubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'So we are sure a personal plan suits you',
      'other': 'So we are sure a personal plan suits you',
    });
    return '$_temp0';
  }

  @override
  String onbInsulinQuestion(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'Do you use insulin?',
      'other': 'Do you use insulin?',
    });
    return '$_temp0';
  }

  @override
  String get onbYes => 'Yes';

  @override
  String get onbNo => 'No';

  @override
  String get onbWhyAsk => 'Why do we ask?';

  @override
  String get onbWhyAskBody =>
      'Insulin use needs carbohydrate planning tied to doses, which this app does not cover, so the general mode is used.';

  @override
  String onbRhythmTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'What does your day look like?',
      'other': 'What does your day look like?',
    });
    return '$_temp0';
  }

  @override
  String get onbRhythmSubtitle =>
      'We arrange meals and water around when you wake and sleep';

  @override
  String get onbWake => 'I wake up';

  @override
  String get onbSleep => 'I sleep';

  @override
  String get onbSuggestedDay => 'Your suggested day';

  @override
  String get onbBreakfast => 'Breakfast';

  @override
  String get onbLunch => 'Lunch';

  @override
  String get onbSnack => 'Snack';

  @override
  String get onbDinner => 'Dinner';

  @override
  String onbWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String get onbFluidTitle => 'Water, with your doctor';

  @override
  String get onbFluidSubtitle =>
      'For some heart conditions a doctor sets a daily fluid amount';

  @override
  String get onbFluidNone => 'My doctor did not set an amount';

  @override
  String get onbFluidNoneBody =>
      'That is fine. We will record what you drink without setting a goal or reminding you to drink.';

  @override
  String get onbFluidDoctor => 'My doctor set a daily amount';

  @override
  String get onbFluidRange => 'Between 500 and 5000 ml';

  @override
  String get onbMl => 'ml';

  @override
  String get onbResultTitle => 'Your daily needs, calculated for you';

  @override
  String get onbDailyCalories => 'Daily calories';

  @override
  String get onbLineLose => 'To lose weight';

  @override
  String get onbLineMaintain => 'To keep your weight';

  @override
  String get onbLineGain => 'To gain weight';

  @override
  String get onbProtein => 'Protein';

  @override
  String get onbCarbs => 'Carbs';

  @override
  String get onbFat => 'Fat';

  @override
  String get onbFiber => 'Fiber';

  @override
  String get onbWater => 'Water';

  @override
  String get onbGrams => 'g';

  @override
  String onbMacroShare(String share) {
    return '$share of calories';
  }

  @override
  String get onbWaterClinician => 'With your doctor';

  @override
  String get onbWaterNone => 'No goal';

  @override
  String get onbHowTitle => 'How did we calculate this?';

  @override
  String get onbHowRestTitle => 'Resting energy (Mifflin-St Jeor)';

  @override
  String get onbHowRestBody =>
      'This is the energy your body needs at complete rest, from the Mifflin-St Jeor equation.';

  @override
  String get onbHowActivityTitle => '× your activity factor';

  @override
  String onbHowActivityBody(String factor) {
    return 'We multiply resting energy by your activity factor ($factor) to get what you burn on a usual day.';
  }

  @override
  String get onbHowDeficitTitle => '− weight-loss deficit';

  @override
  String get onbHowDeficitBody =>
      'This is what we subtract so your weight falls at the pace you chose.';

  @override
  String get onbHowSurplusTitle => '+ gain surplus';

  @override
  String get onbHowSurplusBody =>
      'This is what we add so your weight rises at the pace you chose.';

  @override
  String get onbHowFloorTitle => 'Calories were raised to the safe minimum';

  @override
  String get onbHowFloorBody =>
      'The plan never goes below a safe minimum, so the calories were raised to it.';

  @override
  String get onbHowDailyTitle => 'Your daily target';

  @override
  String onbHowBasedOn(String weight) {
    return 'Calculated from a weight of $weight kg';
  }

  @override
  String get onbBuildPlan => 'Build my first plan';

  @override
  String get onbGeneralTitle => 'Your account is ready in general mode';

  @override
  String get onbReasonUnder18 => 'A personal plan is for adults.';

  @override
  String get onbReasonInsulin =>
      'Insulin use needs planning with your doctor that this app does not cover.';

  @override
  String get onbReasonGeneric =>
      'Your situation needs an estimate the personal plan does not cover.';

  @override
  String get onbCanDo => 'What you can do';

  @override
  String get onbCanMeals => 'Browse healthy meals with nutrition facts';

  @override
  String get onbCanLog => 'Log your food and water';

  @override
  String get onbCanProgress => 'Track weight and progress';

  @override
  String get onbCanShop => 'Build your shopping list';

  @override
  String get onbEnterApp => 'Enter the app';

  @override
  String get onbTimezoneNote =>
      'The device timezone was not accepted, so the profile was saved with UTC.';
}
