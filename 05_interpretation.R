# =============================================================================
# 05_interpretation.R  --  STAGES 5 & 6: the question and the conclusion
# Goal: turn numbers into a sentence a manager can act on.
# Pattern:  STATISTIC -> EVIDENCE -> CONCLUSION
# =============================================================================

dir.create("results", showWarnings = FALSE)
k <- readRDS("results/key_numbers.rds")

question <- "Is the true mean delivery time different from the claimed 30 minutes, and by how much?"

statistic <- sprintf(
  "STATISTIC: Across %d deliveries the mean was %.1f min (95%% CI %.1f to %.1f).",
  k$n, k$mean, k$ci_t[1], k$ci_t[2])

evidence <- if (k$p_two < 0.05) {
  sprintf("EVIDENCE: p = %.3f. If the true mean were 30, data like this would be rare, so there is evidence against the claim.", k$p_two)
} else {
  sprintf("EVIDENCE: p = %.3f. Data like this are not unusual if the true mean were 30, so evidence against the claim is weak.", k$p_two)
}

caution <- sprintf(
  "POWER CHECK: with n = %d the chance of detecting a true 3-minute shortfall is about %.0f%%; ~%d deliveries would give 80%%.",
  k$n, 100 * k$power_n60, k$n_needed)

conclusion <- if (k$p_two < 0.05) {
  "CONCLUSION: The data contradict the 30-minute claim. Check whether the size of the gap matters in practice, not just whether it is significant."
} else {
  "CONCLUSION: We cannot reject the claim, but that is NOT proof it is true. A non-significant result with low power is inconclusive."
}

shift_note <- sprintf(
  "EXTRA: Night deliveries were %.1f min slower than day (Welch p = %.3f, Cohen's d = %.2f).",
  k$diff_shift, k$p_shift, k$d)

report <- c("QUESTION:", question, "", statistic, evidence, caution, "",
            conclusion, "", shift_note)
writeLines(report)
writeLines(report, "results/conclusion.txt")
