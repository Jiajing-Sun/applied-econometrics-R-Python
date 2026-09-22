# Extracted verbatim from book_chapters/ch_nonparametric.tex; run from companion-code root.
library(mgcv)
df <- read.csv(paste0("Chapter13_Nonparametric_Regression_chapter_nonparametric/",
                       "results/chapter13_nonparametric_analysis_data.csv"))
fit <- gam(co2_pc_tonnes ~ s(log_gdp_pc), data=df, method="REML")
print(summary(fit)$s.table[,"edf"])  # 平滑项的 EDF
print(sum(fit$edf))                 # 全模型 EDF（含截距）
plot(fit, shade=TRUE)                # 中心化平滑分量，不含截距
