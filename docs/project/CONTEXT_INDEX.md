# فهرس سياق المشروع (⁨CONTEXT_INDEX⁩)

اقرأ هذا الملف أولًا بدل قراءة ⁨PROJECT_CONTEXT_v4_19.md⁩ كاملًا (حوالي 34⁨k tokens⁩).
ثم اقرأ فقط الأقسام التي تحتاجها بأرقام الأسطر، مثلًا:

```bash
sed -n '344,363p' PROJECT_CONTEXT_v4_19.md
```

## الحالة الحالية (2026-10-17)

- مصدر الحقيقة: ⁨knowledge/claude/PROJECT_CONTEXT_v4_19.md⁩. المخطط ⁨schema-v1⁩ مع ⁨Migration⁩ 0003 و 0004، والمرور ⁨I.0b⁩ يضيف 0005 (القرار #165). البيانات مجمّدة عند ⁨catalog_v2⁩ بالعلامة ⁨dataset-v2⁩ (75 وجبة نشطة).
- آخر قرار: #166، وآخر قيد في ⁨DEV_JOURNAL⁩ هو ⁨J-036⁩.
- الخطوات ⁨B⁩ إلى ⁨H⁩ مغلقة. ⁨Step I⁩ (الـ ⁨API⁩) جارية: ⁨I.0⁩ مغلقة، ثم ⁨I.0b⁩ للمخطط، ثم ⁨I.0c⁩ للبيانات، ثم عقد ⁨I.1⁩. الخطة في ⁨steps/STEP_I_plan.md⁩.
- الواجهات متوقفة مؤقتًا بطلب المستخدم (2026-10-17).
- النسخ القديمة والخطوات المغلقة في ⁨archive⁩/ ولا تُقرأ إلا عند الحاجة لتاريخ قرار.

## خريطة أقسام ⁨PROJECT_CONTEXT_v4_19.md⁩

ملاحظة: أرقام الأسطر صالحة لنسخة ⁨v4.19⁩ فقط؛ أعد توليدها عند كل نسخة جديدة.

```text
    1-1      # PROJECT_CONTEXT.md — v4.19
    2-13     # Fresh-Start Data Architecture & PostgreSQL Rebuild — Nutrition / Meal Recommendation Project
   14-61     ## CHANGELOG — v4.18 → v4.19
   62-87     ## CHANGELOG — v4.17 → v4.18
   88-103    ## CHANGELOG — v4.16 → v4.17
  104-123    ## CHANGELOG — v4.15 → v4.16
  124-142    ## CHANGELOG — v4.14 → v4.15
  143-157    ## CHANGELOG — v4.13 → v4.14
  158-170    ## CHANGELOG — v4.12 → v4.13
  171-183    ## CHANGELOG — v4.11 → v4.12
  184-196    ## CHANGELOG — v4.10 → v4.11
  197-211    ## CHANGELOG — v4.9 → v4.10
  212-223    ## CHANGELOG — v4.8 → v4.9
  224-237    ## CHANGELOG — v4.7 → v4.8
  238-245    ## CHANGELOG — v4.6 → v4.7
  246-259    ## CHANGELOG — v4.5 → v4.6
  260-275    ## CHANGELOG — v4.4 → v4.5
  276-289    ## CHANGELOG — v4.3 → v4.4
  290-299    ## CHANGELOG — v4.2 → v4.3
  300-324    ## CHANGELOG — v4.1 → v4.2
  325-333    ## CHANGELOG — v4 → v4.1
  334-347    ## CHANGELOG — v3 → v4
  348-351    ## 1. Project Identity
  352-367    ### Current technology direction
  368-369    # 2. CRITICAL — Fresh Rebuild, Not a Rewrite of the Old Project
  370-379    ### Do NOT
  380-387    ### What may be reused conceptually
  388-392    ### Core principle
  393-404    # 3. The Main Problem We Are Solving Now
  405-406    # 4. Dataset Architecture vs Database Architecture
  407-411    ## 4.1 Database architecture — NOW
  412-425    ## 4.2 Dataset population — LATER
  426-433    # 5. Why the FNDDS Investigation Still Matters
  434-435    # 6. FNDDS Audit Findings That Influence the New Architecture
  436-441    ## 6.1 Ingredient structure
  442-450    ## 6.2 Nutrition structure — CORRECTED in v4.4 (Decision #40)
  451-470    ## 6.3 Compatibility audit of all five FNDDS files — NEW in v4.4
  471-480    ## 6.4 How FNDDS is used (Decision #38)
  481-482    # 7. Current Objective — Database First, Data Later
  483-487    ## PHASE 1 — DATABASE ARCHITECTURE (CURRENT)
  488-500    ## PHASE 2 — DATASET BUILDING AND POPULATION (LATER)
  501-520    # 8. Authoritative Architecture
  521-522    # 9. DOMAIN 1 — REFERENCE
  523-530    ## 9.1 `categories`
  531-534    ## 9.2 `cuisines`
  535-538    ## 9.3 `allergens`
  539-550    ## 9.4 `dietary_tags` — CHANGED in v4.2 (Decision #24)
  551-557    ### 9.4b Meal Occasion / Time-Suitability Tags (v4.1 Decision #16, refined in v4.2)
  558-567    ## 9.5 `health_conditions` — CHANGED in v4.2 (Decision #27)
  568-591    ## 9.5b `condition_nutrient_limits` — CHANGED in v4.2 (Decision #18)
  592-604    ## 9.5c `condition_tag_restrictions`
  605-616    ## 9.6 `foods`
  617-641    ## 9.7 `nutrients` — CHANGED in v4.2 (Decision #26)
  642-650    ## 9.8 `food_nutrients`
  651-654    ## 9.9 `portions_food`
  655-662    ## 9.10 `ingredients`
  663-668    ## 9.11 `ingredient_aliases` — CHANGED in v4.2 (Decision #28)
  669-672    ## 9.12 `ingredient_allergens`
  673-682    ## 9.13 `ingredient_tags` — NEW in v4.2 (Decision #23)
  683-684    # 10. DOMAIN 2 — CATALOG
  685-712    ## 10.1 `meals` — CHANGED in v4.2 (Decisions #25, #28)
  713-720    ## 10.2 `meal_ingredients`
  721-733    ## 10.3 `meal_nutrients`
  734-736    ## 10.4 `meal_allergens`
  737-746    ## 10.5 `meal_tags` — CHANGED in v4.2 (Decision #23)
  747-753    ## 10.6 `meal_translations` — CHANGED in v4.2 (Decision #28)
  754-761    ## 10.7 `meal_steps` — NEW in v4.19 (Decisions #161, #165)
  762-763    # 11. DOMAIN 3 — USER
  764-767    ## 11.1 `users`
  768-789    ## 11.2 `user_profiles` — CHANGED in v4.2 (Decisions #19, #20, #22, #27)
  790-794    ## 11.3 `user_health_conditions`
  795-797    ## 11.4 `user_allergen_prefs`
  798-800    ## 11.5 `user_ingredient_prefs`
  801-814    ## 11.6 `user_interactions` — CHANGED in v4.2 (Decision #28)
  815-821    ## 11.7 `meal_plans`
  822-832    ## 11.8 `meal_plan_items` — CHANGED in v4.2 (Decision #21)
  833-867    ## 11.9 `consumption_logs` — CHANGED in v4.2 (Decision #21) — single source of truth for what was eaten
  868-882    ## 11.10 `weight_logs` — NEW in v4.2 (Decision #19)
  883-899    ## 11.11 `user_targets` — NEW in v4.2 (Decision #22)
  900-914    ## 11.12 `refresh_tokens` — NEW in v4.5 (Decision #45)
  915-928    ## 11.13 `water_logs` — NEW in v4.6 (Decision #49)
  929-934    ## 11.14 `user_meal_prefs` — NEW in v4.19 (Decisions #149, #165)
  935-940    ## 11.15 `user_cuisine_prefs` — NEW in v4.19 (Decision #165)
  941-1000   # 12. Relationship Map
 1001-1023   # 13. Source Data and Future Dataset Management
 1024-1029   # 14. Data Provenance Is a First-Class Requirement
 1030-1031   # 15. Core Database Design Principles
 1032-1036   ## 15.1 Internal IDs vs external IDs
 1037-1051   ## 15.2 Numeric measurements must be numeric
 1052-1056   ## 15.3 Constraints protect the dataset
 1057-1061   ## 15.4 Normalize first, denormalize only deliberately
 1062-1066   ## 15.5 Multilingual support belongs in the data model
 1067-1069   ## 15.6 Do not encode business rules only in application code
 1070-1091   ## 15.7 Foreign Key delete/update policy
 1092-1094   ## 15.8 Meals use soft delete, never hard delete
 1095-1099   ## 15.9 Arabic-aware search — NEW in v4.2 (Decision #28)
 1100-1114   ## 15.10 Audit-column rule — NEW in v4.5 (Decision #42)
 1115-1120   # 16. PostgreSQL Decision
 1121-1157   # 17. SQLAlchemy / Alembic Structure
 1158-1174   # 18. What Must NOT Be Added Yet
 1175-1266   # 19. Schema Validation Strategy
 1267-1278   # 20. Initial Schema Implementation Workflow
 1279-1290   ## 20.1 Post-freeze change policy — NEW in v4.12 (Decision #73)
 1291-1300   # 21. Future Dataset Population Strategy
 1301-1314   # 22. Future Dataset Versioning
 1315-1322   # 23. Previous Project Lessons — What We Keep and What We Leave Behind
 1323-1324   # 24. Current Status
 1325-1355   ## Completed
 1356-1360   ## Current task
 1361-1385   # 25. Immediate Next Steps
 1386-1392   # 26. Working Method for the AI Assistant
 1393-1403   ### Important rules
 1404-1410   ### Continuous documentation rule (added 2026-09-28, user request)
 1411-1415   ### Step numbering rule
 1416-1445   # 27. Final Project Direction
 1446-1449   # 28. ML / Recommendation Architecture Direction — REWRITTEN in v4.2 (documented only, not implemented)
 1450-1462   ## 28.0 Honest classification
 1463-1473   ## 28.1 Layer 1 — hard-filtering rules
 1474-1481   ## 28.2 Multi-condition limit resolution (Decision #18)
 1482-1488   ## 28.3 Layer 2 — personalization details (direction)
 1489-1491   ## 28.4 Layer 3 — optimization details (direction; implemented as `cpsat_v1` in v4.18, see §28.4c)
 1492-1509   ## 28.4b Baseline planner `greedy_v1` — NEW in v4.15 (Decisions #80, #88)
 1510-1521   ## 28.4c Layer 3 optimizer `cpsat_v1` — NEW in v4.18 (Decisions #108–#122)
 1522-1527   ## 28.5 Evaluation plan (direction)
 1528-1532   ## 28.6 Explainable recommendations (Decision #46, P-11)
 1533-1534   # 29. Feature Scope & Roadmap
 1535-1547   ## Core Now (supported by the v4.2 schema)
 1548-1550   ## Core Important — the project's differentiator
 1551-1558   ## Near-Future Addition
 1559-1576   ## Documented Future Work (not designed, not scheduled)
 1577-1580   # 30. Nutrition Targets & Safety Rules — NEW in v4.2 (Decision #30) — application logic, `formula_version = targets_v1`
 1581-1597   ## 30.1 Screening (before any personalized plan)
 1598-1601   ## 30.2 Energy
 1602-1608   ## 30.3 Goal adjustment & safety
 1609-1616   ## 30.4 Macronutrients — details settled in v4.10 (Decisions #64–#67)
 1617-1623   ## 30.4b Fiber — NEW in v4.10 (Decision #68)
 1624-1630   ## 30.5 Daily adherence (computed, not stored)
 1631-1633   ## 30.6 Recompute triggers
 1634-1643   ## 30.7 Water goal & fluid safety — NEW in v4.6 (Decisions #49, #50)
 1644-1645   # 31. Meal Catalog Content Strategy — NEW in v4.2 (Decision #31) — Phase 2 direction
 1646-1648   ## 31.1 Diagnosis
 1649-1656   ## 31.2 Strategy: Curated Recipe Catalog
 1657-1663   ## 31.3 Quality gates
 1664-1666   ## 31.4 LLM-assisted drafting rules
 1667-1669   ## 31.5 Deferred sources
 1670-1677   ## 31.6 Excluded-ingredients policy — NEW in v4.3 (Decision #34)
 1678-1690   ## 31.7 Step G pipeline and catalog rules — NEW in v4.16 (Decisions #90–#100), results in v4.17 (#101–#107)
 1691-1712   # 32. Technology Additions — NEW in v4.2 (Decision #32)
 1713-1714   # 33. Offline-First Hybrid Architecture — NEW in v4.4 (Decision #37)
 1715-1717   ## 33.1 Clarification
 1718-1728   ## 33.2 Architecture
 1729-1743   ## 33.3 What works offline vs online
 1744-1757   ## 33.4 Sync rules (direction — implemented in the app phase, not Phase 1)
 1758-1762   ## 33.5 Why not fully local (no server)
 1763-1766   # 34. Engineering Standards — NEW in v4.5 (Decision #48; backlog P-01…P-11)
 1767-1769   ## 34.1 Configuration (P-06) — Step B
 1770-1774   ## 34.2 Authentication (P-05) — API phase *(later)*
 1775-1777   ## 34.3 API contract (P-07) — API phase *(later)*
 1778-1780   ## 34.4 Rate limiting (P-09) — API phase *(later)*
 1781-1783   ## 34.5 Observability (P-08) — API phase *(later)*
 1784-1786   ## 34.6 Code quality (P-10) — Step B/C
 1787-1792   ## 34.7 Testing & CI (P-02, P-03) — Step E
 1793-1795   ## 34.8 Schema-level standards (P-01, P-04)
 1796-1798   ## 34.9 Explainability (P-11)
```

## خريطة ⁨DEV_JOURNAL.md⁩

```text
    1-10     # DEV_JOURNAL — سجل التطوير والتوثيق النظري
   11-27     ## قالب كل إدخال
   28-70     ## فهرس الإدخالات حسب فصول التقرير
   71-72     ## الإدخالات
   73-81     ### J-001 — تشخيص المشكلة الجذرية: استراتيجية المحتوى
   82-93     ### J-002 — مصادر البيانات الغذائية وبناء كتالوج منتقى
   94-101    ### J-003 — القيود المرضية القابلة للتنفيذ وحل تعارضها
  102-108    ### J-004 — البيانات الزمنية: سجل الوزن والأهداف ذات الإصدارات
  109-115    ### J-005 — مصدر حقيقة واحد للاستهلاك والالتزام اليومي
  116-122    ### J-006 — الوسوم على مستوى المكوّن والبيانات المشتقة
  123-130    ### J-007 — الوزن بعد الطبخ ومنهجية حساب القيم الغذائية
  131-137    ### J-008 — العناصر الغذائية الإلزامية وقاعدة "المفقود ليس صفرًا"
  138-149    ### J-009 — حساب الاحتياج اليومي وقواعد الأمان
  150-168    ### J-010 — معمارية التوصية الهجينة وتصنيف صادق لتعلم الآلة
  169-177    ### J-011 — سياسة المكونات المستبعدة: صحة البيانات بالبناء
  178-190    ### J-012 — تدقيق FNDDS البرمجي وتصحيح افتراض سابق
  191-203    ### J-013 — الهوية الخارجية للمصادر ونطاق الاستيراد
  204-226    ### J-014 — معمارية Offline-First والمزامنة الـ Idempotent
  227-237    ### J-015 — البحث العربي المُطبَّع
  238-248    ### J-016 — سياسة التوثيق المستمر
  249-268    ### J-017 — اعتماد الميزات الاحترافية بعد تحليل التكامل (Change Impact Analysis)
  269-292    ### J-018 — حل التعارضات وتحويل الميزات إلى مواصفات ملزمة
  293-321    ### J-019 — تتبع الماء والتذكيرات: تغيير نطاق قبل التجميد مع قاعدة أمان للسوائل
  322-342    ### J-020 — الـ Chatbot: تأجيل مع تثبيت قيود التصميم
  343-356    ### J-021 — حذف النقرس من نطاق المشروع
  357-386    ### ⁨J-022⁩ — إغلاق الخطوة ⁨Step B⁩: بيئة ⁨PostgreSQL⁩ المحلية وبوابات جودة الكود
  387-405    ### ⁨J-023⁩ — مراجعة الاتساق قبل ⁨Step C⁩ وإصدار الوثيقة ⁨v4.8⁩
  406-425    ### ⁨J-024⁩ — إغلاق ⁨Step C⁩: نماذج ⁨SQLAlchemy⁩ للجداول الـ 34 وإصدار ⁨v4.9⁩
  426-450    ### ⁨J-025⁩ — إغلاق ⁨Step D⁩: أول ⁨Migration⁩ عبر ⁨Alembic⁩
  451-468    ### ⁨J-026⁩ — تفاصيل حساب الأهداف اليومية في ⁨§30⁩ وإصدار ⁨v4.10⁩
  469-495    ### ⁨J-027⁩ — إغلاق ⁨Step E⁩: اختبارات سلامة القاعدة والتكامل المستمر ⁨CI⁩ وإصدار ⁨v4.11⁩
  496-514    ### ⁨J-028⁩ — مراجعة ما قبل التجميد وإصدار ⁨v4.12⁩ (القرارات #70 إلى #73)
  515-535    ### ⁨J-029⁩ — إغلاق ⁨Step F⁩: تجميد المخطط عند ⁨schema-v1⁩ وإصدار ⁨v4.13⁩
  536-554    ### ⁨J-030⁩ — دراسة ⁨Hugging Face⁩ كمصدر للوصفات والقيم الغذائية، واعتماد خطة ⁨Step F.1⁩
  555-578    ### ⁨J-031⁩ — أول تغيير بعد التجميد: مكونات اختيارية، ونسخ الأطباق، ورموز ثابتة، وحقول الجودة، وإصدار ⁨v4.14⁩ (#74 إلى #79)
  579-615    ### ⁨J-032⁩ — إغلاق ⁨Step F.1⁩: الشريحة الرأسية من البيانات حتى التقدم، وخوارزمية الأساس ⁨greedy_v1⁩، وإصدار ⁨v4.15⁩ (#80 إلى #89)
  616-644    ### ⁨J-033⁩ — بدء ⁨Step G⁩: خطة هندسة البيانات، وفصل المخطط في ⁨Step G.0⁩، وإصدار ⁨v4.16⁩ (#90 إلى #100)
  645-678    ### ⁨J-034⁩ — إغلاق ⁨Step G⁩: الكتالوج الحقيقي الأول، وعزل المعيار، وتجميد ⁨catalog_v1⁩، وإصدار ⁨v4.17⁩ (#101 إلى #107)
  679-712    ### ⁨J-035⁩ — إغلاق ⁨Step H⁩: المُحسِّن ⁨cpsat_v1⁩ بمحرك ⁨CP-SAT⁩، والحدود الصحية العامة، وإصدار ⁨v4.18⁩ (#108 إلى #122)
  713-727    ### ⁨J-036⁩ — مرور المخطط الوحيد في ⁨Step I⁩: الاستيقاظ والنوم، والمفضلة، وخطوات التحضير، وإصدار ⁨v4.19⁩ (#141 إلى #166)
  728-744    ## قائمة الميزات الاحترافية المقترحة (Backlog — بانتظار الموافقة)
```
