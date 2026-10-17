/* ---------- v3: muscle-building path, goal accent, gendered Arabic address, demo personas ---------- */
// Gendered Arabic address: masculine / feminine form (English is unaffected). In Flutter this is an ARB ICU select on sex.
const G=(m,f)=>S.o.sex==='FEMALE'?f:m;

// Accent follows the GOAL, not the sex. Only the accent changes; macro colours stay fixed.
// Light shades keep white text >= 4.5:1 (WCAG 2.2 SC 1.4.3); dark shades keep >= 6:1 on the dark surface.
const ACC={
 EMERALD:{ar:'أخضر منعش',en:'Fresh green',l:['#08875D','#065F46','#FFFFFF'],d:['#34D399','#A7F3D0','#04241A'],
  hl:'linear-gradient(135deg,#08875D 0%,#0E9F8A 50%,#1A8FC9 100%)',hd:'linear-gradient(135deg,#0E8F68 0%,#0F8C86 45%,#1478B8 100%)'},
 TEAL:{ar:'فيروزي هادئ',en:'Calm teal',l:['#0E7C74','#115E59','#FFFFFF'],d:['#2DD4BF','#99F6E4','#042F2E'],
  hl:'linear-gradient(135deg,#0E7C74 0%,#0F8C9A 50%,#2C7BD8 100%)',hd:'linear-gradient(135deg,#0F766E 0%,#0E7490 50%,#1D5FC4 100%)'},
 VIOLET:{ar:'بنفسجي نشيط',en:'Energetic violet',l:['#7C3AED','#5B21B6','#FFFFFF'],d:['#A78BFA','#DDD6FE','#1E1B4B'],
  hl:'linear-gradient(135deg,#5B21B6 0%,#7C3AED 50%,#C026D3 100%)',hd:'linear-gradient(135deg,#4C1D95 0%,#6D28D9 50%,#A21CAF 100%)'},
 PLUM:{ar:'برقوقي دافئ',en:'Warm plum',l:['#A21CAF','#86198F','#FFFFFF'],d:['#E879F9','#F5D0FE','#3B0A3F'],
  hl:'linear-gradient(135deg,#86198F 0%,#A21CAF 50%,#DB2777 100%)',hd:'linear-gradient(135deg,#701A75 0%,#86198F 50%,#BE185D 100%)'}
};
const GOAL_ACC={LOSE:'EMERALD',MAINTAIN:'TEAL',MUSCLE:'VIOLET',GAIN:'PLUM'};
const accentKey=()=>S.o.accent&&S.o.accent!=='AUTO'?S.o.accent:GOAL_ACC[S.o.goal]||'EMERALD';
const isDark=()=>S.mode==='dark'||(S.mode==='auto'&&matchMedia('(prefers-color-scheme: dark)').matches);
function applyAccent(){
 // before sign-up the app keeps the default identity; after it, the accent follows the user
 const pre=S.screen==='welcome'||S.screen==='login'||(S.screen==='onboarding'&&steps().indexOf('goal')>S.step);
 const a=ACC[pre?'EMERALD':accentKey()],dk=isDark(),c=dk?a.d:a.l,st=app.style;
 st.setProperty('--brand',c[0]);st.setProperty('--brand-2',c[1]);st.setProperty('--on-brand',c[2]);
 st.setProperty('--brand-soft',`color-mix(in srgb,${c[0]} ${dk?24:14}%,var(--surface))`);st.setProperty('--hero',dk?a.hd:a.hl);
}
// Avatar follows the user's own choice; the default depends on sex and goal.
const AVATARS={MALE:['man','man-lifting-weights','man-in-lotus-position','person-running'],FEMALE:['woman','woman-lifting-weights','woman-in-lotus-position','woman-running']};
const avatar=()=>S.o.avatar&&S.o.avatar!=='AUTO'&&AVATARS[S.o.sex].includes(S.o.avatar)?S.o.avatar:AVATARS[S.o.sex][S.o.goal==='MUSCLE'?1:0];

