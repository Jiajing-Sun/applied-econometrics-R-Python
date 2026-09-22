# 第6—10章正文代码框：第二轮核验版本

这些脚本从本书本地分析CSV读取数据，然后按正文顺序运行所有代码框。R与Python每章各一份，共36个代码框；须先有对应章节主脚本输出，随包已附。

## 运行

- R：`Rscript ch06_正文代码框.R`（以实际脚本路径替换）。依赖 sandwich、lmtest；第8章另需 survey；第9章 MASS、nnet；第10章 ranger。缺包时先按本机R配置安装。脚本优先使用本轮工作目录 `.R-library`（若存在）。
- Python：使用含 numpy、pandas、scipy、statsmodels、scikit-learn 的环境运行对应 `.py`。无需 marginaleffects。

## 两份明确标记的模拟数据

- `ch08_调查加权_模拟.csv`：600条模拟个人记录，3个抽样层各200人，权重比1:2:3；用于说明分层加权接口。educ为年，age为岁，urban为0/1，income为模拟收入单位，不对应任何真实调查、城市或统计公布值。忽略有限总体修正。
- `ch09_有序多项选择_模拟.csv`：600条模拟记录。edu_level顺序低/中/高；transport无序类别公交/地铁/汽车；age为岁，income按模拟千元计，distance按模拟公里计，log_income为自然对数。仅用于演示有序和多项模型接口，不能报告为真实教育或出行结论。

第8章survey复杂设计标准误与Python独立观测WLS+HC1的目标不同，不应期待标准误数值相同。第10章随机森林只是补充调用示例，OOB不是时间外推验证。
