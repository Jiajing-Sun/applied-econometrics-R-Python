# Extracted verbatim from book_chapters/ch12_causal.tex; run from companion-code root.
library(sandwich)
df <- read.csv("data/processed/nhtsa_fars_rd_age18_24_2018_2023.csv",
                fileEncoding="UTF-8-BOM")
df <- subset(df, age>=18 & age<=24)
df$outcome_observed <- df$drinking %in% c(0, 1)
mean(!df$outcome_observed)  # 结果变量缺失比例
df_h <- subset(df, outcome_observed & abs(age - 21) <= 3)
df_h$alcohol_involved <- as.integer(df_h$drinking == 1)
df_h$rv  <- df_h$age - 21
df_h$Z   <- as.integer(df_h$rv >= 0)
df_h$Zrv <- df_h$Z * df_h$rv
rd <- lm(alcohol_involved ~ Z + rv + Zrv, data = df_h)
print(coef(rd))
print(sqrt(diag(vcovHC(rd, type="HC0"))))
accident <- interaction(df_h$year,df_h$st_case,drop=TRUE)
print(sqrt(diag(vcovCL(rd,cluster=accident,type="HC1",cadjust=TRUE))))
