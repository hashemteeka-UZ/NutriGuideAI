import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application name shown in the interface.
  ///
  /// In ar, this message translates to:
  /// **'NutriGuide'**
  String get appTitle;

  /// Accessibility label while the health check is running.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من الخادم'**
  String get serverCheckLoading;

  /// Shown when GET /api/v1/health succeeds on a compatible API.
  ///
  /// In ar, this message translates to:
  /// **'الخادم متصل'**
  String get serverCheckConnected;

  /// Shown when the server API major version is not 1.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق يحتاج تحديثًا'**
  String get serverCheckNeedsUpdate;

  /// Button that repeats the health check.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get serverCheckRetry;

  /// Label for the API version value.
  ///
  /// In ar, this message translates to:
  /// **'إصدار الواجهة'**
  String get serverCheckApiVersionLabel;

  /// Label for the catalog dataset version.
  ///
  /// In ar, this message translates to:
  /// **'إصدار الكتالوج'**
  String get serverCheckDatasetVersionLabel;

  /// Label for the default planner name.
  ///
  /// In ar, this message translates to:
  /// **'المخطّط'**
  String get serverCheckPlannerLabel;

  /// Placeholder when a health field is null.
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get serverCheckUnknownValue;

  /// No description provided for @failureRateLimited.
  ///
  /// In ar, this message translates to:
  /// **'طلبات كثيرة. حاول بعد قليل.'**
  String get failureRateLimited;

  /// No description provided for @failurePlannerBusy.
  ///
  /// In ar, this message translates to:
  /// **'المخطّط مشغول الآن. حاول بعد قليل.'**
  String get failurePlannerBusy;

  /// No description provided for @failurePlannerTimeout.
  ///
  /// In ar, this message translates to:
  /// **'تعذر بناء الخطة الآن، حاول مرة أخرى بعد قليل.'**
  String get failurePlannerTimeout;

  /// No description provided for @failureNotEligible.
  ///
  /// In ar, this message translates to:
  /// **'الخطة الشخصية غير متاحة لهذا الحساب.'**
  String get failureNotEligible;

  /// No description provided for @failureNoTarget.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد هدف سعرات بعد.'**
  String get failureNoTarget;

  /// No description provided for @failureConditionConflict.
  ///
  /// In ar, this message translates to:
  /// **'الحالات الصحية تتعارض مع بناء خطة شخصية.'**
  String get failureConditionConflict;

  /// No description provided for @failureNoFeasiblePlan.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خطة تناسب حدود هذا اليوم.'**
  String get failureNoFeasiblePlan;

  /// No description provided for @failureSwapRejected.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن هذا الاستبدال لأنه يتجاوز حدود يومك.'**
  String get failureSwapRejected;

  /// No description provided for @failurePlanItemNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم تعد هذه الوجبة في الخطة.'**
  String get failurePlanItemNotFound;

  /// No description provided for @failurePlanItemAlreadyLogged.
  ///
  /// In ar, this message translates to:
  /// **'سجلت هذه الوجبة، لا يمكن استبدالها.'**
  String get failurePlanItemAlreadyLogged;

  /// No description provided for @failureUnauthorized.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة. سجّل الدخول من جديد.'**
  String get failureUnauthorized;

  /// No description provided for @failureTokenReused.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة لأسباب أمنية. سجّل الدخول من جديد.'**
  String get failureTokenReused;

  /// No description provided for @failureValidation.
  ///
  /// In ar, this message translates to:
  /// **'بعض البيانات غير صالحة.'**
  String get failureValidation;

  /// No description provided for @failureServiceUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة غير متاحة الآن. حاول لاحقًا.'**
  String get failureServiceUnavailable;

  /// No description provided for @failureInternal.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في الخادم. حاول لاحقًا.'**
  String get failureInternal;

  /// No description provided for @failureNetwork.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالخادم.'**
  String get failureNetwork;

  /// No description provided for @failureTimeout.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة الاتصال بالخادم.'**
  String get failureTimeout;

  /// No description provided for @failureUnexpectedResponse.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة رد الخادم.'**
  String get failureUnexpectedResponse;

  /// No description provided for @failureGeneric.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع.'**
  String get failureGeneric;

  /// Rate limit message when Retry-After is known.
  ///
  /// In ar, this message translates to:
  /// **'{seconds, plural, zero{محاولات كثيرة. حاول بعد {seconds} ثانية.} one{محاولات كثيرة. حاول بعد ثانية واحدة.} two{محاولات كثيرة. حاول بعد ثانيتين.} few{محاولات كثيرة. حاول بعد {seconds} ثوانٍ.} many{محاولات كثيرة. حاول بعد {seconds} ثانية.} other{محاولات كثيرة. حاول بعد {seconds} ثانية.}}'**
  String failureRateLimitedSeconds(int seconds);

  /// No description provided for @failureEmailTaken.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد مسجل مسبقًا. سجّل الدخول بدلًا من ذلك.'**
  String get failureEmailTaken;

  /// No description provided for @failureInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد أو كلمة المرور غير صحيحة.'**
  String get failureInvalidCredentials;

  /// No description provided for @failureTokenInvalid.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة. سجّل الدخول من جديد.'**
  String get failureTokenInvalid;

  /// No description provided for @splashLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ فتح التطبيق'**
  String get splashLoading;

  /// No description provided for @welcomeSlide1Title.
  ///
  /// In ar, this message translates to:
  /// **'خطة تُبنى لك أنت'**
  String get welcomeSlide1Title;

  /// No description provided for @welcomeSlide1Body.
  ///
  /// In ar, this message translates to:
  /// **'محرك ذكي يختار وجباتك من مطبخنا المحلي حسب جسمك وهدفك وما تحب.'**
  String get welcomeSlide1Body;

  /// No description provided for @welcomeSlide2Title.
  ///
  /// In ar, this message translates to:
  /// **'تناسب يومك'**
  String get welcomeSlide2Title;

  /// No description provided for @welcomeSlide2Body.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد الوجبات والماء تُرتب حسب وقت استيقاظك ونومك.'**
  String get welcomeSlide2Body;

  /// No description provided for @welcomeSlide3Title.
  ///
  /// In ar, this message translates to:
  /// **'ترى تقدمك'**
  String get welcomeSlide3Title;

  /// No description provided for @welcomeSlide3Body.
  ///
  /// In ar, this message translates to:
  /// **'رسوم واضحة وتقرير أسبوعي وإنجازات تحفزك.'**
  String get welcomeSlide3Body;

  /// No description provided for @welcomeStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ رحلتك'**
  String get welcomeStart;

  /// No description provided for @welcomeHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لدي حساب'**
  String get welcomeHaveAccount;

  /// No description provided for @authBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get authBack;

  /// No description provided for @registerTitle.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابك'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة واحدة، ثم نبني خطتك'**
  String get registerSubtitle;

  /// No description provided for @registerSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get registerSubmit;

  /// No description provided for @registerFooterPrompt.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب؟'**
  String get registerFooterPrompt;

  /// No description provided for @registerFooterAction.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك'**
  String get registerFooterAction;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بعودتك'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخولك لتكمل خطتك'**
  String get loginSubtitle;

  /// No description provided for @loginSubmit.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get loginSubmit;

  /// No description provided for @loginFooterPrompt.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get loginFooterPrompt;

  /// No description provided for @loginFooterAction.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابًا'**
  String get loginFooterAction;

  /// No description provided for @authEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get authPasswordLabel;

  /// No description provided for @authShowPassword.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get authHidePassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'٨ أحرف على الأقل'**
  String get authPasswordHint;

  /// No description provided for @authEmailRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل البريد الإلكتروني.'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صالح.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور.'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'٨ أحرف على الأقل.'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordTooLong.
  ///
  /// In ar, this message translates to:
  /// **'١٢٨ حرفًا كحد أقصى.'**
  String get authPasswordTooLong;

  /// No description provided for @authPasswordInvalid.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور غير صالحة.'**
  String get authPasswordInvalid;

  /// No description provided for @homeGreeting.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا'**
  String get homeGreeting;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get logout;

  /// No description provided for @failureTargetValidation.
  ///
  /// In ar, this message translates to:
  /// **'الوزن المستهدف أو السرعة غير صالحة.'**
  String get failureTargetValidation;

  /// No description provided for @failureNoWeight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن غير موجود. حاول مرة أخرى.'**
  String get failureNoWeight;

  /// No description provided for @failureInvalidTimezone.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية غير مقبولة.'**
  String get failureInvalidTimezone;

  /// No description provided for @failureUnknownCode.
  ///
  /// In ar, this message translates to:
  /// **'أحد الاختيارات غير معروف.'**
  String get failureUnknownCode;

  /// No description provided for @failureProfileNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الملف غير موجود.'**
  String get failureProfileNotFound;

  /// No description provided for @failureMealNotFound.
  ///
  /// In ar, this message translates to:
  /// **'هذه الوجبة لم تعد في الكتالوج.'**
  String get failureMealNotFound;

  /// No description provided for @onbContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get onbContinue;

  /// No description provided for @onbBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get onbBack;

  /// No description provided for @onbRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get onbRetry;

  /// No description provided for @onbStepProgress.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {current} من {total}'**
  String onbStepProgress(int current, int total);

  /// No description provided for @onbChecking.
  ///
  /// In ar, this message translates to:
  /// **'نتحقق من حسابك...'**
  String get onbChecking;

  /// No description provided for @onbCalculating.
  ///
  /// In ar, this message translates to:
  /// **'نحسب احتياجاتك...'**
  String get onbCalculating;

  /// No description provided for @onbReferenceError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل قوائم الإعداد.'**
  String get onbReferenceError;

  /// No description provided for @onbJustForYou.
  ///
  /// In ar, this message translates to:
  /// **'سؤال خاص بك'**
  String get onbJustForYou;

  /// No description provided for @onbBecauseWeight.
  ///
  /// In ar, this message translates to:
  /// **'لأن هدفك تغيير الوزن'**
  String get onbBecauseWeight;

  /// No description provided for @onbBecauseHeart.
  ///
  /// In ar, this message translates to:
  /// **'لأن صحة القلب تحتاج متابعة الماء مع الطبيب'**
  String get onbBecauseHeart;

  /// No description provided for @onbAboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'عرّفنا بنفسك'**
  String get onbAboutTitle;

  /// No description provided for @onbAboutSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الجنس والعمر يغيران احتياجك اليومي من الطاقة'**
  String get onbAboutSubtitle;

  /// No description provided for @onbSexMale.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get onbSexMale;

  /// No description provided for @onbSexFemale.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get onbSexFemale;

  /// No description provided for @onbAge.
  ///
  /// In ar, this message translates to:
  /// **'العمر: {age} سنة'**
  String onbAge(String age);

  /// No description provided for @onbMeasureTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطول والوزن'**
  String get onbMeasureTitle;

  /// No description provided for @onbMeasureSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نحسب بهما احتياجك ونتابع تقدمك'**
  String get onbMeasureSubtitle;

  /// No description provided for @onbHeight.
  ///
  /// In ar, this message translates to:
  /// **'الطول'**
  String get onbHeight;

  /// No description provided for @onbWeight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن'**
  String get onbWeight;

  /// No description provided for @onbCm.
  ///
  /// In ar, this message translates to:
  /// **'سم'**
  String get onbCm;

  /// No description provided for @onbKg.
  ///
  /// In ar, this message translates to:
  /// **'كغ'**
  String get onbKg;

  /// No description provided for @onbBmi.
  ///
  /// In ar, this message translates to:
  /// **'مؤشر كتلة الجسم'**
  String get onbBmi;

  /// No description provided for @onbBmiUnder.
  ///
  /// In ar, this message translates to:
  /// **'أقل من الطبيعي'**
  String get onbBmiUnder;

  /// No description provided for @onbBmiNormal.
  ///
  /// In ar, this message translates to:
  /// **'طبيعي'**
  String get onbBmiNormal;

  /// No description provided for @onbBmiOver.
  ///
  /// In ar, this message translates to:
  /// **'فوق الطبيعي'**
  String get onbBmiOver;

  /// No description provided for @onbBmiHigh.
  ///
  /// In ar, this message translates to:
  /// **'مرتفع'**
  String get onbBmiHigh;

  /// No description provided for @onbBmiExplainTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما هو مؤشر كتلة الجسم؟'**
  String get onbBmiExplainTitle;

  /// No description provided for @onbBmiExplainBody.
  ///
  /// In ar, this message translates to:
  /// **'رقم تقريبي من الوزن والطول (الوزن ÷ مربع الطول بالمتر). نستخدمه كمؤشر عام فقط، ولا يقيس نسبة الدهون أو العضلات.'**
  String get onbBmiExplainBody;

  /// No description provided for @onbGoalTitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{ما هدفكِ؟} other{ما هدفك؟}}'**
  String onbGoalTitle(String sex);

  /// No description provided for @onbGoalSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نبني سعراتك اليومية حول هدفك'**
  String get onbGoalSubtitle;

  /// No description provided for @onbGoalLose.
  ///
  /// In ar, this message translates to:
  /// **'إنقاص الوزن'**
  String get onbGoalLose;

  /// No description provided for @onbGoalLoseBody.
  ///
  /// In ar, this message translates to:
  /// **'عجز معتدل وآمن في السعرات'**
  String get onbGoalLoseBody;

  /// No description provided for @onbGoalMaintain.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة على وزني'**
  String get onbGoalMaintain;

  /// No description provided for @onbGoalMaintainBody.
  ///
  /// In ar, this message translates to:
  /// **'أكل متوازن يحافظ على طاقتك'**
  String get onbGoalMaintainBody;

  /// No description provided for @onbGoalGain.
  ///
  /// In ar, this message translates to:
  /// **'زيادة الوزن'**
  String get onbGoalGain;

  /// No description provided for @onbGoalGainBody.
  ///
  /// In ar, this message translates to:
  /// **'فائض مدروس في السعرات'**
  String get onbGoalGainBody;

  /// No description provided for @onbLoseUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'لا نقترح هدفًا أقل من الوزن الطبيعي لطولك'**
  String get onbLoseUnavailable;

  /// No description provided for @onbPaceLoseTitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{إلى أين تريدين أن تصلي؟} other{إلى أين تريد أن تصل؟}}'**
  String onbPaceLoseTitle(String sex);

  /// No description provided for @onbPaceGainTitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{كم تريدين أن تزيدي؟} other{كم تريد أن تزيد؟}}'**
  String onbPaceGainTitle(String sex);

  /// No description provided for @onbPaceSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{اختاري وزنكِ المستهدف وسرعة الوصول} other{اختر وزنك المستهدف وسرعة الوصول}}'**
  String onbPaceSubtitle(String sex);

  /// No description provided for @onbTargetWeight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن المستهدف'**
  String get onbTargetWeight;

  /// No description provided for @onbPaceHeading.
  ///
  /// In ar, this message translates to:
  /// **'السرعة'**
  String get onbPaceHeading;

  /// No description provided for @onbRateGentle.
  ///
  /// In ar, this message translates to:
  /// **'هادئة · الأسهل للاستمرار'**
  String get onbRateGentle;

  /// No description provided for @onbRateGentleBody.
  ///
  /// In ar, this message translates to:
  /// **'ربع كغ أسبوعيًا'**
  String get onbRateGentleBody;

  /// No description provided for @onbRateBalanced.
  ///
  /// In ar, this message translates to:
  /// **'متوازنة · ننصح بها'**
  String get onbRateBalanced;

  /// No description provided for @onbRateBalancedBody.
  ///
  /// In ar, this message translates to:
  /// **'نصف كغ أسبوعيًا'**
  String get onbRateBalancedBody;

  /// No description provided for @onbRateFaster.
  ///
  /// In ar, this message translates to:
  /// **'أسرع'**
  String get onbRateFaster;

  /// No description provided for @onbRateFasterBody.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثة أرباع كغ أسبوعيًا'**
  String get onbRateFasterBody;

  /// No description provided for @onbRateMax.
  ///
  /// In ar, this message translates to:
  /// **'الأقصى'**
  String get onbRateMax;

  /// No description provided for @onbRateMaxBody.
  ///
  /// In ar, this message translates to:
  /// **'كغ أسبوعيًا'**
  String get onbRateMaxBody;

  /// No description provided for @onbRateUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاحة لوزنك الحالي (أكثر من 1% أسبوعيًا)'**
  String get onbRateUnavailable;

  /// No description provided for @onbGainCap.
  ///
  /// In ar, this message translates to:
  /// **'الحد الآمن للزيادة نصف كغ أسبوعيًا'**
  String get onbGainCap;

  /// No description provided for @onbArrival.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{تصلين إلى {weight} كغ بعد نحو {weeks} أسبوعًا، تقريبًا في {when}} other{تصل إلى {weight} كغ بعد نحو {weeks} أسبوعًا، تقريبًا في {when}}}'**
  String onbArrival(String sex, String weight, String weeks, String when);

  /// No description provided for @onbActivityTitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{كم تتحركين في يومكِ؟} other{كم تتحرك في يومك؟}}'**
  String onbActivityTitle(String sex);

  /// No description provided for @onbActivitySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{اختاري ما يصف أسبوعكِ المعتاد} other{اختر ما يصف أسبوعك المعتاد}}'**
  String onbActivitySubtitle(String sex);

  /// No description provided for @onbActSedentary.
  ///
  /// In ar, this message translates to:
  /// **'قليل الحركة'**
  String get onbActSedentary;

  /// No description provided for @onbActSedentaryBody.
  ///
  /// In ar, this message translates to:
  /// **'عمل مكتبي، مشي قليل'**
  String get onbActSedentaryBody;

  /// No description provided for @onbActLight.
  ///
  /// In ar, this message translates to:
  /// **'نشاط خفيف'**
  String get onbActLight;

  /// No description provided for @onbActLightBody.
  ///
  /// In ar, this message translates to:
  /// **'مشي أو رياضة خفيفة 1 إلى 3 أيام'**
  String get onbActLightBody;

  /// No description provided for @onbActModerate.
  ///
  /// In ar, this message translates to:
  /// **'نشاط معتدل'**
  String get onbActModerate;

  /// No description provided for @onbActModerateBody.
  ///
  /// In ar, this message translates to:
  /// **'رياضة متوسطة 3 إلى 5 أيام'**
  String get onbActModerateBody;

  /// No description provided for @onbActHigh.
  ///
  /// In ar, this message translates to:
  /// **'نشيط جدًا'**
  String get onbActHigh;

  /// No description provided for @onbActHighBody.
  ///
  /// In ar, this message translates to:
  /// **'رياضة قوية 6 إلى 7 أيام'**
  String get onbActHighBody;

  /// No description provided for @onbActAthlete.
  ///
  /// In ar, this message translates to:
  /// **'رياضي'**
  String get onbActAthlete;

  /// No description provided for @onbActAthleteBody.
  ///
  /// In ar, this message translates to:
  /// **'تدريب يومي مكثف أو عمل بدني شاق'**
  String get onbActAthleteBody;

  /// No description provided for @onbActivityTip.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{نشاطكِ يحدد كم تحرقين يوميًا. إن ترددتِ بين خيارين، اختاري الأقل لتكون الخطة أدق.} other{نشاطك يحدد كم تحرق يوميًا. إن ترددت بين خيارين، اختر الأقل لتكون الخطة أدق.}}'**
  String onbActivityTip(String sex);

  /// No description provided for @onbCareTitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{هل نراعي شيئًا في أكلكِ؟} other{هل نراعي شيئًا في أكلك؟}}'**
  String onbCareTitle(String sex);

  /// No description provided for @onbCareSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{اختاري ما ينطبق عليكِ، ونختار لكِ وجبات لا تتعارض معه} other{اختر ما ينطبق عليك، ونختار لك وجبات لا تتعارض معه}}'**
  String onbCareSubtitle(String sex);

  /// No description provided for @onbCareNone.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء'**
  String get onbCareNone;

  /// No description provided for @onbCareNoneBody.
  ///
  /// In ar, this message translates to:
  /// **'أريد أكلًا صحيًا ومتوازنًا فقط'**
  String get onbCareNoneBody;

  /// No description provided for @onbCareDiabetesBody.
  ///
  /// In ar, this message translates to:
  /// **'سكريات أقل وكربوهيدرات موزعة على وجباتك'**
  String get onbCareDiabetesBody;

  /// No description provided for @onbCarePressureBody.
  ///
  /// In ar, this message translates to:
  /// **'ملح أقل في وجباتك اليومية'**
  String get onbCarePressureBody;

  /// No description provided for @onbCareHeartBody.
  ///
  /// In ar, this message translates to:
  /// **'دهون صحية وملح أقل'**
  String get onbCareHeartBody;

  /// No description provided for @onbCareExplainTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف نراعي ذلك؟'**
  String get onbCareExplainTitle;

  /// No description provided for @onbCareExplainBody.
  ///
  /// In ar, this message translates to:
  /// **'NutriGuide لا يعالج أي حالة، ولا يغني عن طبيبك. هو فقط يتجنب في خطتك ما قد لا يناسبك، مثل الملح الزائد أو السكريات، حسب توصيات منظمة الصحة العالمية وجمعيات الصحة.'**
  String get onbCareExplainBody;

  /// No description provided for @onbAllergyTitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{هل تتجنبين أي مكون؟} other{هل تتجنب أي مكون؟}}'**
  String onbAllergyTitle(String sex);

  /// No description provided for @onbAllergySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{اضغطي مرة للتجنب، ومرتين إذا كانت حساسية شديدة} other{اضغط مرة للتجنب، ومرتين إذا كانت حساسية شديدة}}'**
  String onbAllergySubtitle(String sex);

  /// No description provided for @onbAvoid.
  ///
  /// In ar, this message translates to:
  /// **'تجنب'**
  String get onbAvoid;

  /// No description provided for @onbSevere.
  ///
  /// In ar, this message translates to:
  /// **'شديدة'**
  String get onbSevere;

  /// No description provided for @onbAllergyTip.
  ///
  /// In ar, this message translates to:
  /// **'«تجنب» يعني أننا لا نضعه في خطتك. «شديدة» تعني أيضًا أننا نحذرك بوضوح إذا ظهر في أي وجبة تتصفحها.'**
  String get onbAllergyTip;

  /// No description provided for @onbSafetyTitle.
  ///
  /// In ar, this message translates to:
  /// **'سؤال أخير للاطمئنان'**
  String get onbSafetyTitle;

  /// No description provided for @onbSafetySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{حتى نتأكد أن الخطة الشخصية مناسبة لكِ} other{حتى نتأكد أن الخطة الشخصية مناسبة لك}}'**
  String onbSafetySubtitle(String sex);

  /// No description provided for @onbInsulinQuestion.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{هل تستخدمين الإنسولين؟} other{هل تستخدم الإنسولين؟}}'**
  String onbInsulinQuestion(String sex);

  /// No description provided for @onbYes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get onbYes;

  /// No description provided for @onbNo.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get onbNo;

  /// No description provided for @onbWhyAsk.
  ///
  /// In ar, this message translates to:
  /// **'لماذا نسأل؟'**
  String get onbWhyAsk;

  /// No description provided for @onbWhyAskBody.
  ///
  /// In ar, this message translates to:
  /// **'استخدام الإنسولين يحتاج تخطيط الكربوهيدرات مرتبطًا بالجرعات، وهذا لا يغطيه التطبيق، فيُستخدم الوضع العام.'**
  String get onbWhyAskBody;

  /// No description provided for @onbRhythmTitle.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, FEMALE{كيف يبدو يومكِ؟} other{كيف يبدو يومك؟}}'**
  String onbRhythmTitle(String sex);

  /// No description provided for @onbRhythmSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نرتب مواعيد وجباتك ومائك حول وقت استيقاظك ونومك'**
  String get onbRhythmSubtitle;

  /// No description provided for @onbWake.
  ///
  /// In ar, this message translates to:
  /// **'أستيقظ'**
  String get onbWake;

  /// No description provided for @onbSleep.
  ///
  /// In ar, this message translates to:
  /// **'أنام'**
  String get onbSleep;

  /// No description provided for @onbSuggestedDay.
  ///
  /// In ar, this message translates to:
  /// **'يومك المقترح'**
  String get onbSuggestedDay;

  /// No description provided for @onbBreakfast.
  ///
  /// In ar, this message translates to:
  /// **'الفطور'**
  String get onbBreakfast;

  /// No description provided for @onbLunch.
  ///
  /// In ar, this message translates to:
  /// **'الغداء'**
  String get onbLunch;

  /// No description provided for @onbSnack.
  ///
  /// In ar, this message translates to:
  /// **'وجبة خفيفة'**
  String get onbSnack;

  /// No description provided for @onbDinner.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get onbDinner;

  /// No description provided for @onbWindow.
  ///
  /// In ar, this message translates to:
  /// **'{start} – {end}'**
  String onbWindow(String start, String end);

  /// No description provided for @onbFluidTitle.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الماء مع طبيبك'**
  String get onbFluidTitle;

  /// No description provided for @onbFluidSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'بعض حالات القلب يحدد لها الطبيب كمية سوائل يومية'**
  String get onbFluidSubtitle;

  /// No description provided for @onbFluidNone.
  ///
  /// In ar, this message translates to:
  /// **'لم يحدد لي طبيبي كمية'**
  String get onbFluidNone;

  /// No description provided for @onbFluidNoneBody.
  ///
  /// In ar, this message translates to:
  /// **'لا بأس. سنسجل ما تشربه ونعرضه لك دون أن نضع هدفًا أو نذكرك بالشرب.'**
  String get onbFluidNoneBody;

  /// No description provided for @onbFluidDoctor.
  ///
  /// In ar, this message translates to:
  /// **'حدد لي طبيبي كمية يومية'**
  String get onbFluidDoctor;

  /// No description provided for @onbFluidRange.
  ///
  /// In ar, this message translates to:
  /// **'بين 500 و5000 مل'**
  String get onbFluidRange;

  /// No description provided for @onbMl.
  ///
  /// In ar, this message translates to:
  /// **'مل'**
  String get onbMl;

  /// No description provided for @onbResultTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذه احتياجاتك اليومية، محسوبة لك أنت'**
  String get onbResultTitle;

  /// No description provided for @onbDailyCalories.
  ///
  /// In ar, this message translates to:
  /// **'سعراتك اليومية'**
  String get onbDailyCalories;

  /// No description provided for @onbLineLose.
  ///
  /// In ar, this message translates to:
  /// **'لإنقاص وزنك'**
  String get onbLineLose;

  /// No description provided for @onbLineMaintain.
  ///
  /// In ar, this message translates to:
  /// **'للمحافظة على وزنك'**
  String get onbLineMaintain;

  /// No description provided for @onbLineGain.
  ///
  /// In ar, this message translates to:
  /// **'لزيادة وزنك'**
  String get onbLineGain;

  /// No description provided for @onbProtein.
  ///
  /// In ar, this message translates to:
  /// **'بروتين'**
  String get onbProtein;

  /// No description provided for @onbCarbs.
  ///
  /// In ar, this message translates to:
  /// **'كربوهيدرات'**
  String get onbCarbs;

  /// No description provided for @onbFat.
  ///
  /// In ar, this message translates to:
  /// **'دهون'**
  String get onbFat;

  /// No description provided for @onbFiber.
  ///
  /// In ar, this message translates to:
  /// **'ألياف'**
  String get onbFiber;

  /// No description provided for @onbWater.
  ///
  /// In ar, this message translates to:
  /// **'الماء'**
  String get onbWater;

  /// No description provided for @onbGrams.
  ///
  /// In ar, this message translates to:
  /// **'غ'**
  String get onbGrams;

  /// No description provided for @onbMacroShare.
  ///
  /// In ar, this message translates to:
  /// **'{share} من السعرات'**
  String onbMacroShare(String share);

  /// No description provided for @onbWaterClinician.
  ///
  /// In ar, this message translates to:
  /// **'بالتنسيق مع طبيبك'**
  String get onbWaterClinician;

  /// No description provided for @onbWaterNone.
  ///
  /// In ar, this message translates to:
  /// **'بدون هدف'**
  String get onbWaterNone;

  /// No description provided for @onbHowTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف حسبناها؟'**
  String get onbHowTitle;

  /// No description provided for @onbHowRestTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطاقة وقت الراحة (معادلة Mifflin-St Jeor)'**
  String get onbHowRestTitle;

  /// No description provided for @onbHowRestBody.
  ///
  /// In ar, this message translates to:
  /// **'هذا ما يحتاجه جسمك للطاقة وأنت مرتاح تمامًا، بحسب معادلة ميفلين-سانت جيور.'**
  String get onbHowRestBody;

  /// No description provided for @onbHowActivityTitle.
  ///
  /// In ar, this message translates to:
  /// **'× معامل نشاطك'**
  String get onbHowActivityTitle;

  /// No description provided for @onbHowActivityBody.
  ///
  /// In ar, this message translates to:
  /// **'نضرب طاقة الراحة في معامل نشاطك ({factor}) لنحصل على ما تحرقه في يومك المعتاد.'**
  String onbHowActivityBody(String factor);

  /// No description provided for @onbHowDeficitTitle.
  ///
  /// In ar, this message translates to:
  /// **'− عجز إنقاص الوزن'**
  String get onbHowDeficitTitle;

  /// No description provided for @onbHowDeficitBody.
  ///
  /// In ar, this message translates to:
  /// **'هذا الفرق الذي نخصمه من احتياجك حتى ينخفض الوزن بالسرعة التي اخترتها.'**
  String get onbHowDeficitBody;

  /// No description provided for @onbHowSurplusTitle.
  ///
  /// In ar, this message translates to:
  /// **'+ فائض الزيادة'**
  String get onbHowSurplusTitle;

  /// No description provided for @onbHowSurplusBody.
  ///
  /// In ar, this message translates to:
  /// **'هذه الزيادة فوق احتياجك حتى يرتفع الوزن بالسرعة التي اخترتها.'**
  String get onbHowSurplusBody;

  /// No description provided for @onbHowFloorTitle.
  ///
  /// In ar, this message translates to:
  /// **'رفعنا السعرات إلى الحد الأدنى الآمن'**
  String get onbHowFloorTitle;

  /// No description provided for @onbHowFloorBody.
  ///
  /// In ar, this message translates to:
  /// **'الخطة لا تنزل تحت حد أدنى آمن، لذلك رفعنا السعرات إليه.'**
  String get onbHowFloorBody;

  /// No description provided for @onbHowDailyTitle.
  ///
  /// In ar, this message translates to:
  /// **'هدفك اليومي'**
  String get onbHowDailyTitle;

  /// No description provided for @onbHowBasedOn.
  ///
  /// In ar, this message translates to:
  /// **'محسوبة على وزن {weight} كغ'**
  String onbHowBasedOn(String weight);

  /// No description provided for @onbBuildPlan.
  ///
  /// In ar, this message translates to:
  /// **'ابنِ خطتي الأولى'**
  String get onbBuildPlan;

  /// No description provided for @onbGeneralTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابك جاهز في الوضع العام'**
  String get onbGeneralTitle;

  /// No description provided for @onbReasonUnder18.
  ///
  /// In ar, this message translates to:
  /// **'الخطة الشخصية مخصصة للبالغين'**
  String get onbReasonUnder18;

  /// No description provided for @onbReasonInsulin.
  ///
  /// In ar, this message translates to:
  /// **'استخدام الإنسولين يحتاج تخطيطًا مع طبيبك لا يغطيه التطبيق'**
  String get onbReasonInsulin;

  /// No description provided for @onbReasonGeneric.
  ///
  /// In ar, this message translates to:
  /// **'وضعك يحتاج تقديرًا لا تغطيه الخطة الشخصية.'**
  String get onbReasonGeneric;

  /// No description provided for @onbCanDo.
  ///
  /// In ar, this message translates to:
  /// **'ماذا يمكنك أن تفعل؟'**
  String get onbCanDo;

  /// No description provided for @onbCanMeals.
  ///
  /// In ar, this message translates to:
  /// **'تصفح وجبات صحية مع قيمها الغذائية'**
  String get onbCanMeals;

  /// No description provided for @onbCanLog.
  ///
  /// In ar, this message translates to:
  /// **'سجل أكلك ومائك يوميًا'**
  String get onbCanLog;

  /// No description provided for @onbCanProgress.
  ///
  /// In ar, this message translates to:
  /// **'تابع وزنك وتقدمك برسوم واضحة'**
  String get onbCanProgress;

  /// No description provided for @onbCanShop.
  ///
  /// In ar, this message translates to:
  /// **'اصنع قائمة مشترياتك'**
  String get onbCanShop;

  /// No description provided for @onbEnterApp.
  ///
  /// In ar, this message translates to:
  /// **'ادخل التطبيق'**
  String get onbEnterApp;

  /// No description provided for @onbTimezoneNote.
  ///
  /// In ar, this message translates to:
  /// **'لم تُقبل المنطقة الزمنية للجهاز، فحُفظ الملف بتوقيت UTC.'**
  String get onbTimezoneNote;

  /// No description provided for @browseMeals.
  ///
  /// In ar, this message translates to:
  /// **'تصفح الوجبات'**
  String get browseMeals;

  /// No description provided for @mealSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن وجبة'**
  String get mealSearchHint;

  /// No description provided for @mealSlotAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get mealSlotAll;

  /// No description provided for @mealSlotBreakfast.
  ///
  /// In ar, this message translates to:
  /// **'فطور'**
  String get mealSlotBreakfast;

  /// No description provided for @mealSlotLunch.
  ///
  /// In ar, this message translates to:
  /// **'غداء'**
  String get mealSlotLunch;

  /// No description provided for @mealSlotDinner.
  ///
  /// In ar, this message translates to:
  /// **'عشاء'**
  String get mealSlotDinner;

  /// No description provided for @mealSlotSnack.
  ///
  /// In ar, this message translates to:
  /// **'خفيفة'**
  String get mealSlotSnack;

  /// No description provided for @mealHideAvoided.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء ما يحتوي على ما أتجنبه'**
  String get mealHideAvoided;

  /// No description provided for @mealFooter.
  ///
  /// In ar, this message translates to:
  /// **'{count} وجبة · آخر تحديث {updated}'**
  String mealFooter(int count, String updated);

  /// No description provided for @mealOfflineEmpty.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج اتصالًا مرة واحدة لتحميل الوجبات، ثم تعمل دون إنترنت'**
  String get mealOfflineEmpty;

  /// No description provided for @mealNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وجبات بهذا الاسم'**
  String get mealNoResults;

  /// No description provided for @mealClearFilters.
  ///
  /// In ar, this message translates to:
  /// **'مسح التصفية'**
  String get mealClearFilters;

  /// No description provided for @mealRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get mealRetry;

  /// No description provided for @mealKcal.
  ///
  /// In ar, this message translates to:
  /// **'{kcal} سعرة'**
  String mealKcal(String kcal);

  /// No description provided for @mealProtein.
  ///
  /// In ar, this message translates to:
  /// **'{grams} غ بروتين'**
  String mealProtein(String grams);

  /// No description provided for @mealServing.
  ///
  /// In ar, this message translates to:
  /// **'{grams} غ'**
  String mealServing(String grams);

  /// No description provided for @mealAllergenBadge.
  ///
  /// In ar, this message translates to:
  /// **'تحتوي على ما تتجنبه'**
  String get mealAllergenBadge;

  /// No description provided for @mealAllergenWarning.
  ///
  /// In ar, this message translates to:
  /// **'تحتوي على {names} مما سجلت أنك تتجنبه'**
  String mealAllergenWarning(String names);

  /// No description provided for @mealMacroKcal.
  ///
  /// In ar, this message translates to:
  /// **'سعرة'**
  String get mealMacroKcal;

  /// No description provided for @mealSodium.
  ///
  /// In ar, this message translates to:
  /// **'الصوديوم (الملح)'**
  String get mealSodium;

  /// No description provided for @mealSaturatedFat.
  ///
  /// In ar, this message translates to:
  /// **'الدهون المشبعة'**
  String get mealSaturatedFat;

  /// No description provided for @mealFacts.
  ///
  /// In ar, this message translates to:
  /// **'القيم الغذائية كاملة'**
  String get mealFacts;

  /// No description provided for @mealIngredients.
  ///
  /// In ar, this message translates to:
  /// **'المكونات'**
  String get mealIngredients;

  /// No description provided for @mealOptional.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get mealOptional;

  /// No description provided for @mealSteps.
  ///
  /// In ar, this message translates to:
  /// **'التحضير'**
  String get mealSteps;

  /// No description provided for @mealStepsSoon.
  ///
  /// In ar, this message translates to:
  /// **'خطوات التحضير ستضاف قريبًا'**
  String get mealStepsSoon;

  /// No description provided for @mealDislike.
  ///
  /// In ar, this message translates to:
  /// **'لا أحب هذه الوجبة، لا تقترحها مجددًا'**
  String get mealDislike;

  /// No description provided for @mealDislikeUndo.
  ///
  /// In ar, this message translates to:
  /// **'لن نقترحها مجددًا · تراجع'**
  String get mealDislikeUndo;

  /// No description provided for @mealFavourite.
  ///
  /// In ar, this message translates to:
  /// **'مفضلة'**
  String get mealFavourite;

  /// No description provided for @mealPrefSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الحفظ، تحقق من الاتصال'**
  String get mealPrefSaveFailed;

  /// No description provided for @mealFavouritesTitle.
  ///
  /// In ar, this message translates to:
  /// **'وجباتي المفضلة'**
  String get mealFavouritesTitle;

  /// No description provided for @mealFavouritesHint.
  ///
  /// In ar, this message translates to:
  /// **'يقترحها المحرك أكثر في خطتك'**
  String get mealFavouritesHint;

  /// No description provided for @mealDislikesTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا أحبها'**
  String get mealDislikesTitle;

  /// No description provided for @mealDislikesHint.
  ///
  /// In ar, this message translates to:
  /// **'لن تظهر في خطتك'**
  String get mealDislikesHint;

  /// No description provided for @mealFavouritesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بعد. اضغط القلب في أي وجبة.'**
  String get mealFavouritesEmpty;

  /// No description provided for @mealDislikesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد.'**
  String get mealDislikesEmpty;

  /// No description provided for @mealRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get mealRemove;

  /// No description provided for @mealMg.
  ///
  /// In ar, this message translates to:
  /// **'ملغ'**
  String get mealMg;

  /// No description provided for @nutrientEnergy.
  ///
  /// In ar, this message translates to:
  /// **'الطاقة'**
  String get nutrientEnergy;

  /// No description provided for @nutrientProtein.
  ///
  /// In ar, this message translates to:
  /// **'بروتين'**
  String get nutrientProtein;

  /// No description provided for @nutrientCarbs.
  ///
  /// In ar, this message translates to:
  /// **'كربوهيدرات'**
  String get nutrientCarbs;

  /// No description provided for @nutrientFat.
  ///
  /// In ar, this message translates to:
  /// **'دهون'**
  String get nutrientFat;

  /// No description provided for @nutrientFiber.
  ///
  /// In ar, this message translates to:
  /// **'ألياف'**
  String get nutrientFiber;

  /// No description provided for @nutrientSugars.
  ///
  /// In ar, this message translates to:
  /// **'سكريات'**
  String get nutrientSugars;

  /// No description provided for @nutrientSaturatedFat.
  ///
  /// In ar, this message translates to:
  /// **'دهون مشبعة'**
  String get nutrientSaturatedFat;

  /// No description provided for @nutrientCholesterol.
  ///
  /// In ar, this message translates to:
  /// **'كوليسترول'**
  String get nutrientCholesterol;

  /// No description provided for @nutrientSodium.
  ///
  /// In ar, this message translates to:
  /// **'صوديوم'**
  String get nutrientSodium;

  /// No description provided for @nutrientPotassium.
  ///
  /// In ar, this message translates to:
  /// **'بوتاسيوم'**
  String get nutrientPotassium;

  /// No description provided for @allergenGluten.
  ///
  /// In ar, this message translates to:
  /// **'الغلوتين'**
  String get allergenGluten;

  /// No description provided for @allergenMilk.
  ///
  /// In ar, this message translates to:
  /// **'الحليب'**
  String get allergenMilk;

  /// No description provided for @allergenEgg.
  ///
  /// In ar, this message translates to:
  /// **'البيض'**
  String get allergenEgg;

  /// No description provided for @allergenFish.
  ///
  /// In ar, this message translates to:
  /// **'السمك'**
  String get allergenFish;

  /// No description provided for @allergenPeanut.
  ///
  /// In ar, this message translates to:
  /// **'الفول السوداني'**
  String get allergenPeanut;

  /// No description provided for @allergenTreeNuts.
  ///
  /// In ar, this message translates to:
  /// **'المكسرات'**
  String get allergenTreeNuts;

  /// No description provided for @allergenSesame.
  ///
  /// In ar, this message translates to:
  /// **'السمسم'**
  String get allergenSesame;

  /// No description provided for @allergenSoy.
  ///
  /// In ar, this message translates to:
  /// **'الصويا'**
  String get allergenSoy;

  /// No description provided for @tabToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get tabToday;

  /// No description provided for @tabPlan.
  ///
  /// In ar, this message translates to:
  /// **'الخطة'**
  String get tabPlan;

  /// No description provided for @tabWater.
  ///
  /// In ar, this message translates to:
  /// **'الماء'**
  String get tabWater;

  /// No description provided for @tabProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدمي'**
  String get tabProgress;

  /// No description provided for @tabMe.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get tabMe;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get comingSoon;

  /// No description provided for @waterSoon.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الماء يأتي في الخطوة التالية.'**
  String get waterSoon;

  /// No description provided for @progressSoon.
  ///
  /// In ar, this message translates to:
  /// **'الالتزام والتقرير الأسبوعي والإنجازات تأتي لاحقًا.'**
  String get progressSoon;

  /// No description provided for @greetMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير'**
  String get greetMorning;

  /// No description provided for @greetEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير'**
  String get greetEvening;

  /// No description provided for @kcalModeEaten.
  ///
  /// In ar, this message translates to:
  /// **'المستهلك'**
  String get kcalModeEaten;

  /// No description provided for @kcalModeLeft.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي'**
  String get kcalModeLeft;

  /// No description provided for @kcalEatenCaption.
  ///
  /// In ar, this message translates to:
  /// **'سعرة أكلتها اليوم'**
  String get kcalEatenCaption;

  /// No description provided for @kcalLeftCaption.
  ///
  /// In ar, this message translates to:
  /// **'سعرة متبقية لك'**
  String get kcalLeftCaption;

  /// No description provided for @kcalOfTarget.
  ///
  /// In ar, this message translates to:
  /// **'من هدف {kcal} سعرة'**
  String kcalOfTarget(String kcal);

  /// No description provided for @todayNoPlan.
  ///
  /// In ar, this message translates to:
  /// **'لم تُبنَ خطة اليوم بعد'**
  String get todayNoPlan;

  /// No description provided for @todayBuildWeek.
  ///
  /// In ar, this message translates to:
  /// **'ابنِ خطة الأسبوع'**
  String get todayBuildWeek;

  /// No description provided for @nowCard.
  ///
  /// In ar, this message translates to:
  /// **'وقت {slot} الآن · حتى {time}'**
  String nowCard(String slot, String time);

  /// No description provided for @waterWithDoctor.
  ///
  /// In ar, this message translates to:
  /// **'بالتنسيق مع طبيبك'**
  String get waterWithDoctor;

  /// No description provided for @todayMeals.
  ///
  /// In ar, this message translates to:
  /// **'وجبات اليوم'**
  String get todayMeals;

  /// No description provided for @fullPlan.
  ///
  /// In ar, this message translates to:
  /// **'الخطة كاملة'**
  String get fullPlan;

  /// No description provided for @stateDone.
  ///
  /// In ar, this message translates to:
  /// **'تمت'**
  String get stateDone;

  /// No description provided for @stateNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get stateNow;

  /// No description provided for @stateMissed.
  ///
  /// In ar, this message translates to:
  /// **'فات موعدها'**
  String get stateMissed;

  /// No description provided for @generalTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوضع العام'**
  String get generalTitle;

  /// No description provided for @generalBody.
  ///
  /// In ar, this message translates to:
  /// **'تسجل أكلك وماءك وترى تقدمك. لا توجد خطة سعرات شخصية.'**
  String get generalBody;

  /// No description provided for @healthyTitle.
  ///
  /// In ar, this message translates to:
  /// **'وجبات صحية لتجربتها'**
  String get healthyTitle;

  /// No description provided for @offlineBar.
  ///
  /// In ar, this message translates to:
  /// **'دون اتصال · تعرض آخر نسخة محفوظة'**
  String get offlineBar;

  /// No description provided for @planTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطتك للأسبوع'**
  String get planTitle;

  /// No description provided for @planRange.
  ///
  /// In ar, this message translates to:
  /// **'{from} – {to}'**
  String planRange(String from, String to);

  /// No description provided for @planOptimizer.
  ///
  /// In ar, this message translates to:
  /// **'بُنيت بالمحسّن'**
  String get planOptimizer;

  /// No description provided for @planRebuild.
  ///
  /// In ar, this message translates to:
  /// **'إعادة البناء'**
  String get planRebuild;

  /// No description provided for @planRebuildBody.
  ///
  /// In ar, this message translates to:
  /// **'سنبني أيام الأسبوع من جديد. الأيام التي سجلت فيها وجبة تبقى كما هي.'**
  String get planRebuildBody;

  /// No description provided for @planRebuildConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إعادة البناء'**
  String get planRebuildConfirm;

  /// No description provided for @planCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get planCancel;

  /// No description provided for @planChartTitle.
  ///
  /// In ar, this message translates to:
  /// **'سعرات الأسبوع المخطط'**
  String get planChartTitle;

  /// No description provided for @planTargetLabel.
  ///
  /// In ar, this message translates to:
  /// **'الهدف {kcal}'**
  String planTargetLabel(String kcal);

  /// No description provided for @withinBand.
  ///
  /// In ar, this message translates to:
  /// **'ضمن ‎±10%‎ من هدفك'**
  String get withinBand;

  /// No description provided for @belowMinimum.
  ///
  /// In ar, this message translates to:
  /// **'أقل من الحد الأدنى: {nutrient}'**
  String belowMinimum(String nutrient);

  /// No description provided for @planEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خطة لهذا اليوم'**
  String get planEmpty;

  /// No description provided for @generalPlanTip.
  ///
  /// In ar, this message translates to:
  /// **'في الوضع العام لا نبني خطة شخصية، لكن يمكنك تصفح الوجبات وحفظ ما يعجبك في المفضلة.'**
  String get generalPlanTip;

  /// No description provided for @planDayKcal.
  ///
  /// In ar, this message translates to:
  /// **'{day} · {kcal} سعرة'**
  String planDayKcal(String day, String kcal);

  /// No description provided for @itemPortion.
  ///
  /// In ar, this message translates to:
  /// **'كميتك: {multiplier} حصة · ≈ {grams} غ'**
  String itemPortion(String multiplier, String grams);

  /// No description provided for @whyChosen.
  ///
  /// In ar, this message translates to:
  /// **'لماذا اخترناها لك؟'**
  String get whyChosen;

  /// No description provided for @perServingFacts.
  ///
  /// In ar, this message translates to:
  /// **'القيم الغذائية لحصة واحدة'**
  String get perServingFacts;

  /// No description provided for @perServingNote.
  ///
  /// In ar, this message translates to:
  /// **'لكل حصة'**
  String get perServingNote;

  /// No description provided for @swapAction.
  ///
  /// In ar, this message translates to:
  /// **'استبدال'**
  String get swapAction;

  /// No description provided for @swapLoggedNote.
  ///
  /// In ar, this message translates to:
  /// **'سجلت هذه الوجبة، لا يمكن استبدالها.'**
  String get swapLoggedNote;

  /// No description provided for @swapTitle.
  ///
  /// In ar, this message translates to:
  /// **'بدائل تناسب خطتك'**
  String get swapTitle;

  /// No description provided for @swapSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كلها تحافظ على سعرات يومك وحدودك'**
  String get swapSubtitle;

  /// No description provided for @swapEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بدائل مناسبة الآن'**
  String get swapEmpty;

  /// No description provided for @swapOffline.
  ///
  /// In ar, this message translates to:
  /// **'الاستبدال يحتاج اتصالًا'**
  String get swapOffline;

  /// No description provided for @swapDone.
  ///
  /// In ar, this message translates to:
  /// **'تم الاستبدال'**
  String get swapDone;

  /// No description provided for @genTitle.
  ///
  /// In ar, this message translates to:
  /// **'نبني خطتك الآن'**
  String get genTitle;

  /// No description provided for @genSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get genSkip;

  /// No description provided for @genNeeds.
  ///
  /// In ar, this message translates to:
  /// **'نحسب احتياجك'**
  String get genNeeds;

  /// No description provided for @genFilter.
  ///
  /// In ar, this message translates to:
  /// **'نستبعد ما لا يناسبك'**
  String get genFilter;

  /// No description provided for @genSearch.
  ///
  /// In ar, this message translates to:
  /// **'المحسّن يبحث عن أفضل تركيبة'**
  String get genSearch;

  /// No description provided for @genWeek.
  ///
  /// In ar, this message translates to:
  /// **'نبني أيام الأسبوع'**
  String get genWeek;

  /// No description provided for @genKcalPerDay.
  ///
  /// In ar, this message translates to:
  /// **'سعرة يوميًا'**
  String get genKcalPerDay;

  /// No description provided for @genMealsInKitchen.
  ///
  /// In ar, this message translates to:
  /// **'وجبة في المطبخ'**
  String get genMealsInKitchen;

  /// No description provided for @genAvoid.
  ///
  /// In ar, this message translates to:
  /// **'تجنب {name}'**
  String genAvoid(String name);

  /// No description provided for @genLessSalt.
  ///
  /// In ar, this message translates to:
  /// **'ملح أقل'**
  String get genLessSalt;

  /// No description provided for @genLessSugar.
  ///
  /// In ar, this message translates to:
  /// **'سكريات أقل'**
  String get genLessSugar;

  /// No description provided for @genNoDislike.
  ///
  /// In ar, this message translates to:
  /// **'بدون ما لا تحبه'**
  String get genNoDislike;

  /// No description provided for @genWithin.
  ///
  /// In ar, this message translates to:
  /// **'السعرات ضمن ‎±10%‎'**
  String get genWithin;

  /// No description provided for @genProtein.
  ///
  /// In ar, this message translates to:
  /// **'البروتين'**
  String get genProtein;

  /// No description provided for @genFiber.
  ///
  /// In ar, this message translates to:
  /// **'الألياف'**
  String get genFiber;

  /// No description provided for @genNoRepeat.
  ///
  /// In ar, this message translates to:
  /// **'بدون تكرار مع أمس'**
  String get genNoRepeat;

  /// No description provided for @genSolver.
  ///
  /// In ar, this message translates to:
  /// **'CP-SAT · {status} · {seconds} ث'**
  String genSolver(String status, String seconds);

  /// No description provided for @genReady.
  ///
  /// In ar, this message translates to:
  /// **'خطتك جاهزة'**
  String get genReady;

  /// No description provided for @genStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ يومك'**
  String get genStart;

  /// No description provided for @genPartial.
  ///
  /// In ar, this message translates to:
  /// **'بنينا {built} من 7 أيام'**
  String genPartial(int built);

  /// No description provided for @genRetryLeft.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى للأيام الباقية'**
  String get genRetryLeft;

  /// No description provided for @genNetwork.
  ///
  /// In ar, this message translates to:
  /// **'انقطع الاتصال. الأيام التي بُنيت محفوظة. حاول مرة أخرى.'**
  String get genNetwork;

  /// No description provided for @genGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إكمال البناء.'**
  String get genGeneric;

  /// No description provided for @genIneligible.
  ///
  /// In ar, this message translates to:
  /// **'حسابك في الوضع العام، ولن نبني خطة شخصية.'**
  String get genIneligible;

  /// No description provided for @shopTitle.
  ///
  /// In ar, this message translates to:
  /// **'قائمة المشتريات'**
  String get shopTitle;

  /// No description provided for @shopNote.
  ///
  /// In ar, this message translates to:
  /// **'محسوبة من وجبات أسبوعك، دون المكونات الاختيارية'**
  String get shopNote;

  /// No description provided for @shopProgress.
  ///
  /// In ar, this message translates to:
  /// **'{done} من {total} مشتريات'**
  String shopProgress(int done, int total);

  /// No description provided for @shopFromPlan.
  ///
  /// In ar, this message translates to:
  /// **'من خطة الأسبوع'**
  String get shopFromPlan;

  /// No description provided for @favouritesCard.
  ///
  /// In ar, this message translates to:
  /// **'مفضلاتي'**
  String get favouritesCard;

  /// No description provided for @favouritesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} وجبات'**
  String favouritesCount(int count);

  /// No description provided for @shopInMeals.
  ///
  /// In ar, this message translates to:
  /// **'في {count} وجبات'**
  String shopInMeals(int count);

  /// No description provided for @shopNeedsNet.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج اتصالًا لحساب القائمة'**
  String get shopNeedsNet;

  /// No description provided for @shopShareHeader.
  ///
  /// In ar, this message translates to:
  /// **'قائمة مشترياتي ({from} – {to})'**
  String shopShareHeader(String from, String to);

  /// No description provided for @shopGrams.
  ///
  /// In ar, this message translates to:
  /// **'≈ {grams} غ'**
  String shopGrams(String grams);

  /// No description provided for @shopKg.
  ///
  /// In ar, this message translates to:
  /// **'{kg} كغ'**
  String shopKg(String kg);

  /// No description provided for @shopShare.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get shopShare;

  /// No description provided for @chartNoPlan.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خطة'**
  String get chartNoPlan;

  /// No description provided for @accountLanguage.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get accountLanguage;

  /// No description provided for @eatAction.
  ///
  /// In ar, this message translates to:
  /// **'أكلتها'**
  String get eatAction;

  /// No description provided for @eatLogged.
  ///
  /// In ar, this message translates to:
  /// **'سجلتها'**
  String get eatLogged;

  /// No description provided for @eatUndo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get eatUndo;

  /// No description provided for @eatOtherAmount.
  ///
  /// In ar, this message translates to:
  /// **'كمية مختلفة'**
  String get eatOtherAmount;

  /// No description provided for @eatAmountTitle.
  ///
  /// In ar, this message translates to:
  /// **'كم أكلت من الكمية المخططة؟'**
  String get eatAmountTitle;

  /// No description provided for @eatAmountHalf.
  ///
  /// In ar, this message translates to:
  /// **'النصف'**
  String get eatAmountHalf;

  /// No description provided for @eatAmountFull.
  ///
  /// In ar, this message translates to:
  /// **'الكمية كاملة'**
  String get eatAmountFull;

  /// No description provided for @eatAmountOneHalf.
  ///
  /// In ar, this message translates to:
  /// **'مرة ونصف'**
  String get eatAmountOneHalf;

  /// No description provided for @eatSaved.
  ///
  /// In ar, this message translates to:
  /// **'سُجّلت الوجبة'**
  String get eatSaved;

  /// No description provided for @eatUndone.
  ///
  /// In ar, this message translates to:
  /// **'أُلغي التسجيل'**
  String get eatUndone;

  /// No description provided for @eatFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تسجيل الوجبة'**
  String get eatFailed;

  /// No description provided for @missedTitle.
  ///
  /// In ar, this message translates to:
  /// **'فاتك موعد {slot}'**
  String missedTitle(Object slot);

  /// No description provided for @missedBody.
  ///
  /// In ar, this message translates to:
  /// **'هل أكلتها؟ سجلها الآن حتى يبقى يومك دقيقًا'**
  String get missedBody;

  /// No description provided for @missedAction.
  ///
  /// In ar, this message translates to:
  /// **'سجّلها'**
  String get missedAction;

  /// No description provided for @provisionalNote.
  ///
  /// In ar, this message translates to:
  /// **'مؤقت حتى المزامنة'**
  String get provisionalNote;

  /// No description provided for @syncUploading.
  ///
  /// In ar, this message translates to:
  /// **'⟳ جارٍ الرفع'**
  String get syncUploading;

  /// No description provided for @syncWaiting.
  ///
  /// In ar, this message translates to:
  /// **'⇡ {count} بانتظار الاتصال'**
  String syncWaiting(Object count);

  /// No description provided for @syncRejected.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ تسجيل'**
  String get syncRejected;

  /// No description provided for @syncRejectedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيلات لم تُحفظ'**
  String get syncRejectedTitle;

  /// No description provided for @syncDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get syncDelete;

  /// No description provided for @syncClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get syncClose;

  /// No description provided for @logoutPendingBody.
  ///
  /// In ar, this message translates to:
  /// **'لديك تسجيلات لم تُرفع بعد. الخروج سيحذفها من الهاتف.'**
  String get logoutPendingBody;

  /// No description provided for @logoutPendingConfirm.
  ///
  /// In ar, this message translates to:
  /// **'خروج وحذف'**
  String get logoutPendingConfirm;

  /// No description provided for @failureClientUuidConflict.
  ///
  /// In ar, this message translates to:
  /// **'هذا التسجيل محفوظ مسبقًا بمحتوى مختلف.'**
  String get failureClientUuidConflict;

  /// No description provided for @failureLogNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يعد هذا التسجيل موجودًا.'**
  String get failureLogNotFound;

  /// No description provided for @failureClockSkew.
  ///
  /// In ar, this message translates to:
  /// **'وقت هاتفك متقدم على الوقت الصحيح. صحّحه ثم حاول مرة أخرى.'**
  String get failureClockSkew;

  /// No description provided for @logRejectedGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ هذا التسجيل'**
  String get logRejectedGeneric;

  /// No description provided for @waterAmountMl.
  ///
  /// In ar, this message translates to:
  /// **'{ml} مل'**
  String waterAmountMl(Object ml);

  /// No description provided for @waterTotalOfGoal.
  ///
  /// In ar, this message translates to:
  /// **'{total} / {goal} مل'**
  String waterTotalOfGoal(Object goal, Object total);

  /// No description provided for @waterTodayGoal.
  ///
  /// In ar, this message translates to:
  /// **'هدف اليوم'**
  String get waterTodayGoal;

  /// No description provided for @waterDoctorGoal.
  ///
  /// In ar, this message translates to:
  /// **'الهدف الذي حدده طبيبك'**
  String get waterDoctorGoal;

  /// No description provided for @waterTotalOnly.
  ///
  /// In ar, this message translates to:
  /// **'مجموع اليوم'**
  String get waterTotalOnly;

  /// No description provided for @waterQuickSmall.
  ///
  /// In ar, this message translates to:
  /// **'كوب صغير'**
  String get waterQuickSmall;

  /// No description provided for @waterQuickCup.
  ///
  /// In ar, this message translates to:
  /// **'كوب'**
  String get waterQuickCup;

  /// No description provided for @waterQuickBottle.
  ///
  /// In ar, this message translates to:
  /// **'زجاجة'**
  String get waterQuickBottle;

  /// No description provided for @waterCustom.
  ///
  /// In ar, this message translates to:
  /// **'مخصص'**
  String get waterCustom;

  /// No description provided for @waterCustomTitle.
  ///
  /// In ar, this message translates to:
  /// **'كمية مخصصة'**
  String get waterCustomTitle;

  /// No description provided for @waterAdd.
  ///
  /// In ar, this message translates to:
  /// **'أضف'**
  String get waterAdd;

  /// No description provided for @waterLargeTip.
  ///
  /// In ar, this message translates to:
  /// **'كمية كبيرة لمرة واحدة، يمكنك تقسيمها على مرتين.'**
  String get waterLargeTip;

  /// No description provided for @waterTodayList.
  ///
  /// In ar, this message translates to:
  /// **'شرب اليوم'**
  String get waterTodayList;

  /// No description provided for @waterEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تسجل ماء اليوم بعد'**
  String get waterEmpty;

  /// No description provided for @waterSaved.
  ///
  /// In ar, this message translates to:
  /// **'سُجّل الماء'**
  String get waterSaved;

  /// No description provided for @waterClinicianTitle.
  ///
  /// In ar, this message translates to:
  /// **'كمية الماء يحددها طبيبك'**
  String get waterClinicianTitle;

  /// No description provided for @waterClinicianAction.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الكمية التي حددها طبيبك'**
  String get waterClinicianAction;

  /// No description provided for @waterSetGoal.
  ///
  /// In ar, this message translates to:
  /// **'حدد هدفًا'**
  String get waterSetGoal;

  /// No description provided for @waterGoalSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'الكمية اليومية'**
  String get waterGoalSheetTitle;

  /// No description provided for @waterGoalSave.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get waterGoalSave;

  /// No description provided for @waterGoalSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ الهدف'**
  String get waterGoalSaved;

  /// No description provided for @waterNeedsConnection.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج اتصالًا'**
  String get waterNeedsConnection;

  /// No description provided for @waterRangeError.
  ///
  /// In ar, this message translates to:
  /// **'الكمية بين 50 و1000 مل'**
  String get waterRangeError;

  /// No description provided for @weightTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل وزنك'**
  String get weightTitle;

  /// No description provided for @weightKgValue.
  ///
  /// In ar, this message translates to:
  /// **'{kg} كغ'**
  String weightKgValue(Object kg);

  /// No description provided for @weightSave.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get weightSave;

  /// No description provided for @weightSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ وزنك'**
  String get weightSaved;

  /// No description provided for @weightQueued.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ وزنك وسيُرفع عند الاتصال'**
  String get weightQueued;

  /// No description provided for @weightStale.
  ///
  /// In ar, this message translates to:
  /// **'يوجد وزن أحدث محفوظ لهذا اليوم'**
  String get weightStale;

  /// No description provided for @weightGoalReached.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, female{وصلتِ إلى هدفكِ!} other{وصلت إلى هدفك!}}'**
  String weightGoalReached(String sex);

  /// No description provided for @weightGoalReachedBody.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, female{أحسنتِ، استمري على عاداتكِ الجيدة.} other{أحسنت، استمر على عاداتك الجيدة.}}'**
  String weightGoalReachedBody(String sex);

  /// No description provided for @weightRangeError.
  ///
  /// In ar, this message translates to:
  /// **'الوزن بين 20 و400 كغ'**
  String get weightRangeError;

  /// No description provided for @weightLatest.
  ///
  /// In ar, this message translates to:
  /// **'آخر وزن: {kg} كغ'**
  String weightLatest(Object kg);

  /// No description provided for @weightNone.
  ///
  /// In ar, this message translates to:
  /// **'لم تسجل وزنًا بعد'**
  String get weightNone;

  /// No description provided for @targetNoticeBody.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث هدفك اليومي بناءً على وزنك الجديد'**
  String get targetNoticeBody;

  /// No description provided for @targetNoticeRebuild.
  ///
  /// In ar, this message translates to:
  /// **'أعد بناء خطة الأيام القادمة'**
  String get targetNoticeRebuild;

  /// No description provided for @targetNoticeLater.
  ///
  /// In ar, this message translates to:
  /// **'لاحقًا'**
  String get targetNoticeLater;

  /// No description provided for @otherMealTitle.
  ///
  /// In ar, this message translates to:
  /// **'أكلت وجبة أخرى'**
  String get otherMealTitle;

  /// No description provided for @otherMealServings.
  ///
  /// In ar, this message translates to:
  /// **'كم حصة أكلت؟'**
  String get otherMealServings;

  /// No description provided for @otherMealSlot.
  ///
  /// In ar, this message translates to:
  /// **'أي وجبة؟'**
  String get otherMealSlot;

  /// No description provided for @servingsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} حصة'**
  String servingsCount(Object count);

  /// No description provided for @extrasTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافات اليوم'**
  String get extrasTitle;

  /// No description provided for @extraPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار المزامنة'**
  String get extraPending;

  /// No description provided for @quickTitle.
  ///
  /// In ar, this message translates to:
  /// **'ماذا تريد أن تضيف؟'**
  String get quickTitle;

  /// No description provided for @quickWater.
  ///
  /// In ar, this message translates to:
  /// **'سجّل ماء'**
  String get quickWater;

  /// No description provided for @fabLabel.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get fabLabel;

  /// No description provided for @progressSegReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الأسبوع'**
  String get progressSegReport;

  /// No description provided for @progressSegWeight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن'**
  String get progressSegWeight;

  /// No description provided for @progressSegBadges.
  ///
  /// In ar, this message translates to:
  /// **'الإنجازات'**
  String get progressSegBadges;

  /// No description provided for @progressBadgesSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا: الشارات والإنجازات.'**
  String get progressBadgesSoon;

  /// No description provided for @weekRange.
  ///
  /// In ar, this message translates to:
  /// **'{from} – {to}'**
  String weekRange(Object from, Object to);

  /// No description provided for @weekPrev.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع السابق'**
  String get weekPrev;

  /// No description provided for @weekNext.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع التالي'**
  String get weekNext;

  /// No description provided for @headlineExcellent.
  ///
  /// In ar, this message translates to:
  /// **'أسبوع ممتاز!'**
  String get headlineExcellent;

  /// No description provided for @headlineGood.
  ///
  /// In ar, this message translates to:
  /// **'أسبوع جيد'**
  String get headlineGood;

  /// No description provided for @headlineFresh.
  ///
  /// In ar, this message translates to:
  /// **'كل يوم فرصة جديدة'**
  String get headlineFresh;

  /// No description provided for @weekAchievedOf.
  ///
  /// In ar, this message translates to:
  /// **'{sex, select, female{حققتِ هدفكِ في {achieved} من {counted} أيام} other{حققت هدفك في {achieved} من {counted} أيام}}'**
  String weekAchievedOf(Object achieved, Object counted, String sex);

  /// No description provided for @bestDayTitle.
  ///
  /// In ar, this message translates to:
  /// **'أفضل يوم'**
  String get bestDayTitle;

  /// No description provided for @bestDayBody.
  ///
  /// In ar, this message translates to:
  /// **'{day} · {percent}% من الهدف'**
  String bestDayBody(Object day, Object percent);

  /// No description provided for @mostMissedTitle.
  ///
  /// In ar, this message translates to:
  /// **'أكثر ما نقصك'**
  String get mostMissedTitle;

  /// No description provided for @mostMissedBody.
  ///
  /// In ar, this message translates to:
  /// **'{nutrient}: {total} من {minimum} في المتوسط، في {days} أيام'**
  String mostMissedBody(
    Object days,
    Object minimum,
    Object nutrient,
    Object total,
  );

  /// No description provided for @waterAvgTitle.
  ///
  /// In ar, this message translates to:
  /// **'متوسط الماء'**
  String get waterAvgTitle;

  /// No description provided for @waterAvgBody.
  ///
  /// In ar, this message translates to:
  /// **'{ml} مل في اليوم'**
  String waterAvgBody(Object ml);

  /// No description provided for @caloriesChartTitle.
  ///
  /// In ar, this message translates to:
  /// **'السعرات مقابل الهدف'**
  String get caloriesChartTitle;

  /// No description provided for @legendAchieved.
  ///
  /// In ar, this message translates to:
  /// **'ضمن الهدف'**
  String get legendAchieved;

  /// No description provided for @legendPartial.
  ///
  /// In ar, this message translates to:
  /// **'قريب'**
  String get legendPartial;

  /// No description provided for @legendNot.
  ///
  /// In ar, this message translates to:
  /// **'بعيد'**
  String get legendNot;

  /// No description provided for @legendNone.
  ///
  /// In ar, this message translates to:
  /// **'لا تسجيل'**
  String get legendNone;

  /// No description provided for @macrosTitle.
  ///
  /// In ar, this message translates to:
  /// **'متوسط العناصر'**
  String get macrosTitle;

  /// No description provided for @macroValue.
  ///
  /// In ar, this message translates to:
  /// **'{avg} / {target} غ'**
  String macroValue(Object avg, Object target);

  /// No description provided for @exceededTitle.
  ///
  /// In ar, this message translates to:
  /// **'تجاوزت حدًا صحيًا في {days} أيام'**
  String exceededTitle(Object days);

  /// No description provided for @exceededLine.
  ///
  /// In ar, this message translates to:
  /// **'{nutrient}: {total} مقابل حد {limit}'**
  String exceededLine(Object limit, Object nutrient, Object total);

  /// No description provided for @emptyWeek.
  ///
  /// In ar, this message translates to:
  /// **'سجّل وجباتك هذا الأسبوع لترى تقريرك هنا'**
  String get emptyWeek;

  /// No description provided for @emptyWeekAction.
  ///
  /// In ar, this message translates to:
  /// **'اذهب إلى اليوم'**
  String get emptyWeekAction;

  /// No description provided for @calendarStreak.
  ///
  /// In ar, this message translates to:
  /// **'🔥 {count} أيام متتالية'**
  String calendarStreak(Object count);

  /// No description provided for @weightStart.
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get weightStart;

  /// No description provided for @weightNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get weightNow;

  /// No description provided for @weightGoal.
  ///
  /// In ar, this message translates to:
  /// **'الهدف'**
  String get weightGoal;

  /// No description provided for @weightMaintain.
  ///
  /// In ar, this message translates to:
  /// **'الحفاظ'**
  String get weightMaintain;

  /// No description provided for @weightFewPoints.
  ///
  /// In ar, this message translates to:
  /// **'سجّل وزنك بانتظام لترى مسارك هنا'**
  String get weightFewPoints;

  /// No description provided for @weightLogToday.
  ///
  /// In ar, this message translates to:
  /// **'سجّل وزنك اليوم'**
  String get weightLogToday;

  /// No description provided for @weightDays.
  ///
  /// In ar, this message translates to:
  /// **'{days} يومًا'**
  String weightDays(Object days);

  /// No description provided for @weightChartSummary.
  ///
  /// In ar, this message translates to:
  /// **'{count} قياسات للوزن، من {first} إلى {last} كغ'**
  String weightChartSummary(Object count, Object first, Object last);

  /// No description provided for @caloriesChartSummary.
  ///
  /// In ar, this message translates to:
  /// **'سعرات الأسبوع: {values}'**
  String caloriesChartSummary(Object values);

  /// No description provided for @adherenceRing.
  ///
  /// In ar, this message translates to:
  /// **'التزام {percent}%'**
  String adherenceRing(Object percent);

  /// No description provided for @rateTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف كانت الوجبة؟'**
  String get rateTitle;

  /// No description provided for @rateLater.
  ///
  /// In ar, this message translates to:
  /// **'لاحقًا'**
  String get rateLater;

  /// No description provided for @rateThanks.
  ///
  /// In ar, this message translates to:
  /// **'شكرًا، سنقترح ما يناسب ذوقك أكثر'**
  String get rateThanks;

  /// No description provided for @rateStar.
  ///
  /// In ar, this message translates to:
  /// **'{value} من 5'**
  String rateStar(Object value);

  /// No description provided for @rateThisMeal.
  ///
  /// In ar, this message translates to:
  /// **'قيّم الوجبة'**
  String get rateThisMeal;

  /// No description provided for @didNotEat.
  ///
  /// In ar, this message translates to:
  /// **'لم آكلها'**
  String get didNotEat;

  /// No description provided for @didNotEatConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سنقلل اقتراح هذه الوجبة قليلًا. متابعة؟'**
  String get didNotEatConfirm;

  /// No description provided for @didNotEatContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get didNotEatContinue;

  /// No description provided for @didNotEatCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get didNotEatCancel;

  /// No description provided for @didNotEatMarked.
  ///
  /// In ar, this message translates to:
  /// **'سُجلت: لم تؤكل'**
  String get didNotEatMarked;

  /// No description provided for @badgeFirstLog.
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get badgeFirstLog;

  /// No description provided for @badgeFirstLogDesc.
  ///
  /// In ar, this message translates to:
  /// **'سجّلت أول وجبة لك'**
  String get badgeFirstLogDesc;

  /// No description provided for @badgeFirstAchievedDay.
  ///
  /// In ar, this message translates to:
  /// **'يوم متوازن'**
  String get badgeFirstAchievedDay;

  /// No description provided for @badgeFirstAchievedDayDesc.
  ///
  /// In ar, this message translates to:
  /// **'يوم بلغت فيه هدفك'**
  String get badgeFirstAchievedDayDesc;

  /// No description provided for @badgeStreak3.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثة أيام متتالية'**
  String get badgeStreak3;

  /// No description provided for @badgeStreak3Desc.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثة أيام متتالية على هدفك'**
  String get badgeStreak3Desc;

  /// No description provided for @badgeStreak7.
  ///
  /// In ar, this message translates to:
  /// **'أسبوع كامل'**
  String get badgeStreak7;

  /// No description provided for @badgeStreak7Desc.
  ///
  /// In ar, this message translates to:
  /// **'سبعة أيام متتالية على هدفك'**
  String get badgeStreak7Desc;

  /// No description provided for @badgeStreak14.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعان بثبات'**
  String get badgeStreak14;

  /// No description provided for @badgeStreak14Desc.
  ///
  /// In ar, this message translates to:
  /// **'أربعة عشر يومًا متتالية على هدفك'**
  String get badgeStreak14Desc;

  /// No description provided for @badgeStreak30.
  ///
  /// In ar, this message translates to:
  /// **'شهر من الالتزام'**
  String get badgeStreak30;

  /// No description provided for @badgeStreak30Desc.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثون يومًا متتالية على هدفك'**
  String get badgeStreak30Desc;

  /// No description provided for @badgeBalancedWeek.
  ///
  /// In ar, this message translates to:
  /// **'أسبوع متوازن'**
  String get badgeBalancedWeek;

  /// No description provided for @badgeBalancedWeekDesc.
  ///
  /// In ar, this message translates to:
  /// **'خمسة أيام متوازنة خلال سبعة أيام'**
  String get badgeBalancedWeekDesc;

  /// No description provided for @badgeWaterGoal3.
  ///
  /// In ar, this message translates to:
  /// **'صديق الماء'**
  String get badgeWaterGoal3;

  /// No description provided for @badgeWaterGoal3Desc.
  ///
  /// In ar, this message translates to:
  /// **'بلغت هدف الماء في ثلاثة أيام'**
  String get badgeWaterGoal3Desc;

  /// No description provided for @badgeWeightTracker.
  ///
  /// In ar, this message translates to:
  /// **'متابع وزنه'**
  String get badgeWeightTracker;

  /// No description provided for @badgeWeightTrackerDesc.
  ///
  /// In ar, this message translates to:
  /// **'أربعة أوزان على مدى ثلاثة أسابيع'**
  String get badgeWeightTrackerDesc;

  /// No description provided for @badgeExplorer10.
  ///
  /// In ar, this message translates to:
  /// **'مستكشف النكهات'**
  String get badgeExplorer10;

  /// No description provided for @badgeExplorer10Desc.
  ///
  /// In ar, this message translates to:
  /// **'جرّبت عشر وجبات مختلفة'**
  String get badgeExplorer10Desc;

  /// No description provided for @badgeEarnedOn.
  ///
  /// In ar, this message translates to:
  /// **'حصلت عليها في {date}'**
  String badgeEarnedOn(Object date);

  /// No description provided for @badgeProgress.
  ///
  /// In ar, this message translates to:
  /// **'{current} من {target}'**
  String badgeProgress(Object current, Object target);

  /// No description provided for @badgeWaterHint.
  ///
  /// In ar, this message translates to:
  /// **'حدّد هدف الماء لتبدأ'**
  String get badgeWaterHint;

  /// No description provided for @badgeCelebrate.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت! حصلت على {name}'**
  String badgeCelebrate(Object name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
