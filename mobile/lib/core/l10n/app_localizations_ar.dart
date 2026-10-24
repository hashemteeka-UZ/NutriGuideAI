// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'NutriGuide';

  @override
  String get serverCheckLoading => 'جارٍ التحقق من الخادم';

  @override
  String get serverCheckConnected => 'الخادم متصل';

  @override
  String get serverCheckNeedsUpdate => 'التطبيق يحتاج تحديثًا';

  @override
  String get serverCheckRetry => 'إعادة المحاولة';

  @override
  String get serverCheckApiVersionLabel => 'إصدار الواجهة';

  @override
  String get serverCheckDatasetVersionLabel => 'إصدار الكتالوج';

  @override
  String get serverCheckPlannerLabel => 'المخطّط';

  @override
  String get serverCheckUnknownValue => 'غير معروف';

  @override
  String get failureRateLimited => 'طلبات كثيرة. حاول بعد قليل.';

  @override
  String get failurePlannerBusy => 'المخطّط مشغول الآن. حاول بعد قليل.';

  @override
  String get failurePlannerTimeout => 'تعذر بناء الخطة الآن. حاول مرة أخرى.';

  @override
  String get failureUnauthorized => 'انتهت الجلسة. سجّل الدخول من جديد.';

  @override
  String get failureTokenReused =>
      'انتهت الجلسة لأسباب أمنية. سجّل الدخول من جديد.';

  @override
  String get failureValidation => 'بعض البيانات غير صالحة.';

  @override
  String get failureServiceUnavailable => 'الخدمة غير متاحة الآن. حاول لاحقًا.';

  @override
  String get failureInternal => 'حدث خطأ في الخادم. حاول لاحقًا.';

  @override
  String get failureNetwork => 'لا يوجد اتصال بالخادم.';

  @override
  String get failureTimeout => 'انتهت مهلة الاتصال بالخادم.';

  @override
  String get failureUnexpectedResponse => 'تعذر قراءة رد الخادم.';

  @override
  String get failureGeneric => 'حدث خطأ غير متوقع.';

  @override
  String failureRateLimitedSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'محاولات كثيرة. حاول بعد $seconds ثانية.',
      many: 'محاولات كثيرة. حاول بعد $seconds ثانية.',
      few: 'محاولات كثيرة. حاول بعد $seconds ثوانٍ.',
      two: 'محاولات كثيرة. حاول بعد ثانيتين.',
      one: 'محاولات كثيرة. حاول بعد ثانية واحدة.',
      zero: 'محاولات كثيرة. حاول بعد $seconds ثانية.',
    );
    return '$_temp0';
  }

  @override
  String get failureEmailTaken =>
      'هذا البريد مسجل مسبقًا. سجّل الدخول بدلًا من ذلك.';

  @override
  String get failureInvalidCredentials => 'البريد أو كلمة المرور غير صحيحة.';

  @override
  String get failureTokenInvalid => 'انتهت الجلسة. سجّل الدخول من جديد.';

  @override
  String get splashLoading => 'جارٍ فتح التطبيق';

  @override
  String get welcomeSlide1Title => 'خطة تُبنى لك أنت';

  @override
  String get welcomeSlide1Body =>
      'محرك ذكي يختار وجباتك من مطبخنا المحلي حسب جسمك وهدفك وما تحب.';

  @override
  String get welcomeSlide2Title => 'تناسب يومك';

  @override
  String get welcomeSlide2Body =>
      'مواعيد الوجبات والماء تُرتب حسب وقت استيقاظك ونومك.';

  @override
  String get welcomeSlide3Title => 'ترى تقدمك';

  @override
  String get welcomeSlide3Body => 'رسوم واضحة وتقرير أسبوعي وإنجازات تحفزك.';

  @override
  String get welcomeStart => 'ابدأ رحلتك';

  @override
  String get welcomeHaveAccount => 'لدي حساب';

  @override
  String get authBack => 'رجوع';

  @override
  String get registerTitle => 'أنشئ حسابك';

  @override
  String get registerSubtitle => 'دقيقة واحدة، ثم نبني خطتك';

  @override
  String get registerSubmit => 'إنشاء الحساب';

  @override
  String get registerFooterPrompt => 'لديك حساب؟';

  @override
  String get registerFooterAction => 'سجّل دخولك';

  @override
  String get loginTitle => 'أهلًا بعودتك';

  @override
  String get loginSubtitle => 'سجل دخولك لتكمل خطتك';

  @override
  String get loginSubmit => 'دخول';

  @override
  String get loginFooterPrompt => 'ليس لديك حساب؟';

  @override
  String get loginFooterAction => 'أنشئ حسابًا';

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authShowPassword => 'إظهار كلمة المرور';

  @override
  String get authHidePassword => 'إخفاء كلمة المرور';

  @override
  String get authPasswordHint => '٨ أحرف على الأقل';

  @override
  String get authEmailRequired => 'أدخل البريد الإلكتروني.';

  @override
  String get authEmailInvalid => 'البريد الإلكتروني غير صالح.';

  @override
  String get authPasswordRequired => 'أدخل كلمة المرور.';

  @override
  String get authPasswordTooShort => '٨ أحرف على الأقل.';

  @override
  String get authPasswordTooLong => '١٢٨ حرفًا كحد أقصى.';

  @override
  String get authPasswordInvalid => 'كلمة المرور غير صالحة.';

  @override
  String get onboardingPlaceholder => 'سنجهز خطتك هنا قريبًا';

  @override
  String get homeGreeting => 'أهلًا';

  @override
  String get logout => 'خروج';
}
