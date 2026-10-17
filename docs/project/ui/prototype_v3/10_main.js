/* ---------- plan generation showcase ---------- */
let genTok=0;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
function genSkeleton(){
 const st=[L('نحسب احتياجك','Calculating your needs'),L('نستبعد ما لا يناسبك','Removing what doesn’t suit you'),L('المحسّن يبحث عن أفضل تركيبة','The optimizer searches for the best mix'),L('نبني أيام الأسبوع','Building the week')];
 return `<div class="gen" role="status" aria-live="polite"><div style="padding:22px 20px 0;display:flex;align-items:center;gap:10px"><div class="grow"><div style="font-size:13px;color:#7FD3F5;font-weight:700">${E('sparkles',16)} NutriGuide Engine</div><h1 style="margin:2px 0 0;font-size:24px">${L('نبني خطتك الآن','Building your plan')}</h1></div>
 <button class="pill press" data-act="genSkip" style="background:rgba(255,255,255,.1);border-color:rgba(255,255,255,.15);color:#cfe">${L('تخطي','Skip')}</button></div>
 <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px 12px;padding:16px 20px 6px">${st.map((s,i)=>`<div class="stp" id="stp${i}"><span class="n num">${i+1}</span><span>${s}</span></div>`).join('')}</div>
 <div id="gstage" style="flex:1;min-height:0;padding:10px 20px;display:flex;flex-direction:column;justify-content:center;gap:14px"></div>
 <div style="padding:0 20px 8px"><div style="font-size:12.5px;color:#8FA6B8;margin-bottom:8px" id="gdaylbl">${L('أيام الأسبوع','Days of the week')}</div><div class="row" style="gap:4px">${DAYS.map((d,i)=>`<div class="dayc" id="gd${i}"><span class="o num">${d[2]}</span><span>${L(d[0].replace('ال','').slice(0,5),d[1])}</span></div>`).join('')}</div></div>
 <div style="padding:8px 20px 18px;font-size:11px;color:#5E7A90;text-align:center">${L('نموذج: الأرقام هنا للعرض. في التطبيق كل يوم طلب حقيقي للخادم ويعيد عدد الوجبات المرشحة وزمن الحل وحالته.','Prototype: numbers are for display. In the app each day is a real server request returning candidates, solve time and status.')}</div></div>`;
}
async function runGen(){
 const tok=++genTok,ok=()=>tok===genTok&&S.gen,$=id=>document.getElementById(id),t=targets();
 const step=i=>{for(let j=0;j<4;j++){const e=$('stp'+j);if(e)e.className='stp'+(j<i?' ok':j===i?' on':'')}};
 const stage=h=>{const g=$('gstage');if(g)g.innerHTML=h};
 // 1. needs
 step(0);stage(`<div style="display:flex;flex-direction:column;align-items:center;gap:14px"><div class="ringwrap" style="width:170px;height:170px"><svg width="170" height="170" viewBox="0 0 170 170"><circle cx="85" cy="85" r="74" fill="none" stroke="rgba(255,255,255,.08)" stroke-width="14"/><circle id="gring" cx="85" cy="85" r="74" fill="none" stroke="#FF9147" stroke-width="14" stroke-linecap="round" stroke-dasharray="465" stroke-dashoffset="465" style="transition:stroke-dashoffset 1.4s cubic-bezier(.3,.7,.2,1)"/></svg><div class="c"><div>${E('fire',30)}<div class="num" style="font-size:34px;font-weight:700" id="gk">0</div><div style="font-size:12px;color:#8FA6B8">${L('سعرة يوميًا','kcal a day')}</div></div></div></div>
  <div class="row" style="gap:6px;flex-wrap:wrap;justify-content:center" id="gform"></div></div>`);
 await sleep(150);if(!ok())return;const r=$('gring');if(r)r.style.strokeDashoffset=465*0.12;countTo($('gk'),t.kcal,1300);
 const chips=[`BMR ${fmt(t.bmr)}`,`× ${PAL[S.o.act]}`,`TDEE ${fmt(t.tdee)}`,S.o.goal==='MAINTAIN'?'':`${S.o.goal==='LOSE'?'−':'+'} ${fmt(t.adj)}`].filter(Boolean);
 for(const c of chips){await sleep(320);if(!ok())return;const f=$('gform');if(f)f.insertAdjacentHTML('beforeend',`<span class="chip num" style="background:rgba(255,255,255,.08);color:#DCEBF5;animation:pop .35s">${c}</span>`)}
 await sleep(500);if(!ok())return;
 // 2. filter
 step(1);stage(`<div class="between"><div><div class="num" style="font-size:40px;font-weight:700;line-height:1" id="gcnt">186</div><div style="font-size:12.5px;color:#8FA6B8">${L('وجبة في المطبخ','meals in the kitchen')}</div></div><div class="col" style="gap:6px;align-items:flex-end" id="gflt"></div></div>
  <div style="display:grid;grid-template-columns:repeat(6,1fr);gap:8px">${GENTILES.map((e,i)=>`<div class="gtile" id="gt${i}">${E(e,30)}${GENOUT[i]?`<span class="why">${muscle()&&['salt','sesame'].includes(GENOUT[i][0])?L('بروتين قليل','low protein'):L(GENOUT[i][1],{sesame:'sesame',salt:'high salt',nope:'disliked',fat:'sat. fat'}[GENOUT[i][0]])}</span>`:''}</div>`).join('')}</div>`);
 const fl=muscle()?[['flexed-biceps',L('الأغنى بالبروتين أولًا','Protein-rich first')],['high-voltage',L('وجبة حول التمرين','Meals around training')],['thumbs-down',L('بدون ما لا تحبه','No disliked meals')]]:[['shield',L('تجنب السمسم','Avoid sesame')],['herb',L('ملح أقل','Less salt')],['thumbs-down',L('بدون ما لا تحبه','No disliked meals')]];
 const outs=Object.keys(GENOUT);countTo($('gcnt'),112,1700,186);
 for(let i=0;i<outs.length;i++){await sleep(170);if(!ok())return;const e=$('gt'+outs[i]);if(e)e.classList.add('out');if(i%3===0){const f=$('gflt'),x=fl[i/3];if(f&&x)f.insertAdjacentHTML('beforeend',`<span class="chip" style="background:rgba(248,113,113,.14);color:#FCA5A5;animation:pop .35s">${E(x[0],14)}${x[1]}</span>`)}}
 await sleep(500);if(!ok())return;
 // 3. optimizer, day 1 in detail
 step(2);
 const SL=['BREAKFAST','LUNCH','SNACK','DINNER'],CM=[['fire',L('السعرات ضمن ±10%','Calories within ±10%')],muscle()?['poultry-leg',L('بروتين ≥ 25 غ في كل وجبة رئيسية','Protein ≥ 25 g in each main meal')]:['poultry-leg',L('البروتين','Protein')],['herb',L('الصوديوم ≤ 2000 ملغ','Sodium ≤ 2000 mg')],['leafy-green',L('الألياف','Fiber')],['sparkles',L('بدون تكرار مع أمس','No repeat from yesterday')]];
 stage(`<div class="row" style="gap:8px">${SL.map((s,i)=>`<div class="slot" id="gs${i}"><span>${sl(s)}</span><span class="reel" id="gr${i}">${E('fork-and-knife-with-plate',36)}</span></div>`).join('')}</div>
  <div class="col" style="gap:9px">${CM.map((c,i)=>`<div class="cm" id="gm${i}">${E(c[0],18)}<span style="width:150px">${c[1]}</span><div class="bar"><i style="width:8%"></i></div><span class="ck">${I('check','',3)}</span></div>`).join('')}</div>
  <div class="num" style="font-size:12px;color:#7FD3F5;text-align:center" id="glog">CP-SAT · ${L('يجرب التركيبات','trying combinations')}…</div>`);
 await solveDay(0,tok,1);if(!ok())return;
 // 4. remaining days, quicker
 step(3);
 for(let d=1;d<7;d++){await solveDay(d,tok,0.35);if(!ok())return}
 step(4);await sleep(300);if(!ok())return;reveal();
}
async function solveDay(d,tok,speed){
 const ok=()=>tok===genTok&&S.gen,$=id=>document.getElementById(id);
 const dc=$('gd'+d);if(dc)dc.className='dayc run';const lbl=$('gdaylbl');if(lbl)lbl.textContent=L(`اليوم ${d+1} من 7 · ${DAYS[d][0]}`,`Day ${d+1} of 7 · ${DAYS[d][1]}`);
 for(let i=0;i<5;i++){const m=$('gm'+i);if(m){m.classList.remove('ok');m.querySelector('i').style.width='10%'}}
 for(let i=0;i<4;i++){const s=$('gs'+i);if(s)s.classList.remove('lock')}
 const pool=GENTILES.filter((_,i)=>!GENOUT[i]);let tick=0,locked=0,combos=0;
 const final=WEEK[d].m.map(m=>MEALS[m].e);
 while(locked<4){
  await sleep(85);if(!ok())return;tick++;combos+=Math.round(40+Math.random()*90);
  for(let i=locked;i<4;i++){const r=$('gr'+i);if(r)r.innerHTML=E(pool[(tick*3+i*5)%pool.length],36)}
  const lg=$('glog');if(lg)lg.textContent=`CP-SAT · ${fmt(combos)} ${L('تركيبة جُربت','combinations tried')}`;
  for(let i=0;i<5;i++){const m=$('gm'+i);if(m&&!m.classList.contains('ok'))m.querySelector('i').style.width=(20+Math.random()*60)+'%'}
  if(tick%Math.max(2,Math.round(9*speed))===0){const r=$('gr'+locked);if(r)r.innerHTML=`<span style="animation:pop .3s;display:inline-block">${E(final[locked],36)}</span>`;const s=$('gs'+locked);if(s)s.classList.add('lock');
   const m=$('gm'+[0,1,3,2][locked]);if(m){m.classList.add('ok');m.querySelector('i').style.width='100%'}locked++}
 }
 const m4=$('gm4');if(m4){m4.classList.add('ok');m4.querySelector('i').style.width='100%'}
 const time=(1.4+((d*7)%5)*0.6).toFixed(1),cand=104+((d*13)%11);
 const lg=$('glog');if(lg)lg.innerHTML=`<span style="color:#2BD49A">● ${L('أمثل','OPTIMAL')}</span> · ${time} ${L('ث','s')} · ${cand} ${L('وجبة مرشحة','candidate meals')}`;
 if(dc){dc.className='dayc ok';dc.querySelector('.o').innerHTML=I('check','',3)}
 await sleep(speed>=1?900:380);
}
function reveal(){
 const g=document.getElementById('gstage');if(!g)return;const t=targets();
 g.innerHTML=`<div style="text-align:center;animation:rise .5s both">${E('party-popper',84)}<h2 style="font-size:26px;margin:8px 0 4px">${L(G('خطة أسبوعك جاهزة!','خطة أسبوعكِ جاهزة!'),'Your week is ready!')}</h2><p style="margin:0;color:#A9C1D3">${L(G('7 أيام بُنيت لك أنت، كلها ضمن حدودك','7 أيام بُنيت لكِ أنتِ، كلها ضمن حدودكِ'),'7 days built for you, all within your limits')}</p></div>
 <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">${[['fork-and-knife-with-plate','28',L('وجبة','meals')],['fire',fmt(t.kcal-18),L('متوسط السعرات','avg kcal')],['shield','0',L('تجاوز للحدود','limit breaks')],['sparkles','21',L('وجبة مختلفة','different meals')]].map((x,i)=>`<div style="background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:18px;padding:12px;display:flex;gap:10px;align-items:center;animation:rise .5s both ${0.15+i*0.08}s">${E(x[0],28)}<div><b class="num" style="font-size:20px">${x[1]}</b><div style="font-size:12px;color:#8FA6B8">${x[2]}</div></div></div>`).join('')}</div>
 <button class="btn block press" data-act="genDone" style="animation:rise .5s both .5s">${L('اعرض خطتي','Show my plan')}</button>`;
 confetti(0.5,0.35,140);
}
function countTo(el,to,ms,from=0){if(!el)return;const t0=performance.now();const f=now=>{const p=Math.min(1,(now-t0)/ms),e=1-Math.pow(1-p,3);el.textContent=fmt(Math.round(from+(to-from)*e));if(p<1)requestAnimationFrame(f)};requestAnimationFrame(f)}
function confetti(cx,cy,n=60){
 const fx=document.getElementById('fx');if(!fx||matchMedia('(prefers-reduced-motion: reduce)').matches)return;
 const c=document.createElement('canvas'),r=fx.getBoundingClientRect();c.width=r.width*2;c.height=r.height*2;c.style.cssText='width:100%;height:100%';fx.appendChild(c);
 const x=c.getContext('2d'),cols=['#2BD49A','#38BDF8','#FF9147','#FFC23D','#FF6B81','#5C9BFF'];
 const ps=Array.from({length:n},()=>({x:cx*c.width,y:cy*c.height,vx:(Math.random()-.5)*26,vy:-Math.random()*26-6,s:6+Math.random()*10,a:Math.random()*6,va:(Math.random()-.5)*.4,c:cols[Math.floor(Math.random()*cols.length)]}));
 let f=0;const loop=()=>{x.clearRect(0,0,c.width,c.height);ps.forEach(p=>{p.x+=p.vx;p.y+=p.vy;p.vy+=.9;p.vx*=.985;p.a+=p.va;x.save();x.translate(p.x,p.y);x.rotate(p.a);x.fillStyle=p.c;x.fillRect(-p.s/2,-p.s/4,p.s,p.s/2);x.restore()});if(++f<110)requestAnimationFrame(loop);else c.remove()};loop();
}

