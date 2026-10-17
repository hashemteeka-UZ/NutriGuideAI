/* ---------- line icons for app chrome ---------- */
const P={
home:'<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V20h14V9.5"/><path d="M10 20v-5h4v5"/>',
cal:'<rect x="3.5" y="5" width="17" height="15.5" rx="3"/><path d="M3.5 10h17M8 3v4M16 3v4"/>',
drop:'<path d="M12 3.5c3.6 4.3 6 7.7 6 10.6a6 6 0 0 1-12 0c0-2.9 2.4-6.3 6-10.6z"/>',
chart:'<path d="M4 4v16h16"/><path d="m7.5 14 3.5-4 3 3 5-6"/>',
user:'<circle cx="12" cy="8" r="4"/><path d="M4 20.5c1.3-3.8 4.4-5.5 8-5.5s6.7 1.7 8 5.5"/>',
bell:'<path d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/>',
plus:'<path d="M12 5v14M5 12h14"/>',minus:'<path d="M5 12h14"/>',
check:'<path d="m5 12.5 4.5 4.5L19 7.5"/>',x:'<path d="M6 6l12 12M18 6 6 18"/>',
chev:'<path d="m9 5 7 7-7 7"/>',back:'<path d="m15 5-7 7 7 7"/>',
swap:'<path d="M7 7h12l-3-3M17 17H5l3 3"/>',
heart:'<path d="M12 20s-7.5-4.4-7.5-10A4.3 4.3 0 0 1 12 7.4 4.3 4.3 0 0 1 19.5 10c0 5.6-7.5 10-7.5 10z"/>',
heartf:'<path fill="currentColor" d="M12 20s-7.5-4.4-7.5-10A4.3 4.3 0 0 1 12 7.4 4.3 4.3 0 0 1 19.5 10c0 5.6-7.5 10-7.5 10z"/>',
nope:'<circle cx="12" cy="12" r="8.5"/><path d="m6 6 12 12"/>',
cart:'<path d="M3 4h2.5l2 11h10.5l2-8H6.5"/><circle cx="9" cy="19.5" r="1.4"/><circle cx="17" cy="19.5" r="1.4"/>',
share:'<path d="M12 15V4m0 0L8 8m4-4 4 4"/><path d="M5 12v7a1.5 1.5 0 0 0 1.5 1.5h11A1.5 1.5 0 0 0 19 19v-7"/>',
edit:'<path d="M4 20h4L19 9l-4-4L4 16z"/>',
gear:'<circle cx="12" cy="12" r="3"/><path d="M12 2.8v2.4M12 18.8v2.4M2.8 12h2.4M18.8 12h2.4M5.5 5.5l1.7 1.7M16.8 16.8l1.7 1.7M5.5 18.5l1.7-1.7M16.8 7.2l1.7-1.7"/>',
globe:'<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.6 3.5 5.4 3.5 8.5s-1 5.9-3.5 8.5c-2.5-2.6-3.5-5.4-3.5-8.5s1-5.9 3.5-8.5z"/>',
sun:'<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"/>',
moon:'<path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/>',
auto:'<circle cx="12" cy="12" r="8.5"/><path d="M12 3.5v17" /><path fill="currentColor" d="M12 3.5a8.5 8.5 0 0 1 0 17z"/>',
clock:'<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
wifi:'<path d="M3 3l18 18"/><path d="M8.5 16.5a5 5 0 0 1 7 0M5 12.8a10 10 0 0 1 4.2-2.3M19 12.8a10 10 0 0 0-3-1.9M2 9.3a15 15 0 0 1 4.3-2.6M22 9.3A15 15 0 0 0 11 5.6"/><circle cx="12" cy="19.5" r=".8"/>',
spark:'<path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5 18 18M6 18l2.5-2.5M15.5 8.5 18 6"/>',
trash:'<path d="M4.5 7h15M9.5 7V4.5h5V7M6.5 7l1 13h9l1-13"/>',
info:'<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5.5M12 7.6v.2"/>',
refresh:'<path d="M20 11a8 8 0 0 0-14.7-4.3L3.5 9M4 13a8 8 0 0 0 14.7 4.3L20.5 15"/><path d="M3.5 4v5h5M20.5 20v-5h-5"/>',
logout:'<path d="M14 4h4.5A1.5 1.5 0 0 1 20 5.5v13a1.5 1.5 0 0 1-1.5 1.5H14"/><path d="M10 16l-4-4 4-4M6 12h10"/>',
lock:'<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5"/>',
fork:'<path d="M7 3v8M5 3v5a2 2 0 0 0 4 0V3M7 11v10M17 3c-2 1-3 3.5-3 6.5V13h3v8"/>'
};
const I=(n,cls='',sw=1.9)=>`<svg class="ic ${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${P[n]||''}</svg>`;
const E=(n,s=28,cls='')=>`<svg class="emo ${cls}" viewBox="0 0 32 32" width="${s}" height="${s}" aria-hidden="true">${FE[n]||''}</svg>`;

