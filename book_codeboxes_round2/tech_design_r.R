# Extracted verbatim from technical_supplements/tech_ols_design_ch12.tex; run from companion-code root.
df <- data.frame(y=c(5,5,5,6,8,7,8,11),
                 d=c(1,0,1,0,1,0,0,1),
                 x=c(50,55,58,60,65,66,70,75))
m0 <- lm(y ~ d, data=df)
# 必须使用稳健标准误 (HC2 对应 Neyman 保守估计)
library(sandwich); library(lmtest)
V0 <- vcovHC(m0,type="HC2")
coeftest(m0,vcov=V0)
v_neyman <- var(df$y[df$d==1])/4 + var(df$y[df$d==0])/4
stopifnot(abs(V0["d","d"]-v_neyman)<1e-12)

# 加入基线协变量（Lin 2013 规范）
df$x_c <- df$x - mean(df$x)     # 去均值
m1 <- lm(y ~ d * x_c, data = df)
coeftest(m1, vcov = vcovHC(m1, type = "HC2"))
# 完全交互调整的主要保证是渐近性质；同时报告未调整结果
