# 第10章：预测与模型比较

## 数据与样本

国家统计局2025年70城住宅销售价格指数。分析表840行；1–9月训练630行，10–12月测试210行。

数据文件：

- [`nbs_70city_house_price_2025.csv`](../data/processed/nbs_70city_house_price_2025.csv)

| 变量 | 含义和单位 |
|---|---|
| `second_hand_yoy` | 因变量：二手住宅同比指数，上年同月＝100 |
| `new_house_yoy` | 新建商品住宅同比指数，上年同月＝100 |
| `second_hand_mom`, `new_house_mom` | 二手/新建住宅环比指数，上月＝100 |
| `city`, `month`, `first_tier` | 城市、月份、北京/上海/广州/深圳指示变量 |

本轮统一使用实际指数名称，清除旧英文案例的金额、面积和费用别名。多项式的中心和尺度仅由训练样本计算。交叉验证使用5个按月份向前扩展的训练窗口（验证月5–9月），不是随机打乱的5折。多项式、岭回归、LASSO、回归树使用共同训练/测试划分。

测试预测以同月解释变量已知为条件，不能直接称作在解释变量尚未发布时完成的提前预测。R与Python的树算法及正则化实现可能不同，比较应先核对目标函数、标准化和调参规则。

## 运行与输出

先按配套代码根目录说明准备R/Python依赖，再在本章目录执行：

```bash
Rscript R/chapter10.R
python3 python/chapter10.py
```

主要核对文件：[`results/chapter10_nbs_70city_prediction_data.csv`](results/chapter10_nbs_70city_prediction_data.csv)；其余数值在 `results/`、表格在 `tables/`，主脚本绘图在 `figures/`。Python结果通常以 `python_` 开头。

本说明核对日期：2026-09-22。数据来源、完整文件清单、缺失值和主键核验见 [共享数据说明](../data/README.md)。运行成功说明程序能够执行；经济识别条件和数据代表性仍按正文解释。
