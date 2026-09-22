# 正文代码框顺序运行；带“模拟”的扩展数据不是真实调查记录。
from pathlib import Path
import numpy as np,pandas as pd,statsmodels.formula.api as smf
from scipy import stats
repo_dir=Path(__file__).resolve().parents[2]
import os
os.chdir(repo_dir)


# 代码框 1: book_chapters/ch09_binary.tex:107 / ch09_binary_1
import numpy as np, pandas as pd
import statsmodels.formula.api as smf
from pathlib import Path
data_path = (Path("Chapter09_Binary_dependent_variable_ch_logit")
             / "results" / "python_chapter09_credit_default_analysis_data.csv")
credit = pd.read_csv(data_path)
lpm = smf.ols(
    "default ~ pay_delay + male + age + limit_bal_10k",
    data=credit
).fit(cov_type="HC1", use_t=False)
credit["pred_lpm"] = lpm.predict(credit)
credit["pred_lpm"].agg(["min", "max"])


# 代码框 2: book_chapters/ch09_binary.tex:198 / ch09_binary_3
acs = pd.read_csv("Chapter09_Binary_dependent_variable_ch_logit/results/python_chapter09_acs_high_income_analysis_data.csv")
mod = smf.logit(
    "high_income ~ bachelor + np.log(age) + female + employed",
    data=acs
).fit()
np.exp(mod.params)


# 代码框 3: book_chapters/ch09_binary.tex:433 / ch09_binary_5
import statsmodels.formula.api as smf

mod_credit = smf.logit(
    "default ~ pay_delay + male + age + limit_bal_10k",
    data=credit
).fit()
p0 = mod_credit.predict(credit)
credit_hi = credit.copy()
credit_hi["pay_delay"] += credit["pay_delay"].std()
p1 = mod_credit.predict(credit_hi)
(p1 - p0).mean()


# 代码框 4: book_chapters/ch09_binary.tex:557 / ch09_binary_7
phat = mod_credit.predict(credit)
for cutoff in [0.3, 0.5]:
    yhat = (phat >= cutoff).astype(int)
    print(pd.crosstab(yhat, credit["default"],
                      rownames=["预测"], colnames=["实际"]))


# 代码框 5: book_chapters/ch09_binary.tex:702 / ch09_binary_9
choice_df = pd.read_csv("补充示例/正文/ch09_有序多项选择_模拟.csv")
import statsmodels.api as sm
from statsmodels.miscmodels.ordinal_model import OrderedModel
choice_df["edu_level"] = pd.Categorical(
    choice_df["edu_level"], categories=["低", "中", "高"], ordered=True)
res_ord = OrderedModel(choice_df["edu_level"],
    choice_df[["log_income", "age"]], distr="logit").fit(method="bfgs")
transport = pd.Categorical(choice_df["transport"],
                           categories=["公交", "地铁", "汽车"])
X_mnl = sm.add_constant(choice_df[["income", "distance"]])
res_mnl = sm.MNLogit(transport.codes, X_mnl).fit()
print(res_mnl.summary())

