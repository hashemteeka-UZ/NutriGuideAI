# مصادر النصائح والمعلومات الصحية في التطبيق

قاعدة ثابتة من المستخدم: كل نصيحة أو معلومة صحية أو شرح يظهر في التطبيق يجب أن يكون له مصدر موثّق. ما لا مصدر موثوقًا له يُعاد صياغته بعبارة محايدة تصف ما يفعله التطبيق، أو يُحذف.

أرقام المراجع بين قوسين مربعين هي أرقامها في ⁨docs/project/report/references.txt⁩، والمراجع الجديدة مرقّمة بحرف ⁨N⁩ ويجب إضافتها إلى قائمة المراجع في التقرير.

| النص بالعربية | المفتاح | الادعاء | المصدر | موضعه في الإطار النظري |
|---|---|---|---|---|
| كوب واحد (نحو 250 مل) في كل مرة يكفي. وزّع الباقي على يومك، ولا حاجة لشرب كمية كبيرة دفعة واحدة. | مفتاح ⁨`waterSessionTip`⁩ | شرب الماء موزعًا على اليوم يكفي، ولا حاجة لكمية كبيرة دفعة واحدة | المرجع: النص: ⁨[21]⁩ للاحتياج اليومي من الماء؛ ⁨[N1]⁩ أن الشرب فوق الحاجة لا فائدة منه وقد يضر عند الإفراط | القسم 2.2.1 التغذية الصحية — الماء والسوائل |
| هذه كمية كبيرة دفعة واحدة. الأريح أن تقسمها على مرتين. | مفتاح ⁨`waterLargeTip`⁩ | تقسيم الكمية الكبيرة على مرتين أريح | المرجع: النص: ⁨[N1]⁩ (لا يذكر النص رقمًا طبيًا؛ نصيحة راحة فقط) | القسم 2.2.1 — الماء والسوائل |
| وقت كوب ماء | مفتاح ⁨`reminderWaterBody`⁩ ومفتاح ⁨`remindersWaterSub`⁩ | تذكير لطيف بالماء على فترات خلال اليوم | المرجع: النص: ⁨[21]⁩ (التوزيع على اليوم)؛ التوقيت نفسه قاعدة تصميم في التطبيق | القسم 2.4.5 الالتزام والاستمرار |
| هدف الماء الافتراضي: 1600 مل للنساء و2000 مل للرجال | مفتاح ⁨`waterTodayGoal`⁩ | الهدف الافتراضي من الماء بعد طرح نحو 20% يأتي من الطعام | المرجع: النص: ⁨[21]⁩ | القسم 2.2.1 — الماء والسوائل؛ الفصل 3 (قاعدة §30.7) |
| لأن صحة القلب تحتاج متابعة الماء مع الطبيب | مفتاح ⁨`onbBecauseHeart`⁩ ومفتاح ⁨`onbFluidSubtitle`⁩ ومفتاح ⁨`waterClinicianTitle`⁩ ومفتاح ⁨`waterDoctorGoal`⁩ | بعض حالات القلب يحدد لها الطبيب كمية سوائل يومية، فلا نضع هدفًا افتراضيًا | المرجع: النص: ⁨[45]⁩ | القسم 2.2.1 — الحالات الصحية الشائعة (أمراض القلب) |
| رقم تقريبي من الوزن والطول (الوزن ÷ مربع الطول بالمتر). نستخدمه دليلًا عامًا فقط، فهو لا يقيس الدهون ولا العضلات. | مفتاح ⁨`onbBmiExplainBody`⁩ ومفتاح ⁨`onbBmiUnder`⁩ ومفتاح ⁨`onbBmiNormal`⁩ ومفتاح ⁨`onbBmiOver`⁩ ومفتاح ⁨`onbBmiHigh`⁩ | مؤشر كتلة الجسم = الوزن ÷ مربع الطول، ومجالاته 18.5 و25 و30، ولا يقيس الدهون | المرجع: النص: ⁨[44]⁩ | القسم 2.2.2 حساب احتياج الطاقة |
| لا نقترح هدفًا أقل من الوزن الطبيعي لطولك | مفتاح ⁨`onbLoseUnavailable`⁩ | لا نقترح وزنًا مستهدفًا تحت مؤشر 18.5 | المرجع: النص: ⁨[44]⁩ | القسم 2.2.2 |
| هذا ما يحتاجه جسمك للطاقة وأنت مرتاح تمامًا، بحسب معادلة ميفلين-سانت جيور. | مفتاح ⁨`onbHowRestBody`⁩ ومفتاح ⁨`onbHowRestTitle`⁩ | طاقة الراحة بمعادلة ميفلين-سانت جيور | المرجع: النص: ⁨[19]⁩؛ ومقارنة دقتها ⁨[42]⁩ | القسم 2.2.2 حساب احتياج الطاقة |
| نضرب طاقة الراحة في معامل نشاطك ({⁨factor⁩}) لنحصل على ما تحرقه في يومك المعتاد. | مفتاح ⁨`onbHowActivityBody`⁩ ومفتاح ⁨`onbActivityTitle`⁩ | الاحتياج اليومي = طاقة الراحة × معامل النشاط (1.2 إلى 1.9) | المرجع: النص: ⁨[43]⁩ | القسم 2.2.2 |
| النص: {⁨sex, select, FEMALE⁩{نشاطكِ يحدد كم تحرقين في يومكِ. إن احترتِ بين خيارين، فاختاري الأقل.} ⁨other⁩{نشاطك يحدد كم تحرق في يومك. إن احترت بين خيارين، فاختر الأقل.}} | مفتاح ⁨`onbActivityTip`⁩ | الناس يبالغون غالبًا في تقدير نشاطهم، فالأقل أدق عند التردد | المرجع: النص: ⁨[N6]⁩ | القسم 2.4.1 جودة البيانات (بيانات المستخدم) |
| هذا ما ننقصه من احتياجك لينزل وزنك بالوتيرة التي اخترتها. | مفتاح ⁨`onbHowDeficitBody`⁩ ومفتاح ⁨`onbHowSurplusBody`⁩ ومفتاح ⁨`onbGoalLoseBody`⁩ ومفتاح ⁨`onbGoalGainBody`⁩ | الفرق اليومي = الوتيرة الأسبوعية × 7700 ÷ 7 سعرة | المرجع: النص: ⁨[N3]⁩؛ وحدود التقدير ⁨[N4]⁩ | القسم 2.2.2 |
| غير متاحة لوزنك الآن: أسرع من 1% من وزنك في الأسبوع | مفتاح ⁨`onbRateUnavailable`⁩ ومفتاح ⁨`onbRateGentleBody`⁩ ومفتاح ⁨`onbRateBalancedBody`⁩ ومفتاح ⁨`onbRateFasterBody`⁩ ومفتاح ⁨`onbRateMaxBody`⁩ | لا تتجاوز سرعة النزول 1% من وزن الجسم أسبوعيًا | المرجع: النص: ⁨[N5]⁩؛ ونطاق نصف إلى واحد كغ أسبوعيًا ⁨[N2]⁩ | القسم 2.2.2 |
| رفعنا السعرات إلى الحد الأدنى الآمن | مفتاح ⁨`onbHowFloorTitle`⁩ ومفتاح ⁨`onbHowFloorBody`⁩ | حد أدنى للسعرات: 1200 للنساء و1500 للرجال | المرجع: النص: ⁨[N2]⁩ | القسم 2.2.2 |
| نجعل الزيادة نصف كغ في الأسبوع على الأكثر | مفتاح ⁨`onbGainCap`⁩ | قاعدة تصميم: الزيادة نصف كغ أسبوعيًا على الأكثر | المرجع: لا مصدر محدد لهذا الرقم؛ صيغ النص كقاعدة للتطبيق لا كحد آمن طبيًا | الفصل 3 (قواعد التطبيق §30.3) |
| النص: {⁨share⁩} من السعرات | مفتاح ⁨`onbMacroShare`⁩ ومفتاح ⁨`onbProtein`⁩ ومفتاح ⁨`onbCarbs`⁩ ومفتاح ⁨`onbFat`⁩ | نسب الطاقة من البروتين والكربوهيدرات والدهون، والدهون 25 إلى 35%، وحد أدنى 130 غ كربوهيدرات | المرجع: النص: ⁨[20]⁩ | القسم 2.2.3 المغذيات الكبرى والألياف |
| ألياف | مفتاح ⁨`onbFiber`⁩ | هدف الألياف 14 غ لكل 1000 سعرة | المرجع: النص: ⁨[20]⁩ | القسم 2.2.3 |
| ملح أقل في وجباتك اليومية | مفتاح ⁨`onbCarePressureBody`⁩ | ملح أقل لمرضى ارتفاع الضغط، وحد 2000 ملغ صوديوم يوميًا | المرجع: النص: ⁨[16]⁩ | القسم 2.2.1 — ارتفاع ضغط الدم |
| سكريات أقل وكربوهيدرات موزعة على وجباتك | مفتاح ⁨`onbCareDiabetesBody`⁩ | سكر أقل وكربوهيدرات موزعة على الوجبات لمرضى السكري من النوع الثاني | المرجع: النص: ⁨[3]⁩؛ ⁨[48]⁩ للسكريات الحرة | القسم 2.2.1 — السكري |
| دهون مشبعة أقل وملح أقل | مفتاح ⁨`onbCareHeartBody`⁩ | دهون مشبعة أقل (أقل من 10% من الطاقة) وملح أقل لصحة القلب | المرجع: النص: ⁨[17]⁩؛ ⁨[5]⁩؛ ⁨[16]⁩ | القسم 2.2.1 — أمراض القلب |
| النص: ⁨NutriGuide⁩ لا يعالج أي حالة ولا يغني عن طبيبك. كل ما يفعله أنه يُبعد عن خطتك ما قد لا يناسبك، مثل الملح الزائد أو السكر، وفق إرشادات منظمة الصحة العالمية والجمعيات الطبية. | مفتاح ⁨`onbCareExplainBody`⁩ ومفتاح ⁨`aboutDisclaimer`⁩ ومفتاح ⁨`accountDisclaimer`⁩ | التطبيق لا يعالج ولا يغني عن الطبيب، ويتبع إرشادات عامة | المرجع: النص: ⁨[16]⁩؛ ⁨[17]⁩؛ ⁨[3]⁩؛ ⁨[5]⁩ | القسم 1.5.2 حدود المشروع؛ 2.2.1 |
| مع الإنسولين يُطابَق نصيب كل وجبة من الكربوهيدرات مع الجرعة، وهذا لا يقدمه التطبيق، لذلك نستخدم الوضع العام. | مفتاح ⁨`onbWhyAskBody`⁩ ومفتاح ⁨`onbReasonInsulin`⁩ ومفتاح ⁨`onbInsulinQuestion`⁩ | مستخدم الإنسولين يطابق كربوهيدرات كل وجبة مع الجرعة، وهذا خارج نطاق التطبيق | المرجع: النص: ⁨[3]⁩ | القسم 1.5.2 حدود المشروع؛ 2.2.1 — السكري |
| الخطة الشخصية مخصصة للبالغين | مفتاح ⁨`onbReasonUnder18`⁩ | الخطة الشخصية للبالغين فقط | المرجع: النص: ⁨[19]⁩ (المعادلة مطوّرة على بالغين)؛ ⁨[43]⁩ | القسم 1.5.2 حدود المشروع |
| تجاوزت حدًا صحيًا في {⁨days⁩} أيام | مفتاح ⁨`exceededTitle`⁩ ومفتاح ⁨`exceededLine`⁩ | حدود يومية للصوديوم والدهون المشبعة وحدود الحالات الصحية | المرجع: النص: ⁨[16]⁩؛ ⁨[17]⁩؛ ⁨[3]⁩؛ ⁨[5]⁩ | القسم 2.4.2 تعدد الحالات الصحية وتعارض قيودها |
| قليلة الصوديوم · قليلة السكر · قليلة الدهون المشبعة | سبب ⁨`LOW_SODIUM`⁩ وسبب ⁨`LOW_SUGAR`⁩ وسبب ⁨`LOW_SATURATED_FAT`⁩ | عتبات «منخفض» لكل 100 غ (صوديوم 120 ملغ، سكر 5 غ، دهون مشبعة 1.5 غ) | المرجع: النص: ⁨[41]⁩ | القسم 2.4.4 الشرح وثقة المستخدم |
| غنية بالألياف · غنية بالبروتين | سبب ⁨`HIGH_FIBER`⁩ وسبب ⁨`HIGH_PROTEIN`⁩ | «غنية بالألياف» 6 غ لكل 100 غ؛ «غنية بالبروتين» 20% من الطاقة على الأقل من البروتين | المرجع: النص: ⁨[N7]⁩ | القسم 2.4.4 |
| مناسبة لسعراتك | سبب ⁨`FITS_KCAL_TARGET`⁩ | طاقة الوجبة ضمن 15% من نصيب وقتها من هدفك | المرجع: قاعدة تصميم في المحسّن (لا ادعاء صحي) | الفصل 3 (المحسّن) |
| القيم الغذائية مبنية على قاعدة بيانات {⁨source⁩}. | مفتاح ⁨`aboutData`⁩ | القيم الغذائية من قاعدة بيانات وزارة الزراعة الأمريكية | المرجع: النص: ⁨[10]⁩ | القسم 2.2.4 قواعد بيانات تركيب الأغذية |
| النص: {⁨sex, select, female⁩{وصلتِ إلى هدفكِ!} ⁨other⁩{وصلت إلى هدفك!}} | مفتاح ⁨`weightGoalReached`⁩ ومفتاح ⁨`weightGoalReachedBody`⁩ | الوصول للهدف = الوزن ضمن 1 كغ من الوزن المستهدف | المرجع: قاعدة تصميم في التطبيق (§30.3)، لا ادعاء صحي | الفصل 3 |
| في بداية وقت كل وجبة | مفتاح ⁨`remindersMealsSub`⁩ ومفتاح ⁨`remindersWeighInSub`⁩ | مواعيد التذكير | المرجع: قاعدة تصميم في التطبيق، لا ادعاء صحي | القسم 2.4.5 الالتزام والاستمرار |

