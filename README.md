# 中文教材配套代码｜2026-09-22 二轮深审版

本目录对应《应用计量经济学：基于R与Python的回归分析与因果推断》二轮深审书稿。书中深红文字、代码和图框累计标示两轮修订。本目录即公开仓库本轮更新的代码版本；复现本版时，请核对README中的版本日期。

## 先选一种语言

初学者可以先学R或Python。把工作目录设为本目录，先运行章节主脚本；它会读取本地冻结数据、输出分析CSV和数值表，R主脚本还生成图形。再在RStudio或Python notebook中按正文顺序执行代码框，查看每一步对象的含义。Python代码框的末尾表达式在notebook会显示结果；作为普通脚本运行时，部分表达式不自动打印，可用print查看。

书中后续框可能使用同一小节前面定义的对象。代码、数据与结果的相对目录需要一起保留。

## 实际验证范围

- 24个章节主脚本：R与Python各12个，最终代码运行通过。
- 正文及技术补充、数学附录共93个R/Python代码框：直接从书稿提取，按标明的执行顺序运行通过。
- R附录69个、Python附录65个离线代码框运行通过，共134个。49个安装命令、自备文件模板、交互帮助或在线API框另列验证状态；未将它们计入离线通过数。
- 事件研究、合成控制和ARMA搜索的6个补充脚本运行通过。
- 17组跨语言及独立实现数值核对、8组回归矩阵公式数值核验，以及Gauss–Markov协方差差和残差自由度核对通过。两语言相同样本和算法的结果可核对；随机数流、R与Python树算法、mgcv与pyGAM调参不同的例子，不要求逐位相同。

主要运行证据在 docs/validation_20260922；完整审查记录随书稿交付。计算成功不等于数据测量、模型假设或因果解释已由程序证明。

## 环境与安装

本轮实测Python版本及系统信息见`docs/validation_20260922/Python运行环境.json`，R信息见`docs/validation_20260922/R运行环境.txt`。Python使用独立环境；`requirements-20260922.txt`是本轮实际包版本，`R-package-versions.csv`记录R包版本。依赖包需要在自己的电脑安装，压缩包不包含本机虚拟环境。

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-20260922.txt
Rscript install_required_R_packages.R
```

若使用不同Python/R或包版本，需要重新核对结果；不要把版本不兼容当作数据错误。在线API扩展还可能需要额外包、联网或自己的服务密钥，按相应附录说明执行。

## 运行示例

以下命令都从本目录运行：

```bash
Rscript Chapter05_The_simple_linear_regression_model/R/chapter05.R
python Chapter05_The_simple_linear_regression_model/python/chapter05.py
Rscript 修订补充示例/第二轮/ch05_正文代码框.R
python 修订补充示例/第二轮/ch05_正文代码框.py
Rscript book_codeboxes_round2/appendix_delta_r.R
python book_codeboxes_round2/appendix_delta_py.py
Rscript 修订补充示例/第二轮/appendix_R_离线正文代码.R
python 修订补充示例/第二轮/appendix_Python_离线正文代码.py
```

- `修订补充示例/第二轮/`：第2—10章正文按章脚本、两个编程附录离线入口、两份明确标记的扩展模拟数据。
- `book_codeboxes_round2/`：第11—13章、对应技术补充、数学附录的独立代码框。非参数框读取本章主脚本输出，随包已附。
- `修订补充示例/`：第一轮补充的事件研究、合成控制和ARMA完整程序，已在本轮环境复跑。
- `data/processed/`：冻结的观测数据和明确标记的模拟数据。

再次运行会更新相应图表和结果CSV。数学或统计简例重抽样时，先核对种子、抽样单位和模拟次数。

## 教材章号与历史目录名

| 中文教材章号 | 配套目录 |
|---|---|
| 第2—10章 | Chapter02—Chapter10 |
| 第11章 非参数回归 | Chapter13_Nonparametric_Regression_chapter_nonparametric |
| 第12章 时间序列 | Chapter11_Time_series_analysis |
| 第13章 因果分析 | Chapter12_Causal_analyses_ch_causality |

## 这轮与运行有关的修正

1. 第9章LPM统一HC1与正态参考分布。
2. 第10章把旧的price/living_area/monthly_fee/city_area改成真实房价指数名；展示图使用预先规定的OLS基准。训练、调参与测试按时间分开。
3. 第13章R与Python读取同一份DiD和IV模拟CSV；DiD用单位聚类CR1，2SLS用结构残差计算HC0，FARS增加按事故聚类的敏感性结果。
4. RD、密度检验、中介、时间价值等书框补齐本地数据和初始化；模拟结果不代表中国实际政策或偏好。
5. 附录修正pandas/Matplotlib失效接口、路径、未定义对象及逆CDF约定，并重新生成插图。

## 数据背景

每行代表谁、变量单位、时期、筛选和已知缺失限制，见`data/metadata/数据字典与样本规则_20260922.md`。数据质量记录的是本地文件实际内容；本轮没有把真实观测刷新到2026年，也没有把旧文件名中的年份当成实际覆盖范围。第4章WDI经济体筛选和元数据冻结沿用第一轮修订。不要删除FARS全列相同的外观记录来“修复重复”：选列缺人员编号，无法据此判定不同人的身份。
