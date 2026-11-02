# دليل استضافة الخادم وقاعدة البيانات على ⁨Render⁩

هذا الدليل لزميل الفريق المسؤول عن الاستضافة. هدفه: تشغيل خادم ⁨NutriGuide⁩ وقاعدة بياناته على ⁨Render⁩، ثم بناء ملف التطبيق ⁨APK⁩ بعنوان الخادم الجديد.

تنبيه: لم يُنشر أي شيء بعد، ولم يُلمس حساب ⁨Render⁩. كل الخطوات هنا يُنفذها زميل الاستضافة بنفسه.

## 1. ما الذي سيُستضاف

- خدمة ويب (⁨Web Service⁩) واحدة: الخادم ⁨FastAPI⁩ من مجلد ⁨backend⁩ في المستودع.
- قاعدة بيانات ⁨PostgreSQL⁩ واحدة (⁨Render Postgres⁩).
- التطبيق لا يُستضاف: هو ملف ⁨APK⁩ يُبنى على الحاسوب ويُثبَّت على الهواتف.

## 2. إنشاء قاعدة البيانات

1. من لوحة ⁨Render⁩ اختر ⁨New⁩ ثم ⁨Postgres⁩.
2. اختر المنطقة نفسها التي ستضع فيها خدمة الويب (مثلًا ⁨Frankfurt⁩)، حتى يتصلا عبر الشبكة الداخلية.
3. اختر إصدار ⁨PostgreSQL 16⁩ (المشروع مبني ومختبر عليه).
4. بعد الإنشاء انسخ من صفحة القاعدة رابطين:
   - الرابط الداخلي (⁨Internal Database URL⁩): تستخدمه خدمة الويب.
   - الرابط الخارجي (⁨External Database URL⁩): تستخدمه أنت مرة واحدة من حاسوبك لإنشاء الجداول وتحميل البيانات.

مهم: الخادم يقبل فقط مشغّل ⁨psycopg 3⁩. لذلك غيّر بداية الرابط الذي يعطيه ⁨Render⁩:

```
postgresql://USER:PASSWORD@HOST/DB          ← كما يعطيه Render
postgresql+psycopg://USER:PASSWORD@HOST/DB  ← كما يقبله الخادم
```

وللرابط الخارجي فقط أضف في آخره طلب التشفير:

```
postgresql+psycopg://USER:PASSWORD@HOST/DB?sslmode=require
```

## 3. إنشاء خدمة الويب

1. من لوحة ⁨Render⁩ اختر ⁨New⁩ ثم ⁨Web Service⁩، واربطها بمستودع ⁨GitHub⁩.
2. الفرع (⁨Branch⁩): الفرع الذي يتفق عليه الفريق للتسليم (⁨main⁩ بعد الدمج).
3. المجلد الجذري (⁨Root Directory⁩):

```
backend
```

4. البيئة (⁨Runtime⁩): ⁨Python⁩.
5. أمر البناء (⁨Build Command⁩):

```
pip install uv && uv sync --frozen --no-dev
```

6. أمر التشغيل (⁨Start Command⁩):

```
uv run --no-sync uvicorn app.api.main:app --host 0.0.0.0 --port $PORT --proxy-headers --forwarded-allow-ips="*"
```

7. فحص الصحة (⁨Health Check Path⁩):

```
/api/v1/health
```

سبب الخيارين الأخيرين في أمر التشغيل: ⁨Render⁩ يضع أمام الخادم وسيطًا (⁨Proxy⁩). بدون هذين الخيارين يرى الخادم كل الطلبات قادمة من عنوان واحد، فيصبح حد الطلبات (⁨Rate limit⁩) مشتركًا بين كل المستخدمين، فيُمنع مستخدمون بسبب غيرهم. الشرح موجود أيضًا في أعلى الملف ⁨backend/app/api/limiting.py⁩.

## 4. متغيرات البيئة (⁨Environment Variables⁩)

ضعها في صفحة الخدمة تحت ⁨Environment⁩. لا تضعها في المستودع أبدًا، ولا ترسلها في محادثة عامة.