// Training days (Sunday-first week, index 2 = today, Tuesday) and the pre/post-workout rule.
const TDAYS={2:[0,3],3:[0,2,4],4:[0,2,4,6],5:[0,1,2,4,6],6:[0,1,2,3,4,6]};
const muscle=()=>S.o.goal==='MUSCLE';
function training(d=2){
 if(!muscle())return null;
 if(!(TDAYS[S.o.tdays]||[]).includes(d))return{on:false};
 const w=baseWindows(),T=S.o.ttime;
 // post: the first main meal that starts 1-3 h after the session start (session ~60 min); otherwise the snack moves after training
 const post=['BREAKFAST','LUNCH','DINNER'].find(s=>w[s][0]>=T+60&&w[s][0]<=T+180)||null;
 if(!post)return{on:true,T,post:null,snack:'POST',sw:[T+75,T+135]};
 // pre: the usual snack already sits 0-3 h before training
 return{on:true,T,post,snack:w.SNACK[1]<=T&&w.SNACK[0]>=T-180?'PRE':null};
}
const ttRange=()=>{const W=S.o.wake,Z=S.o.sleep<=W?S.o.sleep+1440:S.o.sleep;return[W+150,Z-150]};
const sl=(s,d=2)=>{const tr=training(d);if(s==='SNACK'&&tr&&tr.snack)return tr.snack==='PRE'?L('قبل التمرين','Pre-workout'):L('بعد التمرين','Post-workout');return L(SLOT[s][1],SLOT[s][2])};
const MAIN=['BREAKFAST','LUNCH','DINNER'];
function reasonsFor(it){
 const r=[],tr=training();
 if(tr&&tr.on){if(it.slot==='SNACK'&&tr.snack==='PRE')r.push('PRE_WORKOUT');if(tr.post===it.slot||(it.slot==='SNACK'&&tr.snack==='POST'))r.push('POST_WORKOUT')}
 if(muscle()&&MAIN.includes(it.slot)&&nOf(it.m,S.mult[it.id]||it.x).protein>=t25())r.push('PROTEIN_MEAL');
 return [...new Set([...r,...MEALS[it.m].r])];
}
const t25=()=>25;

// Extra reason codes for the muscle path (labels only; the engine rule is the per-meal protein floor).
Object.assign(R,{PRE_WORKOUT:['high-voltage','طاقة قبل التمرين','Pre-workout energy'],POST_WORKOUT:['flexed-biceps','للتعافي بعد التمرين','Post-workout recovery'],
 PROTEIN_MEAL:['poultry-leg','25+ غ بروتين','25 g+ protein'],NEW_BATCH:['sparkles','من دفعة البروتين المقترحة','From the proposed protein batch']});

