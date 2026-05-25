"""Chapter 10: 预测.

Textbook data: NBS 70-city housing price indices for 2025.

教学对应关系：
    教材变量 price       -> 二手住宅同比价格指数
    教材变量 living_area -> 新建商品住宅同比价格指数
    教材变量 monthly_fee -> 二手住宅环比价格指数
    教材变量 city_area   -> 新建住宅环比价格指数

This script mirrors the R workflow with train/test split, polynomial complexity,
5-fold cross-validation, ridge regression, LASSO, a simple regression tree, and
model comparison. It uses only numpy/pandas plus the Python standard library.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd


SCRIPT_DIR = Path(__file__).resolve().parent
CHAPTER_DIR = SCRIPT_DIR.parent
REPO_DIR = CHAPTER_DIR.parent
NBS_PATH = REPO_DIR / "data" / "processed" / "nbs_70city_house_price_2025.csv"
TABLE_DIR = CHAPTER_DIR / "tables"
RESULT_DIR = CHAPTER_DIR / "results"

TABLE_DIR.mkdir(parents=True, exist_ok=True)
RESULT_DIR.mkdir(parents=True, exist_ok=True)


def mse(y: np.ndarray, yhat: np.ndarray) -> float:
    return float(np.mean((y - yhat) ** 2))


def add_intercept(X: np.ndarray) -> np.ndarray:
    return np.column_stack([np.ones(X.shape[0]), X])


def fit_ols(y: np.ndarray, X: np.ndarray) -> np.ndarray:
    return np.linalg.pinv(X) @ y


def predict_ols(beta: np.ndarray, X: np.ndarray) -> np.ndarray:
    return X @ beta


def standardize_train_test(X_train: np.ndarray, X_all: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    mean = X_train.mean(axis=0)
    sd = X_train.std(axis=0, ddof=0)
    sd[sd == 0] = 1.0
    return (X_train - mean) / sd, (X_all - mean) / sd, mean, sd


def ridge_fit_predict(
    X_train: np.ndarray,
    y_train: np.ndarray,
    X_all: np.ndarray,
    lam: float,
) -> np.ndarray:
    Xs_train, Xs_all, _, _ = standardize_train_test(X_train, X_all)
    y_mean = y_train.mean()
    yc = y_train - y_mean
    p = Xs_train.shape[1]
    beta = np.linalg.solve(Xs_train.T @ Xs_train + lam * np.eye(p), Xs_train.T @ yc)
    return y_mean + Xs_all @ beta


def soft_threshold(x: float, lam: float) -> float:
    if x > lam:
        return x - lam
    if x < -lam:
        return x + lam
    return 0.0


def lasso_fit_predict(
    X_train: np.ndarray,
    y_train: np.ndarray,
    X_all: np.ndarray,
    lam: float,
    max_iter: int = 800,
    tol: float = 1e-6,
) -> np.ndarray:
    Xs_train, Xs_all, _, _ = standardize_train_test(X_train, X_all)
    y_mean = y_train.mean()
    yc = y_train - y_mean
    n, p = Xs_train.shape
    beta = np.zeros(p)
    col_norm = (Xs_train**2).sum(axis=0)
    for _ in range(max_iter):
        old = beta.copy()
        residual = yc - Xs_train @ beta
        for j in range(p):
            residual = residual + Xs_train[:, j] * beta[j]
            rho = float((Xs_train[:, j] * residual).sum())
            beta[j] = soft_threshold(rho, lam) / col_norm[j]
            residual = residual - Xs_train[:, j] * beta[j]
        if np.max(np.abs(beta - old)) < tol:
            break
    return y_mean + Xs_all @ beta


def kfold_indices(n: int, k: int, rng: np.random.Generator) -> np.ndarray:
    order = rng.permutation(n)
    folds = np.empty(n, dtype=int)
    for fold, idx in enumerate(np.array_split(order, k), start=1):
        folds[idx] = fold
    return folds


def cv_select_lambda(
    X: np.ndarray,
    y: np.ndarray,
    train_idx: np.ndarray,
    lambdas: np.ndarray,
    method: str,
    k: int = 5,
) -> tuple[float, pd.DataFrame]:
    rng = np.random.default_rng(12)
    X_train = X[train_idx]
    y_train = y[train_idx]
    folds = kfold_indices(len(train_idx), k, rng)
    rows = []
    for lam in lambdas:
        fold_mse = []
        for fold in range(1, k + 1):
            inner_train = folds != fold
            inner_test = folds == fold
            if method == "ridge":
                pred_all = ridge_fit_predict(
                    X_train[inner_train],
                    y_train[inner_train],
                    X_train,
                    lam,
                )
            elif method == "lasso":
                pred_all = lasso_fit_predict(
                    X_train[inner_train],
                    y_train[inner_train],
                    X_train,
                    lam,
                )
            else:
                raise ValueError(method)
            fold_mse.append(mse(y_train[inner_test], pred_all[inner_test]))
        rows.append({"lambda": lam, "log_lambda": np.log(lam), "cvm": np.mean(fold_mse), "cvsd": np.std(fold_mse, ddof=1)})
    table = pd.DataFrame(rows)
    best_lambda = float(table.loc[table["cvm"].idxmin(), "lambda"])
    return best_lambda, table


@dataclass
class TreeNode:
    prediction: float
    feature: int | None = None
    threshold: float | None = None
    left: "TreeNode | None" = None
    right: "TreeNode | None" = None


def build_tree(
    X: np.ndarray,
    y: np.ndarray,
    depth: int = 0,
    max_depth: int = 4,
    min_leaf: int = 20,
) -> TreeNode:
    node = TreeNode(prediction=float(y.mean()))
    if depth >= max_depth or len(y) < 2 * min_leaf:
        return node
    best = None
    base_sse = float(((y - y.mean()) ** 2).sum())
    for j in range(X.shape[1]):
        qs = np.unique(np.quantile(X[:, j], np.linspace(0.1, 0.9, 9)))
        for threshold in qs:
            left_mask = X[:, j] <= threshold
            right_mask = ~left_mask
            if left_mask.sum() < min_leaf or right_mask.sum() < min_leaf:
                continue
            y_left = y[left_mask]
            y_right = y[right_mask]
            sse = float(((y_left - y_left.mean()) ** 2).sum() + ((y_right - y_right.mean()) ** 2).sum())
            improvement = base_sse - sse
            if best is None or improvement > best[0]:
                best = (improvement, j, float(threshold), left_mask, right_mask)
    if best is None or best[0] <= 0:
        return node
    _, j, threshold, left_mask, right_mask = best
    node.feature = j
    node.threshold = threshold
    node.left = build_tree(X[left_mask], y[left_mask], depth + 1, max_depth, min_leaf)
    node.right = build_tree(X[right_mask], y[right_mask], depth + 1, max_depth, min_leaf)
    return node


def predict_tree_one(node: TreeNode, x: np.ndarray) -> float:
    while node.feature is not None:
        if x[node.feature] <= node.threshold:
            node = node.left
        else:
            node = node.right
    return node.prediction


def predict_tree(node: TreeNode, X: np.ndarray) -> np.ndarray:
    return np.array([predict_tree_one(node, row) for row in X])


raw = pd.read_csv(NBS_PATH, encoding="utf-8-sig")
new_house = raw.loc[raw["market"].eq("new_house"), ["year", "month", "date", "city", "mom_index", "yoy_index", "ytd_average_index"]].copy()
second_hand = raw.loc[raw["market"].eq("second_hand"), ["year", "month", "date", "city", "mom_index", "yoy_index", "ytd_average_index"]].copy()
new_house = new_house.rename(
    columns={
        "mom_index": "new_house_mom",
        "yoy_index": "new_house_yoy",
        "ytd_average_index": "new_house_ytd",
    }
)
second_hand = second_hand.rename(
    columns={
        "mom_index": "second_hand_mom",
        "yoy_index": "second_hand_yoy",
        "ytd_average_index": "second_hand_ytd",
    }
)
df = pd.merge(new_house, second_hand, on=["year", "month", "date", "city"])
df["first_tier"] = df["city"].isin(["北京", "上海", "广州", "深圳"]).astype(int)
df["month_numeric"] = df["month"]
df["price"] = df["second_hand_yoy"]
df["living_area"] = df["new_house_yoy"]
df["monthly_fee"] = df["second_hand_mom"]
df["city_area"] = df["new_house_mom"]
df = df.dropna(subset=["price", "living_area", "monthly_fee", "city_area", "first_tier"]).copy()
df = df.sort_values(["city", "month"]).reset_index(drop=True)
for i in range(2, 11):
    df[f"living_area{i}"] = df["living_area"] ** i

df[
    ["year", "month", "date", "city", "price", "living_area", "monthly_fee", "city_area", "first_tier"]
].to_csv(RESULT_DIR / "python_chapter10_nbs_70city_prediction_data.csv", index=False)

# ------------------------------------------------------------------------------
# Box 01--05: 训练数据、测试数据和多项式复杂度
# ------------------------------------------------------------------------------

rng = np.random.default_rng(12)
n = len(df)
train_idx = np.where(df["month"].to_numpy() <= 9)[0]
test_idx = np.where(df["month"].to_numpy() >= 10)[0]

y = df["price"].to_numpy(float)

random_train_idx = rng.choice(n, size=len(train_idx), replace=False)
random_test_idx = np.setdiff1d(np.arange(n), random_train_idx)
X_split = add_intercept(df[["living_area", "monthly_fee", "city_area", "first_tier"]].to_numpy(float))
beta_time = fit_ols(y[train_idx], X_split[train_idx])
beta_random = fit_ols(y[random_train_idx], X_split[random_train_idx])
split_compare = pd.DataFrame(
    {
        "划分方式": ["时间顺序切分", "随机切分"],
        "训练样本量": [len(train_idx), len(random_train_idx)],
        "测试样本量": [len(test_idx), len(random_test_idx)],
        "测试集 MSE": [
            mse(y[test_idx], predict_ols(beta_time, X_split[test_idx])),
            mse(y[random_test_idx], predict_ols(beta_random, X_split[random_test_idx])),
        ],
    }
)
split_compare.to_csv(TABLE_DIR / "python_chapter10_split_comparison_mse.csv", index=False)

poly_rows = []
for degree in range(1, 11):
    cols = ["living_area"] if degree == 1 else ["living_area"] + [f"living_area{i}" for i in range(2, degree + 1)]
    X = add_intercept(df[cols].to_numpy(float))
    beta = fit_ols(y[train_idx], X[train_idx])
    yhat = predict_ols(beta, X)
    poly_rows.append(
        {
            "多项式次数": degree,
            "训练集 MSE": mse(y[train_idx], yhat[train_idx]),
            "测试集 MSE": mse(y[test_idx], yhat[test_idx]),
        }
    )
poly_mse_table = pd.DataFrame(poly_rows)
poly_mse_table.to_csv(TABLE_DIR / "python_chapter10_polynomial_train_test_mse.csv", index=False)

# ------------------------------------------------------------------------------
# 偏误--方差权衡模拟
# ------------------------------------------------------------------------------

sim_rng = np.random.default_rng(2026)
x_grid = np.linspace(0.0, 1.0, 160)
true_y = np.sin(2 * np.pi * x_grid)
degrees_bv = [1, 3, 9]
preds = {deg: [] for deg in degrees_bv}
for _ in range(250):
    x_sim = sim_rng.uniform(size=35)
    y_sim = np.sin(2 * np.pi * x_sim) + sim_rng.normal(scale=0.35, size=35)
    for deg in degrees_bv:
        X_train_poly = np.column_stack([x_sim**j for j in range(deg + 1)])
        beta = fit_ols(y_sim, X_train_poly)
        X_grid_poly = np.column_stack([x_grid**j for j in range(deg + 1)])
        preds[deg].append(predict_ols(beta, X_grid_poly))
bv_rows = []
for deg in degrees_bv:
    pred_mat = np.vstack(preds[deg])
    mean_pred = pred_mat.mean(axis=0)
    bv_rows.append(
        {
            "多项式次数": deg,
            "平均偏误平方": float(np.mean((mean_pred - true_y) ** 2)),
            "平均方差": float(np.mean(pred_mat.var(axis=0, ddof=1))),
        }
    )
pd.DataFrame(bv_rows).to_csv(TABLE_DIR / "python_chapter10_bias_variance_simulation.csv", index=False)

# ------------------------------------------------------------------------------
# Box 06: 5 折交叉验证
# ------------------------------------------------------------------------------

folds_train = kfold_indices(len(train_idx), 5, rng)
cv_rows = []
X_simple = add_intercept(df[["living_area"]].to_numpy(float))
for fold in range(1, 6):
    leave_out_idx = train_idx[folds_train == fold]
    leave_in_idx = train_idx[folds_train != fold]
    beta = fit_ols(y[leave_in_idx], X_simple[leave_in_idx])
    pred = predict_ols(beta, X_simple[leave_out_idx])
    cv_rows.append({"折": fold, "MSE": mse(y[leave_out_idx], pred)})
cv_table = pd.DataFrame(cv_rows)
cv_table.to_csv(TABLE_DIR / "python_chapter10_five_fold_cv_mse.csv", index=False)

# ------------------------------------------------------------------------------
# Box 07--17: 岭回归和 LASSO
# ------------------------------------------------------------------------------

X_df = pd.get_dummies(
    df[["living_area", "monthly_fee", "city_area", "first_tier", "month_numeric", "city"]],
    columns=["city"],
    drop_first=True,
    dtype=float,
)
X = X_df.to_numpy(float)
lambdas = np.exp(np.linspace(np.log(0.01), np.log(100), 16))
ridge_lambda, ridge_cv_table = cv_select_lambda(X, y, train_idx, lambdas, "ridge", k=5)
lasso_lambda, lasso_cv_table = cv_select_lambda(X, y, train_idx, lambdas, "lasso", k=5)
ridge_cv_table.to_csv(TABLE_DIR / "python_chapter10_ridge_cv_curve.csv", index=False)
lasso_cv_table.to_csv(TABLE_DIR / "python_chapter10_lasso_cv_curve.csv", index=False)

# ------------------------------------------------------------------------------
# Box 18--24: 回归树
# ------------------------------------------------------------------------------

tree_features = ["living_area", "monthly_fee", "city_area", "first_tier", "month_numeric"]
X_tree = df[tree_features].to_numpy(float)
tree = build_tree(X_tree[train_idx], y[train_idx], max_depth=4, min_leaf=20)

# ------------------------------------------------------------------------------
# Box 25--42: 不同预测模型的比较
# ------------------------------------------------------------------------------

for i in range(2, 6):
    df[f"poly{i}"] = df["living_area"] ** i

X_linear = add_intercept(df[["living_area", "monthly_fee", "city_area", "first_tier"]].to_numpy(float))
beta_linear = fit_ols(y[train_idx], X_linear[train_idx])
yhat_ols_linear = predict_ols(beta_linear, X_linear)

X_poly = add_intercept(df[["living_area", "poly2", "poly3", "poly4", "poly5", "monthly_fee", "city_area", "first_tier", "month_numeric"]].to_numpy(float))
beta_poly = fit_ols(y[train_idx], X_poly[train_idx])
yhat_ols_poly = predict_ols(beta_poly, X_poly)

yhat_ridge = ridge_fit_predict(X[train_idx], y[train_idx], X, ridge_lambda)
yhat_lasso = lasso_fit_predict(X[train_idx], y[train_idx], X, lasso_lambda)
yhat_tree = predict_tree(tree, X_tree)

models = [
    ("OLS 线性", yhat_ols_linear),
    ("OLS 五阶多项式", yhat_ols_poly),
    ("岭回归", yhat_ridge),
    ("LASSO", yhat_lasso),
    ("回归树", yhat_tree),
]
model_compare = pd.DataFrame(
    {
        "模型": [name for name, _ in models],
        "训练集 MSE": [mse(y[train_idx], pred[train_idx]) for _, pred in models],
        "测试集 MSE": [mse(y[test_idx], pred[test_idx]) for _, pred in models],
    }
)
model_compare.to_csv(TABLE_DIR / "python_chapter10_model_comparison_mse.csv", index=False)

predictions = pd.DataFrame(
    {
        "city": df["city"],
        "month": df["month"],
        "actual": y,
        "yhat_ols_linear": yhat_ols_linear,
        "yhat_ols_poly": yhat_ols_poly,
        "yhat_ridge": yhat_ridge,
        "yhat_lasso": yhat_lasso,
        "yhat_tree": yhat_tree,
        "sample": np.where(np.isin(np.arange(n), train_idx), "训练集", "测试集"),
    }
)
predictions.to_csv(RESULT_DIR / "python_chapter10_predictions_all_models.csv", index=False)

best = model_compare.loc[model_compare["测试集 MSE"].idxmin()]
summary = pd.DataFrame(
    {
        "指标": [
            "样本量",
            "训练集样本量",
            "测试集样本量",
            "简单 OLS 5 折 CV 平均 MSE",
            "岭回归lambda.min",
            "LASSO lambda.min",
            "测试集最小 MSE",
            "测试集最优模型",
        ],
        "数值": [
            n,
            len(train_idx),
            len(test_idx),
            cv_table["MSE"].mean(),
            ridge_lambda,
            lasso_lambda,
            best["测试集 MSE"],
            best["模型"],
        ],
    }
)
summary.to_csv(RESULT_DIR / "python_chapter10_summary.csv", index=False)

print("Chapter 10 finished.")
print(f"Sample size: {n}")
print(f"Best test model: {best['模型']}")
print(f"Best test MSE: {float(best['测试集 MSE']):.4f}")
