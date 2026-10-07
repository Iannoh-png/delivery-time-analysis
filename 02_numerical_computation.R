# =============================================================================
# 02_numerical_computation.R  --  STAGE 2: numerical computation
# Goal: use R to *search* and *integrate* when there is no neat formula.
# Skills: minima/maxima (optimize, optim), maximum likelihood, root finding
#         (uniroot + our own bisection), numerical integration (integrate).
# =============================================================================

dir.create("figures", showWarnings = FALSE)
dir.create("data",    showWarnings = FALSE)
deliveries <- read.csv("data/deliveries_clean.csv")
x <- deliveries$time

# --- A. MAXIMA AND MINIMA IN ONE VARIABLE (warm-up) --------------------------
# optimize() searches an interval for a minimum (or maximum).
curve_f <- function(z) -(z - 3)^2 + 5          # a hill with its peak at z = 3
optimize(curve_f, interval = c(-10, 10), maximum = TRUE)   # finds peak ~ (3, 5)

valley_f <- function(z) (z - 3)^2 + 5          # a valley
optimize(valley_f, interval = c(-10, 10))                  # finds minimum

# Rule of thumb: to MAXIMISE something, minimise its negative.

# --- B. MAXIMUM LIKELIHOOD WITH optim() --------------------------------------
# Question: which gamma(shape, rate) makes OUR data most probable?
# Likelihood is a product of densities; we use the log (sums are easier) and
# flip the sign, so "smaller is better" and we can minimise.
neg_loglik <- function(par, x) {
  if (any(par <= 0)) return(Inf)               # parameters must be positive
  -sum(dgamma(x, shape = par[1], rate = par[2], log = TRUE))
}

fit <- optim(par = c(1, 0.1), fn = neg_loglik, x = x)
shape_hat <- fit$par[1]
rate_hat  <- fit$par[2]
cat("\nMLE  shape:", round(shape_hat, 3), " rate:", round(rate_hat, 4),
    " (convergence code", fit$convergence, "; 0 = success)\n")
cat("Implied mean:", round(shape_hat / rate_hat, 2), "minutes\n")

# Compare with a quick-and-dirty "method of moments" guess
m <- mean(x); v <- var(x)
cat("Method of moments  shape:", round(m^2 / v, 3), " rate:", round(m / v, 4), "\n")

# Does the fitted curve match the data?
png("figures/02_gamma_fit.png", width = 800, height = 500)
hist(x, freq = FALSE, breaks = 12, col = "grey85", border = "white",
     main = "Delivery times with fitted gamma curve", xlab = "Minutes")
curve(dgamma(x, shape_hat, rate_hat), add = TRUE, lwd = 2, col = "red")
dev.off()

# Save the fitted parameters for the next scripts
saveRDS(c(shape = shape_hat, rate = rate_hat), "data/gamma_fit.rds")

# --- C. ROOT FINDING ---------------------------------------------------------
# Question: at what time T are only 10% of deliveries slower than T?
# Rewrite it as f(T) = 0, where f(T) = P(time > T) - 0.10.
f <- function(t) (1 - pgamma(t, shape_hat, rate_hat)) - 0.10

root_builtin <- uniroot(f, interval = c(1, 200))$root

# Our own bisection, to see how root finders really work:
# keep halving an interval that is known to contain a sign change.
bisect <- function(f, lower, upper, tol = 1e-8, max_iter = 200) {
  if (f(lower) * f(upper) > 0) stop("f(lower) and f(upper) need opposite signs")
  for (i in 1:max_iter) {
    mid <- (lower + upper) / 2
    if (abs(f(mid)) < tol || (upper - lower) / 2 < tol)
      return(list(root = mid, iterations = i))
    if (f(lower) * f(mid) < 0) upper <- mid else lower <- mid
  }
  list(root = mid, iterations = max_iter)
}
root_bisect <- bisect(f, 1, 200)

cat("\n90th percentile of delivery time:\n")
cat("  uniroot():", round(root_builtin, 3), "\n")
cat("  bisection:", round(root_bisect$root, 3),
    "in", root_bisect$iterations, "iterations\n")
cat("  qgamma() (the direct formula):",
    round(qgamma(0.90, shape_hat, rate_hat), 3), "\n")

# --- D. NUMERICAL INTEGRATION ------------------------------------------------
# Probabilities are areas under the density curve. integrate() computes them
# even when we have no formula.
p_late <- integrate(dgamma, lower = 30, upper = Inf,
                    shape = shape_hat, rate = rate_hat)$value
cat("\nModel-based P(delivery > 30 min):", round(p_late, 3),
    "| check with pgamma:", round(1 - pgamma(30, shape_hat, rate_hat), 3),
    "| observed proportion:", round(mean(x > 30), 3), "\n")

# Expected value E[T] = integral of t * density(t)
mean_int <- integrate(function(t) t * dgamma(t, shape_hat, rate_hat),
                      lower = 0, upper = Inf)$value
cat("Mean from integration:", round(mean_int, 2),
    "| shape/rate:", round(shape_hat / rate_hat, 2), "\n")

