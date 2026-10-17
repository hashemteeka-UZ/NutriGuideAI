import re,sys
FSI,PDI,RLM='⁨','⁩','‏'
LAT=r"[A-Za-z][A-Za-z0-9_.\-/:+#'&]*"
RUN=re.compile(r"`[^`]+`(?:\s*`[^`]+`)*|(?:[0-9][0-9.,]*[- ])?"+LAT+r"(?:[ ]+(?:"+LAT+r"|(?>[0-9]+(?:[./][0-9]+)*)(?!\s*[ء-ي])))*")
LINK=re.compile(r"(\[[^\]]*\])(\([^)]*\))")
def wrap(seg):
    def f(m):
        t=m.group(0).rstrip('.:-/')
        rest=m.group(0)[len(t):]
        return FSI+t+PDI+rest
    return RUN.sub(f,seg)
def line(l):
    l=l.replace(RLM,'').replace(FSI,'').replace(PDI,'')
    if not re.search(r'[؀-ۿ]',l): return l
    out=[];pos=0
    for m in LINK.finditer(l):
        out.append(wrap(l[pos:m.start()])); out.append(wrap(m.group(1))+m.group(2)); pos=m.end()
    out.append(wrap(l[pos:])); return ''.join(out)
src=open(sys.argv[1]).read().split('\n'); res=[];fence=False
for l in src:
    if l.startswith('```'): fence=not fence; res.append(l); continue
    if fence: res.append(l); continue
    if l.strip() in ('<div dir="rtl">','</div>'): continue
    res.append(line(l))
txt='\n'.join(res); txt=re.sub(r'\n{3,}','\n\n',txt)
open(sys.argv[2],'w').write(txt)
