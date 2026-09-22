"""Simulated commute choice; not real survey data. Seed and true parameters fixed."""
from pathlib import Path
import numpy as np,pandas as pd,json,hashlib
root=Path(__file__).resolve().parents[1];rng=np.random.default_rng(20260922);n=1200
t=rng.uniform(-20,20,n);c=rng.uniform(-30,30,n);pr=1/(1+np.exp(-(.2-.03*t-.015*c)))
y=(rng.uniform(size=n)<pr).astype(int);p=root/'processed/appendix_choice_vot_simulated.csv'
pd.DataFrame({'choice':y,'time_diff':t,'cost_diff':c}).to_csv(p,index=False)
(root/'metadata/appendix_vot_simulated.json').write_text(json.dumps(dict(type='模拟教学数据，不是真实调查',seed=20260922,n=n,beta=[.2,-.03,-.015],true_vot_yuan_per_minute=2,time_unit='分钟',cost_unit='元',sha256=hashlib.sha256(p.read_bytes()).hexdigest()),ensure_ascii=False,indent=2))
