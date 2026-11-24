# Is the delivery service keeping its 30-minute promise?

A beginner-friendly R project that goes from **code → computation → statistical decision**.
A delivery company claims its average delivery time is **30 minutes**. We analyse (simulated) delivery data and ask whether the data supports that claim.

Delivery times are right-skewed (a few very late orders), so textbook formulas are only approximately right. That makes this a good excuse to use numerical methods and simulation, not just `t.test()`.

> **Note on data:** the data are simulated in `01_programming.R` (gamma distribution, night shift slightly slower than day). Because we know how the data were generated, we can check our methods against the truth.
> **Note on process:** project structure developed with AI assistance (Claude); code run, checked and interpreted by me. 

## Project structure

```
delivery-time-analysis/
├── 01_programming.R             Stage 1: data, cleaning, control flow, functions
├── 02_numerical_computation.R   Stage 2: optimisation, root finding, integration
├── 03_simulation.R              Stage 3: Monte Carlo, CLT, bootstrap
├── 04_inference.R               Stage 4: CIs, tests, Type I error, power, multiple testing
├── 05_interpretation.R          Stages 5-6: question -> statistic -> evidence -> conclusion
├── data/                        raw and cleaned CSVs
├── figures/                     saved plots
└── results/                     console output of each script + conclusion.txt
```

## How to run

Requires R (4.x). No extra packages. From the project folder, run the scripts **in order** (each saves files the next one reads):

```bash
Rscript 01_programming.R
Rscript 02_numerical_computation.R
Rscript 03_simulation.R
Rscript 04_inference.R
Rscript 05_interpretation.R
```

Or open each file in RStudio and click *Source*. Set the working directory to the project folder first.

## What each stage does

| Stage | Question it answers | Main tools |
|---|---|---|
| 1. R programming | What does the data look like, and is it clean? | `data.frame`, `read.csv`, `for`, `if/else`, `ifelse`, functions, `hist`, `boxplot` |
| 2. Numerical computation | Which model fits best? Where is the 90th percentile? What is P(late)? | `optimize`, `optim` (maximum likelihood), `uniroot`, own bisection, `integrate` |
| 3. Randomness & simulation | How much would our result change if we repeated the study? | `rgamma`, `replicate`, bootstrap, Monte Carlo, Central Limit Theorem |
| 4. Statistical inference | Is the mean different from 30? How sure are we? Could we even tell? | `t.test`, bootstrap CI, QQ-plots, power simulation, `wilcox.test`, `p.adjust` |
| 5. Statistical question | What exactly are we testing? | H0: mean = 30 vs H1: mean ≠ 30 |
| 6. Interpretation | What do we conclude? | Statistic → evidence → conclusion |

## Results (seed-fixed, so reproducible)

After removing 2 missing values, **n = 58** deliveries.

**Stage 1.** Mean = 32.2 min, SD = 14.2. 33 of 58 deliveries (57%) were over 30 min. Day mean 29.1 vs night mean 35.4.

**Stage 2.** The maximum-likelihood gamma fit has shape ≈ 4.78 and rate ≈ 0.148 (implied mean 32.2). `uniroot()`, my own bisection (26 iterations) and `qgamma()` all agree that the 90th percentile is **52.0 min**.

**Stage 3.** The standard error of the mean is about 1.9 min by simulation, theory, and bootstrap alike. Monte Carlo with 1,000,000 draws reproduced the exact tail probabilities to 3 decimals. The CLT plot shows skewed individual times turning into a bell-shaped distribution of means as n grows.

**Stage 4.**

| Result | Value |
|---|---|
| 95% CI for the mean (t) | 28.5 to 36.0 |
| 95% CI for the mean (bootstrap) | 28.7 to 36.0 |
| Test of H0: mean = 30 | t = 1.20, **p = 0.237** |
| Type I error rate (simulated, n = 60) | ≈ 0.055 (close to the nominal 0.05) |
| Power to detect a true mean of 33, n = 60 | **≈ 25%** |
| n needed for 80% power | ≈ 240 deliveries |
| Night vs day difference | +6.3 min, Welch p = 0.089, Cohen's d = 0.45 |

Multiple testing: in one family of 20 tests where the null was true every time, 7 looked "significant" at 0.05 and 2 survived a Bonferroni correction. Across 1,000 such families, about 68% contained at least one false positive (theory: 64%).

## Conclusion

> **Statistic:** Across 58 deliveries the mean was 32.2 min (95% CI 28.5 to 36.0).
> **Evidence:** p = 0.237. Data like this are not unusual if the true mean were 30, so evidence against the claim is weak.
> **Conclusion:** We **cannot reject** the 30-minute claim, but that is **not proof it is true**. With n ≈ 58 the study had only about 25% power to detect a 3-minute shortfall, so the result is inconclusive. About 240 deliveries would be needed. Night deliveries look slower than day deliveries (+6.3 min, medium effect size), but that difference is also not statistically significant at this sample size.


- Ideas to extend: use a real delivery dataset, add a second distribution (log-normal) and compare fits by likelihood, add a confidence interval for the proportion of late deliveries, try a permutation test.

## Notes

- `wilcox.test` prints a warning about ties (delivery times are rounded to 0.1 min). It is harmless; the p-value uses a normal approximation.
- Figures in `figures/` and console outputs in `results/` are produced by the scripts and can be regenerated.
