/* ---------- meal detail sheet ---------- */
const plateWord=x=>({0.5:L('نصف طبق','Half a plate'),1:L('طبق واحد','One plate'),1.5:L('طبق ونصف','A plate and a half'),2:L('طبقان','Two plates')})[x];
function plates(x){let s='';let r=x;while(r>0){const f=Math.min(1,r);s+=`<svg width="44" height="44" viewBox="0 0 44 44" aria-hidden="true"><circle cx="22" cy="22" r="20" fill="var(--surface)" stroke="var(--line)" stroke-width="2"/><circle cx="22" cy="22" r="14" fill="none" stroke="var(--line)" stroke-width="1"/>${f>=1?'<circle cx="22" cy="22" r="13" fill="color-mix(in srgb,var(--brand) 55%,transparent)"/>':'<path d="M22 9a13 13 0 0 1 0 26z" fill="color-mix(in srgb,var(--brand) 55%,transparent)"/>'}</svg>`;r-=1}return s}
function mealSheet(sh){
 const it=sh.id?TODAY.find(i=>i.id===sh.id):null,m=it?it.m:sh.m,M=MEALS[m],x=it?(S.mult[it.id]||it.x):1,n=nOf(m,x),t=targets();
 const pk=n.protein*4,ck=n.carb*4,fk=n.fat*9,tot=pk+ck+fk,C=2*Math.PI*30;let off=0;
 const seg=(v,c)=>{const l=v/tot*C,s=`<circle cx="40" cy="40" r="30" fill="none" stroke="var(${c})" stroke-width="12" stroke-dasharray="${l} ${C-l}" stroke-dashoffset="${-off}"/>`;off+=l;return s};
 const lim=(lab,v,max,u)=>{const p=v/max;return `<div class="col" style="gap:6px"><div class="between" style="font-size:14px"><span>${lab}</span><span class="faint"><b class="num" style="color:var(--fg)">${fmt(v)}</b> ${u} · <span class="num">${fmt(p*100)}%</span> ${L('من حدك اليومي','of daily limit')}</span></div>${bar(p,p>.5?'var(--part)':'var(--ok)',7)}</div>`};
 const mine=Object.keys(S.o.allergy).filter(a=>M.al.includes(a));
 return `<div class="scrim" data-act="close"><div class="sheet ${sh.still?'still':''}" role="dialog" aria-modal="true" aria-label="${mname(m)}" data-stop>
 <div class="grab"></div>
 <div style="position:relative;border-radius:26px;height:170px;background:radial-gradient(circle at 50% 40%,color-mix(in srgb,var(${M.tc}) 30%,var(--surface)),color-mix(in srgb,var(${M.tc}) 10%,var(--surface)));display:grid;place-items:center;overflow:hidden">
  <span style="animation:floaty 4s ease-in-out infinite">${E(M.e,104)}</span>
  ${M.ing.slice(0,4).map((g,i)=>`<span style="position:absolute;${['top:16px;inset-inline-start:18px','top:22px;inset-inline-end:24px','bottom:18px;inset-inline-start:34px','bottom:14px;inset-inline-end:30px'][i]};opacity:.9;animation:floaty ${3+i*.6}s ease-in-out infinite">${E(g[3],30)}</span>`).join('')}
  <div class="row" style="position:absolute;top:12px;inset-inline-end:12px;gap:8px;display:none"></div></div>
 <div class="between" style="align-items:flex-start"><div><h2 style="font-size:21px;line-height:1.35">${mname(m)}</h2>
  <div class="row faint" style="gap:8px;margin-top:2px">${it?`<span>${E(SLOT[it.slot][0],16)} ${sl(it.slot)} · <span class="num">${hm(windows()[it.slot][0])}–${hm(windows()[it.slot][1])}</span></span>`:''}<span>${E('stopwatch',14)} <span class="num">${M.min}</span> ${L('دقيقة','min')}</span></div></div>
  <div class="row" style="gap:8px"><button class="iconbtn press" data-act="fav" data-m="${m}" aria-pressed="${!!S.favs[m]}" aria-label="${L('مفضلة','Favourite')}" style="${S.favs[m]?'color:var(--protein);border-color:color-mix(in srgb,var(--protein) 40%,var(--line))':''}">${I(S.favs[m]?'heartf':'heart')}</button></div></div>
 ${mine.length?`<div class="tip" style="background:color-mix(in srgb,var(--danger) 12%,var(--surface));border-color:color-mix(in srgb,var(--danger) 35%,transparent)">${E('warning',20)}<div><b>${L('تحتوي على','Contains')} ${mine.map(a=>L(ALG[a][1],ALG[a][2])).join('، ')}</b><div class="faint">${L('مما سجلت أنك تتجنبه','which you said you avoid')}</div></div></div>`:''}
 <div class="card flat"><div class="between"><div><div class="faint">${L('كميتك','Your portion')}</div><div style="font-weight:700;font-size:18px">${plateWord(x)} · <span class="num">≈ ${fmt(gOf(m,x))} ${L('غ','g')}</span></div></div><div class="row" style="gap:2px">${plates(x)}</div></div>
  ${it?`<div class="seg" style="margin-top:12px">${[0.5,1,1.5,2].map(v=>`<button data-act="mult" data-id="${it.id}" data-v="${v}" aria-pressed="${x===v}"><span class="num">×${v}</span></button>`).join('')}</div>`:''}
  <div class="faint" style="margin-top:8px;display:flex;gap:6px">${I('info')}${L('عدّلنا الكمية لتناسب سعراتك اليومية. يمكنك تغييرها، وتتغير القيم أدناه معها.','We sized this to fit your daily calories. Change it and the values below follow.')}</div></div>
 <div><div class="faint" style="font-weight:700;margin-bottom:6px">${L('لماذا اخترناها لك؟','Why we picked it')}</div><div class="chips">${(it?reasonsFor(it):M.r).map(reasonChip).join('')}</div>${M.nw?`<div class="faint" style="margin-top:6px;font-size:12.5px">${E('sparkles',14)} ${L('وصفة مقترحة لدفعة البروتين القادمة، وقيمها تقديرية من USDA حتى تدخل الكتالوج.','A proposed recipe for the coming protein batch; values are USDA estimates until it joins the catalog.')}</div>`:''}</div>
 <div class="card flat"><div class="row" style="gap:16px"><div style="position:relative;width:96px;height:96px;flex:none"><svg viewBox="0 0 80 80" width="96" height="96" style="transform:rotate(-90deg)">${seg(pk,'--protein')}${seg(ck,'--carb')}${seg(fk,'--fat')}</svg><div style="position:absolute;inset:0;display:grid;place-items:center;text-align:center;line-height:1.1"><div><b class="num" style="font-size:18px">${fmt(n.kcal)}</b><div class="faint" style="font-size:11px">${L('سعرة','kcal')}</div></div></div></div>
  <div class="col grow" style="gap:8px">${[['--protein',L('بروتين','Protein'),n.protein],['--carb',L('كربوهيدرات','Carbs'),n.carb],['--fat',L('دهون','Fat'),n.fat]].map(([c,l,v])=>`<div class="between" style="font-size:14px"><span class="row" style="gap:6px"><i style="width:10px;height:10px;border-radius:4px;background:var(${c})"></i>${l}</span><b class="num">${fmt(v,1)} ${L('غ','g')}</b></div>`).join('')}</div></div>
  <div class="col" style="gap:12px;margin-top:14px">${lim(L('الصوديوم (الملح)','Sodium (salt)'),n.sodium,2000,L('ملغ','mg'))}${lim(L('الدهون المشبعة','Saturated fat'),n.satfat,t.kcal*0.1/9,L('غ','g'))}</div></div>
 ${explain(L('القيم الغذائية كاملة','Full nutrition facts'),`<div class="col" style="gap:0">${[['kcal',L('الطاقة','Energy'),L('سعرة','kcal')],['protein',L('بروتين','Protein'),'g'],['carb',L('كربوهيدرات','Carbs'),'g'],['fat',L('دهون','Fat'),'g'],['fiber',L('ألياف','Fiber'),'g'],['sugars',L('سكريات','Sugars'),'g'],['satfat',L('دهون مشبعة','Saturated fat'),'g'],['chol',L('كوليسترول','Cholesterol'),'mg'],['sodium',L('صوديوم','Sodium'),'mg']].map(([k,l,u])=>`<div class="between" style="padding:7px 0;border-bottom:1px solid var(--line)"><span>${l}</span><b class="num">${fmt(n[k],1)} ${u==='g'?L('غ','g'):u==='mg'?L('ملغ','mg'):u}</b></div>`).join('')}</div>`,'clipboard')}
 <div><div class="faint" style="font-weight:700;margin-bottom:4px">${L('المكونات','Ingredients')}</div>${M.ing.map(g=>`<div class="li" style="padding:9px 0">${E(g[3],26)}<span class="grow">${L(g[0],g[1])}</span><span class="num faint">${fmt(g[2]*x)} ${L('غ','g')}</span></div>`).join('')}</div>
 <button class="row press" style="gap:8px;color:var(--fg-3);font-size:13.5px;justify-content:center" data-act="nope" data-m="${m}">${I('nope')}${S.nope[m]?L('لن نقترحها مجددًا · تراجع','We won’t suggest it again · Undo'):L('لا أحب هذه الوجبة، لا تقترحها مجددًا','I don’t like this, don’t suggest it again')}</button>
 ${it?`<div class="row" style="gap:10px;position:sticky;bottom:-26px;background:var(--bg);padding:10px 0 4px"><button class="btn ghost grow press" data-act="swap" data-id="${it.id}">${I('swap')}${L('استبدال','Swap')}</button><button class="btn grow press" data-act="eat" data-id="${it.id}" data-close="1">${S.eaten[it.id]?L('تراجع عن التسجيل','Undo log'):L('أكلتها','I ate it')}</button></div>`:''}
 </div></div>`;
}
function swapSheet(sh){
 const it=TODAY.find(i=>i.id===sh.id),cur=MEALS[it.m],alts=(ALTS[it.m]||[]).filter(m=>!S.nope[m]);
 return `<div class="scrim" data-act="close"><div class="sheet" role="dialog" aria-modal="true" data-stop><div class="grab"></div>
 <h2 style="font-size:20px">${L('بدائل تناسب خطتك','Alternatives that fit your plan')}</h2><p class="faint" style="margin:-8px 0 0">${L('كلها تحافظ على سعرات يومك وحدودك','All keep your day’s calories and limits')}</p>
 ${alts.map((m,i)=>{const d=MEALS[m].n.kcal-cur.n.kcal;return `<button class="card rise press" style="--i:${i};text-align:start;padding:12px" data-act="doswap" data-id="${it.id}" data-m="${m}"><div class="row" style="gap:12px"><span class="thumb" style="width:56px;height:56px;background:color-mix(in srgb,var(${MEALS[m].tc}) 16%,var(--surface-2))">${E(MEALS[m].e,38)}</span><div class="grow"><b>${mname(m)}</b><div class="faint num">${fmt(MEALS[m].n.kcal)} ${L('سعرة','kcal')} · <span dir="ltr">${d>0?'+':''}${fmt(d)}</span></div><div class="chips" style="margin-top:4px">${MEALS[m].r.slice(0,2).map(reasonChip).join('')}</div></div>${I('chev','flip')}</div></button>`}).join('')}
 </div></div>`;
}
function quickSheet(){
 const q=[['droplet',L('سجّل ماء','Log water'),'water'],['fork-and-knife-with-plate',L('أكلت شيئًا آخر','I ate something else'),'other'],['balance-scale',L('سجّل وزنك','Log your weight'),'weight'],['shopping-cart',L('قائمة المشتريات','Shopping list'),'shop']];
 return `<div class="scrim" data-act="close"><div class="sheet" role="dialog" aria-modal="true" data-stop><div class="grab"></div><h2 style="font-size:20px">${L('ماذا تريد أن تضيف؟','What do you want to add?')}</h2>
 <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">${q.map((x,i)=>`<button class="card rise press" style="--i:${i};padding:16px;display:flex;flex-direction:column;align-items:center;gap:8px;font-weight:700" data-act="quickgo" data-v="${x[2]}">${E(x[0],44)}${x[1]}</button>`).join('')}</div></div></div>`;
}
function weightSheet(){
 return `<div class="scrim" data-act="close"><div class="sheet" role="dialog" aria-modal="true" data-stop><div class="grab"></div><h2 style="font-size:20px">${L('وزنك اليوم','Your weight today')}</h2>
 <div class="row">${wheel('wlog',40,200,0.1,L('كغ','kg'),'')}</div><button class="btn block press" data-act="saveWeight">${L('حفظ','Save')}</button></div></div>`;
}
function waterSheet(){
 const v=S.sheet.v||250;
 return `<div class="scrim" data-act="close"><div class="sheet" role="dialog" aria-modal="true" data-stop><div class="grab"></div><h2 style="font-size:20px">${L('كمية مخصصة','Custom amount')}</h2>
 <div style="text-align:center">${E(v<=200?'teacup-without-handle':v<=350?'tumbler-glass':'potable-water',56)}<div><b class="num" style="font-size:44px" id="wv">${fmt(v)}</b> <span class="muted">${L('مل','ml')}</span></div></div>
 <input type="range" min="50" max="1000" step="50" value="${v}" data-in="wrange" style="width:100%;accent-color:var(--water)" aria-label="${L('الكمية','Amount')}">
 <div class="chips" style="justify-content:center">${[100,200,330,750].map(x=>`<button class="chip press" data-act="wset" data-v="${x}"><span class="num">${x}</span> ${L('مل','ml')}</button>`).join('')}</div>
 <div id="wwarn">${v>500?tip('light-bulb',L('كمية كبيرة لجلسة واحدة. الأفضل توزيعها على جلستين، فالجسم يستفيد من الماء أكثر عندما يُشرب على دفعات.','That’s a lot in one sitting. Splitting it in two helps your body use the water better.')):''}</div>
 <button class="btn block press" data-act="addw" data-v="${v}" data-close="1" style="background:var(--water)">${L('أضف','Add')} <span class="num" id="wv2">${fmt(v)}</span> ${L('مل','ml')}</button></div></div>`;
}
function badgeSheet(sh){
 const b=badges().find(x=>x[0]===sh.b);
 return `<div class="scrim" data-act="close"><div class="sheet" role="dialog" aria-modal="true" data-stop style="text-align:center;align-items:center"><div class="grab"></div>
 <div style="animation:pop .5s">${E(b[1],110,b[4]>=1?'':'')}</div><h2 style="font-size:22px">${L(b[2][0],b[2][1])}</h2><p class="muted" style="margin:0">${L(b[3][0],b[3][1])}</p>
 <div style="width:100%">${bar(b[4],'var(--fat)',10)}<div class="faint num" style="margin-top:6px">${Math.round(b[4]*100)}%</div></div></div></div>`;
}
