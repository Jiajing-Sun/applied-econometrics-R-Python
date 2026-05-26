# ============================================================
# 附录 A：R 编程语言
# 脚本: appendix_r_data_wrangle_plot.R
# 内容: 数据整理（70城房价）、dplyr（WDI全球数据）、ggplot2 可视化
# 数据: data/processed/nbs_70city_house_price_2025.csv
#       data/processed/wdi_global_selected_indicators_wide.csv
# 输出: Appendix_R_program_R_code/figures/housing70_*.png
# ============================================================

library(readr)
library(dplyr)
library(ggplot2)

# 图表输出目录（相对于本代码仓库根目录）
fig_dir <- file.path("Appendix_R_program_R_code", "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================
# 第一部分：基础数据整理——70城新建住宅价格指数
# 演示: read.csv、筛选、新建变量、聚合、summary
# ==============================================================

# 读取数据
housing <- read_csv(
  "data/processed/nbs_70city_house_price_2025.csv",
  locale = locale(encoding = "UTF-8")
)

# 快速检查
head(housing)
str(housing)

# 只保留新建住宅，去掉 yoy_index 缺失行
housing_new <- housing |>
  filter(market == "new_house", !is.na(mom_index), !is.na(yoy_index))

# 新建变量：环比偏离（距100的偏差）
housing_new <- housing_new |>
  mutate(mom_deviation = mom_index - 100,
         yoy_deviation = yoy_index - 100)

head(housing_new)

# 按年份聚合：计算各年全国平均环比指数
avg_by_year <- housing_new |>
  group_by(year) |>
  summarise(
    avg_mom    = mean(mom_index, na.rm = TRUE),
    avg_yoy    = mean(yoy_index, na.rm = TRUE),
    n_obs      = n(),
    .groups    = "drop"
  ) |>
  arrange(year)

print(avg_by_year)

# 摘要统计
summary(housing_new[, c("mom_index", "yoy_index")])
mean(housing_new$mom_index)
var(housing_new$mom_index)
quantile(housing_new$mom_index, probs = c(0.1, 0.5, 0.9), na.rm = TRUE)
table(housing_new$year)

# 保存整理后的数据框
dir.create("output", showWarnings = FALSE)
saveRDS(housing_new, "output/housing_new_clean.rds")
write.csv(avg_by_year, "output/housing_avg_by_year.csv", row.names = FALSE)


# ==============================================================
# 第二部分：dplyr 数据处理——WDI 全球指标
# 演示: filter、select、arrange、mutate、group_by、summarise
# ==============================================================

wdi <- read_csv(
  "data/processed/wdi_global_selected_indicators_wide.csv",
  locale = locale(encoding = "UTF-8")
)

# 检查结构
wdi |>
  select(country, country_code, year, gdp_per_capita_constant_2015_usd,
         life_expectancy) |>
  head()

# 筛选：只保留亚洲主要经济体，去掉缺失行
asia <- wdi |>
  filter(country_code %in% c("CHN", "JPN", "KOR", "IND", "IDN"),
         !is.na(gdp_per_capita_constant_2015_usd),
         !is.na(life_expectancy)) |>
  select(country, year, gdp_per_capita_constant_2015_usd, life_expectancy,
         gdp_growth_pct) |>
  arrange(country, year)

head(asia, 10)

# 新建变量：对数人均 GDP，十年组
asia <- asia |>
  mutate(
    log_gdppc = log(gdp_per_capita_constant_2015_usd),
    decade    = (year %/% 10) * 10
  )

# 按国家和十年汇总
asia |>
  filter(!is.na(gdp_growth_pct)) |>
  group_by(country, decade) |>
  summarise(
    avg_growth   = mean(gdp_growth_pct, na.rm = TRUE),
    avg_lifeexp  = mean(life_expectancy),
    n            = n(),
    .groups      = "drop"
  ) |>
  filter(n >= 5) |>
  arrange(country, decade)


# ==============================================================
# 第三部分：ggplot2 可视化——70城房价多角度图表
# ==============================================================

# 合并新建和二手
housing_all <- housing |>
  filter(market %in% c("new_house", "second_hand"),
         !is.na(mom_index), !is.na(yoy_index)) |>
  mutate(market_cn = ifelse(market == "new_house", "新建住宅", "二手住宅"),
         date      = as.Date(paste0(date, "-01"), format = "%Y-%m-%d"))

# 5个代表城市
cities5 <- c("北京", "上海", "广州", "成都", "西安")
housing5 <- housing_new |>
  filter(city %in% cities5) |>
  mutate(date = as.Date(paste0(date, "-01"), format = "%Y-%m-%d"))

# ── 图1: 仅数据层 ──────────────────────────────────────────────
p_base <- ggplot(housing_new, aes(x = mom_index, y = yoy_index)) +
  labs(title = "70城新建商品住宅价格指数（仅数据层）")
ggsave(file.path(fig_dir, "housing70_base_layer.png"),
       p_base, width = 6, height = 4, dpi = 150)

# ── 图2: 散点图（环比 vs 同比，按市场类型着色）──────────────
p_scatter <- ggplot(housing_all,
                    aes(x = mom_index, y = yoy_index, colour = market_cn)) +
  geom_point(alpha = 0.35, size = 0.9) +
  geom_vline(xintercept = 100, linetype = "dashed", colour = "grey60") +
  geom_hline(yintercept = 100, linetype = "dashed", colour = "grey60") +
  scale_colour_manual(values = c("新建住宅" = "#2166ac", "二手住宅" = "#d6604d")) +
  labs(title = "环比与同比房价指数（按市场类型区分）",
       x = "环比指数（上月=100）",
       y = "同比指数（上年同月=100）",
       colour = "市场类型")

ggsave(file.path(fig_dir, "housing70_scatter_mom_yoy.png"),
       p_scatter, width = 6.5, height = 4.5, dpi = 150)

# ── 图3: 环比指数直方图 ────────────────────────────────────────
p_hist <- ggplot(housing_new, aes(x = mom_index)) +
  geom_histogram(bins = 30, fill = "#4393c3", colour = "white", linewidth = 0.3) +
  geom_vline(xintercept = 100, linetype = "dashed", colour = "firebrick",
             linewidth = 1.2) +
  labs(title = "70城新建住宅环比价格指数分布",
       x = "月度环比指数（新建住宅）", y = "频次")

ggsave(file.path(fig_dir, "housing70_hist_mom.png"),
       p_hist, width = 6.5, height = 4.5, dpi = 150)

# ── 图4: 5城市时序分面 ────────────────────────────────────────
p_facet <- ggplot(housing5, aes(x = date, y = mom_index)) +
  geom_point(size = 0.8, alpha = 0.6, colour = "#2166ac") +
  geom_hline(yintercept = 100, linetype = "dashed", colour = "grey60") +
  facet_wrap(~ city, nrow = 1) +
  labs(title = "五城市新建住宅月度环比价格指数",
       x = "", y = "环比指数") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7))

