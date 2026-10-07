# =============================================================================
# 01_programming.R  --  STAGE 1: R programming
# Goal: create a dataset, load it, clean it, and summarise it.
# Skills: variables, data frames, importing data, missing values,
#         control flow (if/else, for, ifelse), functions, plotting.
# Run from the project root folder:  Rscript 01_programming.R
# =============================================================================

set.seed(42)                        # makes the random numbers repeatable
dir.create("data",    showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

# --- 1. VARIABLES ------------------------------------------------------------
n_deliveries <- 60      # how many deliveries we "observe"
claimed_mean <- 30      # the company's claim: 30 minutes on average
shape_true   <- 4       # controls how skewed delivery times are

# --- 2. CREATE DATA ----------------------------------------------------------
# Real delivery times are positive and right-skewed (a few very late orders),
# so we draw from a gamma distribution. Night shift is a bit slower than day.
shift     <- rep(c("day", "night"), each = n_deliveries / 2)
true_mean <- ifelse(shift == "day", 30.5, 35.5)
time      <- round(rgamma(n_deliveries, shape = shape_true,
                          rate = shape_true / true_mean), 1)

raw <- data.frame(id = 1:n_deliveries, shift = shift, time = time)

# Make the data a little "messy" on purpose, like real life: 2 missing values
raw$time[c(7, 41)] <- NA

# Save it as a CSV so we can practise importing real files
write.csv(raw, "data/deliveries_raw.csv", row.names = FALSE)

# --- 3. IMPORT AND INSPECT ---------------------------------------------------
deliveries_raw <- read.csv("data/deliveries_raw.csv")
str(deliveries_raw)                       # structure: columns and types
head(deliveries_raw)                      # first 6 rows
summary(deliveries_raw$time)              # note the NA's count
cat("Missing values per column:\n")
print(colSums(is.na(deliveries_raw)))

# --- 4. CLEAN ----------------------------------------------------------------
# Keep only rows where time is not missing
deliveries <- deliveries_raw[!is.na(deliveries_raw$time), ]
cat("Rows before:", nrow(deliveries_raw), " after:", nrow(deliveries), "\n")
write.csv(deliveries, "data/deliveries_clean.csv", row.names = FALSE)

# --- 5. CONTROL FLOW ---------------------------------------------------------
# (a) for loop: compute the mean by hand
total <- 0
for (t in deliveries$time) {
  total <- total + t
}
manual_mean <- total / nrow(deliveries)
cat("Mean by loop:", manual_mean, " | mean():", mean(deliveries$time), "\n")

# (b) if / else: a simple decision
if (manual_mean > claimed_mean) {
  cat("Sample mean is ABOVE the claim. But is that just chance? (Stage 4)\n")
} else {
  cat("Sample mean is at or below the claim.\n")
}

# (c) ifelse: vectorised version, applied to every row at once
deliveries$late <- ifelse(deliveries$time > claimed_mean, "late", "on time")
print(table(deliveries$late))

# --- 6. FUNCTIONS ------------------------------------------------------------
# A function wraps steps we want to reuse. We'll call this many times later.
summarize_times <- function(x) {
  c(n = length(x), mean = mean(x), sd = sd(x), median = median(x),
    max = max(x))
}
cat("\nOverall summary:\n")
print(round(summarize_times(deliveries$time), 2))

cat("\nSummary by shift:\n")
print(round(sapply(split(deliveries$time, deliveries$shift), summarize_times), 2))

# --- 7. PLOTS ----------------------------------------------------------------
png("figures/01_histogram.png", width = 800, height = 500)
hist(deliveries$time, breaks = 12, col = "steelblue", border = "white",
     main = "Delivery times", xlab = "Minutes")
abline(v = claimed_mean, col = "red", lwd = 2, lty = 2)   # the company's claim
dev.off()

png("figures/01_boxplot_by_shift.png", width = 700, height = 500)
boxplot(time ~ shift, data = deliveries, col = c("gold", "grey60"),
        ylab = "Minutes", main = "Delivery time by shift")
abline(h = claimed_mean, col = "red", lty = 2)
dev.off()
