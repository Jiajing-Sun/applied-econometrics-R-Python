# Chapter 09: 二元因变量

本章使用可公开再分发的个人层面与信用卡违约数据。

## 数据说明

- 高收入概率本章数据：`../data/processed/acs_pums_california_persons_2023_selected.csv`
- 违约概率本章数据：`../data/processed/uci_credit_default_clients.csv`

## 教学对应

- `high_income` -> ACS 个人收入是否处于工作年龄样本最高四分位。
- `share_tertiary_school` -> 是否本科及以上学历。
- `lnpop` -> `log(年龄)`。
- `default_next_month` -> 下月是否信用卡违约。
- `blood_pressure` -> 最近一期还款状态 `pay_0`。
- `male` -> 男性。
- `age` -> 年龄。

## 保留的方法

- logit 模型估计与解释。
- 赔率比与赔率比置信区间。
- 给定协变量画像的预测概率。
- 样本平均风险比与风险差。
- LPM/logit/probit 模型比较。

## 运行

```bash
Rscript R/chapter09.R
/Users/sunjiajing/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 python/chapter09.py
```

## 输出

- 图：`figures/`
- 表：`tables/`
- 结果：`results/`

所有 R 图形的坐标轴、标题和图例均已中文化。Python 版本生成对应的数据表和数值结果；图形由 R 版本生成。
