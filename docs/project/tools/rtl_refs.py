# Post-pass after rtl_fix.py: a bullet that starts with an English citation is wrapped as ONE isolate
# behind an Arabic label, so commas/periods between English runs are not reordered in an RTL paragraph.
import re,sys
FSI,PDI='⁨','⁩'
src=open(sys.argv[1]).read().split('\n');out=[]
for l in src:
    m=re.match(r'^(\s*- \*\*[^*]+:\*\* |\s*- )(.*)$',l)
    if m:
        body=m.group(2).replace(FSI,'').replace(PDI,'')
        if re.match(r'^[A-ZÀ-ɏ]',body) and not body.startswith('**'):
            note=''
            n=re.search(r'\s*(\([^()]*[؀-ۿ][^()]*\)\.?)\s*$',body)
            if not n: n=re.search(r'\s+([\u0600-\u06FF][^A-Za-z]*)$',body)
            if n: note=' '+n.group(1); body=body[:n.start()]
            if not re.search(r'[\u0600-\u06FF]',body):
                l=m.group(1)+('' if '**' in m.group(1) else 'المرجع: ')+FSI+body.strip()+PDI+note
    out.append(l)
open(sys.argv[2] if len(sys.argv)>2 else sys.argv[1],'w').write('\n'.join(out))
