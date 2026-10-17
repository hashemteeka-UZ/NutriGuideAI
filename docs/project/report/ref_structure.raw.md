# بنية مشروع التخرج المرجعي (Text-to-SQL Agent)

المصدر: مشروع تخرج "Designing an Arabic Multi-Agent Text-to-SQL System for Relational Databases" (جامعة مصراتة، كلية تقنية المعلومات، علوم الحاسوب، ربيع 2026، 90 صفحة، مكتوب بالإنجليزية). استُخرجت البنية من الفهرس ومن نص الملف. المرجع للهيكل فقط وليس للمحتوى.

## الصفحات التمهيدية (ترقيم روماني)

| الصفحة | المحتوى |
|---|---|
| غلاف (بدون رقم) | شعار، Misurata University / Faculty of Information Technology / Computer Science، عنوان المشروع، عبارة التقديم لدرجة البكالوريوس، BY + الطالبان، SUPERVISOR، Misurata, Libya + الفصل والسنة |
| I | الآية القرآنية |
| II | Abstract (فقرتان: المشكلة وحدودها، ثم الحل والنتائج بالأرقام) |
| III | الملخص بالعربية |
| IV | الإهداء |
| V | الشكر والتقدير |
| VI | Table of Contents (فصول وأقسام حتى المستوى الثالث 2.2.1) |
| X | List of Figures |
| XI | List of Tables |
| XII | List of Abbreviations (جدول من عمودين: Abbreviation, Full Form) |

ملاحظة: المرجع لا يحتوي صفحة اعتماد القسم ولا قائمة رموز، مع أن دليل الكلية يذكر الاعتماد. نتبع الدليل ونضيف صفحة الاعتماد.

## المتن (ترقيم عادي من 1)

| الفصل | الصفحات | الأقسام |
|---|---|---|
| 1 Introduction | 1 إلى 7 | 1.1 Introduction، 1.2 Problem Statement، 1.3 Study Objectives، 1.4 Study Scope، 1.5 Time Table (جدول Gantt)، 1.6 Study Structure |
| 2 Literature Review | 8 إلى 25 | 2.1 تعريف وأهمية المجال (2.1.1، 2.1.2)، 2.2 Historical Background (طرق تقليدية، ثم LLM، ثم متعددة المراحل)، 2.3 Challenges (أربعة تحديات)، 2.4 Related Works (أربع فئات)، 2.5 Research Gap (خمس فجوات)، 2.6 Summary |
| 3 Methodology | 26 إلى 55 | 3.1 Introduction، 3.2 Development Environment and Tools، 3.3 Database Schema Preparation (4 أقسام)، 3.4 System Architecture Design (4 أقسام)، 3.5 Multi-Stage Workflow Implementation (4 مراحل)، 3.6 Security and Reliability Framework، 3.7 Summary |
| 4 Results and Analysis | 56 إلى 70 | 4.1 Experimental Setup، 4.2 Pipeline Evaluation (لكل مرحلة قسم)، 4.3 Performance and Latency Analysis، 4.4 Security and Guardrail Evaluation، 4.5 Discussion and Limitations، 4.6 Summary |
| 5 Conclusion and Recommendations | 71 إلى 74 | 5.1 Introduction، 5.2 Key Project Contributions، 5.3 Recommendations for Future Development (3 اتجاهات)، 5.4 Conclusion |
| References | A إلى C | 22 مرجعًا بأسلوب IEEE مرقمة بحسب ورودها [1] إلى [22] |

لا توجد ملاحق في هذا المشروع.

## الأعراف التي يتبعها المرجع

- كل فصل يبدأ بصفحة جديدة، ويبدأ بقسم Introduction يعرّف بمحتوى الفصل، وينتهي بقسم Summary.
- الفصل 1 يختم بـ Study Structure يشرح محتوى كل فصل في فقرة.
- ترقيم الأقسام عشري حتى ثلاثة مستويات (مثل 3.3.2).
- الأشكال والجداول مرقمة بالفصل: Figure 3-5 و Table 4-1، والعنوان تحت الشكل.
- قائمة الأشكال ثلاثة عشر شكلًا تقريبًا (مخططات النظام ولقطات الواجهة)، وجدولان إلى ثلاثة جداول فقط.
- الفصل 3 هو الأكبر (30 صفحة من 74)، والفصل 5 هو الأصغر (4 صفحات).
- فصل Results يقيس كل مكوّن على حدة ثم الأداء ثم الأمان، ثم يناقش القيود بصراحة.
- الفصل 2 ينتهي بـ Research Gap الذي يمهد مباشرة لما سيفعله المشروع.
