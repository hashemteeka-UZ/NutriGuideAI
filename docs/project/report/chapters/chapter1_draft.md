# Chapter 1 Introduction

## 1.1 Introduction

Eating well is one of the most practical ways for a person to protect their health. A suitable diet helps people reach and keep a healthy weight, and it is also a central part of managing common chronic conditions such as type 2 diabetes, hypertension and heart disease [REF-1]. Yet knowing what to eat is hard in daily life. The amount of energy a person needs depends on age, sex, height, weight and activity level. A person with a chronic condition must also keep certain nutrients within limits, and a person with a food allergy must avoid specific ingredients altogether. Turning all of this into three meals a day that the person actually likes and can cook is a task that most people cannot do alone.

Mobile health applications try to help, but many of them stop at recording what the user ate, and those that do suggest meals often rely on food data of unclear origin [REF-2]. A meal plan is only as trustworthy as the nutrient values behind it. In addition, most nutrition applications are designed in English and for Western cuisines, which leaves Arabic-speaking users with dishes and portions that do not match what they eat at home.

This project presents NutriGuideAI, a mobile health and nutrition application that collects a user's profile and preferences, calculates the user's daily nutritional targets, and proposes daily meal plans that respect the user's health conditions and allergies. The application also records what the user actually eats and measures how closely each day followed the plan, and it tracks the user's weight against the goal.

The work was carried out as a fresh rebuild on a solid data foundation, after an earlier attempt failed because of its food database (Section 1.2). The system is organized in three layers. The first is a PostgreSQL database of 34 tables, created through versioned migrations, that stores reference data, a meal catalog and user data. The second is a curated catalog of ingredients and recipes whose nutrient values are calculated from laboratory-based food composition data, rather than typed in by hand. The third is a recommendation engine that first removes meals that are unsafe for the user, then builds a plan with a baseline greedy planner and with a constraint optimizer. A Flutter mobile client and a FastAPI service are designed to expose this engine to users, with an offline-first architecture in which the server is the system of record and the phone keeps a synchronized local copy.

This chapter states the problem (Section 1.2), the objectives (Section 1.3), the scope and limitations (Section 1.4), the time table (Section 1.5), and the structure of the report (Section 1.6).

## 1.2 Problem Statement

The project addresses three connected problems.

**Unreliable food data.** The first version of this project failed because of its food and meal database. The cause was not only the design of the tables but the strategy for obtaining content. There is no ready-made, openly licensed source of Arabic or Libyan meals with ingredients weighed in grams and trustworthy nutrient values. Large public recipe collections are restricted by license, state quantities in free text ("a cup", "a pinch"), and are mostly Western cuisine. Meal data that cannot be traced to a reliable source cannot safely be used to compute calories, sodium or sugar for a person with a health condition.

**Personalization under health constraints.** Each user has different energy needs, goals, conditions and allergies, and these interact. A user may have diabetes and hypertension together, and the limits that apply to each condition may conflict. A recommendation that is good in general may be unsafe for a particular person. A system that plans meals must therefore enforce hard limits, resolve conflicts between conditions, and refuse to produce a plan when no safe plan exists, instead of silently ignoring a limit.

**Planning and following the plan.** Producing one acceptable meal is easier than producing a full day that together reaches the calorie and macronutrient targets, respects every limit and avoids repetition. Moreover, a plan is useful only if the user can follow it and see progress, so the system must also record consumption and weight and compute adherence.

These problems lead to the central question of the project: **how can a meal-planning application use trustworthy, traceable food data and explicit safety rules to build daily meal plans that meet a person's nutritional targets and respect their health conditions and allergies?**

## 1.3 Study Objectives

The main objective of the project is to design and build the data foundation, the calculation rules and the planning engine of a personalized meal-planning application that is correct and traceable, and to evaluate the engine against a clear baseline.

The specific objectives are:

