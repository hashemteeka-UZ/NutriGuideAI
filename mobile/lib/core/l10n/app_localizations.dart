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
