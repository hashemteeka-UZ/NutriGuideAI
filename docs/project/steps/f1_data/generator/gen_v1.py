import yaml
yaml.Dumper.ignore_aliases = lambda *a: True
from foods_meta import F
from meals_def import MEALS
from sr import D

class Q(str): pass
class FD(dict): pass
def fd_rep(d,v): return d.represent_mapping("tag:yaml.org,2002:map", v, flow_style=True)
yaml.add_representer(FD,fd_rep)
def q_rep(d,s): return d.represent_scalar('tag:yaml.org,2002:str', s, style='"')
yaml.add_representer(Q,q_rep)
def dump(path, header, data):
    with open(path,'w',encoding='utf-8') as f:
        f.write(header)
        yaml.dump(data,f,allow_unicode=True,sort_keys=False,width=1000,default_flow_style=False)

PENDING="PENDING dietitian review (PROJECT_CONTEXT §30, Expert validation)"
ref={
 "seed_version":"f1_seed_v1",
 "categories_ar":{  # keyed by FDC food_category code; English name comes from FDC food_category.csv
  "0100":"الألبان والبيض","0200":"التوابل والأعشاب","0400":"الدهون والزيوت","0500":"الدواجن",
  "0800":"حبوب الإفطار","0900":"الفواكه وعصائرها","1100":"الخضروات","1200":"المكسرات والبذور",
  "1400":"المشروبات","1500":"الأسماك والمأكولات البحرية","1600":"البقوليات","1700":"لحم الضأن والعجل",
  "1800":"المخبوزات","1900":"الحلويات والمحليات","2000":"الحبوب والمعكرونة","1300":"لحم البقر"},
 "cuisines":[
  {"code":"LIBYAN","name_en":"Libyan","name_ar":"ليبي"},
  {"code":"LEVANTINE","name_en":"Levantine","name_ar":"شامي"},
  {"code":"GENERAL","name_en":"General","name_ar":"عام"}],
 "allergens":[
  {"code":"GLUTEN","name_en":"Gluten","name_ar":"الغلوتين"},{"code":"MILK","name_en":"Milk","name_ar":"الحليب"},
  {"code":"EGG","name_en":"Egg","name_ar":"البيض"},{"code":"FISH","name_en":"Fish","name_ar":"السمك"},
  {"code":"SHELLFISH","name_en":"Shellfish","name_ar":"المحار والقشريات"},{"code":"PEANUT","name_en":"Peanut","name_ar":"الفول السوداني"},
  {"code":"TREE_NUTS","name_en":"Tree nuts","name_ar":"المكسرات الشجرية"},{"code":"SESAME","name_en":"Sesame","name_ar":"السمسم"},
  {"code":"SOY","name_en":"Soy","name_ar":"الصويا"}],
 "dietary_tags":[
  {"code":"breakfast_suitable","tag_group":"OCCASION","name_en":"Suitable for breakfast","name_ar":"مناسب للفطور"},
  {"code":"lunch_suitable","tag_group":"OCCASION","name_en":"Suitable for lunch","name_ar":"مناسب للغداء"},
  {"code":"dinner_suitable","tag_group":"OCCASION","name_en":"Suitable for dinner","name_ar":"مناسب للعشاء"},
  {"code":"snack_suitable","tag_group":"OCCASION","name_en":"Suitable as a snack","name_ar":"مناسب كوجبة خفيفة"},
  {"code":"beverage","tag_group":"OCCASION","name_en":"Beverage","name_ar":"مشروب"},
  {"code":"nuts_seeds_snack","tag_group":"OCCASION","name_en":"Nuts or seeds snack","name_ar":"وجبة خفيفة من المكسرات أو البذور"},
  {"code":"vegetarian","tag_group":"DIETARY","name_en":"Vegetarian","name_ar":"نباتي"},
  {"code":"vegan","tag_group":"DIETARY","name_en":"Vegan","name_ar":"نباتي صرف"},
  {"code":"high_sodium","tag_group":"CONDITION","name_en":"High in sodium","name_ar":"مرتفع الصوديوم"},
  {"code":"high_sugar","tag_group":"CONDITION","name_en":"High in sugars","name_ar":"مرتفع السكريات"},
  {"code":"added_sugar","tag_group":"CONDITION","name_en":"Contains added sugar","name_ar":"يحتوي سكرًا مضافًا"}],
 "nutrients":[
  {"code":"energy_kcal","source_code":"208","name":"Energy","unit":"kcal","is_mandatory":True},
  {"code":"protein","source_code":"203","name":"Protein","unit":"g","is_mandatory":True},
  {"code":"total_fat","source_code":"204","name":"Total lipid (fat)","unit":"g","is_mandatory":True},
  {"code":"carbohydrate","source_code":"205","name":"Carbohydrate, by difference","unit":"g","is_mandatory":True},
  {"code":"fiber","source_code":"291","name":"Fiber, total dietary","unit":"g","is_mandatory":True},
  {"code":"sugars","source_code":"269","name":"Sugars, total","unit":"g","is_mandatory":True},
  {"code":"saturated_fat","source_code":"606","name":"Fatty acids, total saturated","unit":"g","is_mandatory":True},
  {"code":"cholesterol","source_code":"601","name":"Cholesterol","unit":"mg","is_mandatory":True},
  {"code":"sodium","source_code":"307","name":"Sodium, Na","unit":"mg","is_mandatory":True},
  {"code":"potassium","source_code":"306","name":"Potassium, K","unit":"mg","is_mandatory":False}],
 "health_conditions":[
  {"code":"DIABETES_T2","name_en":"Type 2 diabetes (not insulin-treated)","name_ar":"السكري من النوع الثاني (بدون إنسولين)","is_supported":True,"fluid_goal_requires_clinician":False},
  {"code":"HYPERTENSION","name_en":"Hypertension","name_ar":"ارتفاع ضغط الدم","is_supported":True,"fluid_goal_requires_clinician":False},
  {"code":"HEART_DISEASE","name_en":"Heart disease","name_ar":"أمراض القلب","is_supported":True,"fluid_goal_requires_clinician":True},
  {"code":"CKD","name_en":"Chronic kidney disease","name_ar":"مرض الكلى المزمن","is_supported":False,"fluid_goal_requires_clinician":True},
  {"code":"DIABETES_INSULIN","name_en":"Insulin-treated diabetes","name_ar":"السكري المعالج بالإنسولين","is_supported":False,"fluid_goal_requires_clinician":False}],
 "condition_nutrient_limits":[
  {"condition":"HYPERTENSION","nutrient":"sodium","limit_basis":"ABSOLUTE","max_per_day":2000,
   "source_reference":"WHO (2012). Guideline: Sodium intake for adults and children. < 2 g sodium/day","severity_note":PENDING},
  {"condition":"HEART_DISEASE","nutrient":"sodium","limit_basis":"ABSOLUTE","max_per_day":2300,
   "source_reference":"AHA (2021). Dietary Guidance to Improve Cardiovascular Health. <= 2300 mg sodium/day","severity_note":PENDING},
  {"condition":"HEART_DISEASE","nutrient":"saturated_fat","limit_basis":"PERCENT_ENERGY","max_per_day":6,
   "source_reference":"AHA/ACC (2013). Guideline on Lifestyle Management to Reduce Cardiovascular Risk. 5-6% of energy from saturated fat","severity_note":PENDING},
  {"condition":"HEART_DISEASE","nutrient":"cholesterol","limit_basis":"ABSOLUTE","max_per_day":200,
   "source_reference":"NCEP ATP III (2002). Therapeutic Lifestyle Changes diet. < 200 mg cholesterol/day","severity_note":PENDING},
  {"condition":"DIABETES_T2","nutrient":"carbohydrate","limit_basis":"ABSOLUTE","max_per_meal":60,
   "source_reference":"ADA carbohydrate-counting education: 45-60 g carbohydrate per meal for most adults","severity_note":PENDING},
  {"condition":"DIABETES_T2","nutrient":"sugars","limit_basis":"PERCENT_ENERGY","max_per_day":10,
   "source_reference":"WHO (2015). Guideline: Sugars intake for adults and children. < 10% of energy (free sugars; applied here to total sugars, which is stricter - see Decision #69)","severity_note":PENDING},
  {"condition":"DIABETES_T2","nutrient":"fiber","limit_basis":"ABSOLUTE","min_per_day":25,
   "source_reference":"ADA Standards of Care in Diabetes (2024), section 5: at least 14 g fiber per 1000 kcal (about 25 g/day)","severity_note":PENDING}],
 "condition_tag_restrictions":[
  {"condition":"HYPERTENSION","tag":"high_sodium","restriction_type":"LIMIT","max_servings_per_week":3},
  {"condition":"HEART_DISEASE","tag":"high_sodium","restriction_type":"LIMIT","max_servings_per_week":3},
  {"condition":"DIABETES_T2","tag":"high_sugar","restriction_type":"LIMIT","max_servings_per_week":3},
  {"condition":"DIABETES_T2","tag":"added_sugar","restriction_type":"AVOID"}],
 "excluded_keywords":["pork","bacon","ham","lard","prosciutto","salami","pepperoni","gelatin","wine","beer","alcohol","liqueur","rum","vodka","whiskey","blood"],
}
H1=("# Step F.1 reference seed (f1_seed_v1: cuisine and allergen codes, migration 0003). Authored by the project assistant from published guidelines.\n"
    "# Every condition limit is PENDING dietitian review before any pilot with users (PROJECT_CONTEXT §30).\n"
    "# Data, not schema: loading this file does not reopen the schema freeze (§20.1).\n")
