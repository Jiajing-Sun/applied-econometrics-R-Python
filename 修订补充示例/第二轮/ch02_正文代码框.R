# 第 2 章 R：按章顺序提取教材正文代码框。
# 从“配套代码”根目录运行；data/processed 为冻结数据目录。
# 此文件不含审查断言；保留教材显示用的表达式。


# 教材：ch02_covariation.tex:90；box:korr
df <- read.csv("data/processed/nbs_70city_house_price_2025.csv",
               fileEncoding = "UTF-8-BOM")
new_house <- subset(df, market == "new_house")
second_hand <- subset(df, market == "second_hand")

wide <- merge(new_house, second_hand,
              by = c("city", "date", "year", "month"),
              suffixes = c("_new", "_second"))
wide <- wide[order(wide$date, enc2utf8(wide$city), method = "radix"), ]
rownames(wide) <- NULL
x <- wide$yoy_index_new
y <- wide$yoy_index_second

xbar <- mean(x)
ybar <- mean(y)
s_xy <- sum((x - xbar) * (y - ybar)) / (length(x) - 1)
r_xy <- s_xy / (sd(x) * sd(y))
r_xy


# 教材：ch02_covariation.tex:218；box:spearman
wide$rank_new <- rank(wide$yoy_index_new, ties.method = "average")
wide$rank_second <- rank(wide$yoy_index_second, ties.method = "average")

cor(wide$rank_new, wide$rank_second)
cor(wide$yoy_index_new, wide$yoy_index_second, method = "spearman")


# 教材：ch02_covariation.tex:296；ch02_kendall_r
# Kendall tau_b（软件默认处理并列）
cor(
  wide$yoy_index_new, wide$yoy_index_second,
  method = "kendall"
)

# 手工演示（小样本示例）
x_s <- wide$yoy_index_new[1:20]
y_s <- wide$yoy_index_second[1:20]
n_s <- length(x_s)
pairs <- combn(n_s, 2)
concordant  <- sum(apply(pairs, 2, function(ij) {
  sign((x_s[ij[1]] - x_s[ij[2]]) * (y_s[ij[1]] - y_s[ij[2]])) == 1
}))
discordant  <- sum(apply(pairs, 2, function(ij) {
  sign((x_s[ij[1]] - x_s[ij[2]]) * (y_s[ij[1]] - y_s[ij[2]])) == -1
}))
tau_a <- (concordant - discordant) / choose(n_s, 2)
ties <- choose(n_s, 2) - concordant - discordant
cat("C =", concordant, "D =", discordant, "并列对 =", ties,
    "tau_a =", round(tau_a, 3), "\n")


# 教材：ch02_covariation.tex:387；box:ols
ols_model <- lm(yoy_index_second ~ yoy_index_new, data = wide)
coef(ols_model)
summary(ols_model)$r.squared


# 教材：ch02_covariation.tex:521；ch02_binned_r
# 按五分位切分新房同比指数
wide$x_bin <- cut(wide$yoy_index_new,
                  breaks = quantile(wide$yoy_index_new, probs = 0:5/5),
                  include.lowest = TRUE, labels = paste0("Q", 1:5))
bin_means <- aggregate(yoy_index_second ~ x_bin, data = wide, FUN = mean)
bin_means$x_mid <- as.numeric(tapply(wide$yoy_index_new, wide$x_bin, mean))
bin_means$n <- as.integer(table(wide$x_bin))
stopifnot(sum(bin_means$n) == nrow(wide))
print(bin_means)

# OLS 拟合线 + 分箱均值图
library(ggplot2)
ols_m <- lm(yoy_index_second ~ yoy_index_new, data = wide)
ggplot(wide, aes(x = yoy_index_new, y = yoy_index_second)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  geom_point(data = bin_means,
             aes(x = x_mid,
                 y = yoy_index_second),
             color = "red", size = 3, shape = 18)