| المتغير | القيمة | ملاحظة |
|---|---|---|
| المتغير ⁨DATABASE_URL⁩ | الرابط الداخلي بعد تغيير بدايته إلى ⁨postgresql+psycopg⁩:// | إلزامي |
| المتغير ⁨JWT_SECRET⁩ | نص عشوائي طويل (32 حرفًا على الأقل) | إلزامي؛ يوقّع رموز الدخول |
| المتغير ⁨APP_ENV⁩ | القيمة ⁨production⁩ | |
| المتغير ⁨PYTHON_VERSION⁩ | الإصدار 3.12.8 | الخادم يتطلب ⁨Python⁩ 3.12 تحديدًا |
| المتغير ⁨CORS_ORIGINS⁩ | قائمة فارغة [] | اتركها فارغة؛ انظر القسم 6 |
| المتغير ⁨RATE_LIMIT_ENABLED⁩ | القيمة ⁨true⁩ | القيمة الافتراضية |
| المتغير ⁨ML_PLANNING_ENABLED⁩ | القيمة ⁨true⁩ | محرك الخطة مع التعلم؛ ⁨false⁩ يعيد الإصدار السابق |
| المتغير ⁨PLANNER_MAX_CONCURRENT⁩ | العدد 1 | للخطة المجانية ذات الذاكرة الصغيرة؛ 2 إن كانت الذاكرة أكبر |
| المتغير ⁨ACCESS_TOKEN_MINUTES⁩ | العدد 15 | القيمة الافتراضية |
| المتغير ⁨REFRESH_TOKEN_DAYS⁩ | العدد 30 | القيمة الافتراضية |

لتوليد ⁨JWT_SECRET⁩ على حاسوبك:

```
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

تنبيه: إذا تغيّر ⁨JWT_SECRET⁩ لاحقًا يخرج كل المستخدمين ويلزمهم الدخول من جديد.

## 5. إنشاء الجداول وتحميل البيانات (⁨Migrations⁩ و ⁨Seed⁩)

تُنفَّذ مرة واحدة على قاعدة فارغة، من حاسوبك وليس من ⁨Render⁩. تحتاج نسخة من المستودع، وأداة ⁨uv⁩، و⁨Python 3.12⁩.

1. ضع الرابط الخارجي في متغير البيئة في الطرفية نفسها (لا تحفظه في ملف داخل المستودع). في ⁨PowerShell⁩:

```
cd backend
$env:DATABASE_URL = "postgresql+psycopg://USER:PASSWORD@HOST/DB?sslmode=require"
$env:JWT_SECRET = "<أي نص مؤقت من 32 حرفًا للتشغيل المحلي فقط>"
uv sync --frozen
```

2. إنشاء الجداول بآخر نسخة من البنية (6 ملفات ترحيل):

```
uv run alembic upgrade head
```

3. تحميل البيانات المرجعية والكتالوج (الأطعمة والمكونات و158 وجبة والحالات الصحية):

```
uv run python -m app.pipeline.build --load
```

يطبع الأمر في آخره عدد الوجبات المقبولة. وينشئ تقارير داخل ⁨backend/data/catalog⁩؛ لا ترفع هذه التقارير إن تغيرت.

4. لا تستخدم السكربت ⁨scripts/rebuild_dev_db.py⁩ هنا: هو يمسح القاعدة بالكامل، ويرفض أصلًا أي قاعدة خارج الحاسوب المحلي.

5. الحساب التجريبي غير موجود في المستودع. أنشئه من التطبيق بعد الاستضافة (حساب جديد ثم إكمال البيانات)، ولا تكتب كلمة مروره في أي ملف.

6. عند تحديث الخادم لاحقًا بملف ترحيل جديد، أعد الخطوة 2 فقط قبل نشر النسخة الجديدة أو بعدها مباشرة. وإن كانت الخطة المدفوعة متاحة يمكن وضع الأمر نفسه في ⁨Pre-Deploy Command⁩.

## 6. التشفير ⁨HTTPS⁩ و ⁨CORS⁩

- التشفير ⁨HTTPS⁩: كل خدمة على ⁨Render⁩ تأخذ عنوانًا مشفرًا تلقائيًا بالشكل ⁨https⁩://اسم-الخدمة.⁨onrender.com⁩، فلا حاجة لإعداد شهادة.
- التطبيق في نسخة الإصدار يرفض أي عنوان غير مشفر: إذا بُني بعنوان يبدأ بـ ⁨http⁩:// تظهر شاشة خطأ ولا يعمل. هذا مقصود لحماية البيانات الصحية.
- المتغير ⁨CORS_ORIGINS⁩: يخص المتصفحات فقط. تطبيق الهاتف لا يحتاجه، لذلك يبقى []. إذا أُضيفت لاحقًا لوحة ويب، تُكتب عناوينها كقائمة ⁨JSON⁩، مثل:

```
["https://dashboard.example.com"]
```

- لا تضع "*" في ⁨CORS_ORIGINS⁩.

## 7. التحقق بعد النشر

افتح في المتصفح:

```
https://<اسم-الخدمة>.onrender.com/api/v1/health
```

النتيجة الصحيحة تشبه:

```
{"status":"ok","api_version":"1.2.0","database":"ok","dataset_version":"catalog_v3","default_planner":"cpsat"}
```

- إذا ظهر ⁨database⁩ غير ⁨ok⁩: راجع ⁨DATABASE_URL⁩ (البداية ⁨postgresql+psycopg⁩:// والرابط الداخلي).
- إذا ظهر ⁨dataset_version⁩ فارغًا: لم تُنفَّذ الخطوة 3 من القسم 5.
- توثيق الواجهة البرمجية متاح على /⁨api/docs⁩.

## 8. إعادة بناء ملف التطبيق ⁨APK⁩ بعنوان ⁨Render⁩

على حاسوب فيه ⁨Flutter⁩ ومفتاح التوقيع، من المجلد ⁨mobile⁩:

```
flutter build apk --release --dart-define=API_BASE_URL=https://<اسم-الخدمة>.onrender.com
```

- العنوان بدون شرطة مائلة في آخره، وبدون /⁨api/v1⁩.
- لا تستخدم الخيار ⁨ALLOW_HTTP_IN_RELEASE⁩ مع عنوان ⁨Render⁩. هذا الخيار لتجربة الشبكة المحلية فقط.
- الملف الناتج:

```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

