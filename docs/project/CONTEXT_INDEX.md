# فهرس سياق المشروع (⁨CONTEXT_INDEX⁩)

اقرأ هذا الملف أولًا بدل قراءة ⁨PROJECT_CONTEXT_v4_18.md⁩ كاملًا (حوالي 34⁨k tokens⁩).
ثم اقرأ فقط الأقسام التي تحتاجها بأرقام الأسطر، مثلًا:

```bash
sed -n '344,363p' PROJECT_CONTEXT_v4_18.md
```

## الحالة الحالية (2026-10-12)

- مصدر الحقيقة: ⁨knowledge/claude/PROJECT_CONTEXT_v4_18.md⁩ (المخطط مجمّد عند ⁨schema-v1⁩ مع ⁨Migration⁩ 0003 و 0004، ونسخة البيانات مجمّدة عند ⁨catalog_v1⁩ بالعلامة ⁨dataset-v1⁩).
- آخر قرار: #122، وآخر قيد في ⁨DEV_JOURNAL⁩ هو ⁨J-035⁩.
- الخطوات ⁨B⁩ إلى ⁨H⁩ مغلقة، و ⁨CI⁩ أخضر. ⁨Step H⁩ أُغلقت في 2026-10-12: المُحسِّن ⁨cpsat_v1⁩ بمحرك ⁨CP-SAT⁩ هو المخطِّط الافتراضي، و ⁨greedy_v1⁩ خط الأساس الثابت. الـ ⁨commits⁩ هي ⁨18b6803⁩ و ⁨e9d72b7⁩ و ⁨5fa74f7⁩ (⁨H.2⁩) ثم الوثيقة ⁨8f67629⁩، و 1287 اختبارًا ناجحًا. الخطة وسجل التنفيذ في ⁨steps/STEP_H_plan.md⁩، والدليل في ⁨docs/reports/planner_comparison_report.md⁩.
- الخطوة التالية ⁨Step I⁩: مرحلة الـ ⁨API⁩، تُخطَّط مع المستخدم. دفعات وصفات إضافية من قائمة الأطباق (⁨steps/g2_data/dish_list_proposal.xlsx⁩) تُضاف بعد مراجعة الفريق، كل دفعة ملف جديد في ⁨backend/data/catalog/meals⁩.
- النسخ القديمة والخطوات المغلقة في ⁨archive⁩/ ولا تُقرأ إلا عند الحاجة لتاريخ قرار.

## خريطة أقسام ⁨PROJECT_CONTEXT_v4_18.md⁩

ملاحظة: أرقام الأسطر صالحة لنسخة ⁨v4.18⁩ فقط؛ أعد توليدها عند كل نسخة جديدة.

