# 在自己的R环境中安装正文与离线附录使用的包；已安装的包保留。
# 实测版本另见 R-package-versions.csv，在线API扩展按附录另装。
packages <- c("ggplot2", "readr", "dplyr", "tidyr", "tibble", "purrr", "stringr",
              "sandwich", "lmtest", "plm", "nlme", "glmnet", "rpart", "ranger",
              "forecast", "tseries", "vars", "mgcv", "quadprog", "rdrobust",
              "rddensity", "survey", "MASS", "nnet")
missing <- setdiff(packages, rownames(installed.packages()))
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
print(packages)
