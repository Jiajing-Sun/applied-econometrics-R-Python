# 第5章R：从教材按顺序提取；从仓库根目录运行。

# 代码框 1: book_chapters/ch05_simple_regression.tex:194 / ch05_simple_regression_0
raw <- read.csv("data/processed/nbs_70city_house_price_2025.csv",
                fileEncoding = "UTF-8-BOM")
key <- c("city", "date", "year", "month")
a <- subset(raw, market == "new_house", select = c(key, "yoy_index"))
b <- subset(raw, market == "second_hand", select = c(key, "yoy_index"))
stopifnot(!anyDuplicated(a[key]), !anyDuplicated(b[key]))
names(a)[names(a) == "yoy_index"] <- "new_house_yoy"
names(b)[names(b) == "yoy_index"] <- "second_hand_yoy"
df <- merge(a, b, by = key)
stopifnot(nrow(df) == 840,
          all(complete.cases(df[c("new_house_yoy", "second_hand_yoy")])))
mod <- lm(second_hand_yoy ~ new_house_yoy, data = df)
summary(mod)
confint(mod)


# 代码框 2: book_chapters/ch05_simple_regression.tex:365 / ch05_simple_regression_2
library(sandwich)
library(lmtest)
coeftest(mod, vcov = vcovHC(mod, type = "HC0"))
G <- length(unique(df$city))
V_city <- vcovCL(mod, cluster = df$city, type = "HC1", cadjust = TRUE)
coeftest(mod, vcov. = V_city, df = G - 1)


# 代码框 3: book_chapters/ch05_simple_regression.tex:486 / ch05_mc_r
set.seed(42)
n <- 50; beta0 <- 2; beta1 <- 0.5; sigma <- 1
x <- rnorm(n, mean=5, sd=2)   # 固定 X（重复抽样 Y）
SSX <- sum((x - mean(x))^2)

# 重复抽样 2000 次，每次估计 beta1
b1_hat <- replicate(2000, {
  y <- beta0 + beta1*x + rnorm(n, 0, sigma)
  coef(lm(y ~ x))["x"]
})

cat("理论均值:", beta1, "  模拟均值:", mean(b1_hat), "\n")
cat("理论 SE:", sigma/sqrt(SSX), "  模拟 SD:", sd(b1_hat), "\n")

# 分布图
hist(b1_hat, breaks=40, freq=FALSE,
     main=expression(hat(beta)[1] ~ "的抽样分布"),
     xlab=expression(hat(beta)[1]))
curve(dnorm(x, beta1, sigma/sqrt(SSX)), add=TRUE,
      col="red", lwd=2)
abline(v=beta1, lty=2, col="blue")  # 真实值

# 同一个模拟样本下比较预测区间与均值置信区间

m <- lm(y ~ x, data=data.frame(x=x, y=beta0+beta1*x+rnorm(n,0,sigma)))
x_new <- data.frame(x=seq(1,9,by=0.5))
ci  <- predict(m, x_new, interval="confidence", level=0.95)
pi  <- predict(m, x_new, interval="prediction",  level=0.95)

