# 正文代码框顺序运行；带“模拟”的扩展数据不是真实调查记录。
from pathlib import Path
import numpy as np,pandas as pd,statsmodels.formula.api as smf
from scipy import stats
repo_dir=Path(__file__).resolve().parents[2]
import os
os.chdir(repo_dir)


# 代码框 1: book_chapters/ch07_nonlinear.tex:139 / ch07_nonlinear_1
import numpy as np, pandas as pd
import statsmodels.formula.api as smf
from pathlib import Path
data_path = (Path("Chapter07_Nonlinear_functional_form")
             / "results" / "python_chapter07_wdi_owid_income_co2_analysis_data.csv")
df = pd.read_csv(data_path)
df["log_gdp2"] = df["log_gdp_pc"] ** 2
mod_quad = smf.ols("co2_pc_tonnes ~ log_gdp_pc + log_gdp2", data=df).fit()
grid = df["log_gdp_pc"].quantile([.25, .50, .75])
mod_quad.params["log_gdp_pc"] + 2 * mod_quad.params["log_gdp2"] * grid


# 代码框 2: book_chapters/ch07_nonlinear.tex:340 / ch07_nonlinear_3
mod_log = smf.ols("np.log(co2_pc_tonnes) ~ log_gdp_pc", data=df).fit(cov_type="HC0", use_t=True)
mod_log.params


# 代码框 3: book_chapters/ch07_nonlinear.tex:514 / ch07_cont_interact_py
import numpy as np, statsmodels.formula.api as smf, pandas as pd

df["lgdp_c"]  = df["log_gdp_pc"] - df["log_gdp_pc"].mean()
df["trade_c"] = df["trade_pct_gdp"] - df["trade_pct_gdp"].mean()

mod_int = smf.ols("co2_pc_tonnes ~ lgdp_c * trade_c",
                  data=df).fit(cov_type="HC0", use_t=True)
print(mod_int.summary().tables[1])

# 在贸易开放度三个分位数处的边际效应及置信区间
q_trade = df["trade_c"].quantile([0.1, 0.5, 0.9]).values
b1 = mod_int.params["lgdp_c"]
b3 = mod_int.params["lgdp_c:trade_c"]
V  = mod_int.cov_params()

from scipy.stats import t
crit = t.ppf(.975, mod_int.df_resid)
for q in q_trade:
    me = b1 + b3 * q
    grad = np.array([0, 1, 0, q])   # (截距, lgdp_c, trade_c, 交互项)
    se = np.sqrt(grad @ V.values @ grad)
    print(f"ME = {me:.3f}  95% CI = [{me-crit*se:.3f}, {me+crit*se:.3f}]")


# 代码框 4: book_chapters/ch07_nonlinear.tex:599 / ch07_kink_py
import numpy as np, statsmodels.formula.api as smf, pandas as pd

c1 = 8.5
df["kink1"] = np.maximum(df["log_gdp_pc"] - c1, 0)

mod_kink = smf.ols("co2_pc_tonnes ~ log_gdp_pc + kink1",
                   data=df).fit(cov_type="HC0", use_t=True)
print(mod_kink.summary().tables[1])
# log_gdp_pc 系数 = 折点前斜率
# kink1 系数      = 折点处的斜率增量

# 生成预测曲线
grid = pd.DataFrame({"log_gdp_pc": np.linspace(6.0, 11.5, 200)})
grid["kink1"] = np.maximum(grid["log_gdp_pc"] - c1, 0)
grid["pred"]  = mod_kink.predict(grid)


# 代码框 5: book_chapters/ch07_nonlinear.tex:706 / ch07_me_py
# 方法 1: 手动 delta 法（二次模型）
mod_quad = smf.ols(
    "co2_pc_tonnes ~ log_gdp_pc + I(log_gdp_pc**2)", data=df
).fit(cov_type="HC0", use_t=True)

b1, b2 = mod_quad.params["log_gdp_pc"], mod_quad.params["I(log_gdp_pc ** 2)"]
V = mod_quad.cov_params()

points = [df["log_gdp_pc"].mean(), *df["log_gdp_pc"].quantile([.25, .5, .75])]
from scipy.stats import t
crit = t.ppf(.975, mod_quad.df_resid)
for q in points:
    me   = b1 + 2*b2*q
    grad = np.array([0, 1, 2*q])   # (截距, log_gdp_pc, quadratic)
    se   = np.sqrt(grad @ V.values @ grad)
    print(f"x={q:.2f}  ME={me:.3f}  SE={se:.3f}  CI=[{me-crit*se:.3f},{me+crit*se:.3f}]")

# 也可使用专门的边际效应软件；这里无需额外依赖。


# 代码框 6: book_chapters/ch07_nonlinear.tex:779 / ch07_nonlinear_11
grid = pd.DataFrame({
    "log_gdp_pc": np.linspace(df.log_gdp_pc.min(), df.log_gdp_pc.max(), 100)
})
grid["log_gdp2"] = grid["log_gdp_pc"] ** 2
grid["pred_quad"] = mod_quad.predict(grid)
grid["pred_log"] = np.exp(mod_log.predict(grid))
