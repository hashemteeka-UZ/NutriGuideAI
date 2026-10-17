/* ---------- shared pieces ---------- */
function ring(p,size,sw,color,track,inner=''){
 const r=(size-sw)/2,c=2*Math.PI*r,off=c*(1-Math.max(0,Math.min(1,p)));
 return `<div class="ringwrap" style="width:${size}px;height:${size}px"><svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" aria-hidden="true">
 <circle cx="${size/2}" cy="${size/2}" r="${r}" fill="none" stroke="${track}" stroke-width="${sw}"/>
 <circle class="ringv" style="--c:${c}" cx="${size/2}" cy="${size/2}" r="${r}" fill="none" stroke="${color}" stroke-width="${sw}" stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="${off}"/></svg><div class="c">${inner}</div></div>`;
}
const bar=(p,color,h=8)=>`<div class="bar" style="--bc:${color};height:${h}px"><i class="barv" style="width:${Math.max(0,Math.min(100,p*100))}%"></i></div>`;
const tip=(e,txt)=>`<div class="tip">${E(e,20)}<div>${txt}</div></div>`;
const explain=(title,body,e='light-bulb')=>`<details class="explain"><summary>${E(e,20)}<span class="grow">${title}</span>${I('chev','chev flip')}</summary><div class="muted" style="padding-bottom:14px;font-size:14px">${body}</div></details>`;
const rise=(i)=>`rise" style="--i:${i}`;
const reasonChip=r=>`<span class="chip g">${E(R[r][0],14)}${L(R[r][1],R[r][2])}</span>`;
function topbar(title,sub,right=''){return `<header class="top"><div class="grow"><h1>${title}</h1>${sub?`<div class="sub">${sub}</div>`:''}</div>${right}</header>`}
function navbar(){
 const tabs=[['home','home',L('اليوم','Today')],['plan','cal',L('الخطة','Plan')],['water','drop',L('الماء','Water')],['progress','chart',L('تقدمي','Progress')],['profile','user',L('حسابي','Me')]];
 return `<nav class="nav" aria-label="${L('التنقل','Navigation')}">${tabs.map(([k,ic,l])=>`<button data-go="${k}" ${S.screen===k?'aria-current="page"':''}>${I(ic)}<span>${l}</span></button>`).join('')}</nav>`;
}
const offlineBar=()=>S.scen.offline?`<div class="offline">${I('wifi')}${L('دون اتصال · ما تسجله محفوظ وسيُزامن تلقائيًا','Offline · what you log is saved and will sync automatically')}</div>`:'';
const TODAYSTR=()=>L('الثلاثاء 13 أكتوبر','Tuesday, 13 October');
function greet(){const h=Math.floor(S.now/60);return h<12?L('صباح الخير','Good morning'):h<17?L('نهارك سعيد','Good afternoon'):L('مساء الخير','Good evening')}

/* ---------- welcome & auth ---------- */
function welcome(){
 const sl=[['brain',L('خطة تُبنى لك أنت','A plan built for you'),L('محرك ذكي يختار وجباتك من مطبخنا المحلي حسب جسمك وهدفك وما تحب.','A smart engine picks meals from our local kitchen for your body, goal and taste.')],
  ['alarm-clock',L('تناسب يومك','Fits your day'),L('مواعيد الوجبات والماء تُرتب حسب وقت استيقاظك ونومك.','Meal and water times follow when you wake up and sleep.')],
  ['chart-increasing',L('ترى تقدمك','See your progress'),L('رسوم واضحة وتقرير أسبوعي وإنجازات تحفزك.','Clear charts, a weekly report and badges that keep you going.')]][S.welcomeSlide%3];
 const orb=['avocado','fish','broccoli','red-apple','bread','carrot','egg','lemon'];
 return `<div class="screen" style="background:var(--hero);color:#fff"><div class="body" style="flex:1;display:flex;flex-direction:column;padding:28px 22px 26px;gap:18px;position:relative;overflow:hidden">
  <div class="row" style="justify-content:space-between"><div class="row" style="gap:8px;font-weight:700;font-size:18px">${E('seedling',30)}NutriGuide</div>
   <button class="pill press" data-act="lang" data-v="${S.lang==='ar'?'en':'ar'}" style="background:rgba(255,255,255,.15);border-color:rgba(255,255,255,.25);color:#fff">${I('globe')}${S.lang==='ar'?'English':'العربية'}</button></div>
  <div class="orbit"><div class="plate">${E('green-salad',96)}</div><div class="ringo">${orb.map((e,i)=>{const a=i/orb.length*2*Math.PI;return `<span style="left:${50+46*Math.cos(a)}%;top:${50+46*Math.sin(a)}%">${E(e,32)}</span>`}).join('')}</div></div>
  <div style="text-align:center" class="wslide"><div style="display:inline-grid;place-items:center;width:56px;height:56px;border-radius:18px;background:rgba(255,255,255,.16);margin-bottom:10px">${E(sl[0],34)}</div>
   <h1 style="margin:0 0 6px;font-size:26px;line-height:1.3">${sl[1]}</h1><p style="margin:0;opacity:.9">${sl[2]}</p></div>
  <div class="dots">${[0,1,2].map(i=>`<i class="${i===S.welcomeSlide%3?'on':''}"></i>`).join('')}</div>
  <div style="margin-top:auto;display:flex;flex-direction:column;gap:10px">
   <button class="btn block press" data-act="startOnb" style="background:#fff;color:#0B6B4D">${L('ابدأ رحلتك','Get started')}</button>
   <button class="btn block ghost press" data-go="login" style="background:transparent;color:#fff;border-color:rgba(255,255,255,.4)">${L('لدي حساب','I have an account')}</button></div>
 </div></div>`;
}
function login(){
 return `<div class="screen ${S.anim?'anim '+S.nav:''}"><div class="body" style="flex:1;display:flex;flex-direction:column;padding:24px 22px;gap:16px">
  <button class="iconbtn press" data-go="welcome" data-back="1" aria-label="${L('رجوع','Back')}">${I('back','flip')}</button>
  <div class="rise" style="--i:0;text-align:center;margin-top:10px">${E('waving-hand',64,'')}<h1 style="margin:10px 0 4px;font-size:26px">${L('أهلًا بعودتك','Welcome back')}</h1><p class="muted" style="margin:0">${L('سجل دخولك لتكمل خطتك','Sign in to continue your plan')}</p></div>
  <label class="rise" style="--i:1;display:flex;flex-direction:column;gap:6px;font-weight:600;font-size:14px">${L('البريد الإلكتروني','Email')}<input type="email" value="ahmed@example.com" dir="ltr" style="min-height:54px;border-radius:16px;border:1px solid var(--line);background:var(--surface);padding:0 14px"></label>
  <label class="rise" style="--i:2;display:flex;flex-direction:column;gap:6px;font-weight:600;font-size:14px">${L('كلمة المرور','Password')}<input type="password" value="12345678" dir="ltr" style="min-height:54px;border-radius:16px;border:1px solid var(--line);background:var(--surface);padding:0 14px"></label>
  <button class="btn block press rise" style="--i:3" data-go="home">${L('دخول','Sign in')}</button>
  <p class="faint rise" style="--i:4;text-align:center">${L('ليس لديك حساب؟','No account?')} <button class="link" data-act="startOnb">${L('أنشئ حسابًا','Create one')}</button></p>
 </div></div>`;
}
