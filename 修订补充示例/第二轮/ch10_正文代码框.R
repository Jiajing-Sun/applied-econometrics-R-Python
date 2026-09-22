# 正文代码框顺序运行；扩展数据凡带“模拟”均非真实调查记录。
args <- commandArgs(trailingOnly=FALSE)
file_arg <- args[grepl("^--file=",args)]
script_dir <- if(length(file_arg)) dirname(normalizePath(gsub("~+~"," ",sub("^--file=","",file_arg[1]),fixed=TRUE))) else getwd()
repo_dir <- normalizePath(file.path(script_dir,"..",".."))
local_lib <- file.path(repo_dir,"..",".R-library")
if(dir.exists(local_lib)) .libPaths(c(local_lib,.libPaths()))
setwd(repo_dir)
library(sandwich)
library(lmtest)
set.seed(922)
df <- read.csv(file.path(repo_dir,"Chapter10_Prediction_ch_prediction/results/chapter10_nbs_70city_prediction_data.csv"),fileEncoding="UTF-8-BOM")

# 代码框 1: {R 中训练/测试预测}
data_path <- file.path("Chapter10_Prediction_ch_prediction",
                       "results", "chapter10_nbs_70city_prediction_data.csv")
df <- read.csv(data_path, fileEncoding="UTF-8-BOM")
train <- subset(df, month <= 9)
test  <- subset(df, month >= 10)
mod <- lm(second_hand_yoy ~ new_house_yoy + second_hand_mom + new_house_mom + first_tier,
          data = train)
pred <- predict(mod, newdata = test)
mean((test$second_hand_yoy - pred)^2)


# 代码框 2: {R 中按组诊断测试误差}
test$error <- test$second_hand_yoy - pred
test$sq_error <- test$error^2
aggregate(sq_error ~ month, data = test, mean)
aggregate(sq_error ~ first_tier, data = test, mean)


# 代码框 3: {R 中均值基准}
test$pred_train_mean <- mean(train$second_hand_yoy, na.rm = TRUE)
mean((test$second_hand_yoy - test$pred_train_mean)^2)

city_mean <- aggregate(second_hand_yoy ~ city, data = train, mean)
names(city_mean)[2] <- "pred_city_mean"
test_with_mean <- merge(test, city_mean, by = "city", all.x = TRUE)
mean((test_with_mean$second_hand_yoy - test_with_mean$pred_city_mean)^2)


# 代码框 4: {R 中随机森林}
library(ranger)
train_df <- train[, c("second_hand_yoy", "new_house_yoy", "second_hand_mom",
                       "new_house_mom", "first_tier")]
rf <- ranger(second_hand_yoy ~ ., data = train_df, num.trees = 500,
             mtry = 3, importance = "permutation")
# OOB MSE（ranger 默认口径，越小越好）
rf$prediction.error
# 置换重要性
importance(rf)

