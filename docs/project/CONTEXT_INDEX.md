# فهرس سياق المشروع (⁨CONTEXT_INDEX⁩)

اقرأ هذا الملف أولًا بدل قراءة ⁨PROJECT_CONTEXT_v4_21.md⁩ كاملًا (حوالي 34⁨k tokens⁩).
ثم اقرأ فقط الأقسام التي تحتاجها بأرقام الأسطر، مثلًا:

```bash
sed -n '395,398p' PROJECT_CONTEXT_v4_21.md
```

## الحالة الحالية (2026-10-20)

- مصدر الحقيقة: ⁨knowledge/claude/PROJECT_CONTEXT_v4_21.md⁩. المخطط ⁨schema-v1⁩ مع ملفات ⁨migration⁩ حتى 0006 (آخرها حذف الحالات الملغاة، القرار #167). البيانات مجمّدة عند ⁨catalog_v3⁩ بالعلامة ⁨dataset-v3⁩ (158 وجبة نشطة، و 477 خطوة تحضير على 121 وجبة).
- آخر قرار: #216، وآخر قيد في ⁨DEV_JOURNAL⁩ هو ⁨J-046⁩.
- النطاق الصحي نهائي: السكري من النوع الثاني والضغط والقلب فقط. الكلى والحمل والرضاعة والنقرس ملغاة نهائيًا، والإنسولين يدخل الوضع العام.
- الخطوات ⁨B⁩ إلى ⁨I⁩ مغلقة. ⁨Step I⁩ (الـ ⁨API⁩) مغلقة: العقد ثابت عند ⁨1.0.0⁩، و 37 عملية، ولا مسار غير منفذ. الخطة في ⁨steps/STEP_I_plan.md⁩. التالي: ⁨Step J⁩ الاستضافة، ثم ⁨Step K⁩ تطبيق ⁨Flutter⁩.
- الأهداف ثلاثة فقط (إنقاص، محافظة، زيادة)، ومسار بناء العضلات ملغى نهائيًا. المستخدم يبني التطبيق كاملًا وحده (الخادم والواجهات و ⁨Flutter⁩)، والزميلان للجزء النظري فقط.
- النسخ القديمة والخطوات المغلقة في ⁨archive⁩/ ولا تُقرأ إلا عند الحاجة لتاريخ قرار.

## خريطة أقسام ⁨PROJECT_CONTEXT_v4_21.md⁩

ملاحظة: أرقام الأسطر صالحة لنسخة ⁨v4.21⁩ فقط؛ أعد توليدها عند كل نسخة جديدة.

```text
    1-1      # PROJECT_CONTEXT.md — v4.21
    2-13     # Fresh-Start Data Architecture & PostgreSQL Rebuild — Nutrition / Meal Recommendation Project
   14-49     ## CHANGELOG — v4.20 → v4.21
   50-60     ## CHANGELOG — v4.19 → v4.20
   61-108    ## CHANGELOG — v4.18 → v4.19
  109-134    ## CHANGELOG — v4.17 → v4.18
  135-150    ## CHANGELOG — v4.16 → v4.17
  151-170    ## CHANGELOG — v4.15 → v4.16
  171-189    ## CHANGELOG — v4.14 → v4.15
  190-204    ## CHANGELOG — v4.13 → v4.14
  205-217    ## CHANGELOG — v4.12 → v4.13
  218-230    ## CHANGELOG — v4.11 → v4.12
  231-243    ## CHANGELOG — v4.10 → v4.11
  244-258    ## CHANGELOG — v4.9 → v4.10
  259-270    ## CHANGELOG — v4.8 → v4.9
  271-284    ## CHANGELOG — v4.7 → v4.8
  285-292    ## CHANGELOG — v4.6 → v4.7
  293-306    ## CHANGELOG — v4.5 → v4.6
  307-322    ## CHANGELOG — v4.4 → v4.5
  323-336    ## CHANGELOG — v4.3 → v4.4
  337-346    ## CHANGELOG — v4.2 → v4.3
  347-371    ## CHANGELOG — v4.1 → v4.2
  372-380    ## CHANGELOG — v4 → v4.1
  381-394    ## CHANGELOG — v3 → v4
  395-398    ## 1. Project Identity
  399-414    ### Current technology direction
  415-416    # 2. CRITICAL — Fresh Rebuild, Not a Rewrite of the Old Project
  417-426    ### Do NOT
  427-434    ### What may be reused conceptually
  435-439    ### Core principle
  440-451    # 3. The Main Problem We Are Solving Now
  452-453    # 4. Dataset Architecture vs Database Architecture
  454-458    ## 4.1 Database architecture — NOW
  459-472    ## 4.2 Dataset population — LATER
  473-480    # 5. Why the FNDDS Investigation Still Matters
  481-482    # 6. FNDDS Audit Findings That Influence the New Architecture
  483-488    ## 6.1 Ingredient structure
  489-497    ## 6.2 Nutrition structure — CORRECTED in v4.4 (Decision #40)
  498-517    ## 6.3 Compatibility audit of all five FNDDS files — NEW in v4.4
  518-527    ## 6.4 How FNDDS is used (Decision #38)
  528-529    # 7. Current Objective — Database First, Data Later
  530-534    ## PHASE 1 — DATABASE ARCHITECTURE (CURRENT)
  535-547    ## PHASE 2 — DATASET BUILDING AND POPULATION (LATER)
  548-567    # 8. Authoritative Architecture
  568-569    # 9. DOMAIN 1 — REFERENCE
  570-577    ## 9.1 `categories`
  578-581    ## 9.2 `cuisines`
  582-585    ## 9.3 `allergens`
  586-597    ## 9.4 `dietary_tags` — CHANGED in v4.2 (Decision #24)
  598-604    ### 9.4b Meal Occasion / Time-Suitability Tags (v4.1 Decision #16, refined in v4.2)
  605-614    ## 9.5 `health_conditions` — CHANGED in v4.2 (Decision #27)
  615-638    ## 9.5b `condition_nutrient_limits` — CHANGED in v4.2 (Decision #18)
  639-651    ## 9.5c `condition_tag_restrictions`
  652-663    ## 9.6 `foods`
  664-688    ## 9.7 `nutrients` — CHANGED in v4.2 (Decision #26)
  689-697    ## 9.8 `food_nutrients`
  698-701    ## 9.9 `portions_food`
  702-709    ## 9.10 `ingredients`
  710-715    ## 9.11 `ingredient_aliases` — CHANGED in v4.2 (Decision #28)
  716-719    ## 9.12 `ingredient_allergens`
  720-729    ## 9.13 `ingredient_tags` — NEW in v4.2 (Decision #23)
  730-731    # 10. DOMAIN 2 — CATALOG
  732-759    ## 10.1 `meals` — CHANGED in v4.2 (Decisions #25, #28)
  760-767    ## 10.2 `meal_ingredients`
  768-780    ## 10.3 `meal_nutrients`
  781-783    ## 10.4 `meal_allergens`
  784-793    ## 10.5 `meal_tags` — CHANGED in v4.2 (Decision #23)
  794-800    ## 10.6 `meal_translations` — CHANGED in v4.2 (Decision #28)
  801-808    ## 10.7 `meal_steps` — NEW in v4.19 (Decisions #161, #165)
  809-810    # 11. DOMAIN 3 — USER
  811-814    ## 11.1 `users`
  815-835    ## 11.2 `user_profiles` — CHANGED in v4.2 (Decisions #19, #20, #22, #27)
  836-840    ## 11.3 `user_health_conditions`
  841-843    ## 11.4 `user_allergen_prefs`
  844-846    ## 11.5 `user_ingredient_prefs`
  847-860    ## 11.6 `user_interactions` — CHANGED in v4.2 (Decision #28)
  861-867    ## 11.7 `meal_plans`
  868-878    ## 11.8 `meal_plan_items` — CHANGED in v4.2 (Decision #21)
  879-913    ## 11.9 `consumption_logs` — CHANGED in v4.2 (Decision #21) — single source of truth for what was eaten
  914-928    ## 11.10 `weight_logs` — NEW in v4.2 (Decision #19)
  929-945    ## 11.11 `user_targets` — NEW in v4.2 (Decision #22)
  946-960    ## 11.12 `refresh_tokens` — NEW in v4.5 (Decision #45)
  961-974    ## 11.13 `water_logs` — NEW in v4.6 (Decision #49)
  975-980    ## 11.14 `user_meal_prefs` — NEW in v4.19 (Decisions #149, #165)
  981-986    ## 11.15 `user_cuisine_prefs` — NEW in v4.19 (Decision #165)
  987-1046   # 12. Relationship Map
 1047-1069   # 13. Source Data and Future Dataset Management
 1070-1075   # 14. Data Provenance Is a First-Class Requirement
 1076-1077   # 15. Core Database Design Principles
 1078-1082   ## 15.1 Internal IDs vs external IDs
 1083-1097   ## 15.2 Numeric measurements must be numeric
 1098-1102   ## 15.3 Constraints protect the dataset
 1103-1107   ## 15.4 Normalize first, denormalize only deliberately
 1108-1112   ## 15.5 Multilingual support belongs in the data model
 1113-1115   ## 15.6 Do not encode business rules only in application code
 1116-1137   ## 15.7 Foreign Key delete/update policy
 1138-1140   ## 15.8 Meals use soft delete, never hard delete
 1141-1145   ## 15.9 Arabic-aware search — NEW in v4.2 (Decision #28)
 1146-1160   ## 15.10 Audit-column rule — NEW in v4.5 (Decision #42)
 1161-1166   # 16. PostgreSQL Decision
 1167-1203   # 17. SQLAlchemy / Alembic Structure
 1204-1220   # 18. What Must NOT Be Added Yet
 1221-1311   # 19. Schema Validation Strategy
 1312-1323   # 20. Initial Schema Implementation Workflow
 1324-1336   ## 20.1 Post-freeze change policy — NEW in v4.12 (Decision #73)
 1337-1346   # 21. Future Dataset Population Strategy
 1347-1360   # 22. Future Dataset Versioning
 1361-1368   # 23. Previous Project Lessons — What We Keep and What We Leave Behind
 1369-1370   # 24. Current Status
 1371-1404   ## Completed
 1405-1409   ## Current task
 1410-1436   # 25. Immediate Next Steps
 1437-1443   # 26. Working Method for the AI Assistant
 1444-1454   ### Important rules
 1455-1461   ### Continuous documentation rule (added 2026-09-28, user request)
 1462-1466   ### Step numbering rule
 1467-1496   # 27. Final Project Direction
 1497-1500   # 28. ML / Recommendation Architecture Direction — REWRITTEN in v4.2 (documented only, not implemented)
 1501-1513   ## 28.0 Honest classification
 1514-1524   ## 28.1 Layer 1 — hard-filtering rules
 1525-1532   ## 28.2 Multi-condition limit resolution (Decision #18)
 1533-1539   ## 28.3 Layer 2 — personalization details (direction)
 1540-1542   ## 28.4 Layer 3 — optimization details (direction; implemented as `cpsat_v1` in v4.18, see §28.4c)
 1543-1560   ## 28.4b Baseline planner `greedy_v1` — NEW in v4.15 (Decisions #80, #88)
 1561-1572   ## 28.4c Layer 3 optimizer `cpsat_v1` — NEW in v4.18 (Decisions #108–#122)
 1573-1578   ## 28.5 Evaluation plan (direction)
 1579-1583   ## 28.6 Explainable recommendations (Decision #46, P-11)
 1584-1585   # 29. Feature Scope & Roadmap
 1586-1598   ## Core Now (supported by the v4.2 schema)
 1599-1601   ## Core Important — the project's differentiator
 1602-1609   ## Near-Future Addition
 1610-1627   ## Documented Future Work (not designed, not scheduled)
 1628-1631   # 30. Nutrition Targets & Safety Rules — NEW in v4.2 (Decision #30) — application logic, `formula_version = targets_v1`
 1632-1647   ## 30.1 Screening (before any personalized plan)
 1648-1651   ## 30.2 Energy
 1652-1658   ## 30.3 Goal adjustment & safety
 1659-1666   ## 30.4 Macronutrients — details settled in v4.10 (Decisions #64–#67)
 1667-1673   ## 30.4b Fiber — NEW in v4.10 (Decision #68)
 1674-1680   ## 30.5 Daily adherence (computed, not stored)
 1681-1683   ## 30.6 Recompute triggers
 1684-1693   ## 30.7 Water goal & fluid safety — NEW in v4.6 (Decisions #49, #50)
 1694-1695   # 31. Meal Catalog Content Strategy — NEW in v4.2 (Decision #31) — Phase 2 direction
 1696-1698   ## 31.1 Diagnosis
 1699-1706   ## 31.2 Strategy: Curated Recipe Catalog
 1707-1713   ## 31.3 Quality gates
 1714-1716   ## 31.4 LLM-assisted drafting rules
 1717-1719   ## 31.5 Deferred sources
 1720-1727   ## 31.6 Excluded-ingredients policy — NEW in v4.3 (Decision #34)
 1728-1740   ## 31.7 Step G pipeline and catalog rules — NEW in v4.16 (Decisions #90–#100), results in v4.17 (#101–#107)
 1741-1762   # 32. Technology Additions — NEW in v4.2 (Decision #32)
 1763-1764   # 33. Offline-First Hybrid Architecture — NEW in v4.4 (Decision #37)
 1765-1767   ## 33.1 Clarification
 1768-1778   ## 33.2 Architecture
 1779-1793   ## 33.3 What works offline vs online
 1794-1808   ## 33.4 Sync rules (server side built in Step I.7, #208–#213; device side in Step K)
 1809-1813   ## 33.5 Why not fully local (no server)
 1814-1817   # 34. Engineering Standards — NEW in v4.5 (Decision #48; backlog P-01…P-11)
 1818-1820   ## 34.1 Configuration (P-06) — Step B
 1821-1825   ## 34.2 Authentication (P-05) — built in Step I.2 (#130)
 1826-1828   ## 34.3 API contract (P-07) — built in Step I.1, frozen at 1.0.0 in I.8 (#125, #173, #216)
 1829-1831   ## 34.4 Rate limiting (P-09) — built in Step I (#132, #192)
 1832-1834   ## 34.5 Observability (P-08) — built in Step I.0 (#133)
 1835-1837   ## 34.6 Code quality (P-10) — Step B/C
 1838-1843   ## 34.7 Testing & CI (P-02, P-03) — Step E
 1844-1846   ## 34.8 Schema-level standards (P-01, P-04)
 1847-1849   ## 34.9 Explainability (P-11)
```

## خريطة ⁨DEV_JOURNAL.md⁩

```text
  1-10       # DEV_JOURNAL — سجل التطوير والتوثيق النظري
  11-27      ## قالب كل إدخال
  28-80      ## فهرس الإدخالات حسب فصول التقرير
  81-82      ## الإدخالات
  83-91      ### J-001 — تشخيص المشكلة الجذرية: استراتيجية المحتوى
  92-103     ### J-002 — مصادر البيانات الغذائية وبناء كتالوج منتقى
  104-111    ### J-003 — القيود المرضية القابلة للتنفيذ وحل تعارضها
  112-118    ### J-004 — البيانات الزمنية: سجل الوزن والأهداف ذات الإصدارات
  119-125    ### J-005 — مصدر حقيقة واحد للاستهلاك والالتزام اليومي
  126-132    ### J-006 — الوسوم على مستوى المكوّن والبيانات المشتقة
  133-140    ### J-007 — الوزن بعد الطبخ ومنهجية حساب القيم الغذائية
  141-147    ### J-008 — العناصر الغذائية الإلزامية وقاعدة "المفقود ليس صفرًا"
  148-159    ### J-009 — حساب الاحتياج اليومي وقواعد الأمان
  160-178    ### J-010 — معمارية التوصية الهجينة وتصنيف صادق لتعلم الآلة
  179-187    ### J-011 — سياسة المكونات المستبعدة: صحة البيانات بالبناء
  188-200    ### J-012 — تدقيق FNDDS البرمجي وتصحيح افتراض سابق
  201-213    ### J-013 — الهوية الخارجية للمصادر ونطاق الاستيراد
  214-236    ### J-014 — معمارية Offline-First والمزامنة الـ Idempotent
  237-247    ### J-015 — البحث العربي المُطبَّع
  248-258    ### J-016 — سياسة التوثيق المستمر
  259-278    ### J-017 — اعتماد الميزات الاحترافية بعد تحليل التكامل (Change Impact Analysis)
  279-302    ### J-018 — حل التعارضات وتحويل الميزات إلى مواصفات ملزمة
  303-331    ### J-019 — تتبع الماء والتذكيرات: تغيير نطاق قبل التجميد مع قاعدة أمان للسوائل
  332-352    ### J-020 — الـ Chatbot: تأجيل مع تثبيت قيود التصميم
  353-366    ### J-021 — حذف النقرس من نطاق المشروع
  367-396    ### ⁨J-022⁩ — إغلاق الخطوة ⁨Step B⁩: بيئة ⁨PostgreSQL⁩ المحلية وبوابات جودة الكود
  397-415    ### ⁨J-023⁩ — مراجعة الاتساق قبل ⁨Step C⁩ وإصدار الوثيقة ⁨v4.8⁩
  416-435    ### ⁨J-024⁩ — إغلاق ⁨Step C⁩: نماذج ⁨SQLAlchemy⁩ للجداول الـ 34 وإصدار ⁨v4.9⁩
  436-460    ### ⁨J-025⁩ — إغلاق ⁨Step D⁩: أول ⁨Migration⁩ عبر ⁨Alembic⁩
  461-478    ### ⁨J-026⁩ — تفاصيل حساب الأهداف اليومية في ⁨§30⁩ وإصدار ⁨v4.10⁩
  479-505    ### ⁨J-027⁩ — إغلاق ⁨Step E⁩: اختبارات سلامة القاعدة والتكامل المستمر ⁨CI⁩ وإصدار ⁨v4.11⁩
  506-524    ### ⁨J-028⁩ — مراجعة ما قبل التجميد وإصدار ⁨v4.12⁩ (القرارات #70 إلى #73)
  525-545    ### ⁨J-029⁩ — إغلاق ⁨Step F⁩: تجميد المخطط عند ⁨schema-v1⁩ وإصدار ⁨v4.13⁩
  546-564    ### ⁨J-030⁩ — دراسة ⁨Hugging Face⁩ كمصدر للوصفات والقيم الغذائية، واعتماد خطة ⁨Step F.1⁩
  565-588    ### ⁨J-031⁩ — أول تغيير بعد التجميد: مكونات اختيارية، ونسخ الأطباق، ورموز ثابتة، وحقول الجودة، وإصدار ⁨v4.14⁩ (#74 إلى #79)
  589-625    ### ⁨J-032⁩ — إغلاق ⁨Step F.1⁩: الشريحة الرأسية من البيانات حتى التقدم، وخوارزمية الأساس ⁨greedy_v1⁩، وإصدار ⁨v4.15⁩ (#80 إلى #89)
  626-654    ### ⁨J-033⁩ — بدء ⁨Step G⁩: خطة هندسة البيانات، وفصل المخطط في ⁨Step G.0⁩، وإصدار ⁨v4.16⁩ (#90 إلى #100)
  655-688    ### ⁨J-034⁩ — إغلاق ⁨Step G⁩: الكتالوج الحقيقي الأول، وعزل المعيار، وتجميد ⁨catalog_v1⁩، وإصدار ⁨v4.17⁩ (#101 إلى #107)
  689-722    ### ⁨J-035⁩ — إغلاق ⁨Step H⁩: المُحسِّن ⁨cpsat_v1⁩ بمحرك ⁨CP-SAT⁩، والحدود الصحية العامة، وإصدار ⁨v4.18⁩ (#108 إلى #122)
  723-737    ### ⁨J-036⁩ — مرور المخطط الوحيد في ⁨Step I⁩: الاستيقاظ والنوم، والمفضلة، وخطوات التحضير، وإصدار ⁨v4.19⁩ (#141 إلى #166)
  738-754    ### ⁨J-037⁩ — إلغاء الكلى والحمل والرضاعة والنقرس نهائيًا، وإصدار ⁨v4.20⁩ (#167)
  755-776    ### ⁨J-038⁩ — عقد الواجهة البرمجية الكامل قبل التنفيذ (⁨Contract-First API⁩)
  777-808    ### ⁨J-039⁩ — تسجيل الدخول وإدارة الجلسات وحذف الحساب
  809-831    ### ⁨J-040⁩ — الملف الشخصي والأهداف اليومية وهدف الماء والقوائم المرجعية والبحث والوجبات المفضلة
  832-854    ### ⁨J-041⁩ — الكتالوج: البحث وتفاصيل الوجبة ولقطة العمل دون إنترنت ورقم الإصدار
  855-882    ### ⁨J-042⁩ — الخطط عبر الواجهة البرمجية: توليد خطة اليوم، والشاشة الرئيسية، والبدائل والاستبدال، وقائمة المشتريات
  883-916    ### ⁨J-043⁩ — إصلاح بحث المحسّن: لماذا كانت الخطة بطيئة وغير متوازنة، وكيف أُصلحت
  917-941    ### ⁨J-044⁩ — تسجيل الأكل والماء والوزن والتقدم وأحداث التطبيق
  942-975    ### ⁨J-045⁩ — المزامنة دون إنترنت: رفع العمليات دفعة واحدة وموجز التغييرات
  976-1006   ### ⁨J-046⁩ — إغلاق مرحلة الواجهة البرمجية: إصلاح آخر الحالات، والسيناريو الكامل، وقياس الزمن، وتثبيت العقد عند 1.0.0، وإصدار ⁨v4.21⁩
  1007-1023  ## قائمة الميزات الاحترافية المقترحة (Backlog — بانتظار الموافقة)
```
