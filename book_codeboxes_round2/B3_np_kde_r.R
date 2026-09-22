# Extracted verbatim from book_chapters/ch_nonparametric.tex; run from companion-code root.
df <- read.csv(paste0("Chapter13_Nonparametric_Regression_chapter_nonparametric/",
                       "results/chapter13_nonparametric_analysis_data.csv"))
x <- df$log_gdp_pc
h <- 1.06 * sd(x) * length(x)^(-1/5)
dens <- density(x, kernel="gaussian", bw=h, n=1024)
plot(dens, main="log GDP 的核密度估计")
