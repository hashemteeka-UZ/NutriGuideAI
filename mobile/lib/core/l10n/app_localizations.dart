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
  /// **'تعذر بناء الخطة الآن. حاول مرة أخرى.'**
  String get failurePlannerTimeout;

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

  /// No description provided for @onboardingPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'سنجهز خطتك هنا قريبًا'**
  String get onboardingPlaceholder;

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
