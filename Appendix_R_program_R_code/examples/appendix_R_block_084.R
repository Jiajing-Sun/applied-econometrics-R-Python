# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
# install.packages("eurostat")
library(eurostat)

# 月度失业率数据集（示例）
une <- get_eurostat("une_rt_m", time_format = "date")

# 保留一个小切片：总计、所有年龄、德国
une_de <- une[une$geo == "DE" & une$sex == "T" & une$age == "TOTAL", ]

head(une_de)
