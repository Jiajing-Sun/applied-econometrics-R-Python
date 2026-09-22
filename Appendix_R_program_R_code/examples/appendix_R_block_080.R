# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
# install.packages("WDI")
library(WDI)

# 搜索指标名称（返回匹配项数据框）
head(WDIsearch("life expectancy"))

# 下载预期寿命和不变价人均 GDP
wb <- WDI(
  country   = c("CHN", "DEU", "USA"),
  indicator = c(le = "SP.DYN.LE00.IN", gdppc = "NY.GDP.PCAP.KD"),
  start     = 1995,
  end       = 2022,
  extra     = TRUE
)

# 基本检查
head(wb)
str(wb)

# 用 base R 排序，并快速绘制单个国家的图
wb <- wb[order(wb$country, wb$year), ]
china <- wb[wb$iso3c == "CHN", ]
stopifnot(nrow(china)>0, any(is.finite(china$gdppc)))

plot(china$year, china$gdppc, type = "l",
     xlab = "Year", ylab = "GDP per capita (constant prices)",
     main = "China: GDP per capita over time")
