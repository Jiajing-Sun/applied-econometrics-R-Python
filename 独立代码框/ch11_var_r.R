# Extracted verbatim from book_chapters/ch11_timeseries.tex; run from companion-code root.
library(vars)

macro <- read.csv("data/processed/wdi_china_macro_1960_2024.csv",
                  fileEncoding="UTF-8-BOM")
macro <- macro[macro$year>=1978 & macro$year<=2024, ]
macro <- macro[order(macro$year), ]
stopifnot(all(diff(macro$year)==1),
          all(complete.cases(macro[,c("gdp_constant_2015_usd","trade_pct_gdp")])))
y_mat <- cbind(gdp=100*diff(log(macro$gdp_constant_2015_usd)),
               trade_change=diff(macro$trade_pct_gdp))
y_ts <- ts(y_mat, start=1979, frequency=1)

# 用 AIC 选择滞后阶数（最多 4 阶）
lag_sel <- VARselect(y_ts, lag.max=4, type="const")
print(lag_sel$selection)   # AIC, BIC, HQ, FPE 各自选出的阶数

# 估计 AIC 实际选出的阶数，检查稳定性
p_opt <- lag_sel$selection["AIC(n)"]
var_fit <- VAR(y_ts, p=p_opt, type="const")
summary(var_fit)
stopifnot(all(roots(var_fit)<1))

# 贸易变化是否对 GDP 增长有额外预测信息
causality(var_fit, cause="trade_change")$Granger

# 指定排序下，GDP 对贸易创新的响应（10期）
set.seed(20260922)
irf_obj <- irf(var_fit, impulse="trade_change", response="gdp",
               n.ahead=10, boot=TRUE, runs=999, ci=0.95)
plot(irf_obj)

# 预测误差方差分解
fevd_obj <- fevd(var_fit, n.ahead=10)
plot(fevd_obj)