1. To design a PostgreSQL schema that models reference data, the meal catalog and user data, with constraints that protect data quality, and to manage its evolution through versioned migrations and automated tests.
2. To build a curated catalog of ingredients and recipes whose nutrient values are calculated from a laboratory-based food composition source, with provenance, quality checks and a quarantine for data that fails them.
3. To calculate each user's daily energy and macronutrient targets, with safety rules that prevent unsafe goals.
4. To represent the dietary limits of supported health conditions as data, and to resolve the case of several conditions at once.
5. To implement a three-layer recommendation architecture: hard filtering of unsafe meals, a baseline greedy planner, and a constraint optimizer based on CP-SAT.
6. To compare the optimizer with the baseline using independent, reproducible criteria.
7. To record meals eaten and weight over time, and to compute daily adherence and progress.
8. To expose the system through an API and a mobile application with an Arabic-first interface (planned).

## 1.4 Study Scope

### 1.4.1 In Scope

- Daily and weekly meal plans based on goal (lose, maintain or gain weight), with targets that change over time.
- Condition-aware limits for type 2 diabetes (non-insulin), hypertension and heart disease, including the case of several conditions.
- Filtering by allergies and ingredient preferences, and swapping a meal inside a plan.
- A curated catalog of ingredients and recipes, with general and local (Libyan) dishes.
- Consumption logging, daily adherence and weight tracking.
- A backend API and a mobile application with an offline-first design, built on the completed data foundation.

### 1.4.2 Limitations and Exclusions

- **Not a medical device.** The application gives dietary suggestions and does not replace a physician or a dietitian. Users with unsupported conditions, or for whom no safe plan exists, are referred to a professional.
- **Target users.** The app is designed for adults with type 2 diabetes, hypertension or heart disease, or no condition; it is not for pregnancy, lactation, kidney disease or gout.
- **Catalog size.** The current catalog is a curated first release of 196 ingredients and 75 meals. More dishes will be added later in batches through the same pipeline without redesign.
- **Ready-made foods.** Packaged and ready foods from the FNDDS source are deferred to future work.
- **Machine learning.** Personalization with machine learning, clustering and synthetic rating data are not implemented. The recommendation engine in this report is rule-based filtering plus mathematical optimization, and machine learning is described as a direction for future work.
- **Other future features.** A chatbot, water tracking, a Ramadan mode and suggested physical activity are documented as future work only.

## 1.5 Time Table

The project began as a fresh rebuild on 27 September 2026. Table 1-1 lists the phases completed so far, with the dates recorded in the project development journal, and the phases that remain. Dates for the remaining phases are to be set by the team.

**Table 1-1, Project phases and time table**

| Phase | Work | Period | Status |
|---|---|---|---|
| A | Diagnosis of the first attempt, architecture and scope decisions | 27 to 29 Sep 2026 | Completed |
| B | Local PostgreSQL environment and code-quality gates | 30 Sep 2026 | Completed |
| C | SQLAlchemy models for the 34 tables | 1 Oct 2026 | Completed |
| D | First Alembic migration with upgrade and downgrade tests | 1 Oct 2026 | Completed |
| E | Database integrity tests and continuous integration | 2 Oct 2026 | Completed |
| F | Pre-freeze review and schema freeze (schema-v1) | 2 to 4 Oct 2026 | Completed |
| F.1 | Vertical slice from data to progress tracking, and the greedy baseline planner | 4 to 10 Oct 2026 | Completed |
| G | Data engineering: ingredient and recipe catalog, quality gates, dataset freeze | 11 to 12 Oct 2026 | Completed |
| H | CP-SAT optimizer and comparison with the baseline | 12 Oct 2026 | Completed |
| I | Backend API | To be set | Planned |
| J | Mobile application and integration | To be set | Planned |
| K | Final evaluation and report | To be set | Planned |

## 1.6 Study Structure

This report has five chapters.

Chapter 1 introduces the project, states the problem and the objectives, defines the scope and the limitations, and gives the time table.

Chapter 2 reviews the literature: the nutritional background, the history of diet optimization and food recommender systems, the main challenges in this field, related works, and the research gap that this project addresses.

Chapter 3 describes the methodology: the development environment and tools, the requirements, the system architecture, the database design principles, the data engineering pipeline, the nutrition targets and safety rules, the recommendation architecture, the validation strategy, and the planned API and mobile application.

Chapter 4 presents the results and analysis: validation of the database and the pipeline, the quality and coverage of the dataset, the comparison between the baseline planner and the optimizer, the safety evaluation, and a discussion of limitations.

Chapter 5 concludes the report with the main contributions and recommendations for future development.
