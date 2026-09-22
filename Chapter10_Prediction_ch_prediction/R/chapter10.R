# Chapter 10: 预测
#
# 本章数据：国家统计局 70 个大中城市商品住宅销售价格指数（2025）。
# 教学对应关系：
#   教材变量 second_hand_yoy       -> 二手住宅同比价格指数
#   教材变量 new_house_yoy -> 新建商品住宅同比价格指数
#   教材变量 second_hand_mom -> 二手住宅环比价格指数
#   教材变量 new_house_mom   -> 新建住宅环比价格指数
#
# 本脚本保留原章方法：训练/测试划分、多项式复杂度比较、5 折交叉验证、
# 岭回归、LASSO、回归树和不同预测模型的测试误差比较。

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
if (length(file_arg) == 0) {
  script_dir <- getwd()
} else {
  script_dir <- dirname(normalizePath(gsub("~+~", " ", sub("^--file=", "", file_arg[1]), fixed=TRUE)))
}

chapter_dir <- normalizePath(file.path(script_dir, ".."))
repo_dir <- normalizePath(file.path(chapter_dir, ".."))
nbs_path <- file.path(repo_dir, "data", "processed", "nbs_70city_house_price_2025.csv")
fig_dir <- file.path(chapter_dir, "figures")
table_dir <- file.path(chapter_dir, "tables")
result_dir <- file.path(chapter_dir, "results")

dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)

use_quartz <- isTRUE(capabilities("aqua"))
if (use_quartz) {
  try(quartzFonts(PingFang = quartzFont(rep("PingFangSC-Regular", 4))), silent = TRUE)
}
png_type <- if (use_quartz) "quartz" else "cairo"
cn_family <- if (use_quartz) "PingFang" else ""

open_png <- function(filename, width = 1800, height = 1300, res = 220) {
  grDevices::png(filename = file.path(fig_dir, filename),
                 width = width, height = height, res = res, type = png_type)
  par(family = cn_family, mar = c(5, 5, 3, 1) + 0.1)
}

library(glmnet)
library(rpart)

