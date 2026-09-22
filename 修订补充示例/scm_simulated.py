# Run from the companion root; data are simulated teaching examples.
import numpy as np, pandas as pd
from scipy.optimize import minimize
df = pd.read_csv("data/processed/chapter13_scm_cities_simulated.csv")
Y = df.pivot(index="year",columns="city",values="outcome").sort_index()
pre = Y.index < 2016
A = Y.loc[pre].iloc[:,1:].to_numpy(); y = Y.loc[pre,0].to_numpy()
J = A.shape[1]
res = minimize(lambda w: np.sum((y-A@w)**2)+1e-10*(w@w),
    np.ones(J)/J, jac=lambda w: 2*A.T@(A@w-y)+2e-10*w,
    bounds=[(0,1)]*J, constraints={"type":"eq","fun":lambda w: w.sum()-1},
    method="SLSQP", options={"ftol":1e-12,"maxiter":10000})
if not res.success: raise RuntimeError(res.message)
w = res.x
gap = Y[0].to_numpy()-Y.iloc[:,1:].to_numpy()@w
print(w, np.mean(gap[pre]**2), np.mean(gap[~pre]))
pd.DataFrame({"weight":w}).to_csv("修订补充示例/scm_Python.csv",index=False)
