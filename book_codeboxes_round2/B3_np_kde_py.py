# Extracted verbatim from book_chapters/ch_nonparametric.tex; run from companion-code root.
from scipy.stats import gaussian_kde
import numpy as np, pandas as pd
df = pd.read_csv("Chapter13_Nonparametric_Regression_chapter_nonparametric/"
                 "results/chapter13_nonparametric_analysis_data.csv")
x = df["log_gdp_pc"].to_numpy()
sd_x = np.std(x, ddof=1)
h = 1.06 * sd_x * len(x)**(-1/5)
kde = gaussian_kde(x, bw_method=h/sd_x)
x_grid = np.linspace(x.min(), x.max(), 200)
density = kde(x_grid)
