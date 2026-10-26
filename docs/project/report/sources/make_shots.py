from PIL import Image, ImageOps
import sys
SS='../../../../mobile/docs/screenshots/'
sets={'shots_onboarding':['k2_pace.png','k2_result.png','k2_how_calculated.png'],
 'shots_plan':['k4_showcase_optimizer.png','k4_today.png','k4_plan.png'],
 'shots_feedback':['m1/m1_rating_sheet.png','m1/m1_did_not_eat.png','k5a_pending.png'],
 'shots_progress':['k6a_report.png','k6b/k6b_badges.png','k6a_weight.png'],
 'shots_account':['k7a/k7a_about.png','k7a/k7a_delete.png','k7b/k7b_reminders.png']}
H=900; gap=30
for name,fs in sets.items():
    ims=[]
    for f in fs:
        im=Image.open(SS+f).convert('RGB'); w,h=im.size
        im=im.resize((int(w*H/h),H), Image.LANCZOS)
        ims.append(ImageOps.expand(im,border=2,fill=(160,160,160)))
    ims=ims[::-1]
    W=sum(i.size[0] for i in ims)+gap*(len(ims)+1)
    c=Image.new('RGB',(W,H+4+2*gap),'white'); x=gap
    for i in ims: c.paste(i,(x,gap)); x+=i.size[0]+gap
    c.save(f'figs/{name}.png',optimize=True); print(name,c.size)
