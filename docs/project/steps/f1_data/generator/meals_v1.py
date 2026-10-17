# Step F.1-r revision (2026-10-06): user feedback applied on top of meals_def.MEALS (v0).
from meals_def_v0 import MEALS as V0
W='14555'
OPT={  # ndb codes marked optional per meal (assistant proposal, user confirmed; L03 egg by user)
 "B01":{"02014"},"B02":{"09152","11529","11297"},"B03":{"02010"},"B04":{"11297"},
 "L01":{"16358","11124"},"L02":{"11670"},"L03":{"01123","11670"},"L04":{"11304","11124"},
 "L07":{"11333","09152"},"D01":{"16358","11165"},"D02":{"09152"},"D03":{"09193","09152"},
 "D04":{"09152"},"D06":{"11297"},
}
LABEL={("D01","20120"):"حبوب الشربة (لسان العصفور)"}
VG={"L01":"couscous","L02":"mbakbaka","L03":"bazeen","L05":"fasolia","L06":"bamia","D01":"sharba"}
NAME={  # (name_en, name_ar) for the lamb versions
 "L01":("Libyan couscous with lamb and vegetables","كسكسي ليبي بلحم الضأن والخضار"),
 "L02":("Mbakbaka with lamb (pasta in spicy tomato sauce)","مبكبكة بلحم الضأن"),
 "L03":("Bazeen with lamb and potatoes","بازين بلحم الضأن والبطاطا"),
 "L05":("White bean stew with lamb (fasolia)","فاصوليا بيضاء بلحم الضأن"),
 "L06":("Okra stew with lamb (bamia)","بامية بلحم الضأن"),
 "D01":("Libyan soup with lamb (sharba)","شربة ليبية بلحم الضأن"),
}
CH={
 "L01":("Libyan couscous with chicken and vegetables","كسكسي ليبي بالدجاج والخضار"),
 "L02":("Mbakbaka with chicken (pasta in spicy tomato sauce)","مبكبكة بالدجاج"),
 "L03":("Bazeen with chicken and potatoes","بازين بالدجاج والبطاطا"),
 "L05":("White bean stew with chicken (fasolia)","فاصوليا بيضاء بالدجاج"),
 "L06":("Okra stew with chicken (bamia)","بامية بالدجاج"),
 "D01":("Libyan soup with chicken (sharba)","شربة ليبية بالدجاج"),
}
CHANGED=set()
def ing_edit(code, ings):
    ings=list(ings)
    if code=="L02": ings=[x for x in ings if x[0]!="16358"]                      # chickpeas are not in mbakbaka
    if code=="L08": ings=ings[:5]+[("11352",200),("11422",200)]+ings[5:]          # add potatoes and pumpkin
    if code=="D01":
        ings=[("11165",g) if n=="11297" else (n,g) for n,g in ings]               # parsley -> coriander
        i=[n for n,_ in ings].index("02043"); ings.insert(i+1,("02031",3))       # add ground red hot pepper
    if code=="D06":
        i=[n for n,_ in ings].index("02047"); ings[i+1:i+1]=[("02043",2),("02030",2),("02010",1)]  # turmeric + spice
    return ings
MEALS=[]
for code,en,ar,cu,serv,wm,yf,occ,diet,ings in V0:
    if code=="S07": continue
    new=ing_edit(code,ings)
    if code in NAME: en,ar=NAME[code]
    changed = new!=list(ings)   # only ingredient changes need a new review; renames and optional flags were the user's own requests
    m=dict(code=code,en=en,ar=ar,cu=cu,serv=serv,wm=wm,yf=yf,occ=occ,diet=diet,vg=VG.get(code),
           ings=[(n,g,n in OPT.get(code,()),LABEL.get((code,n))) for n,g in new],reviewed=not changed)
    MEALS.append(m)
    if code in CH:
        cen,car=CH[code]
        cing=[("05096",g) if n=="17039" else (n,g) for n,g in new]
        MEALS.append(dict(code=code+"-CH",en=cen,ar=car,cu=cu,serv=serv,wm=wm,yf=yf,occ=occ,diet=diet,vg=VG[code],
           ings=[(n,g,n in OPT.get(code,()),LABEL.get((code,n))) for n,g in cing],reviewed=False))
