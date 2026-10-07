# =============================================================================
# 04_inference.R  --  STAGE 4: statistical inference
# Goal: quantify uncertainty and make decisions.
# Skills: assumption checks, confidence intervals, hypothesis tests,
#         Type I error, power, sample size, two-group comparison,
#         multiple testing, effect size.
# =============================================================================

set.seed(2024)
dir.create("figures", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
deliveries <- read.csv("data/deliveries_clean.csv")
x <- deliveries$time
n <- length(x)
boot_means <- readRDS("data/boot_means.rds")

# --- A. CHECK ASSUMPTIONS ----------------------------------------------------
# The t-test assumes roughly normal data (or a large n). A QQ-plot compares
# our data to a perfect bell curve: points on the line = good fit.
png("figures/04_qqplots.png", width = 900, height = 450)
par(mfrow = c(1, 2))
qqnorm(x, main = "QQ-plot: raw times");      qqline(x, col = "red")
qqnorm(log(x), main = "QQ-plot: log(times)"); qqline(log(x), col = "red")
dev.off()

# --- B. CONFIDENCE INTERVALS -------------------------------------------------
ci_t    <- t.test(x)$conf.int
ci_boot <- quantile(boot_means, c(0.025, 0.975))
cat("Sample mean:", round(mean(x), 2), "\n")
cat("95% CI (t):        [", round(ci_t[1], 2), ",", round(ci_t[2], 2), "]\n")
cat("95% CI (bootstrap):[", round(ci_boot[1], 2), ",", round(ci_boot[2], 2), "]\n")

# --- C. HYPOTHESIS TESTS -----------------------------------------------------
# H0: true mean = 30.   p-value = how surprising our data would be if H0 true.
test_two <- t.test(x, mu = 30)                          # H1: mean != 30
test_gt  <- t.test(x, mu = 30, alternative = "greater") # H1: mean > 30
print(test_two)
cat("One-sided (mean > 30) p-value:", round(test_gt$p.value, 4), "\n")

# --- D. TYPE I ERROR AND POWER BY SIMULATION ---------------------------------
# One function answers both questions:
#   * if mu_true == 30 (H0 true): the rejection rate is the Type I error rate
#   * if mu_true != 30 (H0 false): the rejection rate is the POWER
reject_rate <- function(n, mu_true, mu0 = 30, reps = 2000,
                        shape = 4, alpha = 0.05) {
  mean(replicate(reps, {
    s <- rgamma(n, shape = shape, rate = shape / mu_true)
    t.test(s, mu = mu0)$p.value < alpha
  }))
}

cat("\nType I error (truth = 30, test at 5%):\n")
cat("  n = 10:", reject_rate(10, 30), "\n")
cat("  n = 60:", reject_rate(60, 30), "  <- should be close to 0.05\n")

sizes <- c(20, 60, 120, 240, 400)
power_vals <- sapply(sizes, reject_rate, mu_true = 33)
cat("\nPower to detect a true mean of 33 (3 minutes over the claim):\n")
print(data.frame(n = sizes, power = power_vals))

png("figures/04_power_curve.png", width = 800, height = 500)
plot(sizes, power_vals, type = "b", pch = 19, ylim = c(0, 1),
     xlab = "Sample size n", ylab = "Power",
     main = "Power to detect a 3-minute shortfall")
abline(h = 0.8, col = "red", lty = 2)
dev.off()

# --- E. SAMPLE SIZE NEEDED FOR 80% POWER -------------------------------------
# Gamma(shape 4) with mean 33 has sd = 33 / sqrt(4) = 16.5.
sd_assumed <- 33 / sqrt(4)
power_gap <- function(n) {
  power.t.test(n = n, delta = 3, sd = sd_assumed, type = "one.sample")$power - 0.8
}
n_needed <- uniroot(power_gap, interval = c(5, 2000))$root   # root finding again!
cat("\nSample size for 80% power:", ceiling(n_needed), "deliveries\n")

# --- F. TWO GROUPS: DAY vs NIGHT ---------------------------------------------
day   <- deliveries$time[deliveries$shift == "day"]
night <- deliveries$time[deliveries$shift == "night"]
test_shift <- t.test(night, day)              # Welch t-test (default)
print(test_shift)
wilcox_shift <- wilcox.test(night, day)       # no normality assumption
cat("Wilcoxon p-value:", round(wilcox_shift$p.value, 4), "\n")

# EFFECT SIZE: Cohen's d = difference in means / pooled sd
pooled_sd <- sqrt(((length(day) - 1) * var(day) + (length(night) - 1) * var(night)) /
                    (length(day) + length(night) - 2))
cohens_d <- (mean(night) - mean(day)) / pooled_sd
cat("Night minus day:", round(mean(night) - mean(day), 2), "minutes;",
    "Cohen's d =", round(cohens_d, 2), "\n")

# --- G. MULTIPLE TESTING: why running many tests is dangerous ----------------
# Run 20 tests where H0 is TRUE every time. Some will still look "significant".
one_family <- function(k = 20) {
  replicate(k, t.test(rgamma(30, 4, 4 / 30), mu = 30)$p.value)
}
p_vals <- one_family()
cat("\nOne family of 20 true-null tests:\n")
cat("  'significant' at 0.05:", sum(p_vals < 0.05),
    "| after Bonferroni:", sum(p.adjust(p_vals, "bonferroni") < 0.05), "\n")
at_least_one <- mean(replicate(1000, any(one_family() < 0.05)))
cat("  Chance of >=1 false positive across 20 tests (simulated):",
    at_least_one, "| theory:", round(1 - 0.95^20, 3), "\n")

# Save headline numbers for the write-up
saveRDS(list(n = n, mean = mean(x), ci_t = ci_t, ci_boot = ci_boot,
             p_two = test_two$p.value, p_gt = test_gt$p.value,
             power_n60 = power_vals[sizes == 60], n_needed = ceiling(n_needed),
             diff_shift = mean(night) - mean(day), p_shift = test_shift$p.value,
             d = cohens_d),
        "results/key_numbers.rds")