// Catalog meals (team_recipes_batch_01, NG-xxx; values from the coverage check) + two PROPOSED recipes (nw:1) for the breakfast/snack gap.
Object.assign(MEALS,{
 Q1:{ar:'صدر دجاج مشوي مع كينوا وخضار',en:'Grilled chicken breast with quinoa and vegetables',e:'bento-box',tc:'--protein',min:35,ing:[['صدر دجاج','Chicken breast',125,'poultry-leg','prot'],['كينوا مطبوخة','Cooked quinoa',125,'sheaf-of-rice','grain'],['كوسا','Zucchini',50,'cucumber','veg'],['فلفل أحمر','Red pepper',50,'hot-pepper','veg'],['زيت زيتون','Olive oil',5,'olive','pantry'],['ليمون','Lemon',5,'lemon','veg']],al:[],n:{kcal:372,protein:35.0,carb:30.0,fat:11.5,fiber:4.5,sugars:3.5,satfat:2.0,chol:90,sodium:360},r:['HIGH_PROTEIN','LOW_SODIUM']},
 Q2:{ar:'دجاج مشوي بالثوم والليمون مع بطاطا',en:'Grilled chicken with garlic, lemon and potatoes',e:'poultry-leg',tc:'--fat',min:50,ing:[['فخذ دجاج','Chicken thigh',150,'poultry-leg','prot'],['بطاطا','Potato',100,'potato','veg'],['ثوم','Garlic',4,'garlic','veg'],['ليمون','Lemon',8,'lemon','veg'],['زيت زيتون','Olive oil',5,'olive','pantry']],al:[],n:{kcal:317,protein:32.1,carb:19.0,fat:12.3,fiber:2.0,sugars:1.0,satfat:2.6,chol:140,sodium:480},r:['HIGH_PROTEIN']},
 Q3:{ar:'زبادي يوناني بالفراولة والموز',en:'Greek yogurt with strawberries and banana',e:'strawberry',tc:'--protein',min:3,ing:[['زبادي يوناني','Greek yogurt',170,'glass-of-milk','dairy'],['فراولة','Strawberries',80,'strawberry','veg'],['موز','Banana',50,'banana','veg']],al:['milk'],n:{kcal:170,protein:18.4,carb:23.5,fat:0.9,fiber:2.9,sugars:16.0,satfat:0.2,chol:8,sodium:62},r:['HIGH_PROTEIN']},
 Q4:{ar:'طاجين دجاج بالخضار والزيتون',en:'Chicken tagine with vegetables and olives',e:'pot-of-food',tc:'--kcal',min:60,ing:[['دبوس دجاج','Chicken drumstick',150,'poultry-leg','prot'],['بطاطا','Potato',100,'potato','veg'],['جزر','Carrot',50,'carrot','veg'],['بازلاء','Peas',38,'leafy-green','veg'],['بصل','Onion',38,'onion','veg'],['زيتون أخضر','Green olives',12,'olive','pantry'],['زيت زيتون','Olive oil',6,'olive','pantry']],al:[],n:{kcal:395,protein:34.3,carb:26.0,fat:16.5,fiber:6.0,sugars:6.0,satfat:3.3,chol:140,sodium:520},r:['HIGH_PROTEIN','HIGH_FIBER']},
 N1:{nw:1,ar:'بيض مع شوفان بالحليب والموز',en:'Eggs with oats, milk and banana',e:'egg',tc:'--carb',min:12,ing:[['بيض','Eggs',100,'egg','dairy'],['شوفان','Oats',50,'sheaf-of-rice','grain'],['حليب قليل الدسم','Low-fat milk',250,'glass-of-milk','dairy'],['موز','Banana',50,'banana','veg']],al:['egg','milk','gluten'],n:{kcal:483,protein:28.3,carb:57.0,fat:15.7,fiber:6.3,sugars:20.0,satfat:4.7,chol:375,sodium:230},r:['NEW_BATCH','HIGH_PROTEIN']},
 N2:{nw:1,ar:'زبادي يوناني بالشوفان والموز والعسل',en:'Greek yogurt with oats, banana and honey',e:'bowl-with-spoon',tc:'--protein',min:4,ing:[['زبادي يوناني','Greek yogurt',170,'glass-of-milk','dairy'],['شوفان','Oats',30,'sheaf-of-rice','grain'],['موز','Banana',80,'banana','veg'],['عسل','Honey',5,'honey-pot','pantry']],al:['milk','gluten'],n:{kcal:300,protein:22.2,carb:48.0,fat:3.0,fiber:5.0,sugars:25.0,satfat:0.6,chol:8,sodium:70},r:['NEW_BATCH','HIGH_PROTEIN']}
});
Object.assign(ALTS,{N1:['B09','B03','Q3'],Q4:['Q1','Q2','D05'],Q1:['Q2','Q4','L09'],S01:['N2','Q3','S02']});

