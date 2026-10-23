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
}
