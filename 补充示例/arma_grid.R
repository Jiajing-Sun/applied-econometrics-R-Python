png("补充示例/arma_R.png",width=1000,height=700)
library(forecast)
library(tseries)

# 在配套代码根目录运行；使用与正文相同的历史快照
macro <- read.csv("data/processed/wdi_china_macro_1960_2024.csv",
                  fileEncoding="UTF-8-BOM")
macro <- macro[macro$year>=1978 & macro$gdp_constant_2015_usd>0, ]
macro <- macro[order(macro$year), ]
gdp_growth <- diff(log(macro$gdp_constant_2015_usd))
ts_growth <- ts(gdp_growth, start=1979, frequency=1)

# 手动估计 ARMA(1,0), ARMA(1,1), ARMA(2,1)
m10 <- Arima(ts_growth, order = c(1, 0, 0))
m11 <- Arima(ts_growth, order = c(1, 0, 1))
m21 <- Arima(ts_growth, order = c(2, 0, 1))
cat("AIC: AR(1)=", AIC(m10), " ARMA(1,1)=", AIC(m11),
    " ARMA(2,1)=", AIC(m21), "\n")

# 自动选择
fits <- list()
for (p in 0:2) for (q in 0:2) {
  fits[[paste(p,q)]] <- Arima(ts_growth, order=c(p,0,q),
                             include.mean=TRUE, method="ML")
}
stopifnot(all(sapply(fits, function(m) m$code == 0)))
m_auto <- fits[[which.min(sapply(fits, function(m) m$aicc))]]
summary(m_auto)

# 柳恩--博克斯（Ljung-Box）残差检验（前 10 滞后）
Box.test(residuals(m_auto), lag=10, type="Ljung-Box",
         fitdf=sum(arimaorder(m_auto)[c(1,3)]))
# 残差 ACF 图
acf(residuals(m_auto), main = "ARMA 残差 ACF")
dev.off()
write.csv(data.frame(order=names(fits),AICc=sapply(fits,function(m)m$aicc)),"补充示例/arma_R.csv",row.names=FALSE)
