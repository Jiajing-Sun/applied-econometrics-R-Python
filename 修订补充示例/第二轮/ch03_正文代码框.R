# 第 3 章 R：按章顺序提取教材正文代码框。
# 从“配套代码”根目录运行；data/processed 为冻结数据目录。
# 此文件不含审查断言；保留教材显示用的表达式。


# 教材：ch03_probability.tex:185；ch03_bayes_r
# 企业违规检测数值验证
p_vio   <- 0.02    # 违规先验
p_alarm_vio  <- 0.95   # 灵敏度
p_alarm_comp <- 0.08   # 误报率

p_alarm  <- p_alarm_vio * p_vio + p_alarm_comp * (1 - p_vio)
p_vio_given_alarm <- (p_alarm_vio * p_vio) / p_alarm
cat("Pr(违规|报警) =", round(p_vio_given_alarm, 4), "\n")

# 模拟验证：生成 1e6 个企业
set.seed(42)
N <- 1e6
vio   <- rbinom(N, 1, p_vio)
alarm <- ifelse(vio==1, rbinom(N,1,p_alarm_vio),
                        rbinom(N,1,p_alarm_comp))
mean(vio[alarm == 1])   # 应接近 0.195


# 教材：ch03_probability.tex:334；
set.seed(2026)
B <- 10000
n <- 50
sample_means <- replicate(B, mean(sample(1:6, n, replace = TRUE)))
mean(sample_means)
sd(sample_means)


# 教材：ch03_probability.tex:522；
set.seed(2026)
coverage_B <- 5000
coverage_n <- 30
cover <- replicate(coverage_B, {
  yy <- sample(1:6, coverage_n, replace = TRUE)
  se <- sd(yy) / sqrt(coverage_n)
  ci <- mean(yy) + c(-1, 1) * qt(.975, coverage_n - 1) * se
  ci[1] <= 3.5 && ci[2] >= 3.5
})
mean(cover)

