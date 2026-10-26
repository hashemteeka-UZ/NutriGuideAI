const { chromium } = require('playwright');
const fs=require('fs');
(async()=>{
 const b=await chromium.launch(); const p=await b.newPage({deviceScaleFactor:2});
 const lib=fs.readFileSync(process.env.NPM+'/node_modules/mermaid/dist/mermaid.min.js','utf8');
 for (const f of process.argv.slice(2)){
  const src=fs.readFileSync(f,'utf8');
  await p.setContent(`<html><body style="background:white"><div id=c class=mermaid></div></body></html>`);
  await p.addScriptTag({content:lib});
  await p.evaluate(async(s)=>{mermaid.initialize({startOnLoad:false,theme:'default',flowchart:{htmlLabels:true}});const {svg}=await mermaid.render('g',s);document.getElementById('c').innerHTML=svg;},src);
  const el=await p.$('#c svg'); await el.screenshot({path:f.replace('mmd/','figs/').replace('.mmd','.png')});
  fs.writeFileSync(f.replace('.mmd','.svg'), await p.$eval('#c',e=>e.innerHTML));
 }
 await b.close();})();