## المراجع الكاملة

- المرجع ⁨[3] American Diabetes Association Professional Practice Committee, "5. Facilitating positive health behaviors and well-being to improve health outcomes: Standards of Care in Diabetes—2025," Diabetes Care, vol. 48, suppl. 1, 2025.⁩
- المرجع ⁨[5] A. H. Lichtenstein et al., "2021 dietary guidance to improve cardiovascular health: A scientific statement from the American Heart Association," Circulation, vol. 144, no. 23, pp. e472–e487, 2021.⁩
- المرجع ⁨[10] U.S. Department of Agriculture, Agricultural Research Service, "FoodData Central." https://fdc.nal.usda.gov⁩
- المرجع ⁨[16] World Health Organization, Guideline: Sodium Intake for Adults and Children. Geneva: WHO, 2012.⁩
- المرجع ⁨[17] World Health Organization, Saturated Fatty Acid and Trans-Fatty Acid Intake for Adults and Children: WHO Guideline. Geneva: WHO, 2023.⁩
- المرجع ⁨[19] M. D. Mifflin et al., "A new predictive equation for resting energy expenditure in healthy individuals," Am. J. Clin. Nutr., vol. 51, no. 2, pp. 241–247, 1990.⁩
- المرجع ⁨[20] Institute of Medicine, Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids. Washington, DC: National Academies Press, 2005.⁩
- المرجع ⁨[21] EFSA Panel on Dietetic Products, Nutrition, and Allergies, "Scientific opinion on dietary reference values for water," EFSA J., vol. 8, no. 3, Art. no. 1459, 2010.⁩
- المرجع ⁨[41] Food Standards Agency, "Guide to creating a front of pack (FoP) nutrition label for pre-packed products sold through retail outlets," London, 2016.⁩
- المرجع ⁨[42] D. Frankenfield, L. Roth-Yousey, and C. Compher, "Comparison of predictive equations for resting metabolic rate in healthy nonobese and obese adults: A systematic review," J. Am. Diet. Assoc., vol. 105, no. 5, pp. 775–789, 2005.⁩
- المرجع ⁨[43] FAO/WHO/UNU, "Human energy requirements: Report of a joint FAO/WHO/UNU expert consultation," FAO Food Nutr. Tech. Rep. Ser. 1, Rome, 2004.⁩
- المرجع ⁨[44] World Health Organization, "Obesity: Preventing and managing the global epidemic," WHO Tech. Rep. Ser. 894, Geneva, 2000.⁩
- المرجع ⁨[45] P. A. Heidenreich et al., "2022 AHA/ACC/HFSA guideline for the management of heart failure," Circulation, vol. 145, no. 18, pp. e895–e1032, 2022.⁩
- المرجع ⁨[48] World Health Organization, Guideline: Sugars Intake for Adults and Children. Geneva: WHO, 2015.⁩
- المرجع ⁨[N1] T. Hew-Butler et al., "Statement of the 3rd International Exercise-Associated Hyponatremia Consensus Development Conference, Carlsbad, California, 2015," Clin. J. Sport Med., vol. 25, no. 4, pp. 303–320, 2015.⁩
- المرجع ⁨[N2] National Heart, Lung, and Blood Institute, Clinical Guidelines on the Identification, Evaluation, and Treatment of Overweight and Obesity in Adults: The Evidence Report, NIH Publication No. 98-4083, 1998.⁩
- المرجع ⁨[N3] M. Wishnofsky, "Caloric equivalents of gained or lost weight," Am. J. Clin. Nutr., vol. 6, no. 5, pp. 542–546, 1958.⁩
- المرجع ⁨[N4] K. D. Hall, "What is the required energy deficit per unit weight loss?" Int. J. Obes., vol. 32, no. 3, pp. 573–576, 2008.⁩
- المرجع ⁨[N5] E. R. Helms, A. A. Aragon, and P. J. Fitschen, "Evidence-based recommendations for natural bodybuilding contest preparation: Nutrition and supplementation," J. Int. Soc. Sports Nutr., vol. 11, Art. no. 20, 2014.⁩
- المرجع ⁨[N6] S. A. Prince et al., "A comparison of direct versus self-report measures for assessing physical activity in adults: A systematic review," Int. J. Behav. Nutr. Phys. Act., vol. 5, Art. no. 56, 2008.⁩
- المرجع ⁨[N7] European Parliament and Council, Regulation (EC) No 1924/2006 on nutrition and health claims made on foods, Annex ("High fibre", "High protein"), OJ L 404, 2006.⁩