/* ---------- render ---------- */
const app=document.getElementById('app'),panelEl=document.getElementById('panel');
const SCREENS={welcome,login,onboarding,home,plan,shop,water,progress,profile};
function render(){
 app.className='app'+(S.mode!=='auto'?' mode-'+S.mode:'');applyAccent();app.dir=rtl()?'rtl':'ltr';document.documentElement.lang=S.lang;panelEl.dir=app.dir;
 const sc=app.querySelector('.scroll'),keep=!S.anim&&sc?sc.scrollTop:0;
 let h=SCREENS[S.screen]();
 if(S.sheet){h+=({meal:mealSheet,swap:swapSheet,quick:quickSheet,weight:weightSheet,water:waterSheet,badge:badgeSheet,fav:favSheet})[S.sheet.type](S.sheet)}
 if(S.toast)h+=`<div class="toast" role="status">${E(S.toast.e||'check-mark-button',24)}<span>${S.toast.t}</span></div>`;
 if(S.banner)h+=`<div class="banner" role="alert">${E(S.banner.e,38)}<div class="grow"><div class="row" style="gap:6px;font-size:12px;color:var(--fg-3)">${E('seedling',14)}NutriGuide · ${L('الآن','now')}</div><b>${S.banner.t}</b><div class="faint">${S.banner.b}</div></div></div>`;
 if(S.gen)h+=genSkeleton();
 app.innerHTML=h+'<div id="fx"></div>';
 const ns=app.querySelector('.scroll');if(ns&&keep)ns.scrollTop=keep;
 if(S.sheet)S.sheet.still=true;
 initWheels();runCounters();S.anim=false;renderPanel();
}
function runCounters(){app.querySelectorAll('.cu').forEach(el=>{const to=+el.dataset.to,d=+el.dataset.d;if(el.textContent!==fmt(to,d)){const t0=performance.now();const f=now=>{const p=Math.min(1,(now-t0)/1100),e=1-Math.pow(1-p,3);el.textContent=fmt(to*e,d);if(p<1)requestAnimationFrame(f)};requestAnimationFrame(f)}})}
function initWheels(){
 app.querySelectorAll('.wheel').forEach(wh=>{
  const key=wh.dataset.wheel,min=+wh.dataset.min,step=+wh.dataset.step,get=()=>key==='wlog'?(S.wlog??WEIGHTS[WEIGHTS.length-1]):S.o[key];
  const items=[...wh.querySelectorAll('.it')],idx0=Math.round((get()-min)/step);
  wh.scrollTop=idx0*44;items.forEach((it,i)=>it.classList.toggle('sel',i===idx0));
  let raf=0;wh.addEventListener('scroll',()=>{cancelAnimationFrame(raf);raf=requestAnimationFrame(()=>{
   const i=Math.max(0,Math.min(items.length-1,Math.round(wh.scrollTop/44))),v=+(min+i*step).toFixed(2);
   items.forEach((it,j)=>it.classList.toggle('sel',j===i));
   if(key==='wlog')S.wlog=v;else S.o[key]=v;
   if(key==='h'||key==='w'){const c=document.getElementById('bmicard');if(c)c.innerHTML=bmiCard()}
   if(key==='tw'){const p=document.getElementById('paceinfo');if(p)p.innerHTML=paceInfo()}
  })});
  items.forEach((it,i)=>it.addEventListener('click',()=>wh.scrollTo({top:i*44,behavior:'smooth'})));
 });
}
let toastT,bannerT;
function toast(t,e){S.toast={t,e};render();clearTimeout(toastT);toastT=setTimeout(()=>{S.toast=null;render()},2300)}
function banner(e,t,b){S.banner={e,t,b};render();clearTimeout(bannerT);bannerT=setTimeout(()=>{S.banner=null;render()},4800)}
function go(scr,back){S.screen=scr;S.nav=back?'back':'fwd';S.anim=true;S.sheet=null;render();}

