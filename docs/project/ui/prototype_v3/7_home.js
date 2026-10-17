/* ---------- home ---------- */
function eatenTotals(){const o={kcal:0,protein:0,carb:0,fat:0,fiber:0};TODAY.forEach(it=>{if(S.eaten[it.id]||S.scen.complete){const n=nOf(it.m,S.mult[it.id]||it.x);for(const k in o)o[k]+=n[k]}});return o}
function mealState(it){
 const w=windows()[it.slot];if(S.eaten[it.id]||S.scen.complete)return 'done';
 if(S.now>=w[0]&&S.now<=w[1])return 'now';if(S.now>w[1])return S.scen.late||it.slot==='BREAKFAST'?'late':'late';return 'next';
}
function mealCard(it,i){
 const m=MEALS[it.m],x=S.mult[it.id]||it.x,n=nOf(it.m,x),st=mealState(it),w=windows()[it.slot];
 const stl=st==='done'?`<span class="badge" style="background:color-mix(in srgb,var(--ok) 16%,transparent);color:var(--ok)">${I('check','',3).replace('class="ic ','style="width:12px;height:12px" class="ic ')}${L('تمت','Done')}</span>`:st==='now'?`<span class="badge" style="background:color-mix(in srgb,var(--kcal) 16%,transparent);color:var(--kcal)">${L('الآن','Now')}</span>`:st==='late'?`<span class="badge" style="background:color-mix(in srgb,var(--warn) 16%,transparent);color:var(--warn)">${L('فات موعدها','Missed window')}</span>`:'';
 return `<div class="tlrow rise" style="--i:${i}"><div class="tltime"><span class="tldot ${st}"></span><span class="num faint" style="font-size:11.5px">${hm(w[0])}</span></div>
 <div class="meal"><button class="row grow press" style="gap:12px;text-align:start;min-width:0" data-act="meal" data-id="${it.id}">
  <span class="thumb" style="width:60px;height:60px;background:color-mix(in srgb,var(${m.tc}) 16%,var(--surface-2))">${E(m.e,40)}</span>
  <span class="mm"><span class="row" style="gap:6px"><span class="faint" style="font-weight:600">${sl(it.slot)}</span>${stl}${S.favs[it.m]?`<span style="color:var(--protein)">${I('heartf').replace('class="ic ','style="width:14px;height:14px" class="ic ')}</span>`:''}</span>
  <span class="nm">${mname(it.m)}</span>
  <span class="meta"><span class="num">${fmt(n.kcal)} ${L('سعرة','kcal')}</span>·<span class="num">≈ ${fmt(gOf(it.m,x))} ${L('غ','g')}</span>·<span>${E('stopwatch',13)} <span class="num">${m.min}</span> ${L('د','min')}</span></span>
  <span class="chips">${reasonsFor(it).slice(0,2).map(reasonChip).join('')}</span></span></button>
 <button class="eat ${st==='done'?'done':''}" data-act="eat" data-id="${it.id}" aria-label="${st==='done'?L('تراجع','Undo'):L('أكلتها','I ate it')}">${I(st==='done'?'check':'plus','',2.4)}</button></div></div>`;
}
function home(){
 const t=targets(),e=eatenTotals(),gen=general();
 const left=Math.max(0,t.kcal-e.kcal),show=S.kmode==='eaten'?e.kcal:left,p=e.kcal/t.kcal;
 const wTot=S.water.reduce((a,b)=>a+b.ml,0),wGoal=t.water;
 const cur=TODAY.find(it=>mealState(it)==='now'),late=TODAY.find(it=>mealState(it)==='late');
 const days=DAYS.map((d,i)=>{const s=i<2?WEEK[i].st:i===2?(S.scen.complete?'ACHIEVED':'TODAY'):null;const col=s==='ACHIEVED'?'var(--ok)':s==='PARTIAL'?'var(--part)':'var(--line)';
  return `<button class="press" data-act="pday" data-v="${i}" style="flex:1;display:flex;flex-direction:column;align-items:center;gap:4px;font-size:11px;color:${i===2?'var(--brand)':'var(--fg-3)'};font-weight:600">
  <span>${L(d[0].replace('ال',''),d[1])}</span><span style="position:relative;width:36px;height:36px;border-radius:13px;display:grid;place-items:center;font-family:var(--font-num);font-size:14px;${i===2?'background:var(--brand);color:var(--on-brand)':`border:2px ${s?'solid':'dashed'} ${col};color:var(--fg)`}">${d[2]}${muscle()&&(TDAYS[S.o.tdays]||[]).includes(i)?`<span style="position:absolute;bottom:-7px;inset-inline-end:-6px">${E('person-lifting-weights',16)}</span>`:''}</span></button>`}).join('');
 const macro=(e2,lab,v,g,c,i)=>`<div class="card tint rise" style="--i:${i};--tc:var(${c});flex:1;padding:12px;min-width:0"><div class="row" style="gap:6px;font-size:12.5px;font-weight:600">${E(e2,18)}${lab}</div>
  <div style="margin:8px 0 6px">${bar(S.kmode==='eaten'?v/g:Math.max(0,1-v/g),`var(${c})`,6)}</div><div class="num" style="font-size:13px"><b style="font-size:16px">${fmt(S.kmode==='eaten'?v:Math.max(0,g-v))}</b> / ${fmt(g)}${L('غ','g')}</div></div>`;
 return `<div class="screen ${S.anim?'anim '+S.nav:''}">${offlineBar()}
 <header class="top" style="padding-bottom:4px"><span class="thumb" style="width:46px;height:46px;border-radius:16px;background:var(--brand-soft)">${E(avatar(),32)}</span><div class="grow"><div class="faint">${TODAYSTR()}</div><h1 style="font-size:20px">${greet()}، ${S.o.name} ${E('waving-hand',22)}</h1></div>
  <button class="pill press" data-act="streak" style="color:var(--kcal);border-color:color-mix(in srgb,var(--kcal) 35%,var(--line))">${E('fire',18)}<b class="num">5</b></button>
  <button class="iconbtn press" data-act="notify" aria-label="${L('الإشعارات','Notifications')}">${I('bell')}<span class="dot"></span></button></header>
 <div class="scroll">
  <div class="row rise" style="--i:0;gap:4px;padding-top:4px">${days}</div>
  ${S.scen.late&&late?`<div class="card rise" style="--i:1;padding:12px 14px;border-color:color-mix(in srgb,var(--warn) 40%,var(--line));background:color-mix(in srgb,var(--warn) 8%,var(--surface))"><div class="row">${E('alarm-clock',30)}<div class="grow"><b>${L(G(`فاتك موعد ${sl(late.slot)}`,`فاتكِ موعد ${sl(late.slot)}`),`You missed ${SLOT[late.slot][2].toLowerCase()}`)}</b><div class="faint">${L(G('هل أكلتها؟ سجلها الآن حتى يبقى يومك دقيقًا','هل أكلتِها؟ سجّليها الآن حتى يبقى يومكِ دقيقًا'),'Did you eat it? Log it so your day stays accurate')}</div></div><button class="btn sm press" data-act="eat" data-id="${late.id}">${L(G('سجّل','سجّلي'),'Log')}</button></div></div>`:''}
  ${gen?`<div class="card rise" style="--i:1"><div class="row">${E('seedling',40)}<div class="grow"><b>${L('الوضع العام','General mode')}</b><div class="faint">${L('تسجل أكلك وماءك وترى تقدمك. لا توجد خطة سعرات شخصية.','You log food and water and see progress. No personal calorie plan.')}</div></div></div></div>`:`
  ${muscle()?trainCard()+proteinCard(e,t):''}
  <div class="card tint rise" style="--i:1;--tc:var(--kcal);padding:18px">
   <div class="between"><div class="row" style="gap:6px;font-weight:700">${E('fire',22)}${L('السعرات','Calories')}</div>
   <div class="seg" style="padding:3px;border-radius:13px;width:170px">${[['eaten',L('المستهلك','Eaten')],['left',L('المتبقي','Left')]].map(([v,l])=>`<button style="padding:5px 4px;font-size:12.5px;border-radius:10px" data-act="kmode" data-v="${v}" aria-pressed="${S.kmode===v}">${l}</button>`).join('')}</div></div>
   <div class="row" style="gap:16px;margin-top:12px">${ring(S.kmode==='eaten'?p:1-p,108,12,'var(--kcal)','color-mix(in srgb,var(--kcal) 16%,transparent)',`<div><b class="num" style="font-size:20px">${Math.round((S.kmode==='eaten'?p:1-p)*100)}%</b></div>`)}
    <div class="grow"><div style="font-size:38px;font-weight:700;line-height:1.1">${CU(Math.round(show))}</div><div class="muted">${S.kmode==='eaten'?L(G('سعرة أكلتها اليوم','سعرة أكلتِها اليوم'),'kcal eaten today'):L('سعرة متبقية لك','kcal left today')}</div>
    <div class="faint num" style="margin-top:4px">${L('من هدف','of a')} ${fmt(t.kcal)} ${L('سعرة','kcal target')}</div></div></div></div>
  <div class="row" style="gap:8px">${macro('poultry-leg',L('بروتين','Protein'),e.protein,t.protein,'--protein',2)}${macro('bread',L('كربوهيدرات','Carbs'),e.carb,t.carb,'--carb',3)}${macro('avocado',L('دهون','Fat'),e.fat,t.fat,'--fat',4)}</div>`}
  ${cur&&!gen?`<button class="card hero rise press" style="--i:5;text-align:start;padding:16px" data-act="meal" data-id="${cur.id}"><div class="row" style="position:relative;z-index:1;gap:14px"><span class="thumb" style="width:64px;height:64px;background:rgba(255,255,255,.18)">${E(MEALS[cur.m].e,44,'')}</span>
   <div class="grow"><div style="opacity:.9;font-size:13px">${L(`وقت ${sl(cur.slot)} الآن · حتى`,`${sl(cur.slot)} time · until`)} <span class="num">${hm(windows()[cur.slot][1])}</span></div><div style="font-weight:700;font-size:17px">${mname(cur.m)}</div>
   <div style="margin-top:8px;height:6px;border-radius:9px;background:rgba(255,255,255,.25)"><i style="display:block;height:100%;border-radius:9px;background:#fff;width:${(S.now-windows()[cur.slot][0])/(windows()[cur.slot][1]-windows()[cur.slot][0])*100}%"></i></div></div>${I('chev','flip')}</div></button>`:''}
  <button class="card rise press" style="--i:6;text-align:start;padding:14px" data-go="water"><div class="row" style="gap:14px">${ring(wGoal?wTot/wGoal:0.5,56,7,'var(--water)','color-mix(in srgb,var(--water) 16%,transparent)',E('droplet',22))}
   <div class="grow"><b>${L('الماء','Water')}</b><div class="faint num">${fmt(wTot)} ${wGoal?'/ '+fmt(wGoal):''} ${L('مل','ml')}</div><div class="row" style="gap:3px;margin-top:6px">${sessions().map(s=>`<i style="width:14px;height:5px;border-radius:9px;background:${s.t<S.now&&wTot>=0?'var(--water)':'color-mix(in srgb,var(--water) 20%,transparent)'}"></i>`).join('')}</div></div>
   <span class="btn sm soft" data-act="addw" data-v="250" style="color:var(--water);background:color-mix(in srgb,var(--water) 14%,transparent)">+250</span></div></button>
  ${gen?`<div class="sec"><h3>${L('وجبات صحية لتجربتها','Healthy meals to try')}</h3></div><div class="row" style="gap:10px;overflow-x:auto;padding-bottom:6px">${['D02','L04','S04','B09','L09'].map((m,i)=>`<button class="card rise press" style="--i:${i+7};flex:none;width:150px;padding:12px;text-align:start" data-act="mealx" data-m="${m}"><span class="thumb" style="width:100%;height:80px;background:color-mix(in srgb,var(${MEALS[m].tc}) 14%,var(--surface-2))">${E(MEALS[m].e,52)}</span><div style="font-weight:700;font-size:14px;margin-top:8px;line-height:1.35">${mname(m)}</div><div class="faint num">${fmt(MEALS[m].n.kcal)} ${L('سعرة','kcal')}</div></button>`).join('')}</div>`:`
  <div class="sec"><h3>${L('وجبات اليوم','Today’s meals')}</h3><button class="link" data-go="plan">${L('الخطة كاملة','Full plan')}</button></div>
  <div class="tl">${TODAY.map((it,i)=>mealCard(it,i+7)).join('')}</div>`}
 </div>
 <button class="fab press" data-act="quick" aria-label="${L('إضافة','Add')}">${I('plus','',2.4)}</button>${navbar()}</div>`;
}
/* ---------- v3: muscle-building home cards ---------- */
function trainCard(){
 const tr=training(),w=windows();
 if(!tr.on)return `<div class="card tint rise" style="--i:1;--tc:var(--brand);padding:14px"><div class="row" style="gap:12px">${E(G('man-in-lotus-position','woman-in-lotus-position'),40)}<div class="grow"><b>${L('يوم راحة','Rest day')}</b><div class="faint">${L('عضلاتك تُبنى وقت الراحة. بروتين اليوم مهم مثل أيام التمرين.','Muscle is built while you rest. Today’s protein matters as much as on training days.')}</div></div></div></div>`;
 const pre=tr.snack==='PRE'?['SNACK',w.SNACK[0]]:null,post=tr.post?[tr.post,w[tr.post][0]]:['SNACK',w.SNACK[0]];
 const node=(e,lab,t,big)=>`<div style="flex:1;text-align:center;position:relative;z-index:1"><div style="width:${big?56:44}px;height:${big?56:44}px;margin:0 auto;border-radius:18px;display:grid;place-items:center;background:rgba(255,255,255,${big?.25:.15})">${E(e,big?34:26)}</div><div style="font-size:12px;opacity:.9;margin-top:4px">${lab}</div><b class="num" style="font-size:14px">${hm(t)}</b></div>`;
 return `<div class="card hero rise" style="--i:1;padding:16px"><div class="between" style="position:relative;z-index:1"><b style="font-size:16px">${E('high-voltage',20)} ${L('اليوم يوم تمرين','Training day today')}</b><span class="badge" style="background:rgba(255,255,255,.2);color:#fff">${L(`${TDAYS[S.o.tdays].length} أيام أسبوعيًا`,`${TDAYS[S.o.tdays].length} days a week`)}</span></div>
 <div class="row" style="margin-top:12px;align-items:flex-start;position:relative">
  <i style="position:absolute;top:26px;inset-inline:16%;height:2px;background:rgba(255,255,255,.35)"></i>
  ${pre?node('banana',L('قبل التمرين','Before'),pre[1]):''}${node(avatar(),L('التمرين','Training'),tr.T,1)}${node('poultry-leg',L('بعد التمرين','After'),post[1])}</div></div>`;
}
function proteinCard(e,t){
 const p=e.protein/t.protein;
 const dots=TODAY.filter(it=>MAIN.includes(it.slot)).map(it=>{const g=nOf(it.m,S.mult[it.id]||it.x).protein,ok=g>=t.pmeal,done=S.eaten[it.id]||S.scen.complete;
  return `<div style="flex:1;text-align:center;padding:8px 2px;border-radius:14px;background:${done?'color-mix(in srgb,var(--protein) 16%,var(--surface))':'var(--surface-2)'}">${E(SLOT[it.slot][0],18)}<div class="num" style="font-weight:700;font-size:13px;color:${ok?'var(--protein)':'var(--part)'}">${fmt(g)}${L('غ','g')}</div><div style="font-size:10.5px;color:var(--fg-3)">${done?L('أكلتها','Eaten'):L('مخطط','Planned')}</div></div>`}).join('');
 return `<div class="card tint rise" style="--i:1;--tc:var(--protein);padding:16px">
 <div class="between"><div class="row" style="gap:6px;font-weight:700">${E('flexed-biceps',22)}${L('بروتين اليوم','Today’s protein')}</div><span class="faint num">${L('الحد الأعلى','Upper limit')} ${fmt(t.pmax)}${L('غ','g')}</span></div>
 <div class="row" style="gap:16px;margin-top:10px">${ring(p,96,11,'var(--protein)','color-mix(in srgb,var(--protein) 16%,transparent)',`<b class="num" style="font-size:18px">${Math.round(p*100)}%</b>`)}
  <div class="grow"><div style="font-size:34px;font-weight:700;line-height:1.1">${CU(Math.round(e.protein))}<small style="font-size:15px"> / ${fmt(t.protein)}${L('غ','g')}</small></div><div class="muted">${L('25 غ أو أكثر في كل وجبة رئيسية','25 g or more in every main meal')}</div></div></div>
 <div class="row" style="gap:6px;margin-top:12px">${dots}</div></div>`;
}
