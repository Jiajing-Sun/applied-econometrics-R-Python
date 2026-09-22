"""Generate simulated teaching data, not observations of actual cities. Seed 20260922."""
from pathlib import Path
import numpy as np,pandas as pd
d=Path(__file__).resolve().parents[1]/'processed'
rng=np.random.default_rng(20260922)
rows=[]
for i in range(60):
 a=rng.normal();treated=int(i<30)
 for yr in range(2010,2018):
  ell=yr-2014
  rows.append((i,yr,treated,2014 if treated else 0,ell if treated else -999,10+a+.2*(yr-2010)+treated*max(0,ell+1)*.4+rng.normal(scale=.5)))
pd.DataFrame(rows,columns=['id','year','treated','treat_year','rel_time','Y']).to_csv(d/'chapter13_event_common_timing_simulated.csv',index=False)
factor=rng.normal(size=(25,3));factor[:,0]=np.arange(25)*.25
loading=rng.normal(size=(10,3));donors=20+factor@loading.T+rng.normal(scale=.12,size=(25,10));w=np.array([.4,.35,.25]+[0]*7)
y=donors@w+rng.normal(scale=.05,size=25);y[15:]+=1.5
rows=[(u,yr,float(y[j] if u==0 else donors[j,u-1])) for u in range(11) for j,yr in enumerate(range(2001,2026))]
pd.DataFrame(rows,columns=['city','year','outcome']).to_csv(d/'chapter13_scm_cities_simulated.csv',index=False)
print('Two explicitly simulated teaching datasets saved; shared by R and Python')
