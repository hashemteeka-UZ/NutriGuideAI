# مراجعة نصوص التطبيق — المرحلة ⁨P2c⁩

هذا الجدول يعرض كل نص تغيّر في ⁨app_ar.arb⁩ و⁨app_en.arb⁩ بعد مراجعة النصوص التوضيحية والنصائح وحالات الفراغ.

قواعد المراجعة: عربية بسيطة ودافئة وقصيرة، بلا ادعاءات طبية أكثر مما يفعله التطبيق، مع الإبقاء على صيغ المخاطَب والمخاطَبة (⁨select⁩)، ودون تغيير معنى رسائل الأخطاء.

عدد المفاتيح المعدّلة بالعربية: 26، وبالإنجليزية: 21.

## النصوص العربية

| المفتاح | النص القديم | النص الجديد | سبب التعديل |
|---|---|---|---|
| مفتاح ⁨`waterSessionTip`⁩ | الأفضل للجلسة الواحدة كوب إلى كوبين (250 إلى 500 مل) | كوب واحد (نحو 250 مل) في كل مرة يكفي. وزّع الباقي على يومك، ولا حاجة لشرب كمية كبيرة دفعة واحدة. | نص المستخدم المعتمد؛ لا يحدد سقفًا للجلسة بلا مصدر |
| مفتاح ⁨`waterLargeTip`⁩ | كمية كبيرة لمرة واحدة، يمكنك تقسيمها على مرتين. | هذه كمية كبيرة دفعة واحدة. الأريح أن تقسمها على مرتين. | نص المستخدم المعتمد |
| مفتاح ⁨`onbActivityTip`⁩ | النص: {⁨sex, select, FEMALE⁩{نشاطكِ يحدد كم تحرقين يوميًا. إن ترددتِ بين خيارين، اختاري الأقل لتكون الخطة أدق.} ⁨other⁩{نشاطك يحدد كم تحرق يوميًا. إن ترددت بين خيارين، اختر الأقل لتكون الخطة أدق.}} | النص: {⁨sex, select, FEMALE⁩{نشاطكِ يحدد كم تحرقين في يومكِ. إن احترتِ بين خيارين، فاختاري الأقل.} ⁨other⁩{نشاطك يحدد كم تحرق في يومك. إن احترت بين خيارين، فاختر الأقل.}} | أقصر، وحُذفت عبارة «لتكون الخطة أدق» غير الدقيقة |
| مفتاح ⁨`onbGoalLoseBody`⁩ | عجز معتدل وآمن في السعرات | سعرات أقل قليلًا من احتياجك، بوتيرة معتدلة | «عجز آمن» وعد طبي؛ النص الجديد يصف ما يفعله التطبيق |
| مفتاح ⁨`onbGoalMaintainBody`⁩ | أكل متوازن يحافظ على طاقتك | سعرات على قدر احتياجك لتحافظ على وزنك | «يحافظ على طاقتك» ادعاء غير مقاس |
| مفتاح ⁨`onbGoalGainBody`⁩ | فائض مدروس في السعرات | سعرات أكثر قليلًا من احتياجك، بوتيرة هادئة | «فائض مدروس» عبارة جامدة |
| مفتاح ⁨`onbGainCap`⁩ | الحد الآمن للزيادة نصف كغ أسبوعيًا | نجعل الزيادة نصف كغ في الأسبوع على الأكثر | «الحد الآمن» بلا مصدر محدد؛ صارت قاعدة التطبيق بصيغة محايدة |
| مفتاح ⁨`onbRateUnavailable`⁩ | غير متاحة لوزنك الحالي (أكثر من 1% أسبوعيًا) | غير متاحة لوزنك الآن: أسرع من 1% من وزنك في الأسبوع | أوضح |
| مفتاح ⁨`onbCareHeartBody`⁩ | دهون صحية وملح أقل | دهون مشبعة أقل وملح أقل | «دهون صحية» عامة؛ القاعدة الفعلية هي الدهون المشبعة والصوديوم |
| مفتاح ⁨`onbCareExplainBody`⁩ | النص: ⁨NutriGuide⁩ لا يعالج أي حالة، ولا يغني عن طبيبك. هو فقط يتجنب في خطتك ما قد لا يناسبك، مثل الملح الزائد أو السكريات، حسب توصيات منظمة الصحة العالمية وجمعيات الصحة. | النص: ⁨NutriGuide⁩ لا يعالج أي حالة ولا يغني عن طبيبك. كل ما يفعله أنه يُبعد عن خطتك ما قد لا يناسبك، مثل الملح الزائد أو السكر، وفق إرشادات منظمة الصحة العالمية والجمعيات الطبية. | أوضح وأقصر، والمعنى نفسه |
| مفتاح ⁨`onbWhyAskBody`⁩ | استخدام الإنسولين يحتاج تخطيط الكربوهيدرات مرتبطًا بالجرعات، وهذا لا يغطيه التطبيق، فيُستخدم الوضع العام. | مع الإنسولين يُطابَق نصيب كل وجبة من الكربوهيدرات مع الجرعة، وهذا لا يقدمه التطبيق، لذلك نستخدم الوضع العام. | صياغة بشرية أوضح |
| مفتاح ⁨`onbReasonGeneric`⁩ | وضعك يحتاج تقديرًا لا تغطيه الخطة الشخصية. | وضعك يحتاج حسابًا لا تغطيه الخطة الشخصية. | «تقديرًا» غامضة |
| مفتاح ⁨`onbHowDeficitBody`⁩ | هذا الفرق الذي نخصمه من احتياجك حتى ينخفض الوزن بالسرعة التي اخترتها. | هذا ما ننقصه من احتياجك لينزل وزنك بالوتيرة التي اخترتها. | أقصر وأقرب للكلام اليومي |
| مفتاح ⁨`onbHowSurplusBody`⁩ | هذه الزيادة فوق احتياجك حتى يرتفع الوزن بالسرعة التي اخترتها. | هذا ما نزيده على احتياجك ليرتفع وزنك بالوتيرة التي اخترتها. | أقصر وأقرب للكلام اليومي |
| مفتاح ⁨`onbHowFloorBody`⁩ | الخطة لا تنزل تحت حد أدنى آمن، لذلك رفعنا السعرات إليه. | لا تنزل خطتك عن حد أدنى من السعرات، لذلك رفعناها إليه. | أوضح |
| مفتاح ⁨`onbBmiExplainBody`⁩ | رقم تقريبي من الوزن والطول (الوزن ÷ مربع الطول بالمتر). نستخدمه كمؤشر عام فقط، ولا يقيس نسبة الدهون أو العضلات. | رقم تقريبي من الوزن والطول (الوزن ÷ مربع الطول بالمتر). نستخدمه دليلًا عامًا فقط، فهو لا يقيس الدهون ولا العضلات. | أسلس |
| مفتاح ⁨`onbNameSubtitle`⁩ | سنستخدم اسمك لنحدثك بشكل شخصي | لنناديك باسمك داخل التطبيق | «بشكل شخصي» ترجمة حرفية |
| مفتاح ⁨`mealFavouritesHint`⁩ | يقترحها المحرك أكثر في خطتك | نقترحها لك أكثر في خطتك | «المحرك» مصطلح تقني |
| مفتاح ⁨`mealFavouritesEmpty`⁩ | لا توجد بعد. اضغط القلب في أي وجبة. | لا مفضلات بعد. اضغط القلب على أي وجبة تعجبك. | أدفأ |
| مفتاح ⁨`generalBody`⁩ | تسجل أكلك وماءك وترى تقدمك. لا توجد خطة سعرات شخصية. | تسجّل أكلك وماءك وترى تقدمك، دون خطة سعرات شخصية. | جملة واحدة بدل جملتين جافتين |
| مفتاح ⁨`missedBody`⁩ | هل أكلتها؟ سجلها الآن حتى يبقى يومك دقيقًا | هل أكلتها؟ سجّلها الآن ليبقى يومك صحيحًا | أسلس |
| مفتاح ⁨`remindersIntro`⁩ | كل التذكيرات متوقفة حتى تفعّلها. تصل في وقت تقريبي. | كل التذكيرات متوقفة حتى تشغّلها، وقد تصل قبل موعدها أو بعده بقليل. | «وقت تقريبي» غامضة |
| مفتاح ⁨`reminderWaterBody`⁩ | اشرب كوب ماء | وقت كوب ماء | صيغة محايدة للجنسين بدل الأمر بالمذكر |
| مفتاح ⁨`accentNote`⁩ | اللون يتبع هدفك تلقائيًا، وألوان البروتين والسعرات والماء ثابتة دائمًا حتى لا تختلط المعاني. | يتبع اللون هدفك تلقائيًا. أما ألوان السعرات والبروتين والماء فثابتة دائمًا حتى لا تختلط عليك. | أسلس |
| مفتاح ⁨`shopInMeals`⁩ | في {⁨count⁩} وجبات | النص: {⁨count, plural⁩, =1{في وجبة واحدة} =2{في وجبتين} ⁨few⁩{في {⁨count⁩} وجبات} ⁨other⁩{في {⁨count⁩} وجبة}} | صيغ العدد العربية («في 1 وجبات» خطأ) |
| مفتاح ⁨`favouritesCount`⁩ | النص: {⁨count⁩} وجبات | النص: {⁨count, plural⁩, =0{لا وجبات} =1{وجبة واحدة} =2{وجبتان} ⁨few⁩{{⁨count⁩} وجبات} ⁨other⁩{{⁨count⁩} وجبة}} | صيغ العدد العربية («0 وجبات» و«1 وجبات») |

