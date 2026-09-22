# Extracted verbatim from book_chapters/ch11_timeseries.tex; run from companion-code root.
library(sandwich)
dft <- read.csv("data/processed/wdi_china_macro_1960_2024.csv",
                 fileEncoding="UTF-8-BOM")
dft <- dft[dft$year>=1978 & dft$year<=2024, ]
dft <- dft[order(dft$year), ]
stopifnot(all(diff(dft$year)==1), all(dft$gdp_constant_2015_usd>0))
dft$dloggdp <- c(NA,100*diff(log(dft$gdp_constant_2015_usd)))
dft$dloggdpL1 <- c(NA,head(dft$dloggdp,-1))
reg_df <- subset(dft, !is.na(dloggdp) & !is.na(dloggdpL1))
ar1_model <- lm(dloggdp ~ dloggdpL1, data = reg_df)
coef(ar1_model)                                    # \hat\alpha, \hat\phi
sqrt(diag(vcov(ar1_model)))                        # 普通 OLS 标准误
sqrt(diag(NeweyWest(ar1_model, lag=5, prewhite=FALSE, adjust=FALSE)))  # HAC 标准误
