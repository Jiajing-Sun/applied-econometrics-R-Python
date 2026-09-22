# Extracted verbatim from book_chapters/ch12_causal.tex; run from companion-code root.
import numpy as np, pandas as pd
df = pd.read_csv("data/processed/chapter13_mediation_simulated.csv")
assert df[["X","D","M","Y"]].notna().all().all()
def effects(dat):
    one = np.ones(len(dat))
    X = np.column_stack([one,dat.D,dat.X])
    te = np.linalg.lstsq(X,dat.Y,rcond=None)[0][1]
    a = np.linalg.lstsq(X,dat.M,rcond=None)[0][1]
    Z = np.column_stack([one,dat.D,dat.M,dat.X])
    out = np.linalg.lstsq(Z,dat.Y,rcond=None)[0]
    return np.array([te,out[1],a*out[2]])
point = effects(df)
rng = np.random.default_rng(20260922)
boot = np.array([effects(df.iloc[rng.integers(len(df),size=len(df))])
                 for _ in range(1999)])
ci = np.quantile(boot,[.025,.975],axis=0).T
print(pd.DataFrame({"estimate":point,"SE":boot.std(axis=0,ddof=1),
    "lower":ci[:,0],"upper":ci[:,1]},index=["TE","ADE","ACME"]))
assert abs(point[0]-point[1]-point[2])<1e-10
