# فهرس سياق المشروع (⁨CONTEXT_INDEX⁩)

اقرأ هذا الملف أولًا بدل قراءة ⁨PROJECT_CONTEXT_v4_20.md⁩ كاملًا (حوالي 34⁨k tokens⁩).
ثم اقرأ فقط الأقسام التي تحتاجها بأرقام الأسطر، مثلًا:

```bash
sed -n '344,363p' PROJECT_CONTEXT_v4_20.md
```

## الحالة الحالية (2026-10-19)

- مصدر الحقيقة: ⁨knowledge/claude/PROJECT_CONTEXT_v4_20.md⁩. المخطط ⁨schema-v1⁩ مع ملفات ⁨migration⁩ حتى 0006 (آخرها حذف الحالات الملغاة، القرار #167). البيانات مجمّدة عند ⁨catalog_v3⁩ بالعلامة ⁨dataset-v3⁩ (158 وجبة نشطة، و 477 خطوة تحضير على 121 وجبة).
- آخر قرار: #207، وآخر قيد في ⁨DEV_JOURNAL⁩ هو ⁨J-043⁩.
- النطاق الصحي نهائي: السكري من النوع الثاني والضغط والقلب فقط. الكلى والحمل والرضاعة والنقرس ملغاة نهائيًا، والإنسولين يدخل الوضع العام.
- الخطوات ⁨B⁩ إلى ⁨H⁩ مغلقة. ⁨Step I⁩ (الـ ⁨API⁩) جارية: العقد ⁨I.1⁩ والدخول ⁨I.2⁩ مغلقان، والملف الشخصي ⁨I.3⁩ مغلقة، والجاري الكتالوج ⁨I.4⁩. الخطة في ⁨steps/STEP_I_plan.md⁩.
- الأهداف ثلاثة فقط (إنقاص، محافظة، زيادة)، ومسار بناء العضلات ملغى نهائيًا. المستخدم يبني التطبيق كاملًا وحده (الخادم والواجهات و ⁨Flutter⁩)، والزميلان للجزء النظري فقط.
- النسخ القديمة والخطوات المغلقة في ⁨archive⁩/ ولا تُقرأ إلا عند الحاجة لتاريخ قرار.

## خريطة أقسام ⁨PROJECT_CONTEXT_v4_20.md⁩

ملاحظة: أرقام الأسطر صالحة لنسخة ⁨v4.20⁩ فقط؛ أعد توليدها عند كل نسخة جديدة.

```text
    1-1      # PROJECT_CONTEXT.md — v4.20
    2-13     # Fresh-Start Data Architecture & PostgreSQL Rebuild — Nutrition / Meal Recommendation Project
   14-24     ## CHANGELOG — v4.19 → v4.20
   25-72     ## CHANGELOG — v4.18 → v4.19
   73-98     ## CHANGELOG — v4.17 → v4.18
   99-114    ## CHANGELOG — v4.16 → v4.17
  115-134    ## CHANGELOG — v4.15 → v4.16
  135-153    ## CHANGELOG — v4.14 → v4.15
  154-168    ## CHANGELOG — v4.13 → v4.14
  169-181    ## CHANGELOG — v4.12 → v4.13
  182-194    ## CHANGELOG — v4.11 → v4.12
  195-207    ## CHANGELOG — v4.10 → v4.11
  208-222    ## CHANGELOG — v4.9 → v4.10
  223-234    ## CHANGELOG — v4.8 → v4.9
  235-248    ## CHANGELOG — v4.7 → v4.8
  249-256    ## CHANGELOG — v4.6 → v4.7
  257-270    ## CHANGELOG — v4.5 → v4.6
  271-286    ## CHANGELOG — v4.4 → v4.5
  287-300    ## CHANGELOG — v4.3 → v4.4
  301-310    ## CHANGELOG — v4.2 → v4.3
  311-335    ## CHANGELOG — v4.1 → v4.2
  336-344    ## CHANGELOG — v4 → v4.1
  345-358    ## CHANGELOG — v3 → v4
  359-362    ## 1. Project Identity
  363-378    ### Current technology direction
  379-380    # 2. CRITICAL — Fresh Rebuild, Not a Rewrite of the Old Project
  381-390    ### Do NOT
  391-398    ### What may be reused conceptually
  399-403    ### Core principle
  404-415    # 3. The Main Problem We Are Solving Now
  416-417    # 4. Dataset Architecture vs Database Architecture
  418-422    ## 4.1 Database architecture — NOW
  423-436    ## 4.2 Dataset population — LATER
  437-444    # 5. Why the FNDDS Investigation Still Matters
  445-446    # 6. FNDDS Audit Findings That Influence the New Architecture
  447-452    ## 6.1 Ingredient structure
  453-461    ## 6.2 Nutrition structure — CORRECTED in v4.4 (Decision #40)
  462-481    ## 6.3 Compatibility audit of all five FNDDS files — NEW in v4.4
  482-491    ## 6.4 How FNDDS is used (Decision #38)
  492-493    # 7. Current Objective — Database First, Data Later
  494-498    ## PHASE 1 — DATABASE ARCHITECTURE (CURRENT)
  499-511    ## PHASE 2 — DATASET BUILDING AND POPULATION (LATER)
  512-531    # 8. Authoritative Architecture
  532-533    # 9. DOMAIN 1 — REFERENCE
  534-541    ## 9.1 `categories`
  542-545    ## 9.2 `cuisines`
  546-549    ## 9.3 `allergens`
  550-561    ## 9.4 `dietary_tags` — CHANGED in v4.2 (Decision #24)
  562-568    ### 9.4b Meal Occasion / Time-Suitability Tags (v4.1 Decision #16, refined in v4.2)
  569-578    ## 9.5 `health_conditions` — CHANGED in v4.2 (Decision #27)
  579-602    ## 9.5b `condition_nutrient_limits` — CHANGED in v4.2 (Decision #18)
  603-615    ## 9.5c `condition_tag_restrictions`
  616-627    ## 9.6 `foods`
  628-652    ## 9.7 `nutrients` — CHANGED in v4.2 (Decision #26)
  653-661    ## 9.8 `food_nutrients`
  662-665    ## 9.9 `portions_food`
  666-673    ## 9.10 `ingredients`
  674-679    ## 9.11 `ingredient_aliases` — CHANGED in v4.2 (Decision #28)
  680-683    ## 9.12 `ingredient_allergens`
  684-693    ## 9.13 `ingredient_tags` — NEW in v4.2 (Decision #23)
  694-695    # 10. DOMAIN 2 — CATALOG
  696-723    ## 10.1 `meals` — CHANGED in v4.2 (Decisions #25, #28)
  724-731    ## 10.2 `meal_ingredients`
  732-744    ## 10.3 `meal_nutrients`
  745-747    ## 10.4 `meal_allergens`
  748-757    ## 10.5 `meal_tags` — CHANGED in v4.2 (Decision #23)
  758-764    ## 10.6 `meal_translations` — CHANGED in v4.2 (Decision #28)
  765-772    ## 10.7 `meal_steps` — NEW in v4.19 (Decisions #161, #165)
  773-774    # 11. DOMAIN 3 — USER
  775-778    ## 11.1 `users`
  779-799    ## 11.2 `user_profiles` — CHANGED in v4.2 (Decisions #19, #20, #22, #27)
  800-804    ## 11.3 `user_health_conditions`
  805-807    ## 11.4 `user_allergen_prefs`
  808-810    ## 11.5 `user_ingredient_prefs`
  811-824    ## 11.6 `user_interactions` — CHANGED in v4.2 (Decision #28)
  825-831    ## 11.7 `meal_plans`
  832-842    ## 11.8 `meal_plan_items` — CHANGED in v4.2 (Decision #21)
  843-877    ## 11.9 `consumption_logs` — CHANGED in v4.2 (Decision #21) — single source of truth for what was eaten
  878-892    ## 11.10 `weight_logs` — NEW in v4.2 (Decision #19)
  893-909    ## 11.11 `user_targets` — NEW in v4.2 (Decision #22)
  910-924    ## 11.12 `refresh_tokens` — NEW in v4.5 (Decision #45)
  925-938    ## 11.13 `water_logs` — NEW in v4.6 (Decision #49)
  939-944    ## 11.14 `user_meal_prefs` — NEW in v4.19 (Decisions #149, #165)
  945-950    ## 11.15 `user_cuisine_prefs` — NEW in v4.19 (Decision #165)
  951-1010   # 12. Relationship Map
 1011-1033   # 13. Source Data and Future Dataset Management
 1034-1039   # 14. Data Provenance Is a First-Class Requirement
 1040-1041   # 15. Core Database Design Principles
 1042-1046   ## 15.1 Internal IDs vs external IDs
 1047-1061   ## 15.2 Numeric measurements must be numeric
 1062-1066   ## 15.3 Constraints protect the dataset
 1067-1071   ## 15.4 Normalize first, denormalize only deliberately
 1072-1076   ## 15.5 Multilingual support belongs in the data model
 1077-1079   ## 15.6 Do not encode business rules only in application code
 1080-1101   ## 15.7 Foreign Key delete/update policy
 1102-1104   ## 15.8 Meals use soft delete, never hard delete
 1105-1109   ## 15.9 Arabic-aware search — NEW in v4.2 (Decision #28)
 1110-1124   ## 15.10 Audit-column rule — NEW in v4.5 (Decision #42)
 1125-1130   # 16. PostgreSQL Decision
 1131-1167   # 17. SQLAlchemy / Alembic Structure
 1168-1184   # 18. What Must NOT Be Added Yet
 1185-1275   # 19. Schema Validation Strategy
 1276-1287   # 20. Initial Schema Implementation Workflow
 1288-1300   ## 20.1 Post-freeze change policy — NEW in v4.12 (Decision #73)
 1301-1310   # 21. Future Dataset Population Strategy
 1311-1324   # 22. Future Dataset Versioning
 1325-1332   # 23. Previous Project Lessons — What We Keep and What We Leave Behind
 1333-1334   # 24. Current Status
 1335-1365   ## Completed
 1366-1370   ## Current task
 1371-1395   # 25. Immediate Next Steps
 1396-1402   # 26. Working Method for the AI Assistant
 1403-1413   ### Important rules
 1414-1420   ### Continuous documentation rule (added 2026-09-28, user request)
 1421-1425   ### Step numbering rule
 1426-1455   # 27. Final Project Direction
 1456-1459   # 28. ML / Recommendation Architecture Direction — REWRITTEN in v4.2 (documented only, not implemented)
 1460-1472   ## 28.0 Honest classification
 1473-1483   ## 28.1 Layer 1 — hard-filtering rules
 1484-1491   ## 28.2 Multi-condition limit resolution (Decision #18)
 1492-1498   ## 28.3 Layer 2 — personalization details (direction)
 1499-1501   ## 28.4 Layer 3 — optimization details (direction; implemented as `cpsat_v1` in v4.18, see §28.4c)
 1502-1519   ## 28.4b Baseline planner `greedy_v1` — NEW in v4.15 (Decisions #80, #88)
 1520-1531   ## 28.4c Layer 3 optimizer `cpsat_v1` — NEW in v4.18 (Decisions #108–#122)
 1532-1537   ## 28.5 Evaluation plan (direction)
 1538-1542   ## 28.6 Explainable recommendations (Decision #46, P-11)
 1543-1544   # 29. Feature Scope & Roadmap
 1545-1557   ## Core Now (supported by the v4.2 schema)
 1558-1560   ## Core Important — the project's differentiator
 1561-1568   ## Near-Future Addition
 1569-1586   ## Documented Future Work (not designed, not scheduled)
 1587-1590   # 30. Nutrition Targets & Safety Rules — NEW in v4.2 (Decision #30) — application logic, `formula_version = targets_v1`
 1591-1606   ## 30.1 Screening (before any personalized plan)
 1607-1610   ## 30.2 Energy
 1611-1617   ## 30.3 Goal adjustment & safety
 1618-1625   ## 30.4 Macronutrients — details settled in v4.10 (Decisions #64–#67)
 1626-1632   ## 30.4b Fiber — NEW in v4.10 (Decision #68)
 1633-1639   ## 30.5 Daily adherence (computed, not stored)
 1640-1642   ## 30.6 Recompute triggers
 1643-1652   ## 30.7 Water goal & fluid safety — NEW in v4.6 (Decisions #49, #50)
 1653-1654   # 31. Meal Catalog Content Strategy — NEW in v4.2 (Decision #31) — Phase 2 direction
 1655-1657   ## 31.1 Diagnosis
 1658-1665   ## 31.2 Strategy: Curated Recipe Catalog
 1666-1672   ## 31.3 Quality gates
 1673-1675   ## 31.4 LLM-assisted drafting rules
 1676-1678   ## 31.5 Deferred sources
 1679-1686   ## 31.6 Excluded-ingredients policy — NEW in v4.3 (Decision #34)
 1687-1699   ## 31.7 Step G pipeline and catalog rules — NEW in v4.16 (Decisions #90–#100), results in v4.17 (#101–#107)
 1700-1721   # 32. Technology Additions — NEW in v4.2 (Decision #32)
 1722-1723   # 33. Offline-First Hybrid Architecture — NEW in v4.4 (Decision #37)
 1724-1726   ## 33.1 Clarification
 1727-1737   ## 33.2 Architecture
 1738-1752   ## 33.3 What works offline vs online
 1753-1766   ## 33.4 Sync rules (direction — implemented in the app phase, not Phase 1)
 1767-1771   ## 33.5 Why not fully local (no server)
 1772-1775   # 34. Engineering Standards — NEW in v4.5 (Decision #48; backlog P-01…P-11)
 1776-1778   ## 34.1 Configuration (P-06) — Step B
 1779-1783   ## 34.2 Authentication (P-05) — API phase *(later)*
 1784-1786   ## 34.3 API contract (P-07) — API phase *(later)*
 1787-1789   ## 34.4 Rate limiting (P-09) — API phase *(later)*
 1790-1792   ## 34.5 Observability (P-08) — API phase *(later)*
 1793-1795   ## 34.6 Code quality (P-10) — Step B/C
 1796-1801   ## 34.7 Testing & CI (P-02, P-03) — Step E
 1802-1804   ## 34.8 Schema-level standards (P-01, P-04)
 1805-1807   ## 34.9 Explainability (P-11)
```

## خريطة ⁨DEV_JOURNAL.md⁩

```text
  1-10       # DEV_JOURNAL — سجل التطوير والتوثيق النظري
  11-13      ## قالب كل إدخال
  14-27      ### J-NNN — عنوان مختصر
  28-77      ## فهرس الإدخالات حسب فصول التقرير
  78-79      ## الإدخالات
  80-88      ### J-001 — تشخيص المشكلة الجذرية: استراتيجية المحتوى
  89-100     ### J-002 — مصادر البيانات الغذائية وبناء كتالوج منتقى
  101-108    ### J-003 — القيود المرضية القابلة للتنفيذ وحل تعارضها
  109-115    ### J-004 — البيانات الزمنية: سجل الوزن والأهداف ذات الإصدارات
  116-122    ### J-005 — مصدر حقيقة واحد للاستهلاك والالتزام اليومي
  123-129    ### J-006 — الوسوم على مستوى المكوّن والبيانات المشتقة
  130-137    ### J-007 — الوزن بعد الطبخ ومنهجية حساب القيم الغذائية
  138-144    ### J-008 — العناصر الغذائية الإلزامية وقاعدة "المفقود ليس صفرًا"
  145-156    ### J-009 — حساب الاحتياج اليومي وقواعد الأمان
  157-175    ### J-010 — معمارية التوصية الهجينة وتصنيف صادق لتعلم الآلة
  176-184    ### J-011 — سياسة المكونات المستبعدة: صحة البيانات بالبناء
  185-197    ### J-012 — تدقيق FNDDS البرمجي وتصحيح افتراض سابق
  198-210    ### J-013 — الهوية الخارجية للمصادر ونطاق الاستيراد
  211-233    ### J-014 — معمارية Offline-First والمزامنة الـ Idempotent
  234-244    ### J-015 — البحث العربي المُطبَّع
  245-255    ### J-016 — سياسة التوثيق المستمر
  256-275    ### J-017 — اعتماد الميزات الاحترافية بعد تحليل التكامل (Change Impact Analysis)
  276-299    ### J-018 — حل التعارضات وتحويل الميزات إلى مواصفات ملزمة
  300-328    ### J-019 — تتبع الماء والتذكيرات: تغيير نطاق قبل التجميد مع قاعدة أمان للسوائل
  329-349    ### J-020 — الـ Chatbot: تأجيل مع تثبيت قيود التصميم
  350-363    ### J-021 — حذف النقرس من نطاق المشروع
  364-393    ### ⁨J-022⁩ — إغلاق الخطوة ⁨Step B⁩: بيئة ⁨PostgreSQL⁩ المحلية وبوابات جودة الكود
  394-412    ### ⁨J-023⁩ — مراجعة الاتساق قبل ⁨Step C⁩ وإصدار الوثيقة ⁨v4.8⁩
  413-432    ### ⁨J-024⁩ — إغلاق ⁨Step C⁩: نماذج ⁨SQLAlchemy⁩ للجداول الـ 34 وإصدار ⁨v4.9⁩
  433-457    ### ⁨J-025⁩ — إغلاق ⁨Step D⁩: أول ⁨Migration⁩ عبر ⁨Alembic⁩
  458-475    ### ⁨J-026⁩ — تفاصيل حساب الأهداف اليومية في ⁨§30⁩ وإصدار ⁨v4.10⁩
  476-502    ### ⁨J-027⁩ — إغلاق ⁨Step E⁩: اختبارات سلامة القاعدة والتكامل المستمر ⁨CI⁩ وإصدار ⁨v4.11⁩
  503-521    ### ⁨J-028⁩ — مراجعة ما قبل التجميد وإصدار ⁨v4.12⁩ (القرارات #70 إلى #73)
  522-542    ### ⁨J-029⁩ — إغلاق ⁨Step F⁩: تجميد المخطط عند ⁨schema-v1⁩ وإصدار ⁨v4.13⁩
  543-561    ### ⁨J-030⁩ — دراسة ⁨Hugging Face⁩ كمصدر للوصفات والقيم الغذائية، واعتماد خطة ⁨Step F.1⁩
  562-585    ### ⁨J-031⁩ — أول تغيير بعد التجميد: مكونات اختيارية، ونسخ الأطباق، ورموز ثابتة، وحقول الجودة، وإصدار ⁨v4.14⁩ (#74 إلى #79)
  586-622    ### ⁨J-032⁩ — إغلاق ⁨Step F.1⁩: الشريحة الرأسية من البيانات حتى التقدم، وخوارزمية الأساس ⁨greedy_v1⁩، وإصدار ⁨v4.15⁩ (#80 إلى #89)
  623-651    ### ⁨J-033⁩ — بدء ⁨Step G⁩: خطة هندسة البيانات، وفصل المخطط في ⁨Step G.0⁩، وإصدار ⁨v4.16⁩ (#90 إلى #100)
  652-685    ### ⁨J-034⁩ — إغلاق ⁨Step G⁩: الكتالوج الحقيقي الأول، وعزل المعيار، وتجميد ⁨catalog_v1⁩، وإصدار ⁨v4.17⁩ (#101 إلى #107)
  686-719    ### ⁨J-035⁩ — إغلاق ⁨Step H⁩: المُحسِّن ⁨cpsat_v1⁩ بمحرك ⁨CP-SAT⁩، والحدود الصحية العامة، وإصدار ⁨v4.18⁩ (#108 إلى #122)
  720-734    ### ⁨J-036⁩ — مرور المخطط الوحيد في ⁨Step I⁩: الاستيقاظ والنوم، والمفضلة، وخطوات التحضير، وإصدار ⁨v4.19⁩ (#141 إلى #166)
  735-751    ### ⁨J-037⁩ — إلغاء الكلى والحمل والرضاعة والنقرس نهائيًا، وإصدار ⁨v4.20⁩ (#167)
  752-773    ### ⁨J-038⁩ — عقد الواجهة البرمجية الكامل قبل التنفيذ (⁨Contract-First API⁩)
  774-805    ### ⁨J-039⁩ — تسجيل الدخول وإدارة الجلسات وحذف الحساب
  806-828    ### ⁨J-040⁩ — الملف الشخصي والأهداف اليومية وهدف الماء والقوائم المرجعية والبحث والوجبات المفضلة
  829-851    ### ⁨J-041⁩ — الكتالوج: البحث وتفاصيل الوجبة ولقطة العمل دون إنترنت ورقم الإصدار
  852-879    ### ⁨J-042⁩ — الخطط عبر الواجهة البرمجية: توليد خطة اليوم، والشاشة الرئيسية، والبدائل والاستبدال، وقائمة المشتريات
  880-913    ### ⁨J-043⁩ — إصلاح بحث المحسّن: لماذا كانت الخطة بطيئة وغير متوازنة، وكيف أُصلحت
  914-931    ## قائمة الميزات الاحترافية المقترحة (Backlog — بانتظار الموافقة)
```
