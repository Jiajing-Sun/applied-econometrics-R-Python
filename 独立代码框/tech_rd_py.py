# Extracted verbatim from technical_supplements/tech_rd_ch12.tex; run from companion-code root.
import pandas as pd
from rdrobust import rdrobust, rdplot
from rddensity import rddensity  # 独立软件包，不是 rdrobust 子模块
df = pd.read_csv("data/processed/chapter13_rd_continuous_simulated.csv")
rdr = rdrobust(y=df.Y_sharp.to_numpy(),x=df.X.to_numpy(),c=0,
    p=1,kernel="triangular",bwselect="mserd")
print(rdr)
h_opt = rdr.bws.iloc[0,:].to_numpy()
b_opt = rdr.bws.iloc[1,:].to_numpy()
for mult in [.5,1,2]:
    r = rdrobust(df.Y_sharp.to_numpy(),df.X.to_numpy(),c=0,p=1,
                 kernel="triangular",h=h_opt*mult,b=b_opt*mult)
    estimate_bc = r.coef.iloc[1,0]
    ci_lo,ci_hi = r.ci.iloc[2,0],r.ci.iloc[2,1]
    print(mult,estimate_bc,ci_lo,ci_hi)
print(rdrobust(df.Y_fuzzy.to_numpy(),df.X.to_numpy(),c=0,
    fuzzy=df.D.to_numpy(),p=1,kernel="triangular",bwselect="mserd"))
rdplot(df.Y_sharp.to_numpy(),df.X.to_numpy(),c=0,p=1)
dd = rddensity(df.X.to_numpy(),c=0)
print(dd.test.loc[["t_jk","p_jk"]])
