"""Chapter 09: 二元因变量.

Textbook data:
    1. ACS PUMS 2023 California sample for high-income probability.
    2. UCI Credit Default for default probability, odds ratios, and risk effects.

教学对应关系：
    high_income                   -> ACS 个人收入是否处于最高四分位
    share_tertiary_school         -> 是否本科及以上学历
    lnpop                         -> log(年龄)
    default_next_month            -> 下月是否信用卡违约
    blood_pressure                -> 过去还款状态 pay_0
    male                          -> 男性
    age                           -> 年龄

This script avoids statsmodels/scipy and implements logit/probit/LPM with
numpy/pandas plus the Python standard library.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pandas as pd


SCRIPT_DIR = Path(__file__).resolve().parent
CHAPTER_DIR = SCRIPT_DIR.parent
REPO_DIR = CHAPTER_DIR.parent
ACS_PATH = REPO_DIR / "data" / "processed" / "acs_pums_california_persons_2023_selected.csv"
CREDIT_PATH = REPO_DIR / "data" / "processed" / "uci_credit_default_clients.csv"
TABLE_DIR = CHAPTER_DIR / "tables"
RESULT_DIR = CHAPTER_DIR / "results"

TABLE_DIR.mkdir(parents=True, exist_ok=True)
RESULT_DIR.mkdir(parents=True, exist_ok=True)


def normal_cdf(x: np.ndarray | float) -> np.ndarray | float:
    return 0.5 * (1 + np.vectorize(math.erf)(np.asarray(x) / math.sqrt(2)))


def normal_pdf(x: np.ndarray | float) -> np.ndarray | float:
    arr = np.asarray(x)
    return np.exp(-0.5 * arr * arr) / math.sqrt(2 * math.pi)


def normal_pvalue(z: np.ndarray) -> np.ndarray:
    cdf = normal_cdf(np.abs(z))
    return np.maximum(0.0, 2 * (1 - cdf))


def sigmoid(x: np.ndarray) -> np.ndarray:
    x = np.clip(x, -35, 35)
    return 1 / (1 + np.exp(-x))


def design_matrix(df: pd.DataFrame, cols: list[str], intercept: bool = True) -> np.ndarray:
    blocks = [df[c].to_numpy(float) for c in cols]
    if intercept:
        blocks = [np.ones(len(df))] + blocks
    return np.column_stack(blocks)


def fit_ols(y: np.ndarray, X: np.ndarray, names: list[str]) -> dict[str, object]:
    n, p = X.shape
    xtx_inv = np.linalg.inv(X.T @ X)
    beta = xtx_inv @ X.T @ y
    fitted = X @ beta
    resid = y - fitted
    rss = float((resid**2).sum())
    sigma2 = rss / (n - p)
    vcov = sigma2 * xtx_inv
    se = np.sqrt(np.diag(vcov))
    tval = beta / se
    return {
        "names": names,
        "beta": beta,
        "se": se,
        "stat": tval,
        "p": normal_pvalue(tval),
        "fitted": fitted,
        "rss": rss,
        "aic": n * (math.log(2 * math.pi * rss / n) + 1) + 2 * p,
    }


def fit_binomial_glm(
    y: np.ndarray,
    X: np.ndarray,
    names: list[str],
    link: str = "logit",
    max_iter: int = 100,
    tol: float = 1e-8,
) -> dict[str, object]:
    beta = np.zeros(X.shape[1])
    for _ in range(max_iter):
        eta = X @ beta
        if link == "logit":
            mu = sigmoid(eta)
            dmu = mu * (1 - mu)
        elif link == "probit":
            eta = np.clip(eta, -8, 8)
            mu = np.asarray(normal_cdf(eta), dtype=float)
            dmu = np.asarray(normal_pdf(eta), dtype=float)
        else:
            raise ValueError(link)
        mu = np.clip(mu, 1e-8, 1 - 1e-8)
        dmu = np.clip(dmu, 1e-8, None)
        weights = (dmu * dmu) / (mu * (1 - mu))
        z = eta + (y - mu) / dmu
        xw = X * weights[:, None]
        beta_new = np.linalg.solve(X.T @ xw, X.T @ (weights * z))
        if np.max(np.abs(beta_new - beta)) < tol:
            beta = beta_new
            break
        beta = beta_new
    eta = X @ beta
    if link == "logit":
        mu = sigmoid(eta)
        dmu = mu * (1 - mu)
    else:
        eta = np.clip(eta, -8, 8)
        mu = np.asarray(normal_cdf(eta), dtype=float)
        dmu = np.asarray(normal_pdf(eta), dtype=float)
    mu = np.clip(mu, 1e-8, 1 - 1e-8)
    dmu = np.clip(dmu, 1e-8, None)
    weights = (dmu * dmu) / (mu * (1 - mu))
    vcov = np.linalg.inv(X.T @ (X * weights[:, None]))
    se = np.sqrt(np.diag(vcov))
    zval = beta / se
    ll = float((y * np.log(mu) + (1 - y) * np.log(1 - mu)).sum())
    return {
        "names": names,
        "beta": beta,
        "se": se,
        "stat": zval,
        "p": normal_pvalue(zval),
        "pred": mu,
        "ll": ll,
        "aic": -2 * ll + 2 * X.shape[1],
        "link": link,
    }


def model_table(fit: dict[str, object], model_label: str, stat_name: str = "z值") -> pd.DataFrame:
    return pd.DataFrame(
        {
            "模型": model_label,
            "项": fit["names"],
            "估计值": fit["beta"],
            "标准误": fit["se"],
            stat_name: fit["stat"],
            "p值": fit["p"],
        }
    )


def predict_logit(fit: dict[str, object], X: np.ndarray) -> np.ndarray:
    return sigmoid(X @ fit["beta"])


# ------------------------------------------------------------------------------
# Box 01--08: 高收入概率的 logistic 回归
# ------------------------------------------------------------------------------

acs = pd.read_csv(ACS_PATH, encoding="utf-8-sig")
acs = acs.dropna(
    subset=["age", "personal_income", "female", "employed", "has_bachelor_or_higher"]
).copy()
acs = acs.loc[acs["age"].between(25, 64) & acs["personal_income"].ge(0)].copy()
highest_quartile_limit = float(acs["personal_income"].quantile(0.75))
acs["high_income"] = (acs["personal_income"] > highest_quartile_limit).astype(int)
acs["bachelor"] = acs["has_bachelor_or_higher"]
acs["ln_age"] = np.log(acs["age"])

y_acs = acs["high_income"].to_numpy(float)
logit_model = fit_binomial_glm(
    y_acs,
    design_matrix(acs, ["bachelor"]),
    ["截距", "本科及以上"],
    link="logit",
)
logit_model2 = fit_binomial_glm(
    y_acs,
    design_matrix(acs, ["bachelor", "ln_age", "female", "employed"]),
    ["截距", "本科及以上", "log年龄", "女性", "就业"],
    link="logit",
)
acs_tables = pd.concat(
    [
        model_table(logit_model, "ACS高收入：单变量logit"),
        model_table(logit_model2, "ACS高收入：多变量logit"),
    ],
    ignore_index=True,
)
acs_tables.to_csv(TABLE_DIR / "python_chapter09_acs_high_income_logit_table.csv", index=False)

acs[
    ["age", "female", "employed", "bachelor", "personal_income", "high_income", "ln_age"]
].to_csv(RESULT_DIR / "python_chapter09_acs_high_income_analysis_data.csv", index=False)

beta1hat = float(logit_model2["beta"][1])
beta2hat = float(logit_model2["beta"][2])
odds_ratio_bachelor_income = math.exp(beta1hat)
odds_ratio_age_10pct = math.exp(beta2hat * math.log(1.10))

z_grid = np.linspace(-6, 6, 400)
link_df = pd.DataFrame(
    {
        "z": z_grid,
        "logistic": sigmoid(z_grid),
        "probit": normal_cdf(z_grid),
        "linear": np.minimum(np.maximum(0.5 + z_grid / 6, 0), 1),
    }
)
link_df.to_csv(RESULT_DIR / "python_chapter09_link_function_grid.csv", index=False)

# ------------------------------------------------------------------------------
# Box 09--20: 信用卡违约概率的例子
# ------------------------------------------------------------------------------

credit = pd.read_csv(CREDIT_PATH, encoding="utf-8-sig")
credit["default"] = credit["default_payment_next_month"]
credit["pay_delay"] = credit["pay_0"]
credit["male"] = (credit["sex"] == 1).astype(int)
credit["limit_bal_10k"] = credit["limit_bal"] / 10000
credit["bill_ratio"] = credit["bill_amt1"] / credit["limit_bal"]
credit = credit.dropna(
    subset=["default", "pay_delay", "male", "age", "limit_bal_10k", "bill_ratio"]
).copy()

y_credit = credit["default"].to_numpy(float)
logit_default1 = fit_binomial_glm(
    y_credit,
    design_matrix(credit, ["pay_delay"]),
    ["截距", "还款状态"],
    link="logit",
)
X_credit = design_matrix(credit, ["pay_delay", "male", "age", "limit_bal_10k"])
names_credit = ["截距", "还款状态", "男性", "年龄", "信用额度（万元）"]
logit_default2 = fit_binomial_glm(y_credit, X_credit, names_credit, link="logit")
probit_default2 = fit_binomial_glm(y_credit, X_credit, names_credit, link="probit")
lpm_default2 = fit_ols(y_credit, X_credit, names_credit)
credit["pred_lpm"] = lpm_default2["fitted"]

default_tables = pd.concat(
    [
        model_table(logit_default1, "违约：单变量logit"),
        model_table(logit_default2, "违约：多变量logit"),
        model_table(probit_default2, "违约：多变量probit"),
    ],
    ignore_index=True,
)
default_tables.to_csv(TABLE_DIR / "python_chapter09_credit_logit_probit_table.csv", index=False)
model_table(lpm_default2, "违约：LPM", stat_name="统计量").to_csv(
    TABLE_DIR / "python_chapter09_credit_lpm_table.csv",
    index=False,
)

lpm_range = pd.DataFrame(
    {
        "指标": ["LPM最小预测值", "LPM最大预测值", "小于0比例", "大于1比例"],
        "数值": [
            credit["pred_lpm"].min(),
            credit["pred_lpm"].max(),
            credit["pred_lpm"].lt(0).mean(),
            credit["pred_lpm"].gt(1).mean(),
        ],
    }
)
lpm_range.to_csv(RESULT_DIR / "python_chapter09_lpm_prediction_range.csv", index=False)

std_dev_pay_delay = float(credit["pay_delay"].std(ddof=1))
std_dev_age = float(credit["age"].std(ddof=1))
std_dev_limit = float(credit["limit_bal_10k"].std(ddof=1))
zstat = 1.959963984540054
beta_1_hat = float(logit_default1["beta"][1])
se_beta_1_hat = float(logit_default1["se"][1])
lb_beta_1_hat = beta_1_hat - zstat * se_beta_1_hat
ub_beta_1_hat = beta_1_hat + zstat * se_beta_1_hat
lb_odds_ratio = math.exp(lb_beta_1_hat * std_dev_pay_delay)
ub_odds_ratio = math.exp(ub_beta_1_hat * std_dev_pay_delay)

beta_credit = logit_default2["beta"]
increases = np.array([std_dev_pay_delay, 1, std_dev_age, std_dev_limit])
odds_ratios = np.exp(beta_credit[1:5] * increases)
odds_table = pd.DataFrame(
    {
        "变量": [
            "还款状态增加1个标准差",
            "男性",
            "年龄增加1个标准差",
            "额度增加1个标准差",
            "单变量模型：还款状态OR下限",
            "单变量模型：还款状态OR上限",
        ],
        "赔率比": [*odds_ratios, lb_odds_ratio, ub_odds_ratio],
    }
)
odds_table.to_csv(RESULT_DIR / "python_chapter09_credit_odds_ratios.csv", index=False)

x_profile = np.array([[1, 2, 1, 35, 5]], dtype=float)
pred_default_manual = float(sigmoid(x_profile @ beta_credit)[0])
pred_default = float(predict_logit(logit_default2, x_profile)[0])

credit["pred"] = logit_default2["pred"]
credit_incr_pay = credit.copy()
credit_incr_pay["pay_delay"] = credit_incr_pay["pay_delay"] + std_dev_pay_delay
pred_incr_pay = predict_logit(
    logit_default2,
    design_matrix(credit_incr_pay, ["pay_delay", "male", "age", "limit_bal_10k"]),
)
credit["risk_ratio_pay_delay"] = pred_incr_pay / credit["pred"]
credit["risk_diff_pay_delay"] = pred_incr_pay - credit["pred"]
GRR_pay_delay = float(credit["risk_ratio_pay_delay"].mean())
GRD_pay_delay = float(credit["risk_diff_pay_delay"].mean())

credit_incr_age = credit.copy()
credit_incr_age["age"] = credit_incr_age["age"] + std_dev_age
pred_incr_age = predict_logit(
    logit_default2,
    design_matrix(credit_incr_age, ["pay_delay", "male", "age", "limit_bal_10k"]),
)
credit["risk_ratio_age"] = pred_incr_age / credit["pred"]
credit["risk_diff_age"] = pred_incr_age - credit["pred"]
GRR_age = float(credit["risk_ratio_age"].mean())
GRD_age = float(credit["risk_diff_age"].mean())

credit_female = credit.copy()
credit_female["male"] = 0
credit_male = credit.copy()
credit_male["male"] = 1
pred_female = predict_logit(
    logit_default2,
    design_matrix(credit_female, ["pay_delay", "male", "age", "limit_bal_10k"]),
)
pred_male = predict_logit(
    logit_default2,
    design_matrix(credit_male, ["pay_delay", "male", "age", "limit_bal_10k"]),
)
credit["risk_ratio_male"] = pred_male / pred_female
credit["risk_diff_male"] = pred_male - pred_female
GRR_male = float(credit["risk_ratio_male"].mean())
GRD_male = float(credit["risk_diff_male"].mean())

risk_effects = pd.DataFrame(
    {
        "变量": ["还款状态增加1个标准差", "年龄增加1个标准差", "男性相对女性"],
        "平均风险比": [GRR_pay_delay, GRR_age, GRR_male],
        "平均风险差": [GRD_pay_delay, GRD_age, GRD_male],
    }
)
risk_effects.to_csv(RESULT_DIR / "python_chapter09_credit_risk_effects.csv", index=False)

profile_base = pd.DataFrame(
    {
        "pay_delay": [0, 1, 2],
        "male": 1,
        "age": 35,
        "limit_bal_10k": 5,
    }
)
profile_X = design_matrix(profile_base, ["pay_delay", "male", "age", "limit_bal_10k"])
profile_base["预测概率"] = predict_logit(logit_default2, profile_X)
profile_base["赔率"] = profile_base["预测概率"] / (1 - profile_base["预测概率"])
profile_base.to_csv(RESULT_DIR / "python_chapter09_profile_prediction_table.csv", index=False)

beta_1_hat = float(logit_default1["beta"][1])
intercept_hat = float(logit_default1["beta"][0])
beta_grid = np.linspace(beta_1_hat - 1.5, beta_1_hat + 1.5, 250)
ll_grid = []
for beta_value in beta_grid:
    p = sigmoid(intercept_hat + beta_value * credit["pay_delay"].to_numpy(float))
    ll_grid.append(float((y_credit * np.log(p) + (1 - y_credit) * np.log(1 - p)).sum()))
pd.DataFrame(
    {"beta_pay_delay": beta_grid, "log_likelihood": ll_grid}
).to_csv(RESULT_DIR / "python_chapter09_likelihood_profile.csv", index=False)

credit[
    ["default", "pay_delay", "male", "age", "limit_bal_10k", "bill_ratio", "pred", "pred_lpm"]
].to_csv(RESULT_DIR / "python_chapter09_credit_default_analysis_data.csv", index=False)

comparison = pd.DataFrame(
    {
        "模型": ["LPM", "logit", "probit"],
        "样本量": [len(credit), len(credit), len(credit)],
        "pay_delay系数": [
            float(lpm_default2["beta"][1]),
            float(logit_default2["beta"][1]),
            float(probit_default2["beta"][1]),
        ],
        "AIC": [
            float(lpm_default2["aic"]),
            float(logit_default2["aic"]),
            float(probit_default2["aic"]),
        ],
    }
)
comparison.to_csv(TABLE_DIR / "python_chapter09_binary_model_comparison.csv", index=False)

summary = pd.DataFrame(
    {
        "指标": [
            "ACS样本量",
            "ACS高收入阈值",
            "ACS本科高收入赔率比",
            "信用卡样本量",
            "违约率",
            "还款状态赔率比",
            "男性赔率比",
            "给定画像预测违约概率",
            "手算预测违约概率",
            "还款状态平均风险差",
        ],
        "数值": [
            len(acs),
            highest_quartile_limit,
            odds_ratio_bachelor_income,
            len(credit),
            credit["default"].mean(),
            float(odds_ratios[0]),
            float(odds_ratios[1]),
            pred_default,
            pred_default_manual,
            GRD_pay_delay,
        ],
    }
)
summary.to_csv(RESULT_DIR / "python_chapter09_summary.csv", index=False)

print("Chapter 09 finished.")
print(f"ACS sample size: {len(acs)}")
print(f"Credit sample size: {len(credit)}")
print(f"Default rate: {credit['default'].mean():.4f}")
print(f"Predicted default probability: {pred_default:.4f}")
