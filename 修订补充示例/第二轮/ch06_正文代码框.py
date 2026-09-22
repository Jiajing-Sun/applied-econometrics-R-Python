# 正文代码框顺序运行；带“模拟”的扩展数据不是真实调查记录。
from pathlib import Path
import numpy as np,pandas as pd,statsmodels.formula.api as smf
from scipy import stats
repo_dir=Path(__file__).resolve().parents[2]
import os
os.chdir(repo_dir)


# 代码框 1: book_chapters/ch06_multiple_regression.tex:133 / ch06_multiple_regression_1
import numpy as np, pandas as pd
import statsmodels.formula.api as smf
from pathlib import Path
data_path = (Path("Chapter06_Multiple_Linear_Regression")
             / "results" / "python_chapter06_bea_bls_state_analysis_data.csv")
df = pd.read_csv(data_path)
import statsmodels.formula.api as smf
mod_mid = smf.ols(
    "income_pc_thousand ~ gdp_pc_thousand + unemployment_rate + large_state",
    data=df
).fit(cov_type="HC0", use_t=True)
mod_mid.summary()