## النصوص الإنجليزية المقابلة

| المفتاح | النص القديم | النص الجديد |
|---|---|---|
| مفتاح ⁨`waterSessionTip`⁩ | بالإنجليزية: النص: ⁨One sitting is best at one to two glasses (250 to 500 ml)⁩ | بالإنجليزية: النص: ⁨One glass (about 250 ml) at a time is enough. Spread the rest over your day; there is no need to drink a lot at once.⁩ |
| مفتاح ⁨`waterLargeTip`⁩ | بالإنجليزية: النص: ⁨That's a lot at once; you can split it in two.⁩ | بالإنجليزية: النص: ⁨That is a lot at once. It is easier to split it in two.⁩ |
| مفتاح ⁨`onbGoalLoseBody`⁩ | بالإنجليزية: النص: ⁨A moderate, safe calorie deficit⁩ | بالإنجليزية: النص: ⁨A little under your needs, at a moderate pace⁩ |
| مفتاح ⁨`onbGoalMaintainBody`⁩ | بالإنجليزية: النص: ⁨Balanced eating to keep your energy⁩ | بالإنجليزية: النص: ⁨Calories that match your needs, to keep your weight⁩ |
| مفتاح ⁨`onbGoalGainBody`⁩ | بالإنجليزية: النص: ⁨A planned calorie surplus⁩ | بالإنجليزية: النص: ⁨A little over your needs, at a gentle pace⁩ |
| مفتاح ⁨`onbGainCap`⁩ | بالإنجليزية: النص: ⁨Safe gain is up to 0.5 kg a week⁩ | بالإنجليزية: النص: ⁨We keep gain to at most 0.5 kg a week⁩ |
| مفتاح ⁨`onbRateUnavailable`⁩ | بالإنجليزية: النص: ⁨Not available for your weight (over 1% a week)⁩ | بالإنجليزية: النص: ⁨Not available for your weight now: faster than 1% of your weight a week⁩ |
| مفتاح ⁨`onbCareHeartBody`⁩ | بالإنجليزية: النص: ⁨Healthy fats and less salt⁩ | بالإنجليزية: النص: ⁨Less saturated fat and less salt⁩ |
| مفتاح ⁨`onbCareExplainBody`⁩ | بالإنجليزية: النص: ⁨NutriGuide does not treat any condition and does not replace your doctor. It only avoids what may not suit you, like extra salt or sugar, following WHO and health association guidance.⁩ | بالإنجليزية: النص: ⁨NutriGuide does not treat any condition and does not replace your doctor. It only keeps out of your plan what may not suit you, like extra salt or sugar, following WHO and medical association guidance.⁩ |
| مفتاح ⁨`onbWhyAskBody`⁩ | بالإنجليزية: النص: ⁨Insulin use needs carbohydrate planning tied to doses, which this app does not cover, so the general mode is used.⁩ | بالإنجليزية: النص: ⁨With insulin, each meal's carbohydrate is matched to the dose. The app does not do that, so it uses the general mode.⁩ |
| مفتاح ⁨`onbReasonGeneric`⁩ | بالإنجليزية: النص: ⁨Your situation needs an estimate the personal plan does not cover.⁩ | بالإنجليزية: النص: ⁨Your situation needs a calculation the personal plan does not cover.⁩ |
| مفتاح ⁨`onbHowDeficitBody`⁩ | بالإنجليزية: النص: ⁨This is what we subtract so your weight falls at the pace you chose.⁩ | بالإنجليزية: النص: ⁨This is what we take off your needs so your weight goes down at the pace you chose.⁩ |
| مفتاح ⁨`onbHowSurplusBody`⁩ | بالإنجليزية: النص: ⁨This is what we add so your weight rises at the pace you chose.⁩ | بالإنجليزية: النص: ⁨This is what we add to your needs so your weight goes up at the pace you chose.⁩ |
| مفتاح ⁨`onbHowFloorBody`⁩ | بالإنجليزية: النص: ⁨The plan never goes below a safe minimum, so the calories were raised to it.⁩ | بالإنجليزية: النص: ⁨Your plan never goes below a minimum number of calories, so we raised it to that.⁩ |
| مفتاح ⁨`onbNameSubtitle`⁩ | بالإنجليزية: النص: ⁨We use it to talk to you personally⁩ | بالإنجليزية: النص: ⁨So we can call you by your name in the app⁩ |
| مفتاح ⁨`mealFavouritesHint`⁩ | بالإنجليزية: النص: ⁨The engine suggests these more often⁩ | بالإنجليزية: النص: ⁨We suggest these more often in your plan⁩ |
| مفتاح ⁨`mealFavouritesEmpty`⁩ | بالإنجليزية: النص: ⁨None yet. Tap the heart on any meal.⁩ | بالإنجليزية: النص: ⁨No favourites yet. Tap the heart on any meal you like.⁩ |
| مفتاح ⁨`remindersIntro`⁩ | بالإنجليزية: النص: ⁨All reminders stay off until you turn them on. They arrive at about the set time.⁩ | بالإنجليزية: النص: ⁨All reminders stay off until you turn them on. They may arrive a little before or after the set time.⁩ |
| مفتاح ⁨`reminderWaterBody`⁩ | بالإنجليزية: النص: ⁨Have a glass of water⁩ | بالإنجليزية: النص: ⁨Time for a glass of water⁩ |
| مفتاح ⁨`shopInMeals`⁩ | بالإنجليزية: النص: ⁨In⁩ {⁨count⁩} ⁨meals⁩ | بالإنجليزية: النص: {⁨count, plural⁩, =1{⁨In 1 meal⁩} ⁨other⁩{⁨In⁩ {⁨count⁩} ⁨meals⁩}} |
| مفتاح ⁨`favouritesCount`⁩ | بالإنجليزية: النص: {⁨count⁩} ⁨meals⁩ | بالإنجليزية: النص: {⁨count, plural⁩, =1{1 ⁨meal⁩} ⁨other⁩{{⁨count⁩} ⁨meals⁩}} |

## ما لم يتغيّر ولماذا

- رسائل الأخطاء (مفاتيح ⁨failure*⁩) بقيت كما هي حتى لا يتغير معناها.
- نصوص الإعداد التي لها مصدر واضح بقيت، مثل حد ⁨1%⁩ أسبوعيًا ومؤشر كتلة الجسم والحد الأدنى للسعرات، ومصادرها في ⁨advice_sources.md⁩.
- نصوص الواجهة القصيرة (أسماء الأزرار والتبويبات) لم تُراجع هنا لأنها لا تحمل نصيحة.
