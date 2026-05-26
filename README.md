# Applied Econometrics with R and Python

Code and open-data companion for the textbook:

*应用计量经济学：基于 R 与 Python 的回归分析与因果推断*

This repository follows the chapter-by-chapter style of
`Jiajing-Sun/Regression_with_R_and_Python`, but uses the public datasets and
Chinese figure/table labels prepared for the applied econometrics textbook.

## What is included

- Chapter-level `R/` scripts.
- Chapter-level `python/` scripts.
- Appendix R and Python code split into reusable topic files.
- `data/processed/`: the public teaching datasets used by the chapter examples.
- `data/data_license_inventory.csv`: source and license notes for the datasets.
- `data/chapter_dataset_map.csv`: chapter-to-dataset map.

Generated outputs are intentionally not versioned. Running the scripts will
create chapter-level `figures/`, `tables/`, and `results/` folders locally.

## Repository layout

- `Chapter02_Covariation_in_data/`
- `Chapter03_Basic_probability_theory_and_statistical_inference_ch_probability_theory/`
- `Chapter04_Correlation_and_inference_about_a_population_ch_population_korrelation/`
- `Chapter05_The_simple_linear_regression_model/`
- `Chapter06_Multiple_Linear_Regression/`
- `Chapter07_Nonlinear_functional_form/`
- `Chapter08_Regression_analysis_with_dependent_error_terms_ch_reg_dep_error/`
- `Chapter09_Binary_dependent_variable_ch_logit/`
- `Chapter10_Prediction_ch_prediction/`
- `Chapter11_Time_series_analysis/`
- `Chapter12_Causal_analyses_ch_causality/`
- `Chapter13_Nonparametric_Regression_chapter_nonparametric/`
- `Appendix_R_program_R_code/`
- `Appendix_Python_code/`
- `data/`
- `docs/`

## How to run a chapter

From the repository root, run for example:

```sh
Rscript Chapter10_Prediction_ch_prediction/R/chapter10.R
python Chapter10_Prediction_ch_prediction/python/chapter10.py
```

The scripts read from `data/processed/` and write generated figures, tables, and
intermediate results into their own chapter folders.

## Python setup

Install the Python dependencies once:

```sh
python -m pip install -r requirements.txt
```

## R setup

The examples use base R plus common applied-econometrics packages such as
`sandwich`, `lmtest`, `glmnet`, `rpart`, `rpart.plot`, `plm`, `nlme`, `readr`,
`dplyr`, and `ggplot2`. Install missing packages once, for example:

```r
install.packages(c("sandwich", "lmtest", "glmnet", "rpart", "rpart.plot",
                   "plm", "nlme", "readr", "dplyr", "ggplot2"))
```

Some appendix examples demonstrate API access and may require an internet
connection or an API key.

## Data notes

The repository includes only public teaching datasets. The data inventory in
`data/data_license_inventory.csv` records the source, license/terms page, and
redistribution note for each dataset. Generated outputs and large unused raw
files are excluded from version control.
