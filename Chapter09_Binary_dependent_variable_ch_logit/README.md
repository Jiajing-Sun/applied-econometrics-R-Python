# 第9章：二元因变量

## 数据与样本

两个案例：ACS加州2023年203337名25–64岁、收入非负且所需字段完整的人员；UCI信用卡违约30000条客户记录。

数据文件：

- [`acs_pums_california_persons_2023_selected.csv`](../data/processed/acs_pums_california_persons_2023_selected.csv)
- [`uci_credit_default_clients.csv`](../data/processed/uci_credit_default_clients.csv)

| 案例 | 变量 | 定义 |
|---|---|---|
| ACS | `high_income` | 个人年收入严格超过样本75%分位数90100美元取1；本例约24.9974% |
| ACS | `bachelor`, `ln_age`, `female`, `employed` | 本科及以上、年龄自然对数、女性、就业 |
| UCI | `default` | `default_payment_next_month`，下月违约取1 |
| UCI | `pay_delay` | 原始还款状态编码 `pay_0`；不是每个取值均等于拖欠月数 |
| UCI | `male` | 原始 `sex==1` 取1 |
| UCI | `limit_bal_10k` | 原始信用额度 `limit_bal/10000`；台湾信用卡数据以万元新台币为单位 |
| UCI | `bill_ratio` | `bill_amt1/limit_bal`，无量纲 |

ACS估计不加调查权重；高收入门槛由本章样本生成，不是法定收入标准。UCI演示logit、probit与线性概率模型，并区分优势比、概率差和风险比。`pay_0` 有负值及0等特殊状态，保留原始编码且在线性指数中按数值使用，是本例的建模简化。文件未保留客户ID，不能凭相同选列观测直接删重。

## 运行与输出

先按配套代码根目录说明准备R/Python依赖，再在本章目录执行：

```bash
Rscript R/chapter09.R
python3 python/chapter09.py
```

主要核对文件：[`results/chapter09_acs_high_income_analysis_data.csv`](results/chapter09_acs_high_income_analysis_data.csv)；其余数值在 `results/`、表格在 `tables/`，主脚本绘图在 `figures/`。Python结果通常以 `python_` 开头。

本说明核对日期：2026-09-22。数据来源、完整文件清单、缺失值和主键核验见 [共享数据说明](../data/README.md)。运行成功说明程序能够执行；经济识别条件和数据代表性仍按正文解释。