/* ---------- events ---------- */
app.addEventListener('click',ev=>{
 const g=ev.target.closest('[data-go]');if(g&&!ev.target.closest('[data-act]:not([data-go])')){go(g.dataset.go,!!g.dataset.back);return}
 const a=ev.target.closest('[data-act]');if(!a)return;
 if(a.dataset.act==='close'&&ev.target!==a)return; // clicks inside the sheet do not close it
 act(a.dataset.act,a,ev);
});
app.addEventListener('input',ev=>{
 const k=ev.target.dataset.in;if(k==='name'){S.o.name=ev.target.value;const b=app.querySelector('[data-act=onbNext]');if(b)b.disabled=!S.o.name.trim()}
 if(k==='wrange'){const v=+ev.target.value;S.sheet.v=v;['wv','wv2'].forEach(id=>{const e=document.getElementById(id);if(e)e.textContent=fmt(v)});
  const w=document.getElementById('wwarn');if(w)w.innerHTML=v>500?tip('light-bulb',L('كمية كبيرة لجلسة واحدة. الأفضل توزيعها على جلستين، فالجسم يستفيد من الماء أكثر عندما يُشرب على دفعات.','That’s a lot in one sitting. Splitting it in two helps your body use the water better.')):'';
  const btn=app.querySelector('.sheet [data-act=addw]');if(btn)btn.dataset.v=v}
});
function act(k,a,ev){
 const v=a.dataset.v,id=+a.dataset.id,o=S.o;
 switch(k){
 case 'lang':S.lang=v;save();S.anim=true;render();break;
 case 'mode':S.mode=v;save();render();break;
 case 'startOnb':S.step=0;go('onboarding');break;
 case 'onbNext':{const st=steps();if(S.step>=st.length-1){if(general()){go('home')}else{S.gen=true;render();runGen()}}else{S.step++;S.nav='fwd';S.anim=true;render();}break;}
 case 'onbBack':if(S.step===0)go('welcome',true);else{S.step--;S.nav='back';S.anim=true;render();}break;
 case 'sex':o.sex=v;if(v==='MALE')o.preg=false;render();break;
 case 'goal':o.goal=v;if(v==='MUSCLE'){o.prot='GOAL';o.tw=o.w+3}if(v==='LOSE'&&o.tw>=o.w)o.tw=o.w-8;if(v==='GAIN'&&o.tw<=o.w)o.tw=o.w+5;render();break;
 case 'rate':o.rate=+v;render();break;
 case 'act':o.act=v;if(v!=='HIGH'&&v!=='ATHLETE'&&o.goal!=='MUSCLE')o.prot='GOAL';render();break;
 case 'prot':o.prot=v;render();break;
 case 'tdays':o.tdays=+v;render();break;
 case 'ttime':{const [lo,hi]=ttRange();o.ttime=Math.max(lo,Math.min(hi,o.ttime+ +v));render();break;}
 case 'accent':o.accent=v;render();break;
 case 'avatar':o.avatar=v;render();break;
 case 'editTrain':S.step=steps().indexOf('training');go('onboarding');break;
 case 'care':if(v==='NONE')o.care=[];else o.care=o.care.includes(v)?o.care.filter(x=>x!==v):[...o.care,v];if(!o.care.includes('DIABETES_T2'))o.insulin=false;render();break;
 case 'alg':{const c=o.allergy[v];if(!c)o.allergy[v]='AVOID';else if(c==='AVOID')o.allergy[v]='SEVERE';else delete o.allergy[v];render();break;}
 case 'safe':o[v]=!o[v];render();break;
 case 'time':{const key=a.dataset.k;o[key]=(o[key]+ +v+1440)%1440;render();break;}
 case 'hasDoc':o.hasDoc=!o.hasDoc;render();break;
 case 'doc':o.docGoal=Math.max(500,Math.min(3000,o.docGoal+ +v));render();break;
 case 'genSkip':genTok++;S.gen=false;go('home');toast(L('خطتك جاهزة','Your plan is ready'),'party-popper');break;
 case 'genDone':S.gen=false;go('home');break;
 case 'kmode':S.kmode=v;S.anim=false;render();break;
 case 'eat':{const was=!!S.eaten[id];S.eaten[id]=!was;if(a.dataset.close)S.sheet=null;
  if(!was){const it=TODAY.find(i=>i.id===id);const r=a.getBoundingClientRect(),ar=app.getBoundingClientRect();render();confetti((r.left+r.width/2-ar.left)/ar.width,(r.top-ar.top)/ar.height,36);
   if(TODAY.every(i=>S.eaten[i.id])){setTimeout(()=>confetti(.5,.3,150),200);toast(L(G('يوم مكتمل! حققت خطة اليوم كاملة','يوم مكتمل! حققتِ خطة اليوم كاملة'),'Day complete! You followed today’s plan'),'trophy')}else toast(L(`${G('أحسنتَ','أحسنتِ')}! سجلنا ${sl(it.slot)}`,`Nice! ${sl(it.slot)} logged`),'check-mark-button')}else render();break;}
 case 'meal':S.sheet={type:'meal',id};render();break;
 case 'mealx':S.sheet={type:'meal',m:a.dataset.m};render();break;
 case 'mult':S.mult[id]=+v;render();break;
 case 'swap':S.sheet={type:'swap',id};render();break;
 case 'doswap':{const it=TODAY.find(i=>i.id===id);it.m=a.dataset.m;S.sheet=null;toast(L('تم الاستبدال، وبقي يومك ضمن حدودك','Swapped. Your day stays within limits'),'sparkles');break;}
 case 'fav':S.favs[a.dataset.m]=!S.favs[a.dataset.m];if(S.favs[a.dataset.m])toast(L(G('أضيفت لمفضلاتك، سنقترحها أكثر','أضيفت لمفضلاتكِ، سنقترحها أكثر'),'Added to favourites, we’ll suggest it more'),'red-heart');else render();break;
 case 'nope':S.nope[a.dataset.m]=!S.nope[a.dataset.m];if(S.nope[a.dataset.m])toast(L('لن نقترحها في خططك القادمة','We won’t suggest it in future plans'),'thumbs-down');else render();break;
 case 'close':S.sheet=null;render();break;
 case 'quick':S.sheet={type:'quick'};render();break;
 case 'quickgo':S.sheet=null;if(v==='water')go('water');else if(v==='shop')go('shop');else if(v==='weight'){S.sheet={type:'weight'};render()}else toast(L('في التطبيق: ابحث عن أي طعام وسجله','In the app: search any food and log it'),'magnifying-glass-tilted-left');break;
 case 'weight':S.sheet={type:'weight'};render();break;
 case 'saveWeight':S.sheet=null;toast(L(`سجلنا وزنك ${fmt(S.wlog??88.4,1)} كغ`,`Saved ${fmt(S.wlog??88.4,1)} kg`),'balance-scale');break;
 case 'addw':{if(ev)ev.stopPropagation();const ml=+a.dataset.v;S.water.push({t:hm(S.now),ml});if(a.dataset.close)S.sheet=null;render();
  const b=document.getElementById('bottle');if(b){b.insertAdjacentHTML('beforeend',`<span class="dropfx">${E('droplet',26)}</span>`)}
  const t=targets(),tot=S.water.reduce((x,y)=>x+y.ml,0);
  if(t.water&&tot>=t.water&&tot-ml<t.water){confetti(.5,.3,90);toast(L(G('وصلت هدف الماء اليوم!','وصلتِ هدف الماء اليوم!'),'You reached today’s water goal!'),'trophy')}else toast(L(`أضفنا ${fmt(ml)} مل`,`Added ${fmt(ml)} ml`),'droplet');break;}
 case 'wcustom':S.sheet={type:'water',v:250};render();break;
 case 'wset':S.sheet.v=+v;S.sheet.still=true;render();break;
 case 'delw':S.water.splice(+v,1);render();break;
 case 'pday':if(S.screen==='plan'){S.planDay=+v;render()}else{S.planDay=+v;go('plan')}break;
 case 'regen':S.gen=true;render();runGen();break;
 case 'shopck':S.shop[v]=!S.shop[v];render();break;
 case 'share':toast(L('في التطبيق: تُشارك القائمة كنص عبر أي تطبيق','In the app: the list is shared as text to any app'),'share');break;
 case 'favlist':S.sheet={type:'fav'};render();break;
 case 'ptab':S.progTab=v;S.anim=true;render();break;
 case 'badge':S.sheet={type:'badge',b:v};render();break;
 case 'rem':S.rem[v]=!S.rem[v];render();break;
 case 'editOnb':S.step=1;go('onboarding');break;
 case 'editRhythm':S.step=steps().indexOf('rhythm');go('onboarding');break;
 case 'streak':toast(L(G('5 أيام متتالية من الالتزام. استمر!','5 أيام متتالية من الالتزام. استمري!'),'5 days in a row. Keep going!'),'fire');break;
 case 'notify':notifyMeal();break;
 }
}
function notifyMeal(){const it=TODAY.find(i=>mealState(i)==='now')||TODAY[1];banner(SLOT[it.slot][0],L(`حان وقت ${sl(it.slot)} · ${mname(it.m)}`,`${sl(it.slot)} time · ${mname(it.m)}`),L(`موعدك حتى ${hm(windows()[it.slot][1])}. اضغط «أكلتها» بعد الأكل.`,`Your window is open until ${hm(windows()[it.slot][1])}. Tap “I ate it” after.`))}

