# Extracted verbatim from book_chapters/ch12_causal.tex; run from companion-code root.
library(sandwich)
df <- read.csv("data/processed/chapter13_event_common_timing_simulated.csv")
lags <- c(-4,-3,-2,0,1,2,3)
cols <- ifelse(lags<0,paste0("D_n",abs(lags)),paste0("D_",lags))
for (j in seq_along(lags))
  df[[cols[j]]] <- as.integer(df$treated==1 & df$rel_time==lags[j])
f <- as.formula(paste("Y ~",paste(cols,collapse=" + "),"+ factor(id)+factor(year)"))
fit_es <- lm(f,data=df)
V <- vcovCL(fit_es,cluster=df$id,type="HC1",cadjust=TRUE)
se <- sqrt(diag(V))[cols]; est <- coef(fit_es)[cols]
crit <- qt(.975,length(unique(df$id))-1)
plot(lags,est,ylim=range(est-crit*se,est+crit*se),
     xlab="相对处理时间",ylab="估计值")
arrows(lags,est-crit*se,lags,est+crit*se,angle=90,code=3,length=.04)
abline(h=0,lty=2)
pre <- cols[lags<0]; z <- coef(fit_es)[pre]
Fpre <- as.numeric(t(z)%*%solve(V[pre,pre],z))/length(pre)
print(pf(Fpre,length(pre),length(unique(df$id))-1,lower.tail=FALSE))
