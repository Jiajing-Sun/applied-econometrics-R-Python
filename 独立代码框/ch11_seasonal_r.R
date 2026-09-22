# Extracted verbatim from book_chapters/ch11_timeseries.tex; run from companion-code root.
library(forecast)

# 模拟月度指数，不是实际 CPI；从本代码块首行独立运行
set.seed(123)
t <- 1:120
y <- 100 + 0.5*t + 5*sin(2*pi*t/12) + rnorm(120, sd=2)
cpi_ts <- ts(y, start=c(2000,1), frequency=12)

# STL 分解
stl_fit <- stl(cpi_ts, s.window="periodic", robust=TRUE)
plot(stl_fit, main="STL 分解：趋势 + 季节 + 不规则")

# Holt-Winters 加法模型
hw_fit <- HoltWinters(cpi_ts, seasonal="additive")
hw_fc  <- forecast(hw_fit, h=12)
plot(hw_fc, main="Holt--Winters 12 个月预测")

# ETS 自动选择
ets_fit <- ets(cpi_ts)
summary(ets_fit)
autoplot(forecast(ets_fit, h=12))