/* ---------- state ---------- */
const S={lang:'ar',mode:'auto',screen:'welcome',nav:'fwd',anim:true,sheet:null,toast:null,banner:null,
 scen:{offline:false,late:false,general:false,fluid:false,complete:false},
 o:{name:'أحمد',sex:'MALE',age:29,h:175,w:88,goal:'LOSE',tw:78,rate:0.5,act:'MODERATE',prot:'GOAL',care:['HYPERTENSION'],
    allergy:{sesame:'AVOID'},ckd:false,insulin:false,preg:false,wake:420,sleep:1380,docGoal:1500,hasDoc:true,tdays:4,ttime:1080,accent:'AUTO',avatar:'AUTO'},persona:'ahmed',
 step:0,welcomeSlide:0,eaten:{1:true},water:[{t:'07:40',ml:250},{t:'09:35',ml:250},{t:'11:30',ml:300}],now:13*60+40,
 kmode:'eaten',favs:{L07:true},nope:{},shop:{},progTab:'report',planDay:1,mult:{},rem:{meals:true,water:true,weight:true}};
try{const sv=JSON.parse(localStorage.getItem('ng-proto-v3')||'{}');if(sv.lang)S.lang=sv.lang;if(sv.mode)S.mode=sv.mode;}catch(e){}
const save=()=>{try{localStorage.setItem('ng-proto-v3',JSON.stringify({lang:S.lang,mode:S.mode}))}catch(e){}};
const L=(a,e)=>S.lang==='ar'?a:e;
const rtl=()=>S.lang==='ar';
const fmt=(v,d=0)=>Number(v).toLocaleString('en-US',{maximumFractionDigits:d,minimumFractionDigits:0});
const hm=m=>{m=((m%1440)+1440)%1440;return String(Math.floor(m/60)).padStart(2,'0')+':'+String(m%60).padStart(2,'0')};
const CU=(v,d=0,cls='')=>`<span class="num cu ${cls}" data-to="${v}" data-d="${d}">${fmt(S.anim?0:v,d)}</span>`;

/* ---------- targets (targets_v1 + protein preference) ---------- */
const PAL={SEDENTARY:1.2,LIGHT:1.375,MODERATE:1.55,HIGH:1.725,ATHLETE:1.9};
function targets(){
 const o=S.o,bmr=10*o.w+6.25*o.h-5*o.age+(o.sex==='MALE'?5:-161),tdee=bmr*PAL[o.act];
 let adj=0;const up=o.goal==='GAIN'||o.goal==='MUSCLE';
 // MUSCLE = a small fixed surplus (0.25 kg a week, about 275 kcal), inside the existing gain cap of 500 kcal
 if(o.goal!=='MAINTAIN'){const rate=o.goal==='MUSCLE'?0.25:o.goal==='GAIN'?Math.min(o.rate,0.5):Math.min(o.rate,o.w*0.01);adj=Math.min(up?500:1000,rate*7700/7);}
 const floor=o.sex==='MALE'?1500:1200;const kcal=Math.max(floor,Math.round((o.goal==='LOSE'?tdee-adj:up?tdee+adj:tdee)/10)*10);
 const bmi=o.w/((o.h/100)**2),ibw=25*(o.h/100)**2,refw=bmi<30?o.w:ibw+0.4*(o.w-ibw);
 let gpk={LOSE:1.4,MAINTAIN:1.0,GAIN:1.8,MUSCLE:1.8}[o.goal];if(o.act==='ATHLETE')gpk=Math.max(gpk,1.8);
 if(o.prot==='SPORT')gpk=Math.max(gpk,1.8);if(o.prot==='HIGH')gpk=o.goal==='MUSCLE'?2.2:2.0;
 const protein=Math.round(refw*gpk),fat=Math.round(kcal*0.3/9),carb=Math.round((kcal-protein*4-fat*9)/4),fiber=Math.round(kcal/1000*14);
 const heart=o.care.includes('HEART_DISEASE');
 const water=heart?(o.hasDoc?o.docGoal:null):(o.sex==='MALE'?2000:1600);
 // MUSCLE: protein is a floor (target) with a ceiling of 2.2 g/kg, and each main meal needs at least 25 g
 return {bmr:Math.round(bmr),tdee:Math.round(tdee),adj:Math.round(adj),kcal,protein,fat,carb,fiber,water,bmi,gpk,refw:Math.round(refw),pmax:o.goal==='MUSCLE'?Math.round(refw*2.2):null,pmeal:o.goal==='MUSCLE'?25:null};
}
const general=()=>S.scen.general||S.o.ckd||S.o.insulin||S.o.preg;
/* meal windows from wake/sleep (minutes from midnight) */
function baseWindows(){
 const W=S.o.wake,Z=S.o.sleep<=W?S.o.sleep+1440:S.o.sleep;
 return {BREAKFAST:[W+30,W+150],LUNCH:[W+360,W+480],SNACK:[W+570,W+630],DINNER:[Math.max(W+690,Z-240),Math.max(W+780,Z-150)]};
}
function windows(d=2){const w=baseWindows(),tr=training(d);if(tr&&tr.sw)w.SNACK=tr.sw;return w}
function sessions(){
 const t=targets(),goal=t.water||2000,W=S.o.wake+30,Z=(S.o.sleep<=S.o.wake?S.o.sleep+1440:S.o.sleep)-60;
 const n=Math.max(4,Math.round((Z-W)/120)+1),step=(Z-W)/(n-1),amt=Math.round(goal/n/50)*50;
 return Array.from({length:n},(_,i)=>({t:Math.round((W+i*step)/15)*15,ml:amt}));
}
