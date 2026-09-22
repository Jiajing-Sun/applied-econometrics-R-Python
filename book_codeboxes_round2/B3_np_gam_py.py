# Extracted verbatim from book_chapters/ch_nonparametric.tex; run from companion-code root.
from pygam import LinearGAM, s
import numpy as np, pandas as pd
df = pd.read_csv("Chapter13_Nonparametric_Regression_chapter_nonparametric/"
                 "results/chapter13_nonparametric_analysis_data.csv")
gam = LinearGAM(s(0)).gridsearch(df[["log_gdp_pc"]].to_numpy(),
    df["co2_pc_tonnes"].to_numpy(), lam=np.logspace(-3,3,15), progress=False)
print("全模型 EDF:", gam.statistics_["edof"])
XX = gam.generate_X_grid(term=0)
prediction = gam.predict(XX)   # 包含截距的条件均值预测
pdep, confi = gam.partial_dependence(term=0, X=XX, width=.95)
# pdep 是平滑分量；confi 是模型内点态区间，不是同步置信带
