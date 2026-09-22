# Extracted verbatim from technical_supplements/tech_rd_ch12.tex; run from companion-code root.
library(rdrobust)
library(rddensity)
df <- read.csv("data/processed/chapter13_rd_continuous_simulated.csv")
rdr <- rdrobust(y=df$Y_sharp,x=df$X,c=0,p=1,
                kernel="triangular",bwselect="mserd")
summary(rdr)
# 同步缩放估计带宽h和偏差带宽b，保持h/b
for (mult in c(.5,1,2)) {
  h_use <- as.numeric(rdr$bws[1,])*mult
  b_use <- as.numeric(rdr$bws[2,])*mult
  r <- rdrobust(df$Y_sharp,df$X,c=0,p=1,
                 kernel="triangular",h=h_use,b=b_use)
  print(cbind(r$coef,r$ci))
}
rdr_fuzzy <- rdrobust(df$Y_fuzzy,df$X,c=0,fuzzy=df$D,p=1,
                      kernel="triangular",bwselect="mserd")
summary(rdr_fuzzy)
rdplot(df$Y_sharp,df$X,c=0,p=1)
# Cattaneo--Jansson--Ma 局部多项式密度连续性检验
dd <- rddensity(df$X,c=0)
print(c(t=dd$test$t_jk,p=dd$test$p_jk))
