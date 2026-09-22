# 第5章：简单线性回归

## 数据与样本

国家统计局2025年70城、12个月，最终840个城市—月份观测。

数据文件：

- [`nbs_70city_house_price_2025.csv`](../data/processed/nbs_70city_house_price_2025.csv)

回归以 `second_hand_yoy`（二手住宅同比指数）为因变量、`new_house_yoy`（新建商品住宅同比指数）为解释变量，两者均以上年同月＝100。`first_tier_city` 在北京、上海、广州、深圳取1，其余取0；这是本例采用的城市分组规则。

脚本包含带截距/过原点OLS、残差、HC0及按70个城市聚类的标准误、置信区间和模拟回归。指数单位不是元或面积。相同城市跨月份重复出现，城市聚类用于允许同城误差相关；系数不能直接解释为新房价格对二手房价格的因果效应。

## 运行与输出

先按配套代码根目录说明准备R/Python依赖，再在本章目录执行：

```bash
Rscript R/chapter05.R
python3 python/chapter05.py
```

主要核对文件：[`results/chapter05_70city_regression_data.csv`](results/chapter05_70city_regression_data.csv)；其余数值在 `results/`、表格在 `tables/`，主脚本绘图在 `figures/`。Python结果通常以 `python_` 开头。

本说明核对日期：2026-09-22。数据来源、完整文件清单、缺失值和主键核验见 [共享数据说明](../data/README.md)。运行成功说明程序能够执行；经济识别条件和数据代表性仍按正文解释。