dump("out_v1/reference_seed.yaml",H1,ref)

foods=[]
for n,(en,ar,state,alg,tags) in sorted(F.items()):
    foods.append({"ndb_number":n,"sr_description":D[n],"ingredient_en":en,"ingredient_ar":ar,"state":state,"allergens":alg,"ingredient_tags":tags})
H2=("# Step F.1 slice foods: USDA FDC SR Legacy (public domain), selected by NDB number.\n"
    "# Nutrient values are NOT in this file: they come from the official SR Legacy CSV release via fdc_sr_legacy_subset.csv.\n"
    "# One ingredient per food in F.1 (ingredients.default_food_id = this food).\n")
dump("out_v1/slice_foods.yaml",H2,{"source":"USDA FoodData Central, SR Legacy (April 2018)","foods":foods})

from meals_v1 import MEALS as M1
meals=[]
for m in M1:
    wm=m["wm"]
    d={"ref_external":f"F1-{m['code']}","name_ar":m["ar"],"name_en":m["en"],"cuisine":m["cu"],"servings":m["serv"],
      "weight_method":wm,"yield_factor":m["yf"],
      "yield_factor_source":("team estimate pending weighing (Step G replaces with WEIGHED)" if wm=="YIELD_FACTOR" else None),
      "variant_group":m["vg"],"occasion_tags":m["occ"],"dietary_tags":m["diet"],"reviewed_by":("Hashem" if m["reviewed"] else None),
      "ingredients":[]}
    for n,gr,opt,lab in m["ings"]:
        x=FD(ndb_number=n,grams=gr,label_ar=lab or F[n][1])
        if opt: x["optional"]=True
        d["ingredients"].append(x)
    meals.append(d)
