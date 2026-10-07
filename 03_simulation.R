# =============================================================================
# 03_simulation.R  --  STAGE 3: randomness and simulation
# Goal: see how sample results vary by repeating the "study" many times.
# Skills: random variables, loops vs replicate(), Monte Carlo, the Central
#         Limit Theorem, standard error, bootstrap.
# =============================================================================

set.seed(123)
dir.create("figures", showWarnings = FALSE)
deliveries <- read.csv("data/deliveries_clean.csv")
x <- deliveries$time
n <- length(x)

pars <- readRDS("data/gamma_fit.rds")        # saved by script 02
shape_hat <- pars["shape"]; rate_hat <- pars["rate"]

# --- A. REPEAT THE STUDY: loop version ---------------------------------------
# Imagine the company ran this exact study 5000 times. Each time the mean
# would be a bit different. How different? That spread is the standard error.
B <- 5000
sim_means_loop <- numeric(B)                 # empty box to fill
for (i in 1:B) {
  sim_means_loop[i] <- mean(rgamma(n, shape_hat, rate_hat))
}

# --- B. Same thing with replicate(): shorter, same idea ----------------------
sim_means <- replicate(B, mean(rgamma(n, shape_hat, rate_hat)))

se_sim    <- sd(sim_means)
se_theory <- (sqrt(shape_hat) / rate_hat) / sqrt(n)   # gamma sd / sqrt(n)
se_sample <- sd(x) / sqrt(n)
cat("Standard error of the mean (n =", n, "):\n")
cat("  simulated:", round(se_sim, 3), " theory:", round(se_theory, 3),
    " from sample:", round(se_sample, 3), "\n")

# --- C. CENTRAL LIMIT THEOREM ------------------------------------------------
# Individual times are skewed. Watch the *means* become bell-shaped as n grows.
png("figures/03_clt.png", width = 900, height = 700)
par(mfrow = c(2, 2))
for (size in c(2, 10, 50, 200)) {
  means <- replicate(3000, mean(rgamma(size, shape_hat, rate_hat)))
  hist(means, breaks = 30, col = "steelblue", border = "white",
       main = paste("Sample size n =", size), xlab = "Sample mean")
}
dev.off()

# --- D. BOOTSTRAP: resample the ACTUAL data ----------------------------------
# No distribution assumed: draw n values from our data WITH replacement,
# compute the mean, repeat. The spread shows the uncertainty in our estimate.
boot_means <- replicate(B, mean(sample(x, size = n, replace = TRUE)))
cat("\nBootstrap SE:", round(sd(boot_means), 3), "\n")

png("figures/03_bootstrap.png", width = 800, height = 500)
hist(boot_means, breaks = 40, col = "darkorange", border = "white",
     main = "Bootstrap distribution of the mean", xlab = "Mean delivery time")
abline(v = mean(x), lwd = 2)
abline(v = 30, col = "red", lty = 2, lwd = 2)
dev.off()

# --- E. MONTE CARLO ESTIMATE OF A PROBABILITY --------------------------------
# P(delivery > 30)? Simulate a huge number of deliveries and count.
big <- rgamma(1e6, shape_hat, rate_hat)
cat("\nMonte Carlo P(time > 30):", round(mean(big > 30), 4),
    "| exact:", round(1 - pgamma(30, shape_hat, rate_hat), 4), "\n")
cat("Monte Carlo P(time > 60):", round(mean(big > 60), 4),
    "| exact:", round(1 - pgamma(60, shape_hat, rate_hat), 4), "\n")

# Save bootstrap means for the inference script
saveRDS(boot_means, "data/boot_means.rds")