```text
    1-1      # PROJECT_CONTEXT.md — v4.18
    2-13     # Fresh-Start Data Architecture & PostgreSQL Rebuild — Nutrition / Meal Recommendation Project
   14-39     ## CHANGELOG — v4.17 → v4.18
   40-55     ## CHANGELOG — v4.16 → v4.17
   56-75     ## CHANGELOG — v4.15 → v4.16
   76-94     ## CHANGELOG — v4.14 → v4.15
   95-109    ## CHANGELOG — v4.13 → v4.14
  110-122    ## CHANGELOG — v4.12 → v4.13
  123-135    ## CHANGELOG — v4.11 → v4.12
  136-148    ## CHANGELOG — v4.10 → v4.11
  149-163    ## CHANGELOG — v4.9 → v4.10
  164-175    ## CHANGELOG — v4.8 → v4.9
  176-189    ## CHANGELOG — v4.7 → v4.8
  190-197    ## CHANGELOG — v4.6 → v4.7
  198-211    ## CHANGELOG — v4.5 → v4.6
  212-227    ## CHANGELOG — v4.4 → v4.5
  228-241    ## CHANGELOG — v4.3 → v4.4
  242-251    ## CHANGELOG — v4.2 → v4.3
  252-276    ## CHANGELOG — v4.1 → v4.2
  277-285    ## CHANGELOG — v4 → v4.1
  286-299    ## CHANGELOG — v3 → v4
  300-303    ## 1. Project Identity
  304-319    ### Current technology direction
  320-321    # 2. CRITICAL — Fresh Rebuild, Not a Rewrite of the Old Project
  322-331    ### Do NOT
  332-339    ### What may be reused conceptually
  340-344    ### Core principle
  345-356    # 3. The Main Problem We Are Solving Now
  357-358    # 4. Dataset Architecture vs Database Architecture
  359-363    ## 4.1 Database architecture — NOW
  364-377    ## 4.2 Dataset population — LATER
  378-385    # 5. Why the FNDDS Investigation Still Matters
  386-387    # 6. FNDDS Audit Findings That Influence the New Architecture
  388-393    ## 6.1 Ingredient structure
  394-402    ## 6.2 Nutrition structure — CORRECTED in v4.4 (Decision #40)
  403-422    ## 6.3 Compatibility audit of all five FNDDS files — NEW in v4.4
  423-432    ## 6.4 How FNDDS is used (Decision #38)
  433-434    # 7. Current Objective — Database First, Data Later
  435-439    ## PHASE 1 — DATABASE ARCHITECTURE (CURRENT)
  440-452    ## PHASE 2 — DATASET BUILDING AND POPULATION (LATER)
  453-472    # 8. Authoritative Architecture
  473-474    # 9. DOMAIN 1 — REFERENCE
  475-482    ## 9.1 `categories`
  483-486    ## 9.2 `cuisines`
  487-490    ## 9.3 `allergens`
  491-502    ## 9.4 `dietary_tags` — CHANGED in v4.2 (Decision #24)
  503-509    ### 9.4b Meal Occasion / Time-Suitability Tags (v4.1 Decision #16, refined in v4.2)
  510-519    ## 9.5 `health_conditions` — CHANGED in v4.2 (Decision #27)
  520-543    ## 9.5b `condition_nutrient_limits` — CHANGED in v4.2 (Decision #18)
  544-556    ## 9.5c `condition_tag_restrictions`
  557-568    ## 9.6 `foods`
  569-593    ## 9.7 `nutrients` — CHANGED in v4.2 (Decision #26)
  594-602    ## 9.8 `food_nutrients`
  603-606    ## 9.9 `portions_food`
  607-614    ## 9.10 `ingredients`
  615-620    ## 9.11 `ingredient_aliases` — CHANGED in v4.2 (Decision #28)
  621-624    ## 9.12 `ingredient_allergens`
  625-634    ## 9.13 `ingredient_tags` — NEW in v4.2 (Decision #23)
  635-636    # 10. DOMAIN 2 — CATALOG
  637-662    ## 10.1 `meals` — CHANGED in v4.2 (Decisions #25, #28)
  663-670    ## 10.2 `meal_ingredients`
  671-683    ## 10.3 `meal_nutrients`
  684-686    ## 10.4 `meal_allergens`
  687-696    ## 10.5 `meal_tags` — CHANGED in v4.2 (Decision #23)
  697-705    ## 10.6 `meal_translations` — CHANGED in v4.2 (Decision #28)
  706-707    # 11. DOMAIN 3 — USER
  708-711    ## 11.1 `users`
  712-732    ## 11.2 `user_profiles` — CHANGED in v4.2 (Decisions #19, #20, #22, #27)
  733-737    ## 11.3 `user_health_conditions`
  738-740    ## 11.4 `user_allergen_prefs`
  741-743    ## 11.5 `user_ingredient_prefs`
  744-755    ## 11.6 `user_interactions` — CHANGED in v4.2 (Decision #28)
  756-762    ## 11.7 `meal_plans`
  763-773    ## 11.8 `meal_plan_items` — CHANGED in v4.2 (Decision #21)
  774-806    ## 11.9 `consumption_logs` — CHANGED in v4.2 (Decision #21) — single source of truth for what was eaten
  807-821    ## 11.10 `weight_logs` — NEW in v4.2 (Decision #19)
  822-838    ## 11.11 `user_targets` — NEW in v4.2 (Decision #22)
  839-853    ## 11.12 `refresh_tokens` — NEW in v4.5 (Decision #45)
  854-869    ## 11.13 `water_logs` — NEW in v4.6 (Decision #49)
  870-926    # 12. Relationship Map
  927-949    # 13. Source Data and Future Dataset Management
  950-955    # 14. Data Provenance Is a First-Class Requirement
  956-957    # 15. Core Database Design Principles
  958-962    ## 15.1 Internal IDs vs external IDs
  963-977    ## 15.2 Numeric measurements must be numeric
  978-982    ## 15.3 Constraints protect the dataset
  983-987    ## 15.4 Normalize first, denormalize only deliberately
  988-992    ## 15.5 Multilingual support belongs in the data model
  993-995    ## 15.6 Do not encode business rules only in application code
  996-1017   ## 15.7 Foreign Key delete/update policy
 1018-1020   ## 15.8 Meals use soft delete, never hard delete
 1021-1025   ## 15.9 Arabic-aware search — NEW in v4.2 (Decision #28)
 1026-1040   ## 15.10 Audit-column rule — NEW in v4.5 (Decision #42)
 1041-1046   # 16. PostgreSQL Decision
 1047-1083   # 17. SQLAlchemy / Alembic Structure
 1084-1100   # 18. What Must NOT Be Added Yet
 1101-1192   # 19. Schema Validation Strategy
 1193-1204   # 20. Initial Schema Implementation Workflow
 1205-1215   ## 20.1 Post-freeze change policy — NEW in v4.12 (Decision #73)
 1216-1225   # 21. Future Dataset Population Strategy
 1226-1239   # 22. Future Dataset Versioning
 1240-1247   # 23. Previous Project Lessons — What We Keep and What We Leave Behind
 1248-1249   # 24. Current Status
 1250-1280   ## Completed
 1281-1285   ## Current task
 1286-1310   # 25. Immediate Next Steps
 1311-1317   # 26. Working Method for the AI Assistant
 1318-1328   ### Important rules
 1329-1335   ### Continuous documentation rule (added 2026-09-28, user request)
 1336-1340   ### Step numbering rule
 1341-1370   # 27. Final Project Direction
 1371-1374   # 28. ML / Recommendation Architecture Direction — REWRITTEN in v4.2 (documented only, not implemented)
 1375-1387   ## 28.0 Honest classification
 1388-1398   ## 28.1 Layer 1 — hard-filtering rules
 1399-1406   ## 28.2 Multi-condition limit resolution (Decision #18)
 1407-1413   ## 28.3 Layer 2 — personalization details (direction)
 1414-1416   ## 28.4 Layer 3 — optimization details (direction; implemented as `cpsat_v1` in v4.18, see §28.4c)
 1417-1434   ## 28.4b Baseline planner `greedy_v1` — NEW in v4.15 (Decisions #80, #88)
 1435-1446   ## 28.4c Layer 3 optimizer `cpsat_v1` — NEW in v4.18 (Decisions #108–#122)
 1447-1452   ## 28.5 Evaluation plan (direction)
 1453-1457   ## 28.6 Explainable recommendations (Decision #46, P-11)
 1458-1459   # 29. Feature Scope & Roadmap
 1460-1472   ## Core Now (supported by the v4.2 schema)
 1473-1475   ## Core Important — the project's differentiator
 1476-1483   ## Near-Future Addition
 1484-1501   ## Documented Future Work (not designed, not scheduled)
 1502-1505   # 30. Nutrition Targets & Safety Rules — NEW in v4.2 (Decision #30) — application logic, `formula_version = targets_v1`
 1506-1522   ## 30.1 Screening (before any personalized plan)
 1523-1526   ## 30.2 Energy
 1527-1533   ## 30.3 Goal adjustment & safety
 1534-1541   ## 30.4 Macronutrients — details settled in v4.10 (Decisions #64–#67)
 1542-1548   ## 30.4b Fiber — NEW in v4.10 (Decision #68)
 1549-1555   ## 30.5 Daily adherence (computed, not stored)
 1556-1558   ## 30.6 Recompute triggers
 1559-1568   ## 30.7 Water goal & fluid safety — NEW in v4.6 (Decisions #49, #50)
 1569-1570   # 31. Meal Catalog Content Strategy — NEW in v4.2 (Decision #31) — Phase 2 direction
 1571-1573   ## 31.1 Diagnosis
 1574-1581   ## 31.2 Strategy: Curated Recipe Catalog
 1582-1588   ## 31.3 Quality gates
 1589-1591   ## 31.4 LLM-assisted drafting rules
 1592-1594   ## 31.5 Deferred sources
 1595-1602   ## 31.6 Excluded-ingredients policy — NEW in v4.3 (Decision #34)
 1603-1615   ## 31.7 Step G pipeline and catalog rules — NEW in v4.16 (Decisions #90–#100), results in v4.17 (#101–#107)
 1616-1637   # 32. Technology Additions — NEW in v4.2 (Decision #32)
 1638-1639   # 33. Offline-First Hybrid Architecture — NEW in v4.4 (Decision #37)
 1640-1642   ## 33.1 Clarification
 1643-1653   ## 33.2 Architecture
 1654-1668   ## 33.3 What works offline vs online
 1669-1682   ## 33.4 Sync rules (direction — implemented in the app phase, not Phase 1)
 1683-1687   ## 33.5 Why not fully local (no server)
 1688-1691   # 34. Engineering Standards — NEW in v4.5 (Decision #48; backlog P-01…P-11)
 1692-1694   ## 34.1 Configuration (P-06) — Step B
 1695-1699   ## 34.2 Authentication (P-05) — API phase *(later)*
 1700-1702   ## 34.3 API contract (P-07) — API phase *(later)*
 1703-1705   ## 34.4 Rate limiting (P-09) — API phase *(later)*
 1706-1708   ## 34.5 Observability (P-08) — API phase *(later)*
 1709-1711   ## 34.6 Code quality (P-10) — Step B/C
 1712-1717   ## 34.7 Testing & CI (P-02, P-03) — Step E
 1718-1720   ## 34.8 Schema-level standards (P-01, P-04)
 1721-1724   ## 34.9 Explainability (P-11)
```

