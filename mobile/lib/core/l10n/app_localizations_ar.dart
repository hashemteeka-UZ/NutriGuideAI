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
  String get failurePlannerTimeout =>
      'تعذر بناء الخطة الآن، حاول مرة أخرى بعد قليل.';

  @override
  String get failureNotEligible => 'الخطة الشخصية غير متاحة لهذا الحساب.';

  @override
  String get failureNoTarget => 'لا يوجد هدف سعرات بعد.';

  @override
  String get failureConditionConflict =>
      'الحالات الصحية تتعارض مع بناء خطة شخصية.';

  @override
  String get failureNoFeasiblePlan => 'لا توجد خطة تناسب حدود هذا اليوم.';

  @override
  String get failureSwapRejected =>
      'لا يمكن هذا الاستبدال لأنه يتجاوز حدود يومك.';

  @override
  String get failurePlanItemNotFound => 'لم تعد هذه الوجبة في الخطة.';

  @override
  String get failurePlanItemAlreadyLogged =>
      'سجلت هذه الوجبة، لا يمكن استبدالها.';

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
  String get homeGreeting => 'أهلًا';

  @override
  String get logout => 'خروج';

  @override
  String get failureTargetValidation => 'الوزن المستهدف أو السرعة غير صالحة.';

  @override
  String get failureNoWeight => 'الوزن غير موجود. حاول مرة أخرى.';

  @override
  String get failureInvalidTimezone => 'المنطقة الزمنية غير مقبولة.';

  @override
  String get failureUnknownCode => 'أحد الاختيارات غير معروف.';

  @override
  String get failureProfileNotFound => 'الملف غير موجود.';

  @override
  String get failureMealNotFound => 'هذه الوجبة لم تعد في الكتالوج.';

  @override
  String get onbContinue => 'متابعة';

  @override
  String get onbBack => 'رجوع';

  @override
  String get onbRetry => 'إعادة المحاولة';

  @override
  String onbStepProgress(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get onbChecking => 'نتحقق من حسابك...';

  @override
  String get onbCalculating => 'نحسب احتياجاتك...';

  @override
  String get onbReferenceError => 'تعذر تحميل قوائم الإعداد.';

  @override
  String get onbJustForYou => 'سؤال خاص بك';

  @override
  String get onbBecauseWeight => 'لأن هدفك تغيير الوزن';

  @override
  String get onbBecauseHeart => 'لأن صحة القلب تحتاج متابعة الماء مع الطبيب';

  @override
  String get onbAboutTitle => 'عرّفنا بنفسك';

  @override
  String get onbAboutSubtitle => 'الجنس والعمر يغيران احتياجك اليومي من الطاقة';

  @override
  String get onbSexMale => 'ذكر';

  @override
  String get onbSexFemale => 'أنثى';

  @override
  String onbAge(String age) {
    return 'العمر: $age سنة';
  }

  @override
  String get onbMeasureTitle => 'الطول والوزن';

  @override
  String get onbMeasureSubtitle => 'نحسب بهما احتياجك ونتابع تقدمك';

  @override
  String get onbHeight => 'الطول';

  @override
  String get onbWeight => 'الوزن';

  @override
  String get onbCm => 'سم';

  @override
  String get onbKg => 'كغ';

  @override
  String get onbBmi => 'مؤشر كتلة الجسم';

  @override
  String get onbBmiUnder => 'أقل من الطبيعي';

  @override
  String get onbBmiNormal => 'طبيعي';

  @override
  String get onbBmiOver => 'فوق الطبيعي';

  @override
  String get onbBmiHigh => 'مرتفع';

  @override
  String get onbBmiExplainTitle => 'ما هو مؤشر كتلة الجسم؟';

  @override
  String get onbBmiExplainBody =>
      'رقم تقريبي من الوزن والطول (الوزن ÷ مربع الطول بالمتر). نستخدمه كمؤشر عام فقط، ولا يقيس نسبة الدهون أو العضلات.';

  @override
  String onbGoalTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'ما هدفكِ؟',
      'other': 'ما هدفك؟',
    });
    return '$_temp0';
  }

  @override
  String get onbGoalSubtitle => 'نبني سعراتك اليومية حول هدفك';

  @override
  String get onbGoalLose => 'إنقاص الوزن';

  @override
  String get onbGoalLoseBody => 'عجز معتدل وآمن في السعرات';

  @override
  String get onbGoalMaintain => 'المحافظة على وزني';

  @override
  String get onbGoalMaintainBody => 'أكل متوازن يحافظ على طاقتك';

  @override
  String get onbGoalGain => 'زيادة الوزن';

  @override
  String get onbGoalGainBody => 'فائض مدروس في السعرات';

  @override
  String get onbLoseUnavailable => 'لا نقترح هدفًا أقل من الوزن الطبيعي لطولك';

  @override
  String onbPaceLoseTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'إلى أين تريدين أن تصلي؟',
      'other': 'إلى أين تريد أن تصل؟',
    });
    return '$_temp0';
  }

  @override
  String onbPaceGainTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'كم تريدين أن تزيدي؟',
      'other': 'كم تريد أن تزيد؟',
    });
    return '$_temp0';
  }

  @override
  String onbPaceSubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'اختاري وزنكِ المستهدف وسرعة الوصول',
      'other': 'اختر وزنك المستهدف وسرعة الوصول',
    });
    return '$_temp0';
  }

  @override
  String get onbTargetWeight => 'الوزن المستهدف';

  @override
  String get onbPaceHeading => 'السرعة';

  @override
  String get onbRateGentle => 'هادئة · الأسهل للاستمرار';

  @override
  String get onbRateGentleBody => 'ربع كغ أسبوعيًا';

  @override
  String get onbRateBalanced => 'متوازنة · ننصح بها';

  @override
  String get onbRateBalancedBody => 'نصف كغ أسبوعيًا';

  @override
  String get onbRateFaster => 'أسرع';

  @override
  String get onbRateFasterBody => 'ثلاثة أرباع كغ أسبوعيًا';

  @override
  String get onbRateMax => 'الأقصى';

  @override
  String get onbRateMaxBody => 'كغ أسبوعيًا';

  @override
  String get onbRateUnavailable =>
      'غير متاحة لوزنك الحالي (أكثر من 1% أسبوعيًا)';

  @override
  String get onbGainCap => 'الحد الآمن للزيادة نصف كغ أسبوعيًا';

  @override
  String onbArrival(String sex, String weight, String weeks, String when) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'تصلين إلى $weight كغ بعد نحو $weeks أسبوعًا، تقريبًا في $when',
      'other': 'تصل إلى $weight كغ بعد نحو $weeks أسبوعًا، تقريبًا في $when',
    });
    return '$_temp0';
  }

  @override
  String onbActivityTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'كم تتحركين في يومكِ؟',
      'other': 'كم تتحرك في يومك؟',
    });
    return '$_temp0';
  }

  @override
  String onbActivitySubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'اختاري ما يصف أسبوعكِ المعتاد',
      'other': 'اختر ما يصف أسبوعك المعتاد',
    });
    return '$_temp0';
  }

  @override
  String get onbActSedentary => 'قليل الحركة';

  @override
  String get onbActSedentaryBody => 'عمل مكتبي، مشي قليل';

  @override
  String get onbActLight => 'نشاط خفيف';

  @override
  String get onbActLightBody => 'مشي أو رياضة خفيفة 1 إلى 3 أيام';

  @override
  String get onbActModerate => 'نشاط معتدل';

  @override
  String get onbActModerateBody => 'رياضة متوسطة 3 إلى 5 أيام';

  @override
  String get onbActHigh => 'نشيط جدًا';

  @override
  String get onbActHighBody => 'رياضة قوية 6 إلى 7 أيام';

  @override
  String get onbActAthlete => 'رياضي';

  @override
  String get onbActAthleteBody => 'تدريب يومي مكثف أو عمل بدني شاق';

  @override
  String onbActivityTip(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'نشاطكِ يحدد كم تحرقين يوميًا. إن ترددتِ بين خيارين، اختاري الأقل لتكون الخطة أدق.',
      'other': 'نشاطك يحدد كم تحرق يوميًا. إن ترددت بين خيارين، اختر الأقل لتكون الخطة أدق.',
    });
    return '$_temp0';
  }

  @override
  String onbCareTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'هل نراعي شيئًا في أكلكِ؟',
      'other': 'هل نراعي شيئًا في أكلك؟',
    });
    return '$_temp0';
  }

  @override
  String onbCareSubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'اختاري ما ينطبق عليكِ، ونختار لكِ وجبات لا تتعارض معه',
      'other': 'اختر ما ينطبق عليك، ونختار لك وجبات لا تتعارض معه',
    });
    return '$_temp0';
  }

  @override
  String get onbCareNone => 'لا شيء';

  @override
  String get onbCareNoneBody => 'أريد أكلًا صحيًا ومتوازنًا فقط';

  @override
  String get onbCareDiabetesBody => 'سكريات أقل وكربوهيدرات موزعة على وجباتك';

  @override
  String get onbCarePressureBody => 'ملح أقل في وجباتك اليومية';

  @override
  String get onbCareHeartBody => 'دهون صحية وملح أقل';

  @override
  String get onbCareExplainTitle => 'كيف نراعي ذلك؟';

  @override
  String get onbCareExplainBody =>
      'NutriGuide لا يعالج أي حالة، ولا يغني عن طبيبك. هو فقط يتجنب في خطتك ما قد لا يناسبك، مثل الملح الزائد أو السكريات، حسب توصيات منظمة الصحة العالمية وجمعيات الصحة.';

  @override
  String onbAllergyTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'هل تتجنبين أي مكون؟',
      'other': 'هل تتجنب أي مكون؟',
    });
    return '$_temp0';
  }

  @override
  String onbAllergySubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'اضغطي مرة للتجنب، ومرتين إذا كانت حساسية شديدة',
      'other': 'اضغط مرة للتجنب، ومرتين إذا كانت حساسية شديدة',
    });
    return '$_temp0';
  }

  @override
  String get onbAvoid => 'تجنب';

  @override
  String get onbSevere => 'شديدة';

  @override
  String get onbAllergyTip =>
      '«تجنب» يعني أننا لا نضعه في خطتك. «شديدة» تعني أيضًا أننا نحذرك بوضوح إذا ظهر في أي وجبة تتصفحها.';

  @override
  String get onbSafetyTitle => 'سؤال أخير للاطمئنان';

  @override
  String onbSafetySubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'حتى نتأكد أن الخطة الشخصية مناسبة لكِ',
      'other': 'حتى نتأكد أن الخطة الشخصية مناسبة لك',
    });
    return '$_temp0';
  }

  @override
  String onbInsulinQuestion(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'هل تستخدمين الإنسولين؟',
      'other': 'هل تستخدم الإنسولين؟',
    });
    return '$_temp0';
  }

  @override
  String get onbYes => 'نعم';

  @override
  String get onbNo => 'لا';

  @override
  String get onbWhyAsk => 'لماذا نسأل؟';

  @override
  String get onbWhyAskBody =>
      'استخدام الإنسولين يحتاج تخطيط الكربوهيدرات مرتبطًا بالجرعات، وهذا لا يغطيه التطبيق، فيُستخدم الوضع العام.';

  @override
  String onbRhythmTitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'FEMALE': 'كيف يبدو يومكِ؟',
      'other': 'كيف يبدو يومك؟',
    });
    return '$_temp0';
  }

  @override
  String get onbRhythmSubtitle =>
      'نرتب مواعيد وجباتك ومائك حول وقت استيقاظك ونومك';

  @override
  String get onbWake => 'أستيقظ';

  @override
  String get onbSleep => 'أنام';

  @override
  String get onbSuggestedDay => 'يومك المقترح';

  @override
  String get onbBreakfast => 'الفطور';

  @override
  String get onbLunch => 'الغداء';

  @override
  String get onbSnack => 'وجبة خفيفة';

  @override
  String get onbDinner => 'العشاء';

  @override
  String onbWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String get onbFluidTitle => 'متابعة الماء مع طبيبك';

  @override
  String get onbFluidSubtitle =>
      'بعض حالات القلب يحدد لها الطبيب كمية سوائل يومية';

  @override
  String get onbFluidNone => 'لم يحدد لي طبيبي كمية';

  @override
  String get onbFluidNoneBody =>
      'لا بأس. سنسجل ما تشربه ونعرضه لك دون أن نضع هدفًا أو نذكرك بالشرب.';

  @override
  String get onbFluidDoctor => 'حدد لي طبيبي كمية يومية';

  @override
  String get onbFluidRange => 'بين 500 و5000 مل';

  @override
  String get onbMl => 'مل';

  @override
  String get onbResultTitle => 'هذه احتياجاتك اليومية، محسوبة لك أنت';

  @override
  String get onbDailyCalories => 'سعراتك اليومية';

  @override
  String get onbLineLose => 'لإنقاص وزنك';

  @override
  String get onbLineMaintain => 'للمحافظة على وزنك';

  @override
  String get onbLineGain => 'لزيادة وزنك';

  @override
  String get onbProtein => 'بروتين';

  @override
  String get onbCarbs => 'كربوهيدرات';

  @override
  String get onbFat => 'دهون';

  @override
  String get onbFiber => 'ألياف';

  @override
  String get onbWater => 'الماء';

  @override
  String get onbGrams => 'غ';

  @override
  String onbMacroShare(String share) {
    return '$share من السعرات';
  }

  @override
  String get onbWaterClinician => 'بالتنسيق مع طبيبك';

  @override
  String get onbWaterNone => 'بدون هدف';

  @override
  String get onbHowTitle => 'كيف حسبناها؟';

  @override
  String get onbHowRestTitle => 'الطاقة وقت الراحة (معادلة Mifflin-St Jeor)';

  @override
  String get onbHowRestBody =>
      'هذا ما يحتاجه جسمك للطاقة وأنت مرتاح تمامًا، بحسب معادلة ميفلين-سانت جيور.';

  @override
  String get onbHowActivityTitle => '× معامل نشاطك';

  @override
  String onbHowActivityBody(String factor) {
    return 'نضرب طاقة الراحة في معامل نشاطك ($factor) لنحصل على ما تحرقه في يومك المعتاد.';
  }

  @override
  String get onbHowDeficitTitle => '− عجز إنقاص الوزن';

  @override
  String get onbHowDeficitBody =>
      'هذا الفرق الذي نخصمه من احتياجك حتى ينخفض الوزن بالسرعة التي اخترتها.';

  @override
  String get onbHowSurplusTitle => '+ فائض الزيادة';

  @override
  String get onbHowSurplusBody =>
      'هذه الزيادة فوق احتياجك حتى يرتفع الوزن بالسرعة التي اخترتها.';

  @override
  String get onbHowFloorTitle => 'رفعنا السعرات إلى الحد الأدنى الآمن';

  @override
  String get onbHowFloorBody =>
      'الخطة لا تنزل تحت حد أدنى آمن، لذلك رفعنا السعرات إليه.';

  @override
  String get onbHowDailyTitle => 'هدفك اليومي';

  @override
  String onbHowBasedOn(String weight) {
    return 'محسوبة على وزن $weight كغ';
  }

  @override
  String get onbBuildPlan => 'ابنِ خطتي الأولى';

  @override
  String get onbGeneralTitle => 'حسابك جاهز في الوضع العام';

  @override
  String get onbReasonUnder18 => 'الخطة الشخصية مخصصة للبالغين';

  @override
  String get onbReasonInsulin =>
      'استخدام الإنسولين يحتاج تخطيطًا مع طبيبك لا يغطيه التطبيق';

  @override
  String get onbReasonGeneric => 'وضعك يحتاج تقديرًا لا تغطيه الخطة الشخصية.';

  @override
  String get onbCanDo => 'ماذا يمكنك أن تفعل؟';

  @override
  String get onbCanMeals => 'تصفح وجبات صحية مع قيمها الغذائية';

  @override
  String get onbCanLog => 'سجل أكلك ومائك يوميًا';

  @override
  String get onbCanProgress => 'تابع وزنك وتقدمك برسوم واضحة';

  @override
  String get onbCanShop => 'اصنع قائمة مشترياتك';

  @override
  String get onbEnterApp => 'ادخل التطبيق';

  @override
  String get onbTimezoneNote =>
      'لم تُقبل المنطقة الزمنية للجهاز، فحُفظ الملف بتوقيت UTC.';

  @override
  String get browseMeals => 'تصفح الوجبات';

  @override
  String get mealSearchHint => 'ابحث عن وجبة';

  @override
  String get mealSlotAll => 'الكل';

  @override
  String get mealSlotBreakfast => 'فطور';

  @override
  String get mealSlotLunch => 'غداء';

  @override
  String get mealSlotDinner => 'عشاء';

  @override
  String get mealSlotSnack => 'خفيفة';

  @override
  String get mealHideAvoided => 'إخفاء ما يحتوي على ما أتجنبه';

  @override
  String mealFooter(int count, String updated) {
    return '$count وجبة · آخر تحديث $updated';
  }

  @override
  String get mealOfflineEmpty =>
      'نحتاج اتصالًا مرة واحدة لتحميل الوجبات، ثم تعمل دون إنترنت';

  @override
  String get mealNoResults => 'لا توجد وجبات بهذا الاسم';

  @override
  String get mealClearFilters => 'مسح التصفية';

  @override
  String get mealRetry => 'إعادة المحاولة';

  @override
  String mealKcal(String kcal) {
    return '$kcal سعرة';
  }

  @override
  String mealProtein(String grams) {
    return '$grams غ بروتين';
  }

  @override
  String mealServing(String grams) {
    return '$grams غ';
  }

  @override
  String get mealAllergenBadge => 'تحتوي على ما تتجنبه';

  @override
  String mealAllergenWarning(String names) {
    return 'تحتوي على $names مما سجلت أنك تتجنبه';
  }

  @override
  String get mealMacroKcal => 'سعرة';

  @override
  String get mealSodium => 'الصوديوم (الملح)';

  @override
  String get mealSaturatedFat => 'الدهون المشبعة';

  @override
  String get mealFacts => 'القيم الغذائية كاملة';

  @override
  String get mealIngredients => 'المكونات';

  @override
  String get mealOptional => 'اختياري';

  @override
  String get mealSteps => 'التحضير';

  @override
  String get mealStepsSoon => 'خطوات التحضير ستضاف قريبًا';

  @override
  String get mealDislike => 'لا أحب هذه الوجبة، لا تقترحها مجددًا';

  @override
  String get mealDislikeUndo => 'لن نقترحها مجددًا · تراجع';

  @override
  String get mealFavourite => 'مفضلة';

  @override
  String get mealPrefSaveFailed => 'تعذر الحفظ، تحقق من الاتصال';

  @override
  String get mealFavouritesTitle => 'وجباتي المفضلة';

  @override
  String get mealFavouritesHint => 'يقترحها المحرك أكثر في خطتك';

  @override
  String get mealDislikesTitle => 'لا أحبها';

  @override
  String get mealDislikesHint => 'لن تظهر في خطتك';

  @override
  String get mealFavouritesEmpty => 'لا توجد بعد. اضغط القلب في أي وجبة.';

  @override
  String get mealDislikesEmpty => 'لا توجد.';

  @override
  String get mealRemove => 'إزالة';

  @override
  String get mealMg => 'ملغ';

  @override
  String get nutrientEnergy => 'الطاقة';

  @override
  String get nutrientProtein => 'بروتين';

  @override
  String get nutrientCarbs => 'كربوهيدرات';

  @override
  String get nutrientFat => 'دهون';

  @override
  String get nutrientFiber => 'ألياف';

  @override
  String get nutrientSugars => 'سكريات';

  @override
  String get nutrientSaturatedFat => 'دهون مشبعة';

  @override
  String get nutrientCholesterol => 'كوليسترول';

  @override
  String get nutrientSodium => 'صوديوم';

  @override
  String get nutrientPotassium => 'بوتاسيوم';

  @override
  String get allergenGluten => 'الغلوتين';

  @override
  String get allergenMilk => 'الحليب';

  @override
  String get allergenEgg => 'البيض';

  @override
  String get allergenFish => 'السمك';

  @override
  String get allergenPeanut => 'الفول السوداني';

  @override
  String get allergenTreeNuts => 'المكسرات';

  @override
  String get allergenSesame => 'السمسم';

  @override
  String get allergenSoy => 'الصويا';

  @override
  String get tabToday => 'اليوم';

  @override
  String get tabPlan => 'الخطة';

  @override
  String get tabWater => 'الماء';

  @override
  String get tabProgress => 'تقدمي';

  @override
  String get tabMe => 'حسابي';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get waterSoon => 'تسجيل الماء يأتي في الخطوة التالية.';

  @override
  String get progressSoon =>
      'الالتزام والتقرير الأسبوعي والإنجازات تأتي لاحقًا.';

  @override
  String get greetMorning => 'صباح الخير';

  @override
  String get greetEvening => 'مساء الخير';

  @override
  String get kcalModeEaten => 'المستهلك';

  @override
  String get kcalModeLeft => 'المتبقي';

  @override
  String get kcalEatenCaption => 'سعرة أكلتها اليوم';

  @override
  String get kcalLeftCaption => 'سعرة متبقية لك';

  @override
  String kcalOfTarget(String kcal) {
    return 'من هدف $kcal سعرة';
  }

  @override
  String get todayNoPlan => 'لم تُبنَ خطة اليوم بعد';

  @override
  String get todayBuildWeek => 'ابنِ خطة الأسبوع';

  @override
  String nowCard(String slot, String time) {
    return 'وقت $slot الآن · حتى $time';
  }

  @override
  String get waterWithDoctor => 'بالتنسيق مع طبيبك';

  @override
  String get todayMeals => 'وجبات اليوم';

  @override
  String get fullPlan => 'الخطة كاملة';

  @override
  String get stateDone => 'تمت';

  @override
  String get stateNow => 'الآن';

  @override
  String get stateMissed => 'فات موعدها';

  @override
  String get generalTitle => 'الوضع العام';

  @override
  String get generalBody =>
      'تسجل أكلك وماءك وترى تقدمك. لا توجد خطة سعرات شخصية.';

  @override
  String get healthyTitle => 'وجبات صحية لتجربتها';

  @override
  String get offlineBar => 'دون اتصال · تعرض آخر نسخة محفوظة';

  @override
  String get planTitle => 'خطتك للأسبوع';

  @override
  String planRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get planOptimizer => 'بُنيت بالمحسّن';

  @override
  String get planRebuild => 'إعادة البناء';

  @override
  String get planRebuildBody =>
      'سنبني أيام الأسبوع من جديد. الأيام التي سجلت فيها وجبة تبقى كما هي.';

  @override
  String get planRebuildConfirm => 'إعادة البناء';

  @override
  String get planCancel => 'إلغاء';

  @override
  String get planChartTitle => 'سعرات الأسبوع المخطط';

  @override
  String planTargetLabel(String kcal) {
    return 'الهدف $kcal';
  }

  @override
  String get withinBand => 'ضمن ‎±10%‎ من هدفك';

  @override
  String belowMinimum(String nutrient) {
    return 'أقل من الحد الأدنى: $nutrient';
  }

  @override
  String get planEmpty => 'لا توجد خطة لهذا اليوم';

  @override
  String get generalPlanTip =>
      'في الوضع العام لا نبني خطة شخصية، لكن يمكنك تصفح الوجبات وحفظ ما يعجبك في المفضلة.';

  @override
  String planDayKcal(String day, String kcal) {
    return '$day · $kcal سعرة';
  }

  @override
  String itemPortion(String multiplier, String grams) {
    return 'كميتك: $multiplier حصة · ≈ $grams غ';
  }

  @override
  String get whyChosen => 'لماذا اخترناها لك؟';

  @override
  String get perServingFacts => 'القيم الغذائية لحصة واحدة';

  @override
  String get perServingNote => 'لكل حصة';

  @override
  String get swapAction => 'استبدال';

  @override
  String get swapLoggedNote => 'سجلت هذه الوجبة، لا يمكن استبدالها.';

  @override
  String get swapTitle => 'بدائل تناسب خطتك';

  @override
  String get swapSubtitle => 'كلها تحافظ على سعرات يومك وحدودك';

  @override
  String get swapEmpty => 'لا توجد بدائل مناسبة الآن';

  @override
  String get swapOffline => 'الاستبدال يحتاج اتصالًا';

  @override
  String get swapDone => 'تم الاستبدال';

  @override
  String get genTitle => 'نبني خطتك الآن';

  @override
  String get genSkip => 'تخطي';

  @override
  String get genNeeds => 'نحسب احتياجك';

  @override
  String get genFilter => 'نستبعد ما لا يناسبك';

  @override
  String get genSearch => 'المحسّن يبحث عن أفضل تركيبة';

  @override
  String get genWeek => 'نبني أيام الأسبوع';

  @override
  String get genKcalPerDay => 'سعرة يوميًا';

  @override
  String get genMealsInKitchen => 'وجبة في المطبخ';

  @override
  String genAvoid(String name) {
    return 'تجنب $name';
  }

  @override
  String get genLessSalt => 'ملح أقل';

  @override
  String get genLessSugar => 'سكريات أقل';

  @override
  String get genNoDislike => 'بدون ما لا تحبه';

  @override
  String get genWithin => 'السعرات ضمن ‎±10%‎';

  @override
  String get genProtein => 'البروتين';

  @override
  String get genFiber => 'الألياف';

  @override
  String get genNoRepeat => 'بدون تكرار مع أمس';

  @override
  String genSolver(String status, String seconds) {
    return 'CP-SAT · $status · $seconds ث';
  }

  @override
  String get genReady => 'خطتك جاهزة';

  @override
  String get genStart => 'ابدأ يومك';

  @override
  String genPartial(int built) {
    return 'بنينا $built من 7 أيام';
  }

  @override
  String get genRetryLeft => 'حاول مرة أخرى للأيام الباقية';

  @override
  String get genNetwork =>
      'انقطع الاتصال. الأيام التي بُنيت محفوظة. حاول مرة أخرى.';

  @override
  String get genGeneric => 'تعذر إكمال البناء.';

  @override
  String get genIneligible => 'حسابك في الوضع العام، ولن نبني خطة شخصية.';

  @override
  String get shopTitle => 'قائمة المشتريات';

  @override
  String get shopNote => 'محسوبة من وجبات أسبوعك، دون المكونات الاختيارية';

  @override
  String shopProgress(int done, int total) {
    return '$done من $total مشتريات';
  }

  @override
  String get shopFromPlan => 'من خطة الأسبوع';

  @override
  String get favouritesCard => 'مفضلاتي';

  @override
  String favouritesCount(int count) {
    return '$count وجبات';
  }

  @override
  String shopInMeals(int count) {
    return 'في $count وجبات';
  }

  @override
  String get shopNeedsNet => 'نحتاج اتصالًا لحساب القائمة';

  @override
  String shopShareHeader(String from, String to) {
    return 'قائمة مشترياتي ($from – $to)';
  }

  @override
  String shopGrams(String grams) {
    return '≈ $grams غ';
  }

  @override
  String shopKg(String kg) {
    return '$kg كغ';
  }

  @override
  String get shopShare => 'مشاركة';

  @override
  String get chartNoPlan => 'لا توجد خطة';

  @override
  String get accountLanguage => 'English';

  @override
  String get eatAction => 'أكلتها';

  @override
  String get eatLogged => 'سجلتها';

  @override
  String get eatUndo => 'تراجع';

  @override
  String get eatOtherAmount => 'كمية مختلفة';

  @override
  String get eatAmountTitle => 'كم أكلت من الكمية المخططة؟';

  @override
  String get eatAmountHalf => 'النصف';

  @override
  String get eatAmountFull => 'الكمية كاملة';

  @override
  String get eatAmountOneHalf => 'مرة ونصف';

  @override
  String get eatSaved => 'سُجّلت الوجبة';

  @override
  String get eatUndone => 'أُلغي التسجيل';

  @override
  String get eatFailed => 'تعذر تسجيل الوجبة';

  @override
  String missedTitle(Object slot) {
    return 'فاتك موعد $slot';
  }

  @override
  String get missedBody => 'هل أكلتها؟ سجلها الآن حتى يبقى يومك دقيقًا';

  @override
  String get missedAction => 'سجّلها';

  @override
  String get provisionalNote => 'مؤقت حتى المزامنة';

  @override
  String get syncUploading => '⟳ جارٍ الرفع';

  @override
  String syncWaiting(Object count) {
    return '⇡ $count بانتظار الاتصال';
  }

  @override
  String get syncRejected => 'تعذر حفظ تسجيل';

  @override
  String get syncRejectedTitle => 'تسجيلات لم تُحفظ';

  @override
  String get syncDelete => 'حذف';

  @override
  String get syncClose => 'إغلاق';

  @override
  String get logoutPendingBody =>
      'لديك تسجيلات لم تُرفع بعد. الخروج سيحذفها من الهاتف.';

  @override
  String get logoutPendingConfirm => 'خروج وحذف';

  @override
  String get failureClientUuidConflict =>
      'هذا التسجيل محفوظ مسبقًا بمحتوى مختلف.';

  @override
  String get failureLogNotFound => 'لم يعد هذا التسجيل موجودًا.';

  @override
  String get failureClockSkew =>
      'وقت هاتفك متقدم على الوقت الصحيح. صحّحه ثم حاول مرة أخرى.';

  @override
  String get logRejectedGeneric => 'تعذر حفظ هذا التسجيل';

  @override
  String waterAmountMl(Object ml) {
    return '$ml مل';
  }

  @override
  String waterTotalOfGoal(Object goal, Object total) {
    return '$total / $goal مل';
  }

  @override
  String get waterTodayGoal => 'هدف اليوم';

  @override
  String get waterDoctorGoal => 'الهدف الذي حدده طبيبك';

  @override
  String get waterTotalOnly => 'مجموع اليوم';

  @override
  String get waterQuickSmall => 'كوب صغير';

  @override
  String get waterQuickCup => 'كوب';

  @override
  String get waterQuickBottle => 'زجاجة';

  @override
  String get waterCustom => 'مخصص';

  @override
  String get waterCustomTitle => 'كمية مخصصة';

  @override
  String get waterAdd => 'أضف';

  @override
  String get waterLargeTip => 'كمية كبيرة لمرة واحدة، يمكنك تقسيمها على مرتين.';

  @override
  String get waterTodayList => 'شرب اليوم';

  @override
  String get waterEmpty => 'لم تسجل ماء اليوم بعد';

  @override
  String get waterSaved => 'سُجّل الماء';

  @override
  String get waterClinicianTitle => 'كمية الماء يحددها طبيبك';

  @override
  String get waterClinicianAction => 'أدخل الكمية التي حددها طبيبك';

  @override
  String get waterSetGoal => 'حدد هدفًا';

  @override
  String get waterGoalSheetTitle => 'الكمية اليومية';

  @override
  String get waterGoalSave => 'احفظ';

  @override
  String get waterGoalSaved => 'حُفظ الهدف';

  @override
  String get waterNeedsConnection => 'يحتاج اتصالًا';

  @override
  String get waterRangeError => 'الكمية بين 50 و1000 مل';

  @override
  String get weightTitle => 'سجّل وزنك';

  @override
  String weightKgValue(Object kg) {
    return '$kg كغ';
  }

  @override
  String get weightSave => 'احفظ';

  @override
  String get weightSaved => 'حُفظ وزنك';

  @override
  String get weightQueued => 'حُفظ وزنك وسيُرفع عند الاتصال';

  @override
  String get weightStale => 'يوجد وزن أحدث محفوظ لهذا اليوم';

  @override
  String weightGoalReached(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'وصلتِ إلى هدفكِ!',
      'other': 'وصلت إلى هدفك!',
    });
    return '$_temp0';
  }

  @override
  String weightGoalReachedBody(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'أحسنتِ، استمري على عاداتكِ الجيدة.',
      'other': 'أحسنت، استمر على عاداتك الجيدة.',
    });
    return '$_temp0';
  }

  @override
  String get weightRangeError => 'الوزن بين 20 و400 كغ';

  @override
  String weightLatest(Object kg) {
    return 'آخر وزن: $kg كغ';
  }

  @override
  String get weightNone => 'لم تسجل وزنًا بعد';

  @override
  String get targetNoticeBody => 'تم تحديث هدفك اليومي بناءً على وزنك الجديد';

  @override
  String get targetNoticeRebuild => 'أعد بناء خطة الأيام القادمة';

  @override
  String get targetNoticeLater => 'لاحقًا';

  @override
  String get otherMealTitle => 'أكلت وجبة أخرى';

  @override
  String get otherMealServings => 'كم حصة أكلت؟';

  @override
  String get otherMealSlot => 'أي وجبة؟';

  @override
  String servingsCount(Object count) {
    return '$count حصة';
  }

  @override
  String get extrasTitle => 'إضافات اليوم';

  @override
  String get extraPending => 'بانتظار المزامنة';

  @override
  String get quickTitle => 'ماذا تريد أن تضيف؟';

  @override
  String get quickWater => 'سجّل ماء';

  @override
  String get fabLabel => 'إضافة';

  @override
  String get progressSegReport => 'تقرير الأسبوع';

  @override
  String get progressSegWeight => 'الوزن';

  @override
  String get progressSegBadges => 'الإنجازات';

  @override
  String get progressBadgesSoon => 'قريبًا: الشارات والإنجازات.';

  @override
  String weekRange(Object from, Object to) {
    return '$from – $to';
  }

  @override
  String get weekPrev => 'الأسبوع السابق';

  @override
  String get weekNext => 'الأسبوع التالي';

  @override
  String get headlineExcellent => 'أسبوع ممتاز!';

  @override
  String get headlineGood => 'أسبوع جيد';

  @override
  String get headlineFresh => 'كل يوم فرصة جديدة';

  @override
  String weekAchievedOf(Object achieved, Object counted, String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'حققتِ هدفكِ في $achieved من $counted أيام',
      'other': 'حققت هدفك في $achieved من $counted أيام',
    });
    return '$_temp0';
  }

  @override
  String get bestDayTitle => 'أفضل يوم';

  @override
  String bestDayBody(Object day, Object percent) {
    return '$day · $percent% من الهدف';
  }

  @override
  String get mostMissedTitle => 'أكثر ما نقصك';

  @override
  String mostMissedBody(
    Object days,
    Object minimum,
    Object nutrient,
    Object total,
  ) {
    return '$nutrient: $total من $minimum في المتوسط، في $days أيام';
  }

  @override
  String get waterAvgTitle => 'متوسط الماء';

  @override
  String waterAvgBody(Object ml) {
    return '$ml مل في اليوم';
  }

  @override
  String get caloriesChartTitle => 'السعرات مقابل الهدف';

  @override
  String get legendAchieved => 'ضمن الهدف';

  @override
  String get legendPartial => 'قريب';

  @override
  String get legendNot => 'بعيد';

  @override
  String get legendNone => 'لا تسجيل';

  @override
  String get macrosTitle => 'متوسط العناصر';

  @override
  String macroValue(Object avg, Object target) {
    return '$avg / $target غ';
  }

  @override
  String exceededTitle(Object days) {
    return 'تجاوزت حدًا صحيًا في $days أيام';
  }

  @override
  String exceededLine(Object limit, Object nutrient, Object total) {
    return '$nutrient: $total مقابل حد $limit';
  }

  @override
  String get emptyWeek => 'سجّل وجباتك هذا الأسبوع لترى تقريرك هنا';

  @override
  String get emptyWeekAction => 'اذهب إلى اليوم';

  @override
  String calendarStreak(Object count) {
    return '🔥 $count أيام متتالية';
  }

  @override
  String get weightStart => 'البداية';

  @override
  String get weightNow => 'الآن';

  @override
  String get weightGoal => 'الهدف';

  @override
  String get weightMaintain => 'الحفاظ';

  @override
  String get weightFewPoints => 'سجّل وزنك بانتظام لترى مسارك هنا';

  @override
  String get weightLogToday => 'سجّل وزنك اليوم';

  @override
  String weightDays(Object days) {
    return '$days يومًا';
  }

  @override
  String weightChartSummary(Object count, Object first, Object last) {
    return '$count قياسات للوزن، من $first إلى $last كغ';
  }

  @override
  String caloriesChartSummary(Object values) {
    return 'سعرات الأسبوع: $values';
  }

  @override
  String adherenceRing(Object percent) {
    return 'التزام $percent%';
  }
}