H3=("# Step F.1 slice meals (f1_slice_v1, 35 meals). Drafted by an LLM assistant (§31.4): source = llm_draft_reviewed.\n"
    "# A team member reviews every recipe and writes their name in reviewed_by; is_verified = (reviewed_by is set).\n"
    "# v1 (2026-10-06, team review): S07 removed; chickpeas removed from L02; potatoes and pumpkin added to L08;\n"
    "#   D01 uses soup pasta, coriander and ground red hot pepper; D06 gains turmeric and spices; chicken variants (-CH) added.\n"
    "# label_ar is the recipe's own wording of the ingredient; the loader stores it in meal_ingredients.text_original.\n"
    "# optional: true marks an ingredient people may leave out; nutrients are still computed on the full recipe (Decision #75).\n"
    "# variant_group links versions of one dish (e.g. lamb and chicken couscous); the planner never puts two in one day (Decision #76).\n"
    "# Grams are as added to the recipe, in the state of the referenced food. Nutrients are computed (calc_v1), never typed.\n"
    "# total_grams = sum(grams) x yield_factor for YIELD_FACTOR; sum(grams) for SUM_OF_INGREDIENTS (no-cook dishes only).\n")
dump("out_v1/slice_meals.yaml",H3,{"dataset_version":"f1_slice_v1","source":"llm_draft_reviewed","source_license":"Team-authored recipes, project internal use","quality_tier":"SILVER","default_lang":"ar","meals":meals})