ملاحظة: المراجع الجديدة ⁨N1⁩ إلى ⁨N7⁩ لم تُطابَق بعد مع النص الأصلي لكل مرجع. يُرجى مطابقة الصفحات والأرقام قبل إضافتها إلى قائمة المراجع في التقرير.

## ملاحظتان: ما يقوله المرجع وما اخترناه نحن (⁨P2z⁩)

- الملاحظة ⁨N2⁩: مرجع ⁨NHLBI⁩ (1998) يقترح حمية بين 1000 و1200 سعرة يوميًا لأغلب النساء، وبين 1200 و1600 للرجال. حدنا الأدنى للنساء (1200) هو الحد الأعلى لنطاق النساء، وحدنا الأدنى للرجال (1500) داخل نطاق الرجال. فهذان الرقمان اختيار تصميمي حذر منا داخل النطاق، وليسا رقمًا واحدًا يحدده المرجع. وتُكتب هكذا في التقرير.
- الملاحظة ⁨N6⁩: مراجعة ⁨Prince⁩ وزملائه (2008) وجدت أن تقدير الناس لنشاطهم بأنفسهم يختلف عن القياس المباشر، وفي أغلب الدراسات يكون أعلى منه. أما نصيحة «إن احترت بين خيارين فاختر الأقل» فهي اختيار تصميمي حذر بنيناه على هذه النتيجة، وليست توصية مكتوبة في المرجع. وتُكتب هكذا في التقرير.

## نصوص أُعيدت صياغتها لأنها بلا مصدر موثوق

- «عجز معتدل وآمن في السعرات» صار «سعرات أقل قليلًا من احتياجك، بوتيرة معتدلة» (كلمة «آمن» وعد طبي).
- «أكل متوازن يحافظ على طاقتك» صار «سعرات على قدر احتياجك لتحافظ على وزنك» (أثر على الطاقة غير مقاس).
- «الحد الآمن للزيادة نصف كغ أسبوعيًا» صار «نجعل الزيادة نصف كغ في الأسبوع على الأكثر» (لا مصدر محدد للرقم).
- «دهون صحية وملح أقل» صار «دهون مشبعة أقل وملح أقل» (القاعدة الفعلية لها مصدر ⁨[17]).⁩
- «الأفضل للجلسة الواحدة كوب إلى كوبين (250 إلى 500 مل)» صار نص المستخدم المعتمد بلا سقف رقمي للجلسة (لا مصدر لسقف 500 مل).