## خريطة ⁨DEV_JOURNAL.md⁩

```text
    1-10     # DEV_JOURNAL — سجل التطوير والتوثيق النظري
   11-27     ## قالب كل إدخال
   28-69     ## فهرس الإدخالات حسب فصول التقرير
   70-71     ## الإدخالات
  514-534    ### ⁨J-029⁩ — إغلاق ⁨Step F⁩: تجميد المخطط عند ⁨schema-v1⁩ وإصدار ⁨v4.13⁩
  535-553    ### ⁨J-030⁩ — دراسة ⁨Hugging Face⁩ كمصدر للوصفات والقيم الغذائية، واعتماد خطة ⁨Step F.1⁩
  554-577    ### ⁨J-031⁩ — أول تغيير بعد التجميد: مكونات اختيارية، ونسخ الأطباق، ورموز ثابتة، وحقول الجودة، وإصدار ⁨v4.14⁩ (#74 إلى #79)
  578-614    ### ⁨J-032⁩ — إغلاق ⁨Step F.1⁩: الشريحة الرأسية من البيانات حتى التقدم، وخوارزمية الأساس ⁨greedy_v1⁩، وإصدار ⁨v4.15⁩ (#80 إلى #89)
  615-643    ### ⁨J-033⁩ — بدء ⁨Step G⁩: خطة هندسة البيانات، وفصل المخطط في ⁨Step G.0⁩، وإصدار ⁨v4.16⁩ (#90 إلى #100)
  644-677    ### ⁨J-034⁩ — إغلاق ⁨Step G⁩: الكتالوج الحقيقي الأول، وعزل المعيار، وتجميد ⁨catalog_v1⁩، وإصدار ⁨v4.17⁩ (#101 إلى #107)
  678-713    ### ⁨J-035⁩ — إغلاق ⁨Step H⁩: المُحسِّن ⁨cpsat_v1⁩ بمحرك ⁨CP-SAT⁩، والحدود الصحية العامة، وإصدار ⁨v4.18⁩ (#108 إلى #122)
  714-731    ## قائمة الميزات الاحترافية المقترحة (Backlog — بانتظار الموافقة)
```
