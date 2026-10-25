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
      'The plan could not be built right now. Try again in a little while.';

  @override
  String get failureNotEligible =>
      'A personal plan is not available for this account.';

  @override
  String get failureNoTarget => 'There is no calorie target yet.';

  @override
  String get failureConditionConflict =>
      'The health conditions conflict with a personal plan.';

  @override
  String get failureNoFeasiblePlan => 'No plan fits this day\'s limits.';

  @override
  String get failureSwapRejected =>
      'This swap is not possible because it would pass your day\'s limits.';

  @override
  String get failurePlanItemNotFound => 'This plan meal was not found.';

  @override
  String get failurePlanItemAlreadyLogged =>
      'You logged this meal, so it cannot be swapped.';

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
  String get failureMealNotFound => 'This meal is no longer in the catalog.';

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

  @override
  String get browseMeals => 'Browse meals';

  @override
  String get mealSearchHint => 'Search meals';

  @override
  String get mealSlotAll => 'All';

  @override
  String get mealSlotBreakfast => 'Breakfast';

  @override
  String get mealSlotLunch => 'Lunch';

  @override
  String get mealSlotDinner => 'Dinner';

  @override
  String get mealSlotSnack => 'Snack';

  @override
  String get mealHideAvoided => 'Hide meals with something I avoid';

  @override
  String mealFooter(int count, String updated) {
    return '$count meals · updated $updated';
  }

  @override
  String get mealOfflineEmpty =>
      'We need a connection once to download meals, then they work offline';

  @override
  String get mealNoResults => 'No meals with this name';

  @override
  String get mealClearFilters => 'Clear filters';

  @override
  String get mealRetry => 'Try again';

  @override
  String mealKcal(String kcal) {
    return '$kcal kcal';
  }

  @override
  String mealProtein(String grams) {
    return '$grams g protein';
  }

  @override
  String mealServing(String grams) {
    return '$grams g';
  }

  @override
  String get mealAllergenBadge => 'Contains something you avoid';

  @override
  String mealAllergenWarning(String names) {
    return 'Contains $names, which you said you avoid';
  }

  @override
  String get mealMacroKcal => 'kcal';

  @override
  String get mealSodium => 'Sodium (salt)';

  @override
  String get mealSaturatedFat => 'Saturated fat';

  @override
  String get mealFacts => 'Full nutrition facts';

  @override
  String get mealIngredients => 'Ingredients';

  @override
  String get mealOptional => 'Optional';

  @override
  String get mealSteps => 'Preparation';

  @override
  String get mealStepsSoon => 'Preparation steps will be added soon';

  @override
  String get mealDislike => 'I don’t like this meal, don’t suggest it again';

  @override
  String get mealDislikeUndo => 'We won’t suggest it again · Undo';

  @override
  String get mealFavourite => 'Favourite';

  @override
  String get mealPrefSaveFailed => 'Couldn’t save, check your connection';

  @override
  String get mealFavouritesTitle => 'Favourite meals';

  @override
  String get mealFavouritesHint => 'The engine suggests these more often';

  @override
  String get mealDislikesTitle => 'I don’t like';

  @override
  String get mealDislikesHint => 'They won’t appear in your plan';

  @override
  String get mealFavouritesEmpty => 'None yet. Tap the heart on any meal.';

  @override
  String get mealDislikesEmpty => 'None.';

  @override
  String get mealRemove => 'Remove';

  @override
  String get mealMg => 'mg';

  @override
  String get nutrientEnergy => 'Energy';

  @override
  String get nutrientProtein => 'Protein';

  @override
  String get nutrientCarbs => 'Carbs';

  @override
  String get nutrientFat => 'Fat';

  @override
  String get nutrientFiber => 'Fiber';

  @override
  String get nutrientSugars => 'Sugars';

  @override
  String get nutrientSaturatedFat => 'Saturated fat';

  @override
  String get nutrientCholesterol => 'Cholesterol';

  @override
  String get nutrientSodium => 'Sodium';

  @override
  String get nutrientPotassium => 'Potassium';

  @override
  String get allergenGluten => 'Gluten';

  @override
  String get allergenMilk => 'Milk';

  @override
  String get allergenEgg => 'Egg';

  @override
  String get allergenFish => 'Fish';

  @override
  String get allergenPeanut => 'Peanuts';

  @override
  String get allergenTreeNuts => 'Tree nuts';

  @override
  String get allergenSesame => 'Sesame';

  @override
  String get allergenSoy => 'Soy';

  @override
  String get tabToday => 'Today';

  @override
  String get tabPlan => 'Plan';

  @override
  String get tabWater => 'Water';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabMe => 'Me';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get waterSoon => 'Water logging arrives in the next step.';

  @override
  String get progressSoon =>
      'Adherence, the weekly report and badges come later.';

  @override
  String get greetMorning => 'Good morning';

  @override
  String get greetEvening => 'Good evening';

  @override
  String get kcalModeEaten => 'Eaten';

  @override
  String get kcalModeLeft => 'Left';

  @override
  String get kcalEatenCaption => 'kcal eaten today';

  @override
  String get kcalLeftCaption => 'kcal left today';

  @override
  String kcalOfTarget(String kcal) {
    return 'of a $kcal kcal target';
  }

  @override
  String get todayNoPlan => 'Today\'s plan has not been built yet';

  @override
  String get todayBuildWeek => 'Build the week\'s plan';

  @override
  String nowCard(String slot, String time) {
    return '$slot time · until $time';
  }

  @override
  String get waterWithDoctor => 'With your doctor';

  @override
  String get todayMeals => 'Today\'s meals';

  @override
  String get fullPlan => 'Full plan';

  @override
  String get stateDone => 'Done';

  @override
  String get stateNow => 'Now';

  @override
  String get stateMissed => 'Missed window';

  @override
  String get generalTitle => 'General mode';

  @override
  String get generalBody =>
      'You log food and water and see progress. There is no personal calorie plan.';

  @override
  String get healthyTitle => 'Healthy meals to try';

  @override
  String get offlineBar => 'Offline · showing the last saved copy';

  @override
  String get planTitle => 'Your week';

  @override
  String planRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get planOptimizer => 'Built by the optimizer';

  @override
  String get planRebuild => 'Rebuild';

  @override
  String get planRebuildBody =>
      'We will build the days of the week again. Days where you logged a meal stay as they are.';

  @override
  String get planRebuildConfirm => 'Rebuild';

  @override
  String get planCancel => 'Cancel';

  @override
  String get planChartTitle => 'Planned calories this week';

  @override
  String planTargetLabel(String kcal) {
    return 'Target $kcal';
  }

  @override
  String get withinBand => 'Within ±10% of your target';

  @override
  String belowMinimum(String nutrient) {
    return 'Below the minimum: $nutrient';
  }

  @override
  String get planEmpty => 'There is no plan for this day';

  @override
  String get generalPlanTip =>
      'In general mode we don\'t build a personal plan, but you can browse meals and save the ones you like to favourites.';

  @override
  String planDayKcal(String day, String kcal) {
    return '$day · $kcal kcal';
  }

  @override
  String itemPortion(String multiplier, String grams) {
    return 'Your amount: $multiplier serving · ≈ $grams g';
  }

  @override
  String get whyChosen => 'Why did we choose it for you?';

  @override
  String get perServingFacts => 'Nutrition for one serving';

  @override
  String get perServingNote => 'per serving';

  @override
  String get swapAction => 'Swap';

  @override
  String get swapLoggedNote => 'This meal is logged, so it cannot be swapped.';

  @override
  String get swapTitle => 'Alternatives that fit your plan';

  @override
  String get swapSubtitle => 'Each one keeps your day\'s calories and limits';

  @override
  String get swapEmpty => 'No suitable alternatives right now';

  @override
  String get swapOffline => 'Swapping needs a connection';

  @override
  String get swapDone => 'Swapped';

  @override
  String get genTitle => 'Building your plan';

  @override
  String get genSkip => 'Skip';

  @override
  String get genNeeds => 'Calculating your needs';

  @override
  String get genFilter => 'Removing what does not suit you';

  @override
  String get genSearch => 'The optimizer searches for the best mix';

  @override
  String get genWeek => 'Building the week';

  @override
  String get genKcalPerDay => 'kcal a day';

  @override
  String get genMealsInKitchen => 'meals in the kitchen';

  @override
  String genAvoid(String name) {
    return 'Avoid $name';
  }

  @override
  String get genLessSalt => 'Less salt';

  @override
  String get genLessSugar => 'Less sugar';

  @override
  String get genNoDislike => 'No disliked meals';

  @override
  String get genWithin => 'Calories within ±10%';

  @override
  String get genProtein => 'Protein';

  @override
  String get genFiber => 'Fiber';

  @override
  String get genNoRepeat => 'No repeat from yesterday';

  @override
  String genSolver(String status, String seconds) {
    return 'CP-SAT · $status · $seconds s';
  }

  @override
  String get genReady => 'Your plan is ready';

  @override
  String get genStart => 'Start your day';

  @override
  String genPartial(int built) {
    return 'We built $built of 7 days';
  }

  @override
  String get genRetryLeft => 'Try again for the remaining days';

  @override
  String get genNetwork =>
      'The connection failed. Days already built are saved. Try again.';

  @override
  String get genGeneric => 'The build could not be finished.';

  @override
  String get genIneligible =>
      'Your account is in general mode, so we will not build a personal plan.';

  @override
  String get shopTitle => 'Shopping list';

  @override
  String get shopNote =>
      'Calculated from your week\'s meals, without optional ingredients';

  @override
  String shopProgress(int done, int total) {
    return '$done of $total items';
  }

  @override
  String get shopFromPlan => 'From this week\'s plan';

  @override
  String get favouritesCard => 'Favourites';

  @override
  String favouritesCount(int count) {
    return '$count meals';
  }

  @override
  String shopInMeals(int count) {
    return 'In $count meals';
  }

  @override
  String get shopNeedsNet => 'We need a connection to calculate the list';

  @override
  String shopShareHeader(String from, String to) {
    return 'My shopping list ($from – $to)';
  }

  @override
  String shopGrams(String grams) {
    return '≈ $grams g';
  }

  @override
  String shopKg(String kg) {
    return '$kg kg';
  }

  @override
  String get shopShare => 'Share';

  @override
  String get chartNoPlan => 'No plan';

  @override
  String get accountLanguage => 'العربية';
}
