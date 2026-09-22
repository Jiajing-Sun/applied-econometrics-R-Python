# 正文代码框顺序运行；带“模拟”的扩展数据不是真实调查记录。
from pathlib import Path
import numpy as np,pandas as pd,statsmodels.formula.api as smf
from scipy import stats
repo_dir=Path(__file__).resolve().parents[2]
import os
os.chdir(repo_dir)
df=pd.read_csv(repo_dir / 'Chapter10_Prediction_ch_prediction/results/chapter10_nbs_70city_prediction_data.csv')

# 代码框 1: {Python 中训练/测试预测}
import numpy as np, pandas as pd
import statsmodels.formula.api as smf
from pathlib import Path
data_path = (Path("Chapter10_Prediction_ch_prediction")
             / "results" / "chapter10_nbs_70city_prediction_data.csv")
df = pd.read_csv(data_path)
train = df[df["month"] <= 9]
test = df[df["month"] >= 10]
model = smf.ols(
    "second_hand_yoy ~ new_house_yoy + second_hand_mom + new_house_mom + first_tier",
    data=train
).fit()
pred = model.predict(test)
((test["second_hand_yoy"] - pred) ** 2).mean()


# 代码框 2: {Python 中避免标准化泄漏}
from sklearn.preprocessing import StandardScaler
xvars = ["new_house_yoy", "second_hand_mom", "new_house_mom", "first_tier"]
scaler = StandardScaler().fit(train[xvars])
X_train = scaler.transform(train[xvars])
X_test = scaler.transform(test[xvars])
# 不要对 train 和 test 合并后再 fit scaler


# 代码框 3: {Python 中简单基准模型}
test["pred_train_mean"] = train["second_hand_yoy"].mean()
mse_mean = ((test["second_hand_yoy"] - test["pred_train_mean"]) ** 2).mean()

city_mean = train.groupby("city")["second_hand_yoy"].mean()
test["pred_city_mean"] = test["city"].map(city_mean)
mse_city = ((test["second_hand_yoy"] - test["pred_city_mean"]) ** 2).mean()


# 代码框 4: {Python 中随机森林}
from sklearn.ensemble import RandomForestRegressor
rf = RandomForestRegressor(n_estimators=500, max_features="sqrt",
                           oob_score=True, random_state=42)
y_train = train["second_hand_yoy"].to_numpy()
rf.fit(X_train, y_train)
rf.oob_score_  # OOB R²（sklearn 默认口径，越大越好）
rf.feature_importances_  # 回归树的加权平方误差下降重要性

