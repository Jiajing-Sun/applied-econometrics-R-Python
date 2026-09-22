# Extracted verbatim from Appendix Maths.tex; run from companion-code root.
import numpy as np
import pandas as pd
from scipy.stats import norm
import statsmodels.formula.api as smf

df = pd.read_csv("data/processed/appendix_choice_vot_simulated.csv")
m = smf.logit("choice ~ time_diff + cost_diff", data=df).fit(disp=0)
b = m.params.to_numpy()
V = m.cov_params().to_numpy()
vot = b[1] / b[2]
C = np.array([0, 1 / b[2], -b[1] / b[2]**2])
se_vot = np.sqrt(C @ V @ C)
print(dict(VOT=vot, SE=se_vot,
           low=vot-norm.ppf(.975)*se_vot,
           high=vot+norm.ppf(.975)*se_vot))
print(pd.DataFrame({"OR": np.exp(m.params),
                    "low": np.exp(m.conf_int()[0]),
                    "high": np.exp(m.conf_int()[1])}))