// Demo personas: the same app, personalised by goal (accent, home order, badges) and by sex (Arabic address, avatar).
const PERSONAS={
 ahmed:{ar:'أحمد · إنقاص الوزن',en:'Ahmed · lose weight',o:{name:'أحمد',sex:'MALE',age:29,h:175,w:88,goal:'LOSE',tw:78,rate:0.5,act:'MODERATE',prot:'GOAL',care:['HYPERTENSION'],allergy:{sesame:'AVOID'}},
  today:[['BREAKFAST','B07',1.5],['LUNCH','L07',2],['SNACK','S02',1.5],['DINNER','D05',1]],weights:[92.4,92.0,91.6,91.7,91.1,90.6,90.4,89.9,89.6,89.2,88.9,88.4]},
 sara:{ar:'سارة · إنقاص الوزن',en:'Sara · lose weight',o:{name:'سارة',sex:'FEMALE',age:31,h:163,w:72,goal:'LOSE',tw:64,rate:0.5,act:'LIGHT',prot:'GOAL',care:['DIABETES_T2'],allergy:{}},
  today:[['BREAKFAST','B07',1],['LUNCH','L07',1.5],['SNACK','S02',1],['DINNER','D02',1]],weights:[75.1,74.9,74.6,74.4,74.0,73.8,73.6,73.1,72.9,72.6,72.3,72.0]},
 yusuf:{ar:'يوسف · بناء العضلات',en:'Yusuf · build muscle',o:{name:'يوسف',sex:'MALE',age:24,h:178,w:78,goal:'MUSCLE',tw:81,rate:0.25,act:'LIGHT',prot:'GOAL',care:[],allergy:{},tdays:4,ttime:1080},
  today:[['BREAKFAST','N1',1.5],['LUNCH','L07',2],['SNACK','S01',2],['DINNER','Q4',1.5]],weights:[75.6,75.7,75.9,76.1,76.2,76.5,76.7,76.9,77.2,77.4,77.7,78.0],
  week:[{st:'ACHIEVED',m:['N1','Q1','S01','Q4']},{st:'ACHIEVED',m:['B09','Q2','Q3','D05']},{st:null,m:['N1','L07','S01','Q4']},{st:null,m:['B03','L09','N2','Q1']},{st:null,m:['N1','Q4','S01','L04']},{st:null,m:['B09','L07','Q3','Q2']},{st:null,m:['N1','Q1','N2','D05']}]},
 reem:{ar:'ريم · بناء العضلات',en:'Reem · build muscle',o:{name:'ريم',sex:'FEMALE',age:26,h:165,w:60,goal:'MUSCLE',tw:63,rate:0.25,act:'LIGHT',prot:'GOAL',care:[],allergy:{},tdays:3,ttime:1050},
  today:[['BREAKFAST','N1',1],['LUNCH','L07',1.5],['SNACK','S01',2],['DINNER','Q4',1]],weights:[58.1,58.2,58.4,58.5,58.7,58.9,59.0,59.2,59.4,59.6,59.8,60.0],
  week:[{st:'ACHIEVED',m:['N1','Q1','S01','Q4']},{st:'PARTIAL',m:['B09','Q2','Q3','D05']},{st:null,m:['N1','L07','S01','Q4']},{st:null,m:['B03','L09','N2','Q1']},{st:null,m:['N1','Q4','S01','L04']},{st:null,m:['B09','L07','Q3','Q2']},{st:null,m:['N1','Q1','N2','D05']}]}
};
const WEEK_STD=WEEK.map(w=>({...w,m:[...w.m]}));
function setPersona(k){
 const p=PERSONAS[k];S.persona=k;
 Object.assign(S.o,{care:[],allergy:{},tdays:4,ttime:1080,accent:'AUTO',avatar:'AUTO',ckd:false,insulin:false,preg:false},JSON.parse(JSON.stringify(p.o)));
 TODAY=p.today.map(([slot,m,x],i)=>({id:i+1,slot,m,x}));
 WEEK=p.week?p.week.map(w=>({...w,m:[...w.m]})):WEEK_STD.map(w=>({...w,m:[...w.m]}));
 WEEK[2].m=TODAY.map(it=>it.m);WEIGHTS=p.weights;
 S.eaten={1:true};S.mult={};S.water=[{t:'07:40',ml:250},{t:'09:35',ml:250},{t:'11:30',ml:300}];S.favs=muscle()?{Q1:true}:{L07:true};S.nope={};S.planDay=2;
}
