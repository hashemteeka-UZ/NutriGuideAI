import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt, numpy as np
# numbers copied from backend/scripts/out/ml_sim/summary.md, ml_tags/summary.md, ml_compare/summary.md
pol=["Random","Popularity","Content only","LinUCB disjoint","LinUCB hybrid"]
ind=[77.41,75.90,51.05,17.74,17.39]; ind_e=[2.14,3.62,5.99,1.30,0.60]
sh=[70.42,38.15,52.33,19.64,10.96]; sh_e=[8.40,7.85,5.47,2.43,1.95]
x=np.arange(len(pol)); w=0.38
fig,ax=plt.subplots(figsize=(8,4.2),dpi=200)
ax.bar(x-w/2,ind,w,yerr=ind_e,capsize=3,label="Independent users",color="#4C72B0")
ax.bar(x+w/2,sh,w,yerr=sh_e,capsize=3,label="Shared taste",color="#DD8452")
for i in range(len(pol)):
    ax.text(x[i]-w/2,ind[i]+3,f"{ind[i]:.1f}",ha="center",fontsize=7); ax.text(x[i]+w/2,sh[i]+3,f"{sh[i]:.1f}",ha="center",fontsize=7)
ax.set_xticks(x,pol,fontsize=8); ax.set_ylabel("Cumulative regret at T = 200 (lower is better)")
ax.legend(fontsize=8); ax.spines[["top","right"]].set_visible(False)
ax.set_title("Simulation: 50 users x 5 seeds, 20 safe candidates per round, alpha = 0.5",fontsize=9)
fig.tight_layout(); fig.savefig("figs/fig4-5_ml_regret.png")
# classifier
m=["Prior\n(most frequent)","Kcal-only\nlogistic","Logistic\nregression","Random\nforest"]
f1=[0.0,0.601,0.816,0.875]; e=[0,0.045,0.039,0.032]
fig,ax=plt.subplots(figsize=(6.5,3.8),dpi=200)
b=ax.bar(m,f1,yerr=e,capsize=4,color=["#999","#999","#4C72B0","#55A868"])
for i,v in enumerate(f1): ax.text(i,v+0.04,f"{v:.3f}",ha="center",fontsize=8)
ax.set_ylim(0,1); ax.set_ylabel("Macro-F1 (nested CV, 25 folds)"); ax.spines[["top","right"]].set_visible(False)
ax.set_title("Meal slot-tag classifier, 158 meals, 110 features",fontsize=9)
fig.tight_layout(); fig.savefig("figs/fig4-6_tag_classifier.png")
# week compare
lab=["Distinct meals\nin the week","Max repeats\nof one meal","Max |kcal deviation|\nper day","Mean solve\nseconds/day"]
v1=[10,4,2.2,2.23]; v2=[24,3,4.9,4.96]
x=np.arange(4); fig,ax=plt.subplots(figsize=(7,3.8),dpi=200)
ax.bar(x-w/2,v1,w,label="cpsat_v1",color="#999"); ax.bar(x+w/2,v2,w,label="cpsat_v2_learned",color="#55A868")
for i in range(4): ax.text(x[i]-w/2,v1[i]+0.4,str(v1[i]),ha="center",fontsize=8); ax.text(x[i]+w/2,v2[i]+0.4,str(v2[i]),ha="center",fontsize=8)
ax.set_xticks(x,lab,fontsize=8); ax.legend(fontsize=8); ax.spines[["top","right"]].set_visible(False)
ax.set_title("Same user, same week (7 days), target 1524 kcal",fontsize=9)
fig.tight_layout(); fig.savefig("figs/fig4-7_week_v1_vs_v2.png")
