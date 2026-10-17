/* ---------- plan (week) ---------- */
function plan(){
 const d=S.planDay,day=WEEK[d],t=targets(),dayKc=i=>i===2?TODAY.reduce((a,it)=>a+nOf(it.m,S.mult[it.id]||it.x).kcal,0):t.kcal*(0.94+((i*13)%9)/100),kc=dayKc(d);
 const wk=WEEK.map((w,i)=>Math.round(dayKc(i)));
 const bw=320,bh=110,mx=3000,slot=bw/7;
 return `<div class="screen ${S.anim?'anim '+S.nav:''}">${offlineBar()}${topbar(L('خطتك للأسبوع','Your week'),L('11 – 17 أكتوبر · بُنيت بالمحسّن','11–17 Oct · built by the optimizer'),`<button class="iconbtn press" data-act="regen" aria-label="${L('إعادة البناء','Rebuild')}">${I('refresh')}</button>`)}
 <div class="scroll">
  ${general()?`<div class="card rise" style="--i:0">${tip('seedling',L('في الوضع العام لا نبني خطة شخصية، لكن يمكنك تصفح الوجبات وإضافتها لقائمة مشترياتك.','In general mode we don’t build a personal plan, but you can browse meals and add them to your shopping list.'))}</div>`:''}
  <div class="row rise" style="--i:0;gap:4px">${DAYS.map((x,i)=>`<button class="press" data-act="pday" data-v="${i}" style="flex:1;display:flex;flex-direction:column;align-items:center;gap:3px;padding:8px 0;border-radius:16px;font-size:11.5px;font-weight:600;${i===d?'background:var(--brand);color:var(--on-brand)':'background:var(--surface);border:1px solid var(--line);color:var(--fg-2)'}"><span>${L(x[0].replace('ال',''),x[1])}</span><b class="num" style="font-size:15px">${x[2]}</b></button>`).join('')}</div>
  <div class="card rise" style="--i:1"><div class="between"><h2>${L('سعرات الأسبوع المخطط','Planned calories this week')}</h2><span class="faint num">${L('الهدف','Target')} ${fmt(t.kcal)}</span></div>
   <svg class="chart" viewBox="0 0 ${bw} ${bh+18}" style="margin-top:8px"><rect x="0" y="${bh-(t.kcal*1.1)/mx*bh}" width="${bw}" height="${(t.kcal*0.2)/mx*bh}" fill="color-mix(in srgb,var(--ok) 14%,transparent)" rx="4"/>
   ${wk.map((k,i)=>{const x=rtl()?bw-(i+1)*slot+slot*.22:i*slot+slot*.22,h=k/mx*bh;return `<rect class="barg" x="${x}" y="${bh-h}" width="${slot*.56}" height="${h}" rx="7" fill="${i===d?'var(--brand)':'color-mix(in srgb,var(--brand) 35%,transparent)'}"/><text x="${x+slot*.28}" y="${bh+14}" text-anchor="middle">${DAYS[i][2]}</text>`}).join('')}</svg></div>
  <div class="row rise" style="--i:2;gap:10px"><button class="card tint press grow" style="--tc:var(--kcal);padding:14px;text-align:start" data-go="shop"><div class="row">${E('shopping-cart',34)}<div class="grow"><b>${L('قائمة المشتريات','Shopping list')}</b><div class="faint">${L('من خطة الأسبوع','From this week’s plan')}</div></div></div></button>
   <button class="card tint press grow" style="--tc:var(--protein);padding:14px;text-align:start" data-act="favlist"><div class="row">${E('red-heart',30)}<div class="grow"><b>${L('مفضلاتي','Favourites')}</b><div class="faint num">${Object.keys(S.favs).filter(k=>S.favs[k]).length} ${L('وجبات','meals')}</div></div></div></button></div>
  <div class="sec rise" style="--i:3"><h3>${L(DAYS[d][0],DAYS[d][1])} · <span class="num">${fmt(Math.round(kc))}</span> ${L('سعرة','kcal')}</h3><span class="chip g">${E('check-mark-button',14)}${L('ضمن حدودك','Within your limits')}</span></div>
  ${['BREAKFAST','LUNCH','SNACK','DINNER'].map((s,i)=>{const m=day.m[i];return `<button class="meal rise press" style="--i:${i+4}" data-act="mealx" data-m="${m}"><span class="thumb" style="width:54px;height:54px;background:color-mix(in srgb,var(${MEALS[m].tc}) 16%,var(--surface-2))">${E(MEALS[m].e,36)}</span><span class="mm"><span class="faint" style="font-weight:600">${E(SLOT[s][0],14)} ${sl(s,d)} · <span class="num">${hm(windows(d)[s][0])}</span></span><span class="nm">${mname(m)}</span><span class="meta num">${fmt(MEALS[m].n.kcal)} ${L('سعرة','kcal')}</span></span>${I('chev','flip')}</button>`}).join('')}
 </div>${navbar()}</div>`;
}
/* ---------- shopping list (aggregated from the week plan) ---------- */
function shopItems(){const agg={};WEEK.forEach(w=>w.m.forEach(m=>MEALS[m].ing.forEach(g=>{const k=g[1];agg[k]=agg[k]||{ar:g[0],en:g[1],g:0,e:g[3],c:g[4]};agg[k].g+=g[2]*1.25})));return Object.values(agg)}
function shop(){
 const items=shopItems(),done=items.filter(i=>S.shop[i.en]).length;
 const q=g=>g>=1000?`${fmt(g/1000,1)} ${L('كغ','kg')}`:`${fmt(Math.round(g/10)*10)} ${L('غ','g')}`;
 return `<div class="screen ${S.anim?'anim '+S.nav:''}">${topbar(L('قائمة المشتريات','Shopping list'),L('محسوبة من وجبات أسبوعك','Calculated from your week’s meals'),`<button class="iconbtn press" data-go="plan" data-back="1" aria-label="${L('رجوع','Back')}">${I('back','flip')}</button>`)}
 <div class="scroll">
  <div class="card hero rise" style="--i:0"><div class="row" style="position:relative;z-index:1">${E('shopping-cart',46)}<div class="grow"><b style="font-size:18px">${L(`${done} من ${items.length} مشتريات`,`${done} of ${items.length} items`)}</b><div style="margin-top:8px;height:7px;border-radius:9px;background:rgba(255,255,255,.25)"><i style="display:block;height:100%;width:${done/items.length*100}%;background:#fff;border-radius:9px;transition:width .4s"></i></div></div>
  <button class="iconbtn press" data-act="share" style="background:rgba(255,255,255,.18);border-color:transparent;color:#fff" aria-label="${L('مشاركة','Share')}">${I('share')}</button></div></div>
  ${Object.entries(CATS).map(([c,v],ci)=>{const its=items.filter(i=>i.c===c);if(!its.length)return '';return `<div class="card rise" style="--i:${ci+1};padding:8px 16px"><div class="row" style="padding:8px 0;font-weight:700">${E(v[0],22)}${L(v[1],v[2])}<span class="faint num">(${its.length})</span></div>
  ${its.map(i=>`<button class="shop press" role="checkbox" aria-checked="${!!S.shop[i.en]}" data-act="shopck" data-v="${i.en}"><span class="cbx">${I('check','',3)}</span>${E(i.e,26)}<span class="grow sn">${L(i.ar,i.en)}</span><span class="num faint">${q(i.g)}</span></button>`).join('')}</div>`}).join('')}
 </div>${navbar()}</div>`;
}
/* ---------- water ---------- */
function water(){
 const t=targets(),goal=t.water,tot=S.water.reduce((a,b)=>a+b.ml,0),p=goal?Math.min(1,tot/goal):Math.min(1,tot/2500),ses=sessions();
 const heart=S.o.care.includes('HEART_DISEASE')||S.scen.fluid;
 const lvl=190-170*p;
 let acc=0;const doneN=ses.filter(s=>{acc+=s.ml;return acc<=tot+1}).length;
 return `<div class="screen ${S.anim?'anim '+S.nav:''}">${offlineBar()}${topbar(L('الماء','Water'),TODAYSTR())}
 <div class="scroll">
  <div class="card rise" style="--i:0;padding:18px;overflow:hidden">
   <div class="bottle" id="bottle"><svg viewBox="0 0 150 200" aria-hidden="true"><defs><clipPath id="bclip"><path d="M48 10h54v18c0 6 18 14 18 34v118a14 14 0 0 1-14 14H44a14 14 0 0 1-14-14V62c0-20 18-28 18-34z"/></clipPath></defs>
    <path d="M48 10h54v18c0 6 18 14 18 34v118a14 14 0 0 1-14 14H44a14 14 0 0 1-14-14V62c0-20 18-28 18-34z" fill="color-mix(in srgb,var(--water) 8%,var(--surface))" stroke="color-mix(in srgb,var(--water) 45%,var(--line))" stroke-width="3"/>
    <g clip-path="url(#bclip)"><g style="transform:translateY(${lvl}px);transition:transform 1s cubic-bezier(.3,.7,.2,1)"><g style="animation:wave 3.5s linear infinite"><path d="M0 8 Q 18.75 0 37.5 8 T 75 8 T 112.5 8 T 150 8 T 187.5 8 T 225 8 T 262.5 8 T 300 8 V 220 H 0 Z" fill="var(--water)" opacity=".9"/></g>
    <g style="animation:wave 5s linear infinite reverse"><path d="M0 12 Q 18.75 4 37.5 12 T 75 12 T 112.5 12 T 150 12 T 187.5 12 T 225 12 T 262.5 12 T 300 12 V 220 H 0 Z" fill="var(--water)" opacity=".45"/></g></g></g>
    <rect x="52" y="2" width="46" height="12" rx="4" fill="color-mix(in srgb,var(--water) 45%,var(--line))"/></svg>
    <div style="position:absolute;inset:0;display:grid;place-items:center;padding-top:40px;text-align:center;color:${p>.45?'#fff':'var(--fg)'}"><div><b class="num" style="font-size:30px">${CU(tot)}</b><div style="font-size:12px;opacity:.85">${L('مل','ml')}</div></div></div></div>
   ${goal?`<div class="between" style="margin-top:14px"><span class="muted">${heart?L('الهدف الذي حدده طبيبك','Goal set by your doctor'):L('هدف اليوم','Today’s goal')}</span><b class="num">${fmt(goal)} ${L('مل','ml')}</b></div><div style="margin-top:8px">${bar(p,'var(--water)',9)}</div><div class="faint" style="text-align:center;margin-top:6px">${tot>=goal?L('أحسنت! وصلت هدفك اليوم','Well done! You reached today’s goal'):L(`متبقٍ ${fmt(goal-tot)} مل`,`${fmt(goal-tot)} ml to go`)}</div>`
   :`<div class="tip" style="margin-top:14px">${E('stethoscope',20)}<div>${L('إذا حدد لك طبيبك كمية يومية، أدخلها من حسابي لنتابعها معك.','If your doctor set a daily amount, add it in Me and we’ll track it with you.')}</div></div>`}</div>
  ${!heart||goal?`<div class="sec rise" style="--i:1"><h3>${L('جلسات الشرب','Drinking sessions')}</h3><span class="faint">${L(`${doneN} من ${ses.length}`,`${doneN} of ${ses.length}`)}</span></div>
  <div class="sess rise" style="--i:2">${ses.map((s,i)=>{const st=i<doneN?'done':(s.t<=S.now&&i===doneN)?'now':s.t<S.now?'miss':'';return `<div class="ses ${st}"><span class="num faint" style="font-weight:600">${hm(s.t)}</span>${E(st==='done'?'droplet':'potable-water',26)}<b class="num">${s.ml}</b><span class="faint" style="font-size:10.5px">${st==='done'?L('تمت','Done'):st==='now'?L('الآن','Now'):st==='miss'?L('فاتت','Missed'):L('لاحقًا','Later')}</span></div>`}).join('')}</div>`:''}
  <div class="rise" style="--i:3;display:grid;grid-template-columns:repeat(4,1fr);gap:8px">
   ${[[150,'teacup-without-handle',L('كوب صغير','Small cup')],[250,'tumbler-glass',L('كوب','Glass')],[500,'potable-water',L('زجاجة','Bottle')]].map(([v,e,l])=>`<button class="qa press" data-act="addw" data-v="${v}">${E(e,30)}<span class="num">${v}</span><span class="faint" style="font-size:11px;font-weight:600">${l}</span></button>`).join('')}
   <button class="qa press" data-act="wcustom" style="color:var(--water)">${E('straight-ruler',30)}<span>${L('مخصص','Custom')}</span><span class="faint" style="font-size:11px">${L('أي كمية','Any amount')}</span></button></div>
  <div class="rise" style="--i:4">${tip('light-bulb',L('الأفضل للجلسة الواحدة كوب إلى كوبين (250 إلى 500 مل)، موزعة على يومك، وآخرها قبل النوم بساعة.','One sitting is best at one to two glasses (250–500 ml), spread over your day, the last one an hour before sleep.'))}</div>
  <div class="card rise" style="--i:5;padding:4px 16px"><div class="li" style="font-weight:700">${L('سجل اليوم','Today’s log')}</div>
  ${S.water.slice().reverse().map((w,ix)=>`<div class="li">${E('droplet',22)}<div class="grow"><b class="num">${fmt(w.ml)} ${L('مل','ml')}</b><div class="faint num">${w.t}</div></div><button class="iconbtn press" style="width:38px;height:38px" data-act="delw" data-v="${S.water.length-1-ix}" aria-label="${L('حذف','Delete')}">${I('trash')}</button></div>`).join('')}</div>
 </div>${navbar()}</div>`;
}
/* ---------- progress: weekly report, weight, badges ---------- */
// badges follow the goal (muscle path gets protein and training badges) and the Arabic address follows the sex
function badges(){
 const b=[['first','fork-and-knife-with-plate',['أول وجبة','First meal'],[G('سجلت أول وجبة لك','سجّلتِ أول وجبة لكِ'),'You logged your first meal'],1],['streak3','fire',['3 أيام متتالية','3-day streak'],[G('التزمت بخطتك 3 أيام متتالية','التزمتِ بخطتكِ 3 أيام متتالية'),'You hit your plan 3 days in a row'],1],
 ['water','droplet',['بطل الماء','Water hero'],[G('وصلت هدف الماء 5 أيام','وصلتِ هدف الماء 5 أيام'),'Reached your water goal on 5 days'],1],['veg','broccoli',['محب الخضار','Veggie fan'],[G('أكلت 20 وجبة غنية بالألياف','أكلتِ 20 وجبة غنية بالألياف'),'Ate 20 high-fiber meals'],0.65],
 ['week','trophy',['أسبوع كامل','Full week'],[G('حققت هدف السعرات 7 أيام','حققتِ هدف السعرات 7 أيام'),'Hit your calorie target 7 days'],0.71],['kg','1st-place-medal',['أول 5 كغ','First 5 kg'],[G('خسرت أول 5 كغ نحو هدفك','خسرتِ أول 5 كغ نحو هدفكِ'),'Lost your first 5 kg'],0.8],
 ['explore','world-map',['مستكشف','Explorer'],[G('جربت 25 وجبة مختلفة','جرّبتِ 25 وجبة مختلفة'),'Tried 25 different meals'],0.44],['early','sunrise',['فطور في موعده','On-time breakfast'],[G('فطرت في موعدك 10 أيام','فطرتِ في موعدكِ 10 أيام'),'Breakfast on time for 10 days'],0.3],['month','crown',['شهر من الالتزام','A month strong'],['30 يومًا مع NutriGuide','30 days with NutriGuide'],0.17]];
 if(muscle()){b[3]=['protein7','flexed-biceps',['بطل البروتين','Protein hero'],[G('وصلت هدف البروتين 7 أيام','وصلتِ هدف البروتين 7 أيام'),'Hit your protein target 7 days'],0.86];
  b[5]=['train','person-lifting-weights',['أسبوع تمرين كامل','Full training week'],[G('أكلت قبل التمرين وبعده في كل أيام تمرينك','أكلتِ قبل التمرين وبعده في كل أيام تمرينكِ'),'Ate before and after every training session this week'],0.75];
  b[7]=['post','high-voltage',['تعافٍ ذكي','Smart recovery'],[G('سجلت وجبة بعد التمرين 10 مرات','سجّلتِ وجبة بعد التمرين 10 مرات'),'Logged a post-workout meal 10 times'],0.4]}
 return b;
}
function progress(){
 const tab=S.progTab,t=targets();
 const tabs=`<div class="seg rise" style="--i:0">${[['report',L('تقرير الأسبوع','Weekly report')],['weight',L('الوزن','Weight')],['badges',L('الإنجازات','Badges')]].map(([v,l])=>`<button data-act="ptab" data-v="${v}" aria-pressed="${tab===v}">${l}</button>`).join('')}</div>`;
 let body='';
 if(tab==='report'){
  const bw=320,bh=130,mx=2900,slot=bw/7,by=v=>bh-v/mx*bh;
  body=`<div class="card hero rise" style="--i:1;padding:18px"><div class="row" style="gap:16px;position:relative;z-index:1">${ring(.86,100,11,'#fff','rgba(255,255,255,.25)',`<b class="num" style="font-size:24px">86%</b>`)}<div class="grow"><div style="opacity:.9">${L(G('التزامك هذا الأسبوع','التزامكِ هذا الأسبوع'),'Your adherence this week')}</div><div style="font-size:22px;font-weight:700;line-height:1.3">${L('أسبوع ممتاز!','A great week!')} ${E('star-struck',24)}</div><div style="opacity:.9;font-size:13px">${L(G('5 أيام حققت فيها هدفك من 6','5 أيام حققتِ فيها هدفكِ من 6'),'You hit your target on 5 of 6 days')}</div></div></div></div>
  <div class="row" style="gap:8px"><div class="card tint rise" style="--i:2;--tc:var(--fat);flex:1;padding:12px">${E('trophy',28)}<div class="faint">${L('أفضل يوم','Best day')}</div><b>${L('الإثنين','Monday')}</b><div class="faint num">99% ${L('من الهدف','of target')}</div></div>
   <div class="card tint rise" style="--i:3;--tc:var(--fiber);flex:1;padding:12px">${E('leafy-green',28)}<div class="faint">${L('أكثر ما نقصك','Most missed')}</div><b>${L('الألياف','Fiber')}</b><div class="faint num">${L('متوسط','avg')} 24 / ${t.fiber} ${L('غ','g')}</div></div>
   <div class="card tint rise" style="--i:4;--tc:var(--water);flex:1;padding:12px">${E('droplet',28)}<div class="faint">${L('متوسط الماء','Avg water')}</div><b class="num">1,850</b><div class="faint">${L('مل يوميًا','ml a day')}</div></div></div>
  <div class="card rise" style="--i:5"><h2>${L('السعرات مقابل هدفك','Calories vs your target')}</h2><svg class="chart" viewBox="0 0 ${bw} ${bh+18}" style="margin-top:10px">
   <rect x="0" y="${by(t.kcal*1.1)}" width="${bw}" height="${by(t.kcal*0.9)-by(t.kcal*1.1)}" fill="color-mix(in srgb,var(--ok) 13%,transparent)" rx="4"/><line x1="0" x2="${bw}" y1="${by(t.kcal)}" y2="${by(t.kcal)}" stroke="var(--ok)" stroke-dasharray="4 4"/>
   ${KCALW.map((k,i)=>{const x=rtl()?bw-(i+1)*slot+slot*.2:i*slot+slot*.2,ok=Math.abs(k-t.kcal)<=t.kcal*.1;return `<rect x="${x}" y="${by(k)}" width="${slot*.6}" height="${bh-by(k)}" rx="7" fill="${ok?'var(--ok)':'var(--part)'}"/><text x="${x+slot*.3}" y="${bh+14}" text-anchor="middle">${L(DAYS[(i+3)%7][0].replace('ال','').slice(0,4),DAYS[(i+3)%7][1])}</text>`}).join('')}</svg>
   <div class="row faint" style="gap:14px;font-size:12px;margin-top:6px"><span class="row" style="gap:5px"><i style="width:10px;height:10px;border-radius:3px;background:var(--ok)"></i>${L('ضمن الهدف','On target')}</span><span class="row" style="gap:5px"><i style="width:10px;height:10px;border-radius:3px;background:var(--part)"></i>${L('قريب','Close')}</span><span class="row" style="gap:5px"><i style="width:10px;height:10px;border-radius:3px;background:color-mix(in srgb,var(--ok) 25%,transparent)"></i>${L('نطاق ±10%','±10% band')}</span></div></div>
  <div class="card rise" style="--i:6"><h2>${L('توزيع طاقتك','Where your energy came from')}</h2><div class="row" style="height:14px;border-radius:9px;overflow:hidden;margin:12px 0 8px;gap:2px"><i class="barv" style="height:100%;width:24%;background:var(--protein)"></i><i class="barv" style="height:100%;width:47%;background:var(--carb)"></i><i class="barv" style="height:100%;width:29%;background:var(--fat)"></i></div>
   <div class="between faint" style="font-size:12.5px"><span>${L('بروتين','Protein')} <b class="num">24%</b></span><span>${L('كربوهيدرات','Carbs')} <b class="num">47%</b></span><span>${L('دهون','Fat')} <b class="num">29%</b></span></div></div>
  <div class="card rise" style="--i:7"><div class="between"><h2>${L('أكتوبر','October')}</h2><span class="faint">${E('fire',16)} <span class="num">5</span> ${L('أيام متتالية','day streak')}</span></div><div class="cal" style="margin-top:10px">${Array.from({length:31},(_,i)=>{const s=i>12?null:['ok','ok','part','ok','miss','ok','ok'][(i*3+1)%7];return `<div style="background:${s==='ok'?'color-mix(in srgb,var(--ok) 22%,transparent)':s==='part'?'color-mix(in srgb,var(--part) 22%,transparent)':s==='miss'?'var(--surface-3)':'var(--surface-2)'};${i===12?'outline:2px solid var(--brand)':''}">${i+1}</div>`}).join('')}</div></div>`;
 }else if(tab==='weight'){
  const W=WEIGHTS,mn=Math.floor(Math.min(...W,S.o.tw)-2),mx=Math.ceil(Math.max(...W,S.o.tw)+2),w=320,h=170,pl=28,pr=8,pt=10,pb=22,n=W.length+6;
  const xs=i=>{const x=pl+(w-pl-pr)*i/(n-1);return rtl()?w-x:x},ys=v=>pt+(h-pt-pb)*(mx-v)/(mx-mn);
  const pts=W.map((v,i)=>`${xs(i)},${ys(v)}`).join(' '),proj=[W.length-1,n-1].map((i,j)=>`${xs(i)},${ys(j?W[W.length-1]+(S.o.tw-W[W.length-1])*.6:W[W.length-1])}`).join(' ');
  body=`<div class="row" style="gap:8px">${[[L('البداية','Start'),W[0],'flag'],[L('الآن','Now'),W[W.length-1],'balance-scale'],[L('الهدف','Goal'),S.o.tw,'bullseye']].map((x,i)=>`<div class="card rise" style="--i:${i+1};flex:1;padding:12px;text-align:center">${E(x[2]==='flag'?'chart-decreasing':x[2],24)}<div class="faint">${x[0]}</div><b class="num" style="font-size:19px">${fmt(x[1],1)}</b> <span class="faint">${L('كغ','kg')}</span></div>`).join('')}</div>
  <div class="card rise" style="--i:4"><div class="between"><h2>${L('مسار وزنك','Your weight trend')}</h2><span class="chip g num" dir="ltr">${W[W.length-1]<W[0]?'−':'+'}${fmt(Math.abs(W[0]-W[W.length-1]),1)} ${L('كغ','kg')}</span></div>
  <svg class="chart" viewBox="0 0 ${w} ${h}" style="margin-top:10px">${[0,1,2,3,4].map(k=>Math.round(mn+(mx-mn)*(k+.5)/5)).map(v=>`<line x1="${rtl()?pr:pl}" x2="${rtl()?w-pl:w-pr}" y1="${ys(v)}" y2="${ys(v)}" stroke="var(--line)"/><text x="${rtl()?w-2:2}" y="${ys(v)+3}" text-anchor="${rtl()?'end':'start'}">${v}</text>`).join('')}
   <line x1="${rtl()?pr:pl}" x2="${rtl()?w-pl:w-pr}" y1="${ys(S.o.tw)}" y2="${ys(S.o.tw)}" stroke="var(--ok)" stroke-dasharray="5 4"/>
   <polygon points="${xs(0)},${ys(mn)} ${pts} ${xs(W.length-1)},${ys(mn)}" fill="color-mix(in srgb,var(--brand) 14%,transparent)"/>
   <polyline points="${pts}" fill="none" stroke="var(--brand)" stroke-width="3" stroke-linejoin="round" stroke-linecap="round" style="stroke-dasharray:900;stroke-dashoffset:${S.anim?900:0};animation:${S.anim?'ringdraw 1.4s .2s both':'none'};--c:900"/>
   <polyline points="${proj}" fill="none" stroke="var(--brand)" stroke-width="2" stroke-dasharray="3 5" opacity=".6"/>
   <circle cx="${xs(W.length-1)}" cy="${ys(W[W.length-1])}" r="6" fill="var(--brand)" stroke="var(--surface)" stroke-width="3"/>
   ${[0,5,11].map(i=>`<text x="${xs(i)}" y="${h-4}" text-anchor="middle">${L('أ','W')}${i+1}</text>`).join('')}</svg>
   <div class="faint" style="margin-top:6px">${L('الخط المتقطع: تقدير الوصول لهدفك بالوتيرة الحالية','Dashed line: estimate to your goal at the current pace')}</div></div>
  <button class="btn block press rise" style="--i:5" data-act="weight">${E('balance-scale',22)}${L(G('سجّل وزنك اليوم','سجّلي وزنكِ اليوم'),'Log today’s weight')}</button>`;
 }else{
  body=`<div class="card tint rise" style="--i:1;--tc:var(--fat)"><div class="row">${E('trophy',44)}<div class="grow"><b style="font-size:17px">${L('3 إنجازات من 9','3 of 9 badges')}</b><div class="faint">${L('التالي: أسبوع كامل (5 من 7 أيام)','Next: full week (5 of 7 days)')}</div></div></div></div>
  <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:10px">${badges().map((b,i)=>`<button class="badgecell rise press ${b[4]>=1?'got':'lock'}" style="--i:${i+2}" data-act="badge" data-v="${b[0]}">${E(b[1],44)}<span>${L(b[2][0],b[2][1])}</span>${b[4]<1?`<div style="width:100%">${bar(b[4],'var(--fat)',5)}</div>`:''}</button>`).join('')}</div>`;
 }
 return `<div class="screen ${S.anim?'anim '+S.nav:''}">${offlineBar()}${topbar(L('تقدمي','My progress'),L('11 – 17 أكتوبر','11–17 October'))}<div class="scroll">${tabs}${body}</div>${navbar()}</div>`;
}
/* ---------- profile ---------- */
function profile(){
 const o=S.o,t=targets();
 const row=(e,l,v,act)=>`<button class="li press" ${act||''}>${E(e,26)}<span class="grow" style="font-weight:600">${l}</span><span class="faint">${v}</span>${I('chev','flip')}</button>`;
 const tg=(k,e,l)=>`<div class="li">${E(e,26)}<span class="grow" style="font-weight:600">${l}</span><button class="tgl" role="switch" aria-checked="${S.rem[k]}" data-act="rem" data-v="${k}" aria-label="${l}"></button></div>`;
 const seg=(key,opts)=>`<div class="seg">${opts.map(([v,l,ic])=>`<button data-act="${key}" data-v="${v}" aria-pressed="${S[key]===v}">${ic?I(ic).replace('class="ic ','style="width:16px;height:16px;margin-inline-end:4px" class="ic '):''}${l}</button>`).join('')}</div>`;
 return `<div class="screen ${S.anim?'anim '+S.nav:''}">${topbar(L('حسابي','Me'),'')}<div class="scroll">
 <div class="card hero rise" style="--i:0"><div class="row" style="position:relative;z-index:1;gap:14px"><span class="thumb" style="width:64px;height:64px;background:rgba(255,255,255,.2)">${E(avatar(),46)}</span><div class="grow"><b style="font-size:19px">${o.name}</b><div style="opacity:.9;font-size:13px">ahmed@example.com</div></div>
  <div style="text-align:center"><b class="num" style="font-size:20px">${E('fire',18)} 5</b><div style="opacity:.85;font-size:11px">${L('أيام','days')}</div></div></div></div>
 <div class="card rise" style="--i:1;padding:4px 16px">${row('bullseye',L('هدفي','My goal'),L({LOSE:'إنقاص الوزن',MAINTAIN:'المحافظة',GAIN:'الزيادة',MUSCLE:'بناء العضلات'}[o.goal],{LOSE:'Lose',MAINTAIN:'Maintain',GAIN:'Gain',MUSCLE:'Build muscle'}[o.goal]),'data-act="editOnb"')}
  ${row('straight-ruler',L('الطول والوزن','Height and weight'),`<span class="num">${o.h} · ${o.w}</span>`,'data-act="editOnb"')}${row('person-biking',L('نشاطي','Activity'),'','data-act="editOnb"')}${muscle()?row('person-lifting-weights',L('تمريني','My training'),`<span class="num">${TDAYS[o.tdays].length} ${L('أيام','days')} · ${hm(o.ttime)}</span>`,'data-act="editTrain"'):''}
  ${row('herb',L('ما نراعيه في أكلي','What we keep in mind'),o.care.length?o.care.length+'':L('لا شيء','None'),'data-act="editOnb"')}${row('shield',L('ما أتجنبه','What I avoid'),Object.keys(o.allergy).length+'','data-act="editOnb"')}</div>
 <div class="card rise" style="--i:2"><div class="between"><h2>${E('alarm-clock',22)} ${L('مواعيد يومي','My daily rhythm')}</h2><button class="link" data-act="editRhythm">${L('تعديل','Edit')}</button></div>
  <div class="row" style="gap:8px;margin-top:10px">${Object.entries(windows()).map(([s,[a]])=>`<div style="flex:1;text-align:center;padding:8px 2px;border-radius:14px;background:var(--surface-2)">${E(SLOT[s][0],22)}<div class="num" style="font-weight:700;font-size:13px">${hm(a)}</div></div>`).join('')}</div>
  <div class="faint" style="margin-top:8px">${L(`أستيقظ ${hm(o.wake)} · أنام ${hm(o.sleep)}`,`Wake ${hm(o.wake)} · Sleep ${hm(o.sleep)}`)}</div></div>
 <div class="card rise" style="--i:3;padding:4px 16px">${row('red-heart',L('وجباتي المفضلة','Favourite meals'),Object.keys(S.favs).filter(k=>S.favs[k]).length+'','data-act="favlist"')}${row('thumbs-down',L('وجبات لا أحبها','Meals I don’t like'),Object.keys(S.nope).filter(k=>S.nope[k]).length+'','data-act="favlist"')}</div>
 <div class="card rise" style="--i:4;padding:4px 16px"><div class="li" style="font-weight:700">${E('bell',22)} ${L('التذكيرات','Reminders')}</div>${tg('meals','fork-and-knife',L('مواعيد الوجبات','Meal times'))}${tg('water','droplet',L('جلسات الماء','Water sessions'))}${tg('weight','balance-scale',L('وزن أسبوعي','Weekly weigh-in'))}</div>
 <div class="card rise" style="--i:5"><h2>${E('artist-palette',22)} ${L('لمساتك','Your touches')}</h2>
  <div class="faint" style="font-weight:700;margin-top:10px">${L('رسمتك','Your avatar')}</div>
  <div class="row" style="gap:8px;margin-top:8px">${AVATARS[o.sex].map(a=>`<button class="press" data-act="avatar" data-v="${a}" aria-pressed="${avatar()===a}" style="flex:1;height:58px;border-radius:18px;display:grid;place-items:center;border:2px solid ${avatar()===a?'var(--brand)':'var(--line)'};background:${avatar()===a?'var(--brand-soft)':'var(--surface)'}">${E(a,36)}</button>`).join('')}</div>
  <div class="faint" style="font-weight:700;margin-top:14px">${L('لون التطبيق','App colour')}</div>${swatches()}
  <div class="faint" style="margin-top:10px;font-size:12.5px">${L('اللون يتبع هدفك تلقائيًا، وألوان البروتين والسعرات والماء ثابتة دائمًا حتى لا تختلط المعاني.','The colour follows your goal by default; protein, calorie and water colours never change so their meaning stays clear.')}</div></div>
 <div class="card rise col" style="--i:5"><div class="faint" style="font-weight:700">${L('اللغة','Language')}</div>${seg('lang',[['ar','العربية'],['en','English']])}<div class="faint" style="font-weight:700">${L('المظهر','Appearance')}</div>${seg('mode',[['light',L('فاتح','Light'),'sun'],['dark',L('ليلي','Dark'),'moon'],['auto',L('تلقائي','Auto'),'auto']])}</div>
 <div class="rise" style="--i:6">${tip('seedling',L('NutriGuide يساعدك على الأكل الصحي ولا يغني عن استشارة طبيبك أو أخصائي التغذية.','NutriGuide helps you eat well and does not replace your doctor or dietitian.'))}</div>
 <button class="btn ghost block press rise" style="--i:7" data-go="welcome" data-back="1">${I('logout','flip')}${L('تسجيل الخروج','Sign out')}</button>
 </div>${navbar()}</div>`;
}
function favSheet(){
 const f=Object.keys(S.favs).filter(k=>S.favs[k]),n=Object.keys(S.nope).filter(k=>S.nope[k]);
 const li=(m,act)=>`<div class="li">${E(MEALS[m].e,30)}<span class="grow" style="font-weight:600">${mname(m)}</span><button class="iconbtn press" style="width:38px;height:38px" data-act="${act}" data-m="${m}" aria-label="${L('إزالة','Remove')}">${I('x')}</button></div>`;
 return `<div class="scrim" data-act="close"><div class="sheet" role="dialog" aria-modal="true" data-stop><div class="grab"></div>
 <h2 style="font-size:20px">${E('red-heart',22)} ${L('وجباتي المفضلة','Favourite meals')}</h2><p class="faint" style="margin:-8px 0 0">${L('يقترحها المحرك أكثر في خطتك','The engine suggests these more often')}</p>
 <div>${f.length?f.map(m=>li(m,'fav')).join(''):`<p class="faint">${L('لا توجد بعد. اضغط القلب في أي وجبة.','None yet. Tap the heart on any meal.')}</p>`}</div>
 <h2 style="font-size:18px">${E('thumbs-down',20)} ${L('لا أحبها','I don’t like')}</h2><p class="faint" style="margin:-8px 0 0">${L('لن تظهر في خطتك','They won’t appear in your plan')}</p>
 <div>${n.length?n.map(m=>li(m,'nope')).join(''):`<p class="faint">${L('لا توجد.','None.')}</p>`}</div></div></div>`;
}
