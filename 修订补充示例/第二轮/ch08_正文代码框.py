# 正文代码框顺序运行；带“模拟”的扩展数据不是真实调查记录。
from pathlib import Path
import numpy as np,pandas as pd,statsmodels.formula.api as smf
from scipy import stats
repo_dir=Path(__file__).resolve().parents[2]
import os
os.chdir(repo_dir)
acs=pd.read_csv(repo_dir / 'Chapter08_Regression_analysis_with_dependent_error_terms_ch_reg_dep_error/results/python_chapter08_acs_cluster_analysis_data.csv')
df=pd.read_csv(repo_dir / '修订补充示例/第二轮/ch08_调查加权_模拟.csv')

# 代码框 1: {Python 中按家庭聚类标准误}
import numpy as np, pandas as pd
import statsmodels.formula.api as smf
from pathlib import Path
data_path = (Path("Chapter08_Regression_analysis_with_dependent_error_terms_ch_reg_dep_error")
             / "results" / "chapter08_acs_cluster_analysis_data.csv")
acs = pd.read_csv(data_path)
mod = smf.ols("log_income ~ bachelor", data=acs).fit()
clustered = mod.get_robustcov_results(
    cov_type="cluster", groups=acs["household_id"],
    use_correction=False, df_correction=True, use_t=True
)
G = acs["household_id"].nunique()
# R 的 HC0 + cadjust=TRUE：只乘 G/(G-1)
clustered.cov_params_default *= G / (G - 1)
clustered.summary()


# 代码框 2: [label=ch08_survey_py]{Python 中调查加权回归（示意代码）}
import statsmodels.formula.api as smf
import numpy as np

# 模拟数据，仅展示独立观测下 WLS+HC1
df = pd.read_csv("修订补充示例/第二轮/ch08_调查加权_模拟.csv")
# 方法一：WLS（指定权重）；df 列含义同 R 版
m_wls = smf.wls("income ~ educ + age + urban",
                data=df, weights=df["weight"]).fit(
                cov_type="HC1")
print(m_wls.summary().tables[1])   # coef、std err、t、P>|t|、95% CI

# 方法二：用加权统计量做描述性分析（不输出回归系数）
# 复杂调查设计应使用支持分层与整群的专门调查分析工具
from statsmodels.stats.weightstats import DescrStatsW
ds = DescrStatsW(df[["income","educ"]], weights=df["weight"])
print(ds.mean)   # 加权均值（用于描述统计，与 svyglm 的系数解释一致性）

