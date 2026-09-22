# 第 4 章 R：按章顺序提取教材正文代码框。
# 从“配套代码”根目录运行；data/processed 为冻结数据目录。
# 此文件不含审查断言；保留教材显示用的表达式。


# 教材：ch04_correlation_inference.tex:91；ch4_corr_r
library(readr); library(dplyr)
df <- read_csv("data/processed/chapter04_wdi_life_gdp_2024_economies.csv")
stopifnot(nrow(df) == 192, !anyDuplicated(df$country_code))

# Pearson 相关检验（默认 H0: rho = 0）
res <- cor.test(df$log_gdp_pc, df$life_expectancy,
                method = "pearson", conf.level = 0.95)
res$statistic   # t 统计量
res$p.value     # 参考模型下的 p 值
res$conf.int    # Fisher 变换 95% 置信区间

# 手工验证 Fisher 变换
r <- res$estimate; n <- nrow(df)
z  <- 0.5 * log((1 + r)/(1 - r))
se_z <- 1/sqrt(n - 3)
ci_z <- z + c(-1, 1) * qnorm(0.975) * se_z
ci_r <- (exp(2 * ci_z) - 1)/(exp(2 * ci_z) + 1)
round(ci_r, 3)   # 应与 res$conf.int 一致

# 按世界银行地区分类作描述性比较（并非大洲分类）
df %>% group_by(region) %>%
  summarise(r = cor(log_gdp_pc, life_expectancy), n = n())


# 教材：ch04_correlation_inference.tex:241；ch4_boot_r
set.seed(42)
B <- 9999
r_boot <- replicate(B, {
  idx <- sample(nrow(df), replace = TRUE)
  cor(df$log_gdp_pc[idx], df$life_expectancy[idx])
})
quantile(r_boot, c(0.025, 0.975))   # 百分位 Bootstrap 95% CI


# 教材：ch04_correlation_inference.tex:400；
x <- df$log_gdp_pc; y <- df$life_expectancy
z <- log(df$population)
ex <- resid(lm(x ~ z)); ey <- resid(lm(y ~ z))
partial <- cor(ex, ey)
semipartial <- cor(y, ex)
delta_r2 <- summary(lm(y ~ z + x))$r.squared -
            summary(lm(y ~ z))$r.squared
stopifnot(abs(semipartial^2 - delta_r2) < 1e-10)
c(partial = partial, semipartial = semipartial)


# 教材：ch04_correlation_inference.tex:479；
set.seed(42)
T_obs <- cor(df$log_gdp_pc, df$life_expectancy)
B <- 9999
T_perm <- replicate(B, cor(sample(df$log_gdp_pc),
                           df$life_expectancy))
p_perm <- (1 + sum(abs(T_perm) >= abs(T_obs))) / (B + 1)
p_perm  # 置换 p 值