ggsave(file.path(fig_dir, "housing70_facet_cities.png"),
       p_facet, width = 13, height = 3.5, dpi = 150)

# ── 图5: 北京 + 线性趋势 ──────────────────────────────────────
bj <- housing5 |> filter(city == "北京") |> arrange(date)
p_trend <- ggplot(bj, aes(x = date, y = mom_index)) +
  geom_point(size = 1.2, alpha = 0.7, colour = "#4393c3") +
  geom_smooth(method = "lm", se = FALSE, colour = "firebrick", linewidth = 1.5) +
  geom_hline(yintercept = 100, linetype = "dashed", colour = "grey60") +
  labs(title = "北京新建住宅环比价格指数与线性趋势",
       x = "日期", y = "环比指数（新建住宅）")

ggsave(file.path(fig_dir, "housing70_trend_beijing.png"),
       p_trend, width = 6.5, height = 4.5, dpi = 150)

# ── 图6: 缩放视图（2022年后）─────────────────────────────────
p_zoom <- ggplot(
  housing_all |> filter(date >= "2022-01-01"),
  aes(x = mom_index, y = yoy_index, colour = market_cn)
) +
  geom_point(alpha = 0.35, size = 0.9) +
  coord_cartesian(xlim = c(96, 104), ylim = c(85, 115)) +
  scale_colour_manual(values = c("新建住宅" = "#2166ac", "二手住宅" = "#d6604d")) +
  labs(title = "房价指数缩放视图（2022年后）",
       x = "环比指数", y = "同比指数", colour = "市场类型")

ggsave(file.path(fig_dir, "housing70_zoom_mom.png"),
       p_zoom, width = 6.5, height = 4.5, dpi = 150)

# ── 图7: 极简主题 + 分面 ─────────────────────────────────────
p_minimal <- ggplot(housing5, aes(x = date, y = mom_index)) +
  geom_point(size = 0.8, alpha = 0.55, colour = "#636363") +
  geom_hline(yintercept = 100, colour = "#cccccc") +
  facet_wrap(~ city, nrow = 1) +
  theme_minimal() +
  labs(title = "五城市新建住宅价格（极简主题）",
       x = "", y = "环比指数") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7))

ggsave(file.path(fig_dir, "housing70_theme_minimal.png"),
       p_minimal, width = 13, height = 3.5, dpi = 150)

# ── 图8: 保存/复用的图形对象 ─────────────────────────────────
p_saved <- ggplot(housing_all,
                  aes(x = mom_index, y = yoy_index, colour = market_cn)) +
  geom_point(alpha = 0.3, size = 0.9) +
  scale_colour_manual(values = c("新建住宅" = "#2166ac", "二手住宅" = "#d6604d")) +
  labs(title = "新旧住宅环比与同比价格指数",
       x = "环比指数（上月=100）",
       y = "同比指数（上年同月=100）",
       colour = "市场类型")

ggsave(file.path(fig_dir, "housing70_saved_plot.png"),
       p_saved, width = 6.5, height = 4.5, dpi = 150)

cat("全部 R 附录图表生成完毕\n")