/* ---------- prototype panel (not part of the app) ---------- */
function renderPanel(){
 const b=(act,v,l,on)=>`<button data-pact="${act}" data-v="${v}" aria-pressed="${!!on}">${l}</button>`;
 const sc=[['welcome',L('الترحيب','Welcome')],['login',L('الدخول','Sign in')],['onboarding',L('الإعداد المتكيف','Adaptive setup')],['result',L('نتيجة الإعداد','Setup result')],['gen',L('بناء الخطة','Plan building')],['home',L('اليوم','Today')],['meal',L('تفاصيل وجبة','Meal detail')],['plan',L('الخطة','Plan')],['shop',L('المشتريات','Shopping')],['water',L('الماء','Water')],['progress',L('التقدم','Progress')],['profile',L('حسابي','Me')]];
 const cur=S.gen?'gen':S.sheet&&S.sheet.type==='meal'?'meal':S.screen==='onboarding'&&steps()[S.step]==='result'?'result':S.screen;
 panelEl.innerHTML=`<h2>${L('لوحة التجربة','Demo controls')}</h2><p>${L('أداة لعرض النموذج فقط، وليست جزءًا من التطبيق.','For the demo only, not part of the app.')}</p>
 <div class="lbl">${L('جرّب شخصية','Try a persona')}</div><div class="grid">${Object.entries(PERSONAS).map(([k,p])=>b('persona',k,L(p.ar,p.en),S.persona===k)).join('')}</div>
 <p style="margin-top:6px">${L('اللون يتبع الهدف، والمخاطبة والرسمة تتبع الجنس. قارن يوسف بريم.','Colour follows the goal; address and avatar follow sex. Compare Yusuf and Reem.')}</p>
 <div class="lbl">${L('الشاشات','Screens')}</div><div class="grid">${sc.map(([k,l])=>b('scr',k,l,cur===k)).join('')}</div>
 <div class="lbl">${L('سيناريوهات','Scenarios')}</div><div class="grid">
 ${b('notify','',L('إشعار موعد وجبة','Meal reminder'),0)}${b('scen','late',L('فات موعد وجبة','Missed a meal'),S.scen.late)}
 ${b('scen','complete',L('يوم مكتمل','Day complete'),S.scen.complete)}${b('scen','offline',L('دون إنترنت','Offline'),S.scen.offline)}
 ${b('scen','general',L('الوضع العام','General mode'),S.scen.general)}${b('scen','fluid',L('ماء بهدف الطبيب','Doctor water goal'),S.o.care.includes('HEART_DISEASE'))}
 ${b('athlete','',L('سؤال البروتين (نشاط عالٍ)','Protein question (high activity)'),0)}${b('female','',L('سؤال الأمان (أنثى)','Safety question (female)'),0)}</div>
 <div class="lbl">${L('اللغة والمظهر','Language and theme')}</div><div class="grid">${b('lang','ar','العربية',S.lang==='ar')}${b('lang','en','English',S.lang==='en')}</div>
 <div class="grid" style="grid-template-columns:1fr 1fr 1fr">${b('mode','light',L('فاتح','Light'),S.mode==='light')}${b('mode','dark',L('ليلي','Dark'),S.mode==='dark')}${b('mode','auto',L('تلقائي','Auto'),S.mode==='auto')}</div>
 <p>${L('الرسومات: Fluent Emoji من Microsoft (رخصة MIT). أسماء الوجبات من كتالوج المشروع، والأرقام للعرض.','Illustrations: Microsoft Fluent Emoji (MIT). Meal names from the project catalog; numbers are illustrative.')}</p>`;
}
panelEl.addEventListener('click',ev=>{
 const a=ev.target.closest('[data-pact]');if(!a)return;const k=a.dataset.pact,v=a.dataset.v;
 genTok++;S.gen=false;S.sheet=null;
 if(k==='scr'){if(v==='result'){S.step=steps().length-1;go('onboarding')}else if(v==='gen'){S.screen='home';S.gen=true;render();runGen()}else if(v==='meal'){go('home');S.sheet={type:'meal',id:2};render()}else go(v);}
 else if(k==='notify'){if(S.screen==='welcome'||S.screen==='onboarding'||S.screen==='login')go('home');notifyMeal()}
 else if(k==='scen'){if(v==='fluid'){S.o.care=S.o.care.includes('HEART_DISEASE')?S.o.care.filter(x=>x!=='HEART_DISEASE'):[...S.o.care,'HEART_DISEASE'];go('water')}
  else{S.scen[v]=!S.scen[v];if(v==='late'){S.eaten[1]=!S.scen.late}if(v==='complete'&&S.scen.complete){go('home');setTimeout(()=>confetti(.5,.3,150),300);return}go(['home','plan','water','progress','profile','shop'].includes(S.screen)?S.screen:'home')}}
 else if(k==='persona'){setPersona(v);S.planDay=2;go(['welcome','login','onboarding'].includes(S.screen)?'home':S.screen)}
 else if(k==='athlete'){S.o.act='ATHLETE';S.step=steps().indexOf('protein');go('onboarding')}
 else if(k==='female'){S.o.sex='FEMALE';S.o.name='سارة';S.step=steps().indexOf('safety');go('onboarding')}
 else if(k==='lang'){S.lang=v;save();S.anim=true;render()}
 else if(k==='mode'){S.mode=v;save();render()}
});
setInterval(()=>{if(S.screen==='welcome'&&!S.sheet){S.welcomeSlide++;const w=app.querySelector('.wslide');if(w){w.style.animation='none';void w.offsetWidth;}render();const n=app.querySelector('.wslide');if(n)n.style.animation='rise .5s both'}},4200);
setPersona(S.persona||'ahmed');render();