- التوقيع: نسخة الإصدار توقَّع بالمفتاح المذكور في ⁨mobile/android/key.properties⁩، وهذا الملف والمفتاح خارج المستودع. بدونه يوقَّع الملف بمفتاح التطوير، ولا يمكن حينها تثبيته فوق نسخة موقعة بالمفتاح الحقيقي. لا ترفع المفتاح ولا ⁨key.properties⁩ ولا كلمات مروره إلى ⁨GitHub⁩ أبدًا.
- بعد اعتماد الاستضافة يمكن حذف عناوين الشبكة المحلية من الملف ⁨mobile/android/app/src/main/res/xml/network_security_config.xml⁩.
- طريقة التثبيت على الهاتف موجودة في ⁨mobile/docs/INSTALL_APK.md⁩.

## 9. ملاحظات عن الخطة المجانية في ⁨Render⁩

- خدمة الويب المجانية تتوقف بعد فترة بلا طلبات، وأول طلب بعدها يأخذ وقتًا أطول حتى تستيقظ. التطبيق يتحمل ذلك: يعرض آخر نسخة محفوظة على الهاتف ثم يحدّث.
- قاعدة البيانات المجانية لها مدة صلاحية محدودة. راجع الشروط الحالية في ⁨Render⁩ قبل يوم المناقشة، وخذ نسخة احتياطية.
- بناء خطة أسبوع كاملة يستهلك المعالج نحو 5 ثوانٍ لكل يوم، لذلك اجعل ⁨PLANNER_MAX_CONCURRENT⁩ يساوي 1 في الخطة المجانية.

## 10. قائمة تحقق سريعة

- القاعدة: ⁨PostgreSQL⁩ 16 في منطقة الخدمة نفسها.
- الرابط: يبدأ بـ ⁨postgresql+psycopg⁩://، والخارجي فيه ⁨sslmode⁩=⁨require⁩.
- المتغيرات: ⁨DATABASE_URL⁩ و ⁨JWT_SECRET⁩ و ⁨PYTHON_VERSION⁩ على الأقل.
- البيانات: ⁨alembic upgrade head⁩ ثم ⁨app.pipeline.build⁩ --⁨load⁩ مرة واحدة.
- الفحص: /⁨api/v1/health⁩ يعطي ⁨database ok⁩ و ⁨catalog_v3⁩.
- التطبيق: بُني بـ ⁨https⁩:// ويعمل الدخول وإنشاء الحساب وبناء الخطة.
- الأسرار: لا شيء منها في المستودع.

## مراجع

- مرجع ⁨Render: Deploy a FastAPI App. https://render.com/docs/deploy-fastapi⁩
- مرجع ⁨Render: Environment Variables and Secrets. https://render.com/docs/configure-environment-variables⁩
- مرجع ⁨Render: Render Postgres. https://render.com/docs/postgresql⁩
- مرجع ⁨Uvicorn: Settings⁩ (⁨proxy headers⁩). ⁨https://www.uvicorn.org/settings⁩/
- مرجع ⁨Alembic: Tutorial⁩ (⁨upgrade head⁩). ⁨https://alembic.sqlalchemy.org/en/latest/tutorial.html⁩
- مرجع ⁨Flutter: Build and release an Android app. https://docs.flutter.dev/deployment/android⁩
- مرجع ⁨OWASP: MASVS-NETWORK⁩ (⁨Mobile Application Security Verification Standard v2⁩).
