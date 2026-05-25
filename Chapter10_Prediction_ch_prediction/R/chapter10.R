# Chapter 10: 预测
#
# 本章数据：国家统计局 70 个大中城市商品住宅销售价格指数（2025）。
# 教学对应关系：
#   教材变量 price       -> 二手住宅同比价格指数
#   教材变量 living_area -> 新建商品住宅同比价格指数
#   教材变量 monthly_fee -> 二手住宅环比价格指数
#   教材变量 city_area   -> 新建住宅环比价格指数
#
# 本脚本保留原章方法：训练/测试划分、多项式复杂度比较、5 折交叉验证、
# 岭回归、LASSO、回归树和不同预测模型的测试误差比较。

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
if (length(file_arg) == 0) {
  script_dir <- getwd()
} else {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
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
df$month_factor <- factor(df$month)
df$city_factor <- factor(df$city)
df$first_tier <- ifelse(df$city %in% c("北京", "上海", "广州", "深圳"), 1, 0)
df$month_numeric <- df$month
df$price <- df$second_hand_yoy
df$living_area <- df$new_house_yoy
df$monthly_fee <- df$second_hand_mom
df$city_area <- df$new_house_mom
df <- df[complete.cases(df[, c("price", "living_area", "monthly_fee",
                               "city_area", "first_tier")]), ]
df <- df[order(df$city, df$month), ]
row.names(df) <- NULL

for (i in 2:10) {
  df[, paste0("living_area", i)] <- df$living_area^i
}

write.csv(df[, c("year", "month", "date", "city", "price", "living_area",
                 "monthly_fee", "city_area", "first_tier")],
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
ols_time <- lm(price ~ living_area + monthly_fee + city_area + first_tier,
               data = df_train)
ols_random <- lm(price ~ living_area + monthly_fee + city_area + first_tier,
                 data = df[random_train_ind, ])
split_compare <- data.frame(
  划分方式 = c("时间顺序切分", "随机切分"),
  训练样本量 = c(length(train_ind), length(random_train_ind)),
  测试样本量 = c(length(test_ind), length(random_test_ind)),
  `测试集 MSE` = c(
    mse(df$price[test_ind], predict(ols_time, newdata = df[test_ind, ])),
    mse(df$price[random_test_ind], predict(ols_random, newdata = df[random_test_ind, ]))
  ),
  check.names = FALSE
)
write.csv(split_compare,
          file.path(table_dir, "chapter10_split_comparison_mse.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

f <- "price ~ living_area"
mse_train_list <- c()
mse_test_list <- c()
for (degree in 1:10) {
  if (degree == 1) {
    f_degree <- "price ~ living_area"
  } else {
    terms <- c("living_area", paste0("living_area", 2:degree))
    f_degree <- paste("price ~", paste(terms, collapse = " + "))
  }
  ols_model <- lm(as.formula(f_degree), data = df_train)
  yhat_train <- predict(ols_model, newdata = df_train)
  yhat_test <- predict(ols_model, newdata = df_test)
  mse_train_list <- c(mse_train_list, mse(df_train$price, yhat_train))
  mse_test_list <- c(mse_test_list, mse(df_test$price, yhat_test))
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
barplot(t(as.matrix(bv_table[, c("平均偏误平方", "平均方差")])),
        beside = FALSE,
        names.arg = paste0(bv_table$多项式次数, "阶"),
        col = c("#9ECAE1", "#FD8D3C"),
        xlab = "模型复杂度",
        ylab = "平均误差分解",
        main = "偏误--方差权衡的模拟说明")
legend("topright", legend = c("平均偏误平方", "平均方差"),
       fill = c("#9ECAE1", "#FD8D3C"), bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# Box 06: 5 折交叉验证
# ------------------------------------------------------------------------------

set.seed(12)
m <- 5
shuffle_ind <- sample(train_ind, length(train_ind), replace = FALSE)
fold_indexes <- cut(seq_along(shuffle_ind), breaks = m, labels = FALSE)
fold_id <- setNames(fold_indexes, shuffle_ind)

MSE_hat <- rep(NA, m)
for (i in 1:m) {
  leave_out_ind <- as.integer(names(fold_id)[fold_id == i])
  leave_in_ind <- setdiff(train_ind, leave_out_ind)
  train_df <- df[leave_in_ind, ]
  test_df <- df[leave_out_ind, ]
  ols_train <- lm(price ~ living_area, data = train_df)
  pred <- predict(ols_train, test_df)
  MSE_hat[i] <- mse(test_df$price, pred)
}
cv_table <- data.frame(折 = 1:m, MSE = MSE_hat)
write.csv(cv_table,
          file.path(table_dir, "chapter10_five_fold_cv_mse.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter10_five_fold_cv_mse.png")
barplot(cv_table$MSE, names.arg = paste0("第", cv_table$折, "折"),
        col = "#9ECAE1", border = NA,
        xlab = "交叉验证折",
        ylab = "验证集MSE",
        main = "5折交叉验证误差")
abline(h = mean(cv_table$MSE), col = "#D73027", lwd = 2, lty = 2)
legend("topright", legend = "平均MSE", col = "#D73027", lty = 2, lwd = 2, bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# Box 07--17: 岭回归和 LASSO
# ------------------------------------------------------------------------------

df$month_factor <- factor(df$month)
df$city_factor <- factor(df$city)
X <- model.matrix(
  price ~ living_area + monthly_fee + city_area + first_tier +
    month_numeric + city_factor,
  data = df
)[, -1]
Y <- df$price

ridge_model_cv <- cv.glmnet(X[train_ind, ], Y[train_ind], alpha = 0,
                            standardize = TRUE)
lasso_model_cv <- cv.glmnet(X[train_ind, ], Y[train_ind], alpha = 1,
                            standardize = TRUE)

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
legend("topright", legend = c("岭回归", "LASSO"),
       col = c("#2166AC", "#D73027"), lwd = 2, bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# Box 18--24: 回归树
# ------------------------------------------------------------------------------

formCART <- price ~ living_area + monthly_fee + city_area +
  first_tier + month_numeric + city_factor
CART_model <- rpart(formCART, data = df_train,
                    control = rpart.control(minsplit = 20, minbucket = 5, cp = 0))
cp_table <- printcp(CART_model)
best_cp <- cp_table[which.min(cp_table[, "xerror"]), "CP"]
pruned_tree <- prune(CART_model, cp = best_cp)
write.csv(as.data.frame(cp_table),
          file.path(table_dir, "chapter10_cart_cp_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter10_pruned_regression_tree.png", width = 2200, height = 1400)
plot(pruned_tree, uniform = TRUE, branch = 0.5,
     main = "剪枝后的回归树")
text(pruned_tree, use.n = TRUE, cex = 0.65)
dev.off()

# ------------------------------------------------------------------------------
# Box 25--42: 不同预测模型的比较
# ------------------------------------------------------------------------------

ols_linear <- lm(price ~ living_area + monthly_fee + city_area + first_tier,
                 data = df_train)
ols_poly <- lm(price ~ living_area + living_area2 + living_area3 +
                 living_area4 + living_area5 +
                 monthly_fee + city_area + first_tier + month_numeric + city_factor,
               data = df_train)

yhat_ols_linear <- predict(ols_linear, newdata = df)
yhat_ols_poly <- predict(ols_poly, newdata = df)
yhat_ridge <- as.numeric(predict(ridge_model_cv, newx = X, s = "lambda.min"))
yhat_lasso <- as.numeric(predict(lasso_model_cv, newx = X, s = "lambda.min"))
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
best_yhat <- YHAT_models[[which.min(model_compare$`测试集 MSE`)]]
plot(Y[test_ind], best_yhat[test_ind],
     pch = 16, col = rgb(0.13, 0.40, 0.67, 0.55),
     xlab = "实际二手住宅同比价格指数",
     ylab = "最佳模型预测值",
     main = "测试集：实际值与预测值")
abline(0, 1, col = "#D73027", lwd = 2, lty = 2)
dev.off()

summary_table <- data.frame(
  指标 = c("样本量", "训练集样本量", "测试集样本量",
         "简单 OLS 5 折 CV 平均 MSE", "岭回归 lambda.min",
         "LASSO lambda.min", "测试集最小 MSE", "测试集最优模型"),
  数值 = c(n, length(train_ind), length(test_ind),
         mean(MSE_hat), ridge_model_cv$lambda.min,
         lasso_model_cv$lambda.min,
         min(model_compare$`测试集 MSE`),
         model_compare$模型[which.min(model_compare$`测试集 MSE`)])
)
write.csv(summary_table,
          file.path(result_dir, "chapter10_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

cat("Chapter 10 finished.\n")
cat("Sample size:", n, "\n")
cat("Best test model:", model_compare$模型[which.min(model_compare$`测试集 MSE`)], "\n")
cat("Best test MSE:", round(min(model_compare$`测试集 MSE`), 4), "\n")
