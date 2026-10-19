# فهرس سياق المشروع (⁨CONTEXT_INDEX⁩)

اقرأ هذا الملف أولًا بدل قراءة ⁨PROJECT_CONTEXT_v4_20.md⁩ كاملًا (حوالي 34⁨k tokens⁩).
ثم اقرأ فقط الأقسام التي تحتاجها بأرقام الأسطر، مثلًا:

```bash
sed -n '344,363p' PROJECT_CONTEXT_v4_20.md
```

## الحالة الحالية (2026-10-19)

- مصدر الحقيقة: ⁨knowledge/claude/PROJECT_CONTEXT_v4_20.md⁩. المخطط ⁨schema-v1⁩ مع ملفات ⁨migration⁩ حتى 0005، والمرور ⁨I.0d⁩ يضيف 0006 لحذف الحالات الملغاة (القرار #167). البيانات مجمّدة عند ⁨catalog_v3⁩ بالعلامة ⁨dataset-v3⁩ (158 وجبة نشطة، و 477 خطوة تحضير على 121 وجبة).
- آخر قرار: #167، وآخر قيد في ⁨DEV_JOURNAL⁩ هو ⁨J-037⁩.
- النطاق الصحي نهائي: السكري من النوع الثاني والضغط والقلب فقط. الكلى والحمل والرضاعة والنقرس ملغاة نهائيًا، والإنسولين يدخل الوضع العام.
- الخطوات ⁨B⁩ إلى ⁨H⁩ مغلقة. ⁨Step I⁩ (الـ ⁨API⁩) جارية: ⁨I.0⁩ و ⁨I.0b⁩ و ⁨I.0c⁩ مغلقة، ثم ⁨I.0d⁩ لحذف الحالات، ثم عقد ⁨I.1⁩. الخطة في ⁨steps/STEP_I_plan.md⁩.
- مسار بناء العضلات مؤجل بطلب المستخدم، والواجهات متوقفة مؤقتًا.
- النسخ القديمة والخطوات المغلقة في ⁨archive⁩/ ولا تُقرأ إلا عند الحاجة لتاريخ قرار.

## خريطة أقسام ⁨PROJECT_CONTEXT_v4_20.md⁩

ملاحظة: أرقام الأسطر صالحة لنسخة ⁨v4.20⁩ فقط؛ أعد توليدها عند كل نسخة جديدة.

```text
    1-1      # PROJECT_CONTEXT.md — v4.20
    2-13     # Fresh-Start Data Architecture & PostgreSQL Rebuild — Nutrition / Meal Recommendation Project
   14-23     ## CHANGELOG — v4.19 → v4.20
   24-71     ## CHANGELOG — v4.18 → v4.19
   72-97     ## CHANGELOG — v4.17 → v4.18
   98-113    ## CHANGELOG — v4.16 → v4.17
  114-133    ## CHANGELOG — v4.15 → v4.16
  134-152    ## CHANGELOG — v4.14 → v4.15
  153-167    ## CHANGELOG — v4.13 → v4.14
  168-180    ## CHANGELOG — v4.12 → v4.13
  181-193    ## CHANGELOG — v4.11 → v4.12
  194-206    ## CHANGELOG — v4.10 → v4.11
  207-221    ## CHANGELOG — v4.9 → v4.10
  222-233    ## CHANGELOG — v4.8 → v4.9
  234-247    ## CHANGELOG — v4.7 → v4.8
  248-255    ## CHANGELOG — v4.6 → v4.7
  256-269    ## CHANGELOG — v4.5 → v4.6
  270-285    ## CHANGELOG — v4.4 → v4.5
  286-299    ## CHANGELOG — v4.3 → v4.4
  300-309    ## CHANGELOG — v4.2 → v4.3
  310-334    ## CHANGELOG — v4.1 → v4.2
  335-343    ## CHANGELOG — v4 → v4.1
  344-357    ## CHANGELOG — v3 → v4
  358-361    ## 1. Project Identity
  362-377    ### Current technology direction
  378-379    # 2. CRITICAL — Fresh Rebuild, Not a Rewrite of the Old Project
  380-389    ### Do NOT
  390-397    ### What may be reused conceptually
  398-402    ### Core principle
  403-414    # 3. The Main Problem We Are Solving Now
  415-416    # 4. Dataset Architecture vs Database Architecture
  417-421    ## 4.1 Database architecture — NOW
  422-435    ## 4.2 Dataset population — LATER
  436-443    # 5. Why the FNDDS Investigation Still Matters
  444-445    # 6. FNDDS Audit Findings That Influence the New Architecture
  446-451    ## 6.1 Ingredient structure
  452-460    ## 6.2 Nutrition structure — CORRECTED in v4.4 (Decision #40)
  461-480    ## 6.3 Compatibility audit of all five FNDDS files — NEW in v4.4
  481-490    ## 6.4 How FNDDS is used (Decision #38)
  491-492    # 7. Current Objective — Database First, Data Later
  493-497    ## PHASE 1 — DATABASE ARCHITECTURE (CURRENT)
  498-510    ## PHASE 2 — DATASET BUILDING AND POPULATION (LATER)
  511-530    # 8. Authoritative Architecture
  531-532    # 9. DOMAIN 1 — REFERENCE
  533-540    ## 9.1 `categories`
  541-544    ## 9.2 `cuisines`
  545-548    ## 9.3 `allergens`
  549-560    ## 9.4 `dietary_tags` — CHANGED in v4.2 (Decision #24)
  561-567    ### 9.4b Meal Occasion / Time-Suitability Tags (v4.1 Decision #16, refined in v4.2)
  568-577    ## 9.5 `health_conditions` — CHANGED in v4.2 (Decision #27)
  578-601    ## 9.5b `condition_nutrient_limits` — CHANGED in v4.2 (Decision #18)
  602-614    ## 9.5c `condition_tag_restrictions`
  615-626    ## 9.6 `foods`
  627-651    ## 9.7 `nutrients` — CHANGED in v4.2 (Decision #26)
  652-660    ## 9.8 `food_nutrients`
  661-664    ## 9.9 `portions_food`
  665-672    ## 9.10 `ingredients`
  673-678    ## 9.11 `ingredient_aliases` — CHANGED in v4.2 (Decision #28)
  679-682    ## 9.12 `ingredient_allergens`
  683-692    ## 9.13 `ingredient_tags` — NEW in v4.2 (Decision #23)
  693-694    # 10. DOMAIN 2 — CATALOG
  695-722    ## 10.1 `meals` — CHANGED in v4.2 (Decisions #25, #28)
  723-730    ## 10.2 `meal_ingredients`
  731-743    ## 10.3 `meal_nutrients`
  744-746    ## 10.4 `meal_allergens`
  747-756    ## 10.5 `meal_tags` — CHANGED in v4.2 (Decision #23)
  757-763    ## 10.6 `meal_translations` — CHANGED in v4.2 (Decision #28)
  764-771    ## 10.7 `meal_steps` — NEW in v4.19 (Decisions #161, #165)
  772-773    # 11. DOMAIN 3 — USER
  774-777    ## 11.1 `users`
  778-798    ## 11.2 `user_profiles` — CHANGED in v4.2 (Decisions #19, #20, #22, #27)
  799-803    ## 11.3 `user_health_conditions`
  804-806    ## 11.4 `user_allergen_prefs`
  807-809    ## 11.5 `user_ingredient_prefs`
  810-823    ## 11.6 `user_interactions` — CHANGED in v4.2 (Decision #28)
  824-830    ## 11.7 `meal_plans`
  831-841    ## 11.8 `meal_plan_items` — CHANGED in v4.2 (Decision #21)
  842-876    ## 11.9 `consumption_logs` — CHANGED in v4.2 (Decision #21) — single source of truth for what was eaten
  877-891    ## 11.10 `weight_logs` — NEW in v4.2 (Decision #19)
  892-908    ## 11.11 `user_targets` — NEW in v4.2 (Decision #22)
  909-923    ## 11.12 `refresh_tokens` — NEW in v4.5 (Decision #45)
  924-937    ## 11.13 `water_logs` — NEW in v4.6 (Decision #49)
  938-943    ## 11.14 `user_meal_prefs` — NEW in v4.19 (Decisions #149, #165)
  944-949    ## 11.15 `user_cuisine_prefs` — NEW in v4.19 (Decision #165)
  950-1009   # 12. Relationship Map
 1010-1032   # 13. Source Data and Future Dataset Management
 1033-1038   # 14. Data Provenance Is a First-Class Requirement
 1039-1040   # 15. Core Database Design Principles
 1041-1045   ## 15.1 Internal IDs vs external IDs
 1046-1060   ## 15.2 Numeric measurements must be numeric
 1061-1065   ## 15.3 Constraints protect the dataset
 1066-1070   ## 15.4 Normalize first, denormalize only deliberately
 1071-1075   ## 15.5 Multilingual support belongs in the data model
 1076-1078   ## 15.6 Do not encode business rules only in application code
 1079-1100   ## 15.7 Foreign Key delete/update policy
 1101-1103   ## 15.8 Meals use soft delete, never hard delete
 1104-1108   ## 15.9 Arabic-aware search — NEW in v4.2 (Decision #28)
 1109-1123   ## 15.10 Audit-column rule — NEW in v4.5 (Decision #42)
 1124-1129   # 16. PostgreSQL Decision
 1130-1166   # 17. SQLAlchemy / Alembic Structure
 1167-1183   # 18. What Must NOT Be Added Yet
 1184-1274   # 19. Schema Validation Strategy
 1275-1286   # 20. Initial Schema Implementation Workflow
 1287-1299   ## 20.1 Post-freeze change policy — NEW in v4.12 (Decision #73)
 1300-1309   # 21. Future Dataset Population Strategy
 1310-1323   # 22. Future Dataset Versioning
 1324-1331   # 23. Previous Project Lessons — What We Keep and What We Leave Behind
 1332-1333   # 24. Current Status
 1334-1364   ## Completed
 1365-1369   ## Current task
 1370-1394   # 25. Immediate Next Steps
 1395-1401   # 26. Working Method for the AI Assistant
 1402-1412   ### Important rules
 1413-1419   ### Continuous documentation rule (added 2026-09-28, user request)
 1420-1424   ### Step numbering rule
 1425-1454   # 27. Final Project Direction
 1455-1458   # 28. ML / Recommendation Architecture Direction — REWRITTEN in v4.2 (documented only, not implemented)
 1459-1471   ## 28.0 Honest classification
 1472-1482   ## 28.1 Layer 1 — hard-filtering rules
 1483-1490   ## 28.2 Multi-condition limit resolution (Decision #18)
 1491-1497   ## 28.3 Layer 2 — personalization details (direction)
 1498-1500   ## 28.4 Layer 3 — optimization details (direction; implemented as `cpsat_v1` in v4.18, see §28.4c)
 1501-1518   ## 28.4b Baseline planner `greedy_v1` — NEW in v4.15 (Decisions #80, #88)
 1519-1530   ## 28.4c Layer 3 optimizer `cpsat_v1` — NEW in v4.18 (Decisions #108–#122)
 1531-1536   ## 28.5 Evaluation plan (direction)
 1537-1541   ## 28.6 Explainable recommendations (Decision #46, P-11)
 1542-1543   # 29. Feature Scope & Roadmap
 1544-1556   ## Core Now (supported by the v4.2 schema)
 1557-1559   ## Core Important — the project's differentiator
 1560-1567   ## Near-Future Addition
 1568-1585   ## Documented Future Work (not designed, not scheduled)
 1586-1589   # 30. Nutrition Targets & Safety Rules — NEW in v4.2 (Decision #30) — application logic, `formula_version = targets_v1`
 1590-1605   ## 30.1 Screening (before any personalized plan)
 1606-1609   ## 30.2 Energy
 1610-1616   ## 30.3 Goal adjustment & safety
 1617-1624   ## 30.4 Macronutrients — details settled in v4.10 (Decisions #64–#67)
 1625-1631   ## 30.4b Fiber — NEW in v4.10 (Decision #68)
 1632-1638   ## 30.5 Daily adherence (computed, not stored)
 1639-1641   ## 30.6 Recompute triggers
 1642-1651   ## 30.7 Water goal & fluid safety — NEW in v4.6 (Decisions #49, #50)
 1652-1653   # 31. Meal Catalog Content Strategy — NEW in v4.2 (Decision #31) — Phase 2 direction
 1654-1656   ## 31.1 Diagnosis
 1657-1664   ## 31.2 Strategy: Curated Recipe Catalog
 1665-1671   ## 31.3 Quality gates
 1672-1674   ## 31.4 LLM-assisted drafting rules
 1675-1677   ## 31.5 Deferred sources
 1678-1685   ## 31.6 Excluded-ingredients policy — NEW in v4.3 (Decision #34)
 1686-1698   ## 31.7 Step G pipeline and catalog rules — NEW in v4.16 (Decisions #90–#100), results in v4.17 (#101–#107)
 1699-1720   # 32. Technology Additions — NEW in v4.2 (Decision #32)
 1721-1722   # 33. Offline-First Hybrid Architecture — NEW in v4.4 (Decision #37)
 1723-1725   ## 33.1 Clarification
 1726-1736   ## 33.2 Architecture
 1737-1751   ## 33.3 What works offline vs online
 1752-1765   ## 33.4 Sync rules (direction — implemented in the app phase, not Phase 1)
 1766-1770   ## 33.5 Why not fully local (no server)
 1771-1774   # 34. Engineering Standards — NEW in v4.5 (Decision #48; backlog P-01…P-11)
 1775-1777   ## 34.1 Configuration (P-06) — Step B
 1778-1782   ## 34.2 Authentication (P-05) — API phase *(later)*
 1783-1785   ## 34.3 API contract (P-07) — API phase *(later)*
 1786-1788   ## 34.4 Rate limiting (P-09) — API phase *(later)*
 1789-1791   ## 34.5 Observability (P-08) — API phase *(later)*
 1792-1794   ## 34.6 Code quality (P-10) — Step B/C
 1795-1800   ## 34.7 Testing & CI (P-02, P-03) — Step E
 1801-1803   ## 34.8 Schema-level standards (P-01, P-04)
 1804-1806   ## 34.9 Explainability (P-11)
```

## خريطة ⁨DEV_JOURNAL.md⁩

```text
    1-10     # DEV_JOURNAL — سجل التطوير والتوثيق النظري
   11-27     ## قالب كل إدخال
   28-71     ## فهرس الإدخالات حسب فصول التقرير
   72-73     ## الإدخالات
   74-82     ### J-001 — تشخيص المشكلة الجذرية: استراتيجية المحتوى
   83-94     ### J-002 — مصادر البيانات الغذائية وبناء كتالوج منتقى
   95-102    ### J-003 — القيود المرضية القابلة للتنفيذ وحل تعارضها
  103-109    ### J-004 — البيانات الزمنية: سجل الوزن والأهداف ذات الإصدارات
  110-116    ### J-005 — مصدر حقيقة واحد للاستهلاك والالتزام اليومي
  117-123    ### J-006 — الوسوم على مستوى المكوّن والبيانات المشتقة
  124-131    ### J-007 — الوزن بعد الطبخ ومنهجية حساب القيم الغذائية
  132-138    ### J-008 — العناصر الغذائية الإلزامية وقاعدة "المفقود ليس صفرًا"
  139-150    ### J-009 — حساب الاحتياج اليومي وقواعد الأمان
  151-169    ### J-010 — معمارية التوصية الهجينة وتصنيف صادق لتعلم الآلة
  170-178    ### J-011 — سياسة المكونات المستبعدة: صحة البيانات بالبناء
  179-191    ### J-012 — تدقيق FNDDS البرمجي وتصحيح افتراض سابق
  192-204    ### J-013 — الهوية الخارجية للمصادر ونطاق الاستيراد
  205-227    ### J-014 — معمارية Offline-First والمزامنة الـ Idempotent
  228-238    ### J-015 — البحث العربي المُطبَّع
  239-249    ### J-016 — سياسة التوثيق المستمر
  250-269    ### J-017 — اعتماد الميزات الاحترافية بعد تحليل التكامل (Change Impact Analysis)
  270-293    ### J-018 — حل التعارضات وتحويل الميزات إلى مواصفات ملزمة
  294-322    ### J-019 — تتبع الماء والتذكيرات: تغيير نطاق قبل التجميد مع قاعدة أمان للسوائل
  323-343    ### J-020 — الـ Chatbot: تأجيل مع تثبيت قيود التصميم
  344-357    ### J-021 — حذف النقرس من نطاق المشروع
  358-387    ### ⁨J-022⁩ — إغلاق الخطوة ⁨Step B⁩: بيئة ⁨PostgreSQL⁩ المحلية وبوابات جودة الكود
  388-406    ### ⁨J-023⁩ — مراجعة الاتساق قبل ⁨Step C⁩ وإصدار الوثيقة ⁨v4.8⁩
  407-426    ### ⁨J-024⁩ — إغلاق ⁨Step C⁩: نماذج ⁨SQLAlchemy⁩ للجداول الـ 34 وإصدار ⁨v4.9⁩
  427-451    ### ⁨J-025⁩ — إغلاق ⁨Step D⁩: أول ⁨Migration⁩ عبر ⁨Alembic⁩
  452-469    ### ⁨J-026⁩ — تفاصيل حساب الأهداف اليومية في ⁨§30⁩ وإصدار ⁨v4.10⁩
  470-496    ### ⁨J-027⁩ — إغلاق ⁨Step E⁩: اختبارات سلامة القاعدة والتكامل المستمر ⁨CI⁩ وإصدار ⁨v4.11⁩
  497-515    ### ⁨J-028⁩ — مراجعة ما قبل التجميد وإصدار ⁨v4.12⁩ (القرارات #70 إلى #73)
  516-536    ### ⁨J-029⁩ — إغلاق ⁨Step F⁩: تجميد المخطط عند ⁨schema-v1⁩ وإصدار ⁨v4.13⁩
  537-555    ### ⁨J-030⁩ — دراسة ⁨Hugging Face⁩ كمصدر للوصفات والقيم الغذائية، واعتماد خطة ⁨Step F.1⁩
  556-579    ### ⁨J-031⁩ — أول تغيير بعد التجميد: مكونات اختيارية، ونسخ الأطباق، ورموز ثابتة، وحقول الجودة، وإصدار ⁨v4.14⁩ (#74 إلى #79)
  580-616    ### ⁨J-032⁩ — إغلاق ⁨Step F.1⁩: الشريحة الرأسية من البيانات حتى التقدم، وخوارزمية الأساس ⁨greedy_v1⁩، وإصدار ⁨v4.15⁩ (#80 إلى #89)
  617-645    ### ⁨J-033⁩ — بدء ⁨Step G⁩: خطة هندسة البيانات، وفصل المخطط في ⁨Step G.0⁩، وإصدار ⁨v4.16⁩ (#90 إلى #100)
  646-679    ### ⁨J-034⁩ — إغلاق ⁨Step G⁩: الكتالوج الحقيقي الأول، وعزل المعيار، وتجميد ⁨catalog_v1⁩، وإصدار ⁨v4.17⁩ (#101 إلى #107)
  680-713    ### ⁨J-035⁩ — إغلاق ⁨Step H⁩: المُحسِّن ⁨cpsat_v1⁩ بمحرك ⁨CP-SAT⁩، والحدود الصحية العامة، وإصدار ⁨v4.18⁩ (#108 إلى #122)
  714-728    ### ⁨J-036⁩ — مرور المخطط الوحيد في ⁨Step I⁩: الاستيقاظ والنوم، والمفضلة، وخطوات التحضير، وإصدار ⁨v4.19⁩ (#141 إلى #166)
  729-744    ### ⁨J-037⁩ — إلغاء الكلى والحمل والرضاعة والنقرس نهائيًا، وإصدار ⁨v4.20⁩ (#167)
  745-761    ## قائمة الميزات الاحترافية المقترحة (Backlog — بانتظار الموافقة)
```
