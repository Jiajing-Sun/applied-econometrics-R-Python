# Extracted verbatim from Appendix Maths.tex; run from companion-code root.
df <- read.csv("data/processed/appendix_choice_vot_simulated.csv")
m <- glm(choice ~ time_diff + cost_diff,
         family = binomial(), data = df)
b <- coef(m); V <- vcov(m)
vot <- unname(b[2] / b[3])
C <- c(0, 1 / b[3], -b[2] / b[3]^2)
se_vot <- sqrt(drop(C %*% V %*% C))
print(c(VOT = vot, SE = se_vot,
        low = vot - qnorm(.975) * se_vot,
        high = vot + qnorm(.975) * se_vot))
# 对系数的正态近似区间取指数：优势比，不是概率比
se_b <- sqrt(diag(V))
print(cbind(OR = exp(b),
            low = exp(b - qnorm(.975) * se_b),
            high = exp(b + qnorm(.975) * se_b)))
