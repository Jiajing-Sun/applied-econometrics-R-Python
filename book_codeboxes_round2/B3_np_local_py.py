# Extracted verbatim from book_chapters/ch_nonparametric.tex; run from companion-code root.
import numpy as np, pandas as pd
df = pd.read_csv("Chapter13_Nonparametric_Regression_chapter_nonparametric/"
                 "results/chapter13_nonparametric_analysis_data.csv")
grid = np.linspace(*df.log_gdp_pc.quantile([.02,.98]), 180)
pred = []
for x0 in grid:
    z = df["log_gdp_pc"].to_numpy() - x0
    Z = np.column_stack([np.ones(len(z)), z])
    root_w = np.exp(-0.25 * (z / 0.64)**2)
    beta = np.linalg.lstsq(Z * root_w[:, None],
        df["co2_pc_tonnes"].to_numpy() * root_w, rcond=None)[0]
    pred.append(beta[0])
pred = np.asarray(pred)
