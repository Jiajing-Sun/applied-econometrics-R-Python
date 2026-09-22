"""Explicitly simulated data for RD and mediation teaching; not observed policy data."""
from pathlib import Path
import numpy as np,pandas as pd,json,hashlib
root=Path(__file__).resolve().parents[1];d=root/'processed';m=root/'metadata'
rng=np.random.default_rng(20260922);n=2000
X=rng.uniform(-1,1,n);Z=(X>=0).astype(int);D=(rng.uniform(size=n)<.25+.5*Z).astype(int);e=rng.normal(size=n)
pd.DataFrame({'X':X,'D':D,'Y_sharp':1+.4*X+.2*X**2+.8*Z+e,'Y_fuzzy':1+.4*X+.2*X**2+.8*D+e}).to_csv(d/'chapter13_rd_continuous_simulated.csv',index=False)
rng=np.random.default_rng(20260922);n=600
X=rng.normal(size=n);D=(rng.uniform(size=n)<1/(1+np.exp(-.3*X))).astype(int);M=.5*D+.3*X+rng.normal(size=n);Y=.2*D+.4*M+.5*X+rng.normal(size=n)
pd.DataFrame({'X':X,'D':D,'M':M,'Y':Y}).to_csv(d/'chapter13_mediation_simulated.csv',index=False)
manifest={'seed':20260922,'type':'模拟教学数据；不是真实中国政策或城市观测','rd':{'n':2000,'assignment':'Z=1[X>=0]; P(D=1|X)=.25+.5Z','outcomes':'Y_sharp=1+.4X+.2X^2+.8Z+e; Y_fuzzy=1+.4X+.2X^2+.8D+e','true_sharp_effect':.8,'true_fuzzy_effect':.8},'mediation':{'n':600,'assignment':'P(D=1|X)=logit_inverse(.3X)','equations':'M=.5D+.3X+eM; Y=.2D+.4M+.5X+eY; errors independent','direct_effect':.2,'indirect_effect':.2,'total_effect':.4}}
manifest['files']=[{'path':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [d/'chapter13_rd_continuous_simulated.csv',d/'chapter13_mediation_simulated.csv']]
(m/'round2_simulated_data.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2));print('Generated RD n=2000 and mediation n=600, with explicit provenance.')
