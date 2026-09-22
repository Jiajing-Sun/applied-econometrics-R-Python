# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
dir.create("data_cache", showWarnings = FALSE)
saveRDS(wb, file = "data_cache/wb_le_gdppc.rds")

# 以后可这样读取：
# wb <- readRDS("data_cache/wb_le_gdppc.rds")
