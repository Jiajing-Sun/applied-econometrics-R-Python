# Extracted verbatim from book_chapters/ch12_causal.tex; run from companion-code root.
df <- read.csv("data/processed/chapter13_mediation_simulated.csv")
stopifnot(all(complete.cases(df[,c("X","D","M","Y")])))
effects <- function(dat) {
  te <- coef(lm(Y ~ D+X,dat))["D"]
  a <- coef(lm(M ~ D+X,dat))["D"]
  out <- coef(lm(Y ~ D+M+X,dat))
  c(TE=unname(te), ADE=unname(out["D"]), ACME=unname(a*out["M"]))
}
point <- effects(df)
set.seed(20260922)
boot <- replicate(1999, effects(df[sample.int(nrow(df),replace=TRUE), ]))
ci <- t(apply(boot,1,quantile,probs=c(.025,.975)))
print(cbind(estimate=point, SE=apply(boot,1,sd), ci))
stopifnot(abs(point["TE"]-point["ADE"]-point["ACME"])<1e-10)