raw <- read.csv(nbs_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
names(raw) <- gsub("^\ufeff", "", names(raw))

new_house <- raw[raw$market == "new_house",
                 c("year", "month", "date", "city", "mom_index", "yoy_index",
                   "ytd_average_index")]
second_hand <- raw[raw$market == "second_hand",
                   c("year", "month", "date", "city", "mom_index", "yoy_index",
                     "ytd_average_index")]
names(new_house)[names(new_house) == "mom_index"] <- "new_house_mom"
names(new_house)[names(new_house) == "yoy_index"] <- "new_house_yoy"
names(new_house)[names(new_house) == "ytd_average_index"] <- "new_house_ytd"
names(second_hand)[names(second_hand) == "mom_index"] <- "second_hand_mom"
names(second_hand)[names(second_hand) == "yoy_index"] <- "second_hand_yoy"
names(second_hand)[names(second_hand) == "ytd_average_index"] <- "second_hand_ytd"

df <- merge(new_house, second_hand,
            by = c("year", "month", "date", "city"))
Encoding(df$city) <- "UTF-8"
df$month_factor <- factor(df$month)
df$city_factor <- factor(df$city, levels = sort(unique(df$city), method="radix"))
df$first_tier <- ifelse(df$city %in% c("北京", "上海", "广州", "深圳"), 1, 0)
df$month_numeric <- df$month
df$second_hand_yoy <- df$second_hand_yoy
df$new_house_yoy <- df$new_house_yoy
df$second_hand_mom <- df$second_hand_mom
df$new_house_mom <- df$new_house_mom
df <- df[complete.cases(df[, c("second_hand_yoy", "new_house_yoy", "second_hand_mom",
                               "new_house_mom", "first_tier")]), ]
df <- df[order(df$city, df$month), ]
row.names(df) <- NULL

df$poly_x <- (df$new_house_yoy-mean(df$new_house_yoy[df$month<=9])) / sd(df$new_house_yoy[df$month<=9])
for (i in 2:10) {
  df[, paste0("new_house_yoy", i)] <- df$poly_x^i
}

write.csv(df[, c("year", "month", "date", "city", "second_hand_yoy", "new_house_yoy",
                 "second_hand_mom", "new_house_mom", "first_tier")],
          file.path(result_dir, "chapter10_nbs_70city_prediction_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 01--05: 训练数据、测试数据和多项式复杂度
# ------------------------------------------------------------------------------

n <- nrow(df)
train_ind <- which(df$month <= 9)
test_ind <- which(df$month >= 10)
df_train <- df[train_ind, ]
df_test <- df[test_ind, ]

mse <- function(y, yhat) mean((y - yhat)^2)

open_png("chapter10_time_split_scheme.png", width = 1800, height = 900, res = 220)
plot(df$month, rep(1, n),
     pch = 15,
     col = ifelse(seq_len(n) %in% train_ind, "#2166AC", "#D73027"),
     xlab = "月份",
     ylab = "",
     yaxt = "n",
     main = "按时间顺序划分训练集和测试集",
     xlim = c(1, 12))
axis(1, at = 1:12)
legend("topright", legend = c("训练集：1--9月", "测试集：10--12月"),
       col = c("#2166AC", "#D73027"), pch = 15, bty = "n")
dev.off()

set.seed(12)
random_train_ind <- sample(1:n, length(train_ind), replace = FALSE)
random_test_ind <- setdiff(1:n, random_train_ind)
ols_time <- lm(second_hand_yoy ~ new_house_yoy + second_hand_mom + new_house_mom + first_tier,
               data = df_train)
ols_random <- lm(second_hand_yoy ~ new_house_yoy + second_hand_mom + new_house_mom + first_tier,
                 data = df[random_train_ind, ])
split_compare <- data.frame(
  划分方式 = c("时间顺序切分", "随机切分"),
  训练样本量 = c(length(train_ind), length(random_train_ind)),
  测试样本量 = c(length(test_ind), length(random_test_ind)),
  `测试集 MSE` = c(
    mse(df$second_hand_yoy[test_ind], predict(ols_time, newdata = df[test_ind, ])),
    mse(df$second_hand_yoy[random_test_ind], predict(ols_random, newdata = df[random_test_ind, ]))
  ),
  check.names = FALSE
)
write.csv(split_compare,
          file.path(table_dir, "chapter10_split_comparison_mse.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

f <- "second_hand_yoy ~ new_house_yoy"
mse_train_list <- c()
mse_test_list <- c()
for (degree in 1:10) {
  if (degree == 1) {
    f_degree <- "second_hand_yoy ~ new_house_yoy"
  } else {
    terms <- c("new_house_yoy", paste0("new_house_yoy", 2:degree))
    f_degree <- paste("second_hand_yoy ~", paste(terms, collapse = " + "))
  }
  ols_model <- lm(as.formula(f_degree), data = df_train)
  yhat_train <- predict(ols_model, newdata = df_train)
  yhat_test <- predict(ols_model, newdata = df_test)
  mse_train_list <- c(mse_train_list, mse(df_train$second_hand_yoy, yhat_train))
  mse_test_list <- c(mse_test_list, mse(df_test$second_hand_yoy, yhat_test))
}

poly_mse_table <- data.frame(
  多项式次数 = 1:10,
  `训练集 MSE` = mse_train_list,
  `测试集 MSE` = mse_test_list,
  check.names = FALSE
)
write.csv(poly_mse_table,
          file.path(table_dir, "chapter10_polynomial_train_test_mse.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter10_polynomial_train_test_mse.png")
plot(poly_mse_table$多项式次数, poly_mse_table$`训练集 MSE`,
     type = "b", pch = 19, col = "#2166AC", lwd = 2,
     ylim = range(poly_mse_table[, c("训练集 MSE", "测试集 MSE")]),
     xlab = "多项式次数",
     ylab = "均方误差",
     main = "训练误差与测试误差")
lines(poly_mse_table$多项式次数, poly_mse_table$`测试集 MSE`,
      type = "b", pch = 17, col = "#D73027", lwd = 2)
legend("topright", legend = c("训练集 MSE", "测试集 MSE"),
       col = c("#2166AC", "#D73027"), pch = c(19, 17), lwd = 2, bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# 偏误--方差权衡模拟
# ------------------------------------------------------------------------------

set.seed(2026)
x_grid <- seq(0, 1, length.out = 160)
true_fun <- function(x) sin(2 * pi * x)
degrees_bv <- c(1, 3, 9)
R <- 250
pred_array <- array(NA_real_, dim = c(length(x_grid), length(degrees_bv), R))
for (r in 1:R) {
  x_sim <- runif(35)
  y_sim <- true_fun(x_sim) + rnorm(35, sd = 0.35)
  sim_train <- data.frame(x = x_sim, y = y_sim)
  sim_grid <- data.frame(x = x_grid)
  for (j in seq_along(degrees_bv)) {
    fit <- lm(y ~ poly(x, degrees_bv[j], raw = TRUE), data = sim_train)
    pred_array[, j, r] <- predict(fit, newdata = sim_grid)
  }
}
bv_rows <- lapply(seq_along(degrees_bv), function(j) {
  mean_pred <- rowMeans(pred_array[, j, ])
  variance <- apply(pred_array[, j, ], 1, var)
  data.frame(
    多项式次数 = degrees_bv[j],
    平均偏误平方 = mean((mean_pred - true_fun(x_grid))^2),
    平均方差 = mean(variance)
  )
})
bv_table <- do.call(rbind, bv_rows)
write.csv(bv_table,
          file.path(table_dir, "chapter10_bias_variance_simulation.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter10_bias_variance_simulation.png")
bar_heights <- t(as.matrix(bv_table[, c("平均偏误平方", "平均方差")]))
barplot(bar_heights,
        beside = FALSE,
        names.arg = paste0(bv_table$多项式次数, "阶"),
        col = c("#9ECAE1", "#FD8D3C"),
        ylim = c(0, max(colSums(bar_heights)) * 1.12),
        xlab = "模型复杂度",
        ylab = "平均误差分解",
        main = "偏误--方差权衡的模拟说明")
legend("topleft", legend = c("平均偏误平方", "平均方差"),
       fill = c("#9ECAE1", "#FD8D3C"), bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# Box 06: 扩展窗口验证
# ------------------------------------------------------------------------------

m <- 5
validation_months <- 5:9
MSE_hat <- sapply(validation_months, function(v) {
  fit <- lm(second_hand_yoy ~ new_house_yoy, data=df[df$month < v, ])
  mse(df$second_hand_yoy[df$month == v], predict(fit, newdata=df[df$month == v, ]))
})
cv_table <- data.frame(折 = 1:m, 验证月份=validation_months, MSE = MSE_hat)
write.csv(cv_table,
          file.path(table_dir, "chapter10_five_fold_cv_mse.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter10_five_fold_cv_mse.png")
barplot(cv_table$MSE, names.arg = paste0(cv_table$验证月份, "月"),
        col = "#9ECAE1", border = NA,
        xlab = "验证月份",
        ylab = "验证集MSE",
        main = "扩展窗口验证误差（验证月5—9月）")
abline(h = mean(cv_table$MSE), col = "#D73027", lwd = 2, lty = 2)
legend("topright", legend = "平均MSE", col = "#D73027", lty = 2, lwd = 2, bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# Box 07--17: 岭回归和 LASSO
# ------------------------------------------------------------------------------

Encoding(df$city) <- "UTF-8"
df$month_factor <- factor(df$month)
df$city_factor <- factor(df$city, levels = sort(unique(df$city), method="radix"))
X <- model.matrix(
  second_hand_yoy ~ new_house_yoy + second_hand_mom + new_house_mom + first_tier +
    month_numeric + city_factor,
  data = df
)[, -1]
Y <- df$second_hand_yoy

# Shared objective with Python: RSS/(2*n) + lambda*penalty;
# ridge penalty is sum(beta^2)/2; LASSO penalty is sum(abs(beta)).
pen_predict <- function(xt, yt, xa, lambda, method) {
  center <- colMeans(xt); scale <- sqrt(colMeans(sweep(xt,2,center)^2))
  scale[scale == 0] <- 1
  xs <- sweep(sweep(xt,2,center),2,scale,"/")
  za <- sweep(sweep(xa,2,center),2,scale,"/")
  ym <- mean(yt); yc <- yt-ym; nn <- length(yt)
  if (method == "ridge") {
    beta <- solve(crossprod(xs)+nn*lambda*diag(ncol(xs)), crossprod(xs,yc))
  } else {
    beta <- rep(0,ncol(xs)); norms <- colSums(xs^2)
    for (iter in 1:10000) {
      old <- beta; residual <- yc-as.vector(xs %*% beta)
      for (j in seq_along(beta)) {
        residual <- residual+xs[,j]*beta[j]
        rho <- sum(xs[,j]*residual)
        beta[j] <- if(norms[j] > 0) sign(rho)*max(abs(rho)-nn*lambda,0)/norms[j] else 0
        residual <- residual-xs[,j]*beta[j]
      }
      if(max(abs(beta-old)) < 1e-7) break
      if(iter == 10000) stop("LASSO did not converge")
    }
  }
  as.vector(ym+za %*% beta)
}
lambda_grid <- exp(seq(log(0.001), log(10), length.out=20))
time_cv <- function(method) {
  errors <- sapply(lambda_grid, function(lam) sapply(5:9, function(v) {
    tr <- which(df$month < v); va <- which(df$month == v)
    mse(Y[va],pen_predict(X[tr,],Y[tr],X[va,],lam,method))
  }))
  means <- colMeans(errors)
  list(lambda=lambda_grid, cvm=means, cvsd=apply(errors,2,sd),
       lambda.min=lambda_grid[which.min(means)])
}
ridge_model_cv <- time_cv("ridge")
lasso_model_cv <- time_cv("lasso")
ridge_cv_table <- data.frame(
  log_lambda = log(ridge_model_cv$lambda),
  cvm = ridge_model_cv$cvm,
  cvsd = ridge_model_cv$cvsd
)
lasso_cv_table <- data.frame(
  log_lambda = log(lasso_model_cv$lambda),
  cvm = lasso_model_cv$cvm,
  cvsd = lasso_model_cv$cvsd
)
write.csv(ridge_cv_table, file.path(table_dir, "chapter10_ridge_cv_curve.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(lasso_cv_table, file.path(table_dir, "chapter10_lasso_cv_curve.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter10_glmnet_cv_curves.png")
plot(ridge_cv_table$log_lambda, ridge_cv_table$cvm, type = "l",
     col = "#2166AC", lwd = 2,
     xlab = "log(lambda)",
     ylab = "交叉验证 MSE",
     main = "岭回归与 LASSO 的交叉验证曲线")
lines(lasso_cv_table$log_lambda, lasso_cv_table$cvm, col = "#D73027", lwd = 2)
abline(v = log(ridge_model_cv$lambda.min), col = "#2166AC", lty = 2)
abline(v = log(lasso_model_cv$lambda.min), col = "#D73027", lty = 2)
legend("bottomright", legend = c("岭回归", "LASSO"),
       col = c("#2166AC", "#D73027"), lwd = 2, bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# Box 18--24: 回归树
# ------------------------------------------------------------------------------

formCART <- second_hand_yoy ~ new_house_yoy + second_hand_mom + new_house_mom +
  first_tier + month_numeric + city_factor
cp_grid <- c(0,0.001,0.003,0.01,0.03,0.1)
cp_errors <- sapply(cp_grid, function(cp) mean(sapply(5:9,function(v) {
  fit <- rpart(formCART, data=df[df$month < v, ],
    control=rpart.control(minsplit=20,minbucket=5,cp=cp,xval=0))
  mse(df$second_hand_yoy[df$month == v],predict(fit,newdata=df[df$month == v, ]))
})))
best_cp <- cp_grid[which.min(cp_errors)]
pruned_tree <- rpart(formCART, data=df_train,
  control=rpart.control(minsplit=20,minbucket=5,cp=best_cp,xval=0))
cp_table <- data.frame(CP=cp_grid, time_cv_mse=cp_errors)
write.csv(cp_table,file.path(table_dir,"chapter10_cart_cp_table.csv"),row.names=FALSE)

display_df <- df_train
display_df$`新房同比指数` <- display_df$new_house_yoy
display_df$`二手住宅环比指数` <- display_df$second_hand_mom
display_df$`新建住宅环比指数` <- display_df$new_house_mom
display_df$`一线城市` <- display_df$first_tier
display_df$`月份` <- display_df$month_numeric
display_form <- second_hand_yoy ~ `新房同比指数` + `二手住宅环比指数` +
  `新建住宅环比指数` + `一线城市` + `月份`
display_tree <- rpart(display_form, data = display_df,
                      control = rpart.control(maxdepth = 3, minsplit = 30,
                                              minbucket = 12, cp = best_cp, xval=0))
open_png("chapter10_pruned_regression_tree.png", width = 2400, height = 1500)
par(mar = c(1, 1, 4, 1) + 0.1, xpd = NA)
# 固定使用rpart自带绘图，不因本机是否另装rpart.plot改变展示。
# 给节点文字加白底，并将阈值另起一行，避免连线穿过文字。
plot(display_tree, uniform = TRUE, branch = 1,
     main = "浅层回归树（可读展示版）")
boxed_text <- function(x, y, labels, ..., adj = 0.5) {
  labels <- sub("([<>]=?)", "\n\\1", labels)
  keep <- is.finite(x) & is.finite(y) & !is.na(labels)
  x <- x[keep]; y <- y[keep]; labels <- labels[keep]
  half_w <- strwidth(labels, cex = 1.15) / 2 + strwidth(" ", cex = 1.15)
  half_h <- strheight(labels, cex = 1.15) / 2 + strheight("M", cex = 1.15) * 0.25
  rect(x - half_w, y - half_h, x + half_w, y + half_h,
       col = "white", border = NA)
  graphics::text(x, y, labels, cex = 1.15, adj = adj)
}
text(display_tree, use.n = TRUE, FUN = boxed_text)

dev.off()

# ------------------------------------------------------------------------------
# Box 25--42: 不同预测模型的比较
# ------------------------------------------------------------------------------

ols_linear <- lm(second_hand_yoy ~ new_house_yoy + second_hand_mom + new_house_mom + first_tier,
                 data = df_train)
ols_poly <- lm(second_hand_yoy ~ new_house_yoy + new_house_yoy2 + new_house_yoy3 +
                 new_house_yoy4 + new_house_yoy5 +
                 second_hand_mom + new_house_mom + first_tier + month_numeric + city_factor,
               data = df_train)

yhat_ols_linear <- predict(ols_linear, newdata = df)
yhat_ols_poly <- predict(ols_poly, newdata = df)
yhat_ridge <- pen_predict(X[train_ind,],Y[train_ind],X,ridge_model_cv$lambda.min,"ridge")
yhat_lasso <- pen_predict(X[train_ind,],Y[train_ind],X,lasso_model_cv$lambda.min,"lasso")
yhat_tree <- predict(pruned_tree, newdata = df)

YHAT_models <- list(yhat_ols_linear, yhat_ols_poly, yhat_ridge,
                    yhat_lasso, yhat_tree)
model_names <- c("OLS 线性", "OLS 五阶多项式", "岭回归", "LASSO", "回归树")
MSE_train <- c()
MSE_test <- c()
for (yhat in YHAT_models) {
  MSE_train <- c(MSE_train, mse(Y[train_ind], yhat[train_ind]))
  MSE_test <- c(MSE_test, mse(Y[test_ind], yhat[test_ind]))
}

model_compare <- data.frame(
  模型 = model_names,
  `训练集 MSE` = MSE_train,
  `测试集 MSE` = MSE_test,
  check.names = FALSE
)
write.csv(model_compare,
          file.path(table_dir, "chapter10_model_comparison_mse.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

predictions <- data.frame(
  city = df$city,
  month = df$month,
  actual = Y,
  yhat_ols_linear = yhat_ols_linear,
  yhat_ols_poly = yhat_ols_poly,
  yhat_ridge = yhat_ridge,
  yhat_lasso = yhat_lasso,
  yhat_tree = yhat_tree,
  sample = ifelse(seq_len(n) %in% train_ind, "训练集", "测试集")
)
write.csv(predictions,
          file.path(result_dir, "chapter10_predictions_all_models.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter10_model_comparison_mse.png")
barplot(rbind(model_compare$`训练集 MSE`, model_compare$`测试集 MSE`),
        beside = TRUE,
        names.arg = model_compare$模型,
        col = c("#9ECAE1", "#FD8D3C"),
        xlab = "预测模型",
        ylab = "均方误差",
        main = "不同预测模型的训练与测试误差")
legend("topright", legend = c("训练集 MSE", "测试集 MSE"),
       fill = c("#9ECAE1", "#FD8D3C"), bty = "n")
dev.off()

open_png("chapter10_test_actual_vs_predicted.png")
display_yhat <- yhat_ols_linear  # Prespecified baseline; never select on test MSE.
plot(Y[test_ind], display_yhat[test_ind],
     pch = 16, col = rgb(0.13, 0.40, 0.67, 0.55),
     xlab = "实际二手住宅同比价格指数",
     ylab = "OLS线性基准预测值",
     main = "测试集：实际值与预测值")
abline(0, 1, col = "#D73027", lwd = 2, lty = 2)
dev.off()

summary_table <- data.frame(
  指标 = c("样本量", "训练集样本量", "测试集样本量",
         "简单 OLS 扩展窗口 CV 平均 MSE", "岭回归 lambda.min",
         "LASSO lambda.min", "固定展示模型测试集 MSE", "固定展示模型"),
  数值 = c(n, length(train_ind), length(test_ind),
         mean(MSE_hat), ridge_model_cv$lambda.min,
         lasso_model_cv$lambda.min,
         model_compare$`测试集 MSE`[1],
         model_compare$模型[1])
)
write.csv(summary_table,
          file.path(result_dir, "chapter10_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

cat("Chapter 10 finished.\n")
cat("Sample size:", n, "\n")
cat("Prespecified display model:", model_compare$模型[1], "\n")
cat("Prespecified baseline test MSE:", round(model_compare$`测试集 MSE`[1], 4), "\n")
