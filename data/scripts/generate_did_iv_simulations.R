# Run from companion root. These are simulated teaching examples, not observations.
set.seed(20260412)
did_units <- 40; did_times <- -3:3
did_df <- expand.grid(unit=1:did_units,period=did_times)
did_df$treated <- as.integer(did_df$unit>did_units/2)
unit_fe <- rnorm(did_units,sd=.7)
did_df$unit_fe <- unit_fe[did_df$unit]
did_df$post <- as.integer(did_df$period>=0)
did_df$common_trend <- .35*did_df$period
did_df$tau <- 1.8*did_df$treated*did_df$post
did_df$y <- 5+did_df$unit_fe+did_df$common_trend+did_df$tau+rnorm(nrow(did_df),sd=.5)
write.csv(did_df,'data/processed/chapter13_did_simulated.csv',row.names=FALSE)
iv_n <- 800; z <- rbinom(iv_n,1,.5); u <- rnorm(iv_n)
d <- .7*z+.9*u+rnorm(iv_n); y <- 1+2*d+u+rnorm(iv_n)
write.csv(data.frame(y=y,d=d,z=z,u=u),'data/processed/chapter13_iv_simulated.csv',row.names=FALSE)
