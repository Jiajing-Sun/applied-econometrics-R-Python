# Extracted verbatim from book_chapters/ch12_causal.tex; run from companion-code root.
library(quadprog)
df <- read.csv("data/processed/chapter13_scm_cities_simulated.csv")
Y <- xtabs(outcome ~ year + city, data=df)
pre <- as.integer(rownames(Y)) < 2016
A <- Y[pre,-1]; y <- Y[pre,1]; J <- ncol(A)
fit <- solve.QP(2*(crossprod(A)+1e-10*diag(J)),
  2*as.vector(crossprod(A,y)), cbind(rep(1,J),diag(J)),
  c(1,rep(0,J)), meq=1)
w <- fit$solution
stopifnot(min(w)>-1e-8,abs(sum(w)-1)<1e-8)
gap <- Y[,1]-Y[,-1] %*% w
print(w); print(mean(gap[pre]^2)); print(mean(gap[!pre]))
