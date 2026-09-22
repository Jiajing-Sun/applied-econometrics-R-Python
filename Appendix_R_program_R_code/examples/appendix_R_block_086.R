# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
# install.packages("quantmod")
library(quantmod)

# 示例：从 Yahoo Finance 下载微软日度价格
getSymbols("MSFT", src = "yahoo")

# 查看前几行
head(MSFT)

# 绘制复权收盘价
plot(Ad(MSFT), main = "MSFT adjusted close", ylab = "Price")
