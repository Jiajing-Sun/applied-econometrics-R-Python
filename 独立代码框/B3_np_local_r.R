# Extracted verbatim from book_chapters/ch_nonparametric.tex; run from companion-code root.
df <- read.csv(paste0("Chapter13_Nonparametric_Regression_chapter_nonparametric/",
                       "results/chapter13_nonparametric_analysis_data.csv"))
grid <- seq(quantile(df$log_gdp_pc, .02),
            quantile(df$log_gdp_pc, .98), length.out=180)
pred <- sapply(grid, function(x0) {
  z <- df$log_gdp_pc - x0
  w <- exp(-0.5 * (z / 0.64)^2)
  coef(lm(df$co2_pc_tonnes ~ z, weights = w))[1]
})
