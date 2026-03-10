---
name: causal-ml
description: >-
  Guide for causal machine learning methods in applied economics and quantitative social science. Use when implementing or choosing between modern ML-based causal estimators — including double machine learning, DML, partially linear models, interactive regression models, cross-fitting, Neyman orthogonality, debiased ML, causal forests, generalized random forest, GRF, honest causal trees, AIPW with machine learning, doubly robust with machine learning, DR-Learner, T-Learner, S-Learner, X-Learner, meta-learners, heterogeneous treatment effects, conditional average treatment effect, CATE, HTE, high-dimensional controls, LASSO controls, post-LASSO, post-double selection, Belloni-Chernozhukov-Hansen, Riesz representer, Chernozhukov, sample splitting, econml, DoubleML package, or any combination of machine learning and causal inference.
---

# Causal Machine Learning

Reference for semiparametric machine learning estimators: DML with cross-fitting, generalized random forests, debiased regularization approaches, and nuisance function approximation. Covers Neyman-orthogonal moment conditions, sample splitting, plug-in bias correction, and heterogeneous treatment effects using R and Python frameworks.

## When to Use This Skill

Use when the user is:
- Estimating treatment effects when controls are high-dimensional (p large relative to n)
- Interested in heterogeneous treatment effects (CATE) as a primary estimand — not just ATE
- Applying ML for flexible nuisance function estimation within a causal framework
- Implementing cross-fitting, sample splitting, or Neyman-orthogonal estimators
- Using `econml`, `DoubleML`, or `grf` packages
- Combining LASSO/random forests/neural nets with causal identification

Skip when:
- The sample is small (n < 500 — ML nuisance models need data)
- A well-specified parametric model is available and the specification is defensible
- The primary question is identification, not estimation (use `causal-inference` skill first)
- Structural modeling is needed (use `structural-modeling` skill)

## Where to Start
- **Choosing a causal ML method?** Jump to [Method Selection Guide](#method-selection-guide) at the end
- **Estimating average treatment effects with many controls?** Go to [Double Machine Learning](#double-machine-learning-dml)
- **Estimating heterogeneous treatment effects?** Go to [Causal Forests](#causal-forests-generalized-random-forests) or [Meta-Learners](#dr-learner-and-meta-learners)
- **Variable selection for controls?** Go to [High-Dimensional Controls](#high-dimensional-controls)

## Causal ML vs Traditional Methods

| Dimension | Traditional (IV, DiD, RDD) | Causal ML |
|-----------|--------------------------|-----------|
| Functional form | Parametric (linear, polynomial) | Nonparametric / semi-parametric |
| High-dimensional controls | Problematic | Native support |
| Heterogeneous effects | Secondary (subgroup analysis) | Primary estimand (CATE) |
| Sample requirements | Works at moderate N | ML nuisance models need large N |
| Inference | Well-established | Valid via Neyman orthogonality + cross-fitting |
| Identification | Explicit (IV, DiD, RCT) | Same underlying assumptions apply — ML is estimation, not identification |
| Interpretability | High | Lower for forest/neural net nuisance models |

**Critical point:** Causal ML does not relax identification assumptions. If you need a valid instrument, parallel trends, or no unmeasured confounding, those assumptions must still hold. Causal ML methods are better nuisance estimators wrapped around the same identification logic.

## Double Machine Learning (DML)

DML (Chernozhukov et al. 2018) fixes a fundamental problem with naive ML-in-regression: regularization in LASSO or random forests biases the coefficient on the treatment variable, and this bias does not vanish with large n. The solution is to partial out controls X from both Y and D using separate ML nuisance models, then regress the residuals on each other. Two properties make this work: **Neyman orthogonality** (the moment condition is locally insensitive to nuisance estimation error) and **cross-fitting** (nuisance models trained on held-out folds prevent overfitting bias from contaminating the main estimate).

The **Partially Linear Regression (PLR)** model is the workhorse: `Y = θD + g(X) + ε` where g(X) is estimated nonparametrically. Use PLR when D is continuous or binary and you want ATE under selection on observables. The **Interactive Regression Model (IRM)** relaxes additive separability — use it when D is binary and treatment effect heterogeneity is suspected.

```python
import doubleml as dml
plr = dml.DoubleMLPLR(data, ml_g=rf_regressor, ml_m=rf_regressor, n_folds=5)
plr.fit()
print(plr.summary)
```

For full implementation details, code for the `DoubleML` package in Python and R, cross-fitting from scratch, and diagnostics, see `references/dml.md`.

## Causal Forests (Generalized Random Forests)

Causal forests (Wager and Athey 2018; Athey, Tibshirani, Wager 2019) estimate the CATE τ(x) = E[Y(1) − Y(0) | X = x] using a forest that is **honest**: the tree structure is learned on one subsample and leaf-level effects estimated on a separate subsample. Honesty is necessary for valid confidence intervals — without it, leaf estimates are biased. The forest constructs weights αᵢ(x) that define a local ATE around each point x in feature space, after residualizing out propensity and mean outcome.

Use causal forests when CATE as a function of covariates is the primary estimand and n ≥ 2,000. Always run the **calibration test** (Chernozhukov et al. 2022) before reporting heterogeneity: if the differential.forest.prediction coefficient is not significant, the heterogeneity may be noise.

```r
library(grf)
cf <- causal_forest(X, Y, W, num.trees=2000, honesty=TRUE, seed=42)
# older grf versions used causal.forest(); current API uses causal_forest()
test_calibration(cf)  # always report this
```

For R (`grf`) and Python (`econml`) implementations, ATE/ATT extraction, BLP projections, and diagnostics, see `references/grf-meta-learners.md`.

## DR-Learner and Meta-Learners

Meta-learners decompose CATE estimation into supervised learning sub-problems. The **T-Learner** fits separate outcome models for treated and control groups and takes their difference — simple but regularization is not targeted at the treatment effect. The **DR-Learner** (Kennedy 2023) constructs doubly-robust pseudo-outcomes by combining propensity-weighted residuals with outcome model predictions, then regresses these on X; it has the best statistical properties when both nuisance models are well-specified. The **X-Learner** is designed for imbalanced treatment (rare treatment) and combines imputed counterfactuals with propensity-weighted averaging.

For applied work: DR-Learner as the primary estimator, T-Learner as a benchmark. Large disagreement between the two signals a nuisance model problem.

```python
from econml.dr import DRLearner
dr = DRLearner(model_propensity=rf_cls, model_regression=rf_reg, model_final=RidgeCV(), cv=5)
dr.fit(Y=y, T=t, X=X)
```

For complete implementations of all meta-learners (T/S/X/DR) with `econml`, pseudo-outcome formulas, and diagnostics, see `references/grf-meta-learners.md`.

## High-Dimensional Controls

When controls are high-dimensional (p large relative to n), naive LASSO of Y on D and X regularizes the treatment coefficient toward zero — this cannot be undone. **Post-double selection LASSO (PDS-LASSO)** (Belloni, Chernozhukov, Hansen 2014) solves this by running separate LASSOes of Y on X and D on X, taking the union of selected variables, then running OLS on D plus the union. The union step is critical: it controls for confounders (variables predicting D) and improves efficiency (variables predicting Y), without ever regularizing the causal parameter θ.

Use PDS-LASSO when n is moderate (as low as ~200 with sparse confounders) and you want ATE under selection on observables with many candidate controls. The `hdm` package in R implements the theory-based Belloni-Chernozhukov penalty, which has stronger guarantees for post-selection inference than cross-validated LASSO.

```r
library(hdm)
pds <- rlassoEffect(x=X_matrix, y=Y_vector, d=D_vector, method="double selection")
```

For Python implementation, R `hdm` package usage, penalty selection guidance, and diagnostics, see `references/high-dim-cross-fitting.md`. For the theoretical basis of cross-fitting more broadly (why naive ML-in-regression fails and the K-fold protocol), see the Sample Splitting section in the same file.

## HTE Inference and Reporting

### Global Test for Heterogeneity

Before reporting CATE estimates, test whether there is genuine heterogeneity. The BLP (best linear projection) approach due to Chernozhukov, Demirer, Duflo, Fernandez-Val (2022) is the standard test:

```r
# R: grf
cal <- test_calibration(cf)
# H0: no heterogeneity (differential.forest.prediction = 0)
# Reject H0 → genuine heterogeneity detected

# Python: econml (manual BLP)
from econml.inference import LinearModelFinalInference
# Use cf.effect() predictions and regress on summary statistics
```

**Do not report heterogeneous effects if the calibration test fails to reject at a reasonable level (p > 0.10).** Report the calibration test result alongside CATE estimates.

### Confidence Intervals on Individual CATE

Individual CATE confidence intervals from causal forests are valid but conservative (they are honest pointwise CIs, not uniform CIs). They should be interpreted as uncertainty about τ(xᵢ), not as evidence that τ(xᵢ) ≠ 0 for that individual.

```python
# econml: point estimates and CIs for each unit
tau_lb, tau_ub = cf.effect_interval(X_test, alpha=0.05)

# R: grf
tau_hat <- predict(cf, estimate.variance = TRUE)
tau_ci_lo <- tau_hat$predictions - 1.96 * sqrt(tau_hat$variance.estimates)
tau_ci_hi <- tau_hat$predictions + 1.96 * sqrt(tau_hat$variance.estimates)
```

**Warning:** Do not use individual CIs for policy targeting without accounting for multiple testing. Targeting based on wide CIs that nominally include zero for some units and not others leads to invalid inference.

### Best Linear Projection of CATE

The best linear projection (BLP) onto covariates gives a sparse, interpretable summary of heterogeneity:

```python
# econml: summary of CATE heterogeneity
blp = cf.const_marginal_effect_inference(X).summary_frame()
print(blp)  # coefficient on each X variable in BLP of CATE
```

```r
# R: grf
blp <- best_linear_projection(cf, A = X_matrix)
print(blp)
# Coefficients tell you: which observed characteristics predict larger/smaller CATE
```

### Subgroup Analysis: Pre-Specified vs Data-Driven

**Pre-specified subgroups** (defined before analysis):
- Report group-specific ATEs using forest-weighted estimators
- Standard: `average_treatment_effect(cf, subset = group_indicator)` in R

**Data-driven subgroups** (quartiles of τ̂(x)):
- Compute quartile cutoffs of τ̂ on a held-out sample
- Report ATEs within quartiles — this is exploratory, not confirmatory
- Requires multiplicity correction (Benjamini-Hochberg) if multiple subgroups reported

```r
# R: subgroup ATE using forest
high_effect <- tau_hat$predictions > median(tau_hat$predictions)

ate_high <- average_treatment_effect(cf, subset = high_effect)
ate_low  <- average_treatment_effect(cf, subset = !high_effect)

cat("ATE (high CATE group):", ate_high["estimate"], "\n")
cat("ATE (low CATE group): ", ate_low["estimate"],  "\n")
```

## Connections to Traditional Methods

Understanding how causal ML relates to traditional methods helps build intuition and credibility with traditional audiences.

### DML Reduces to IV When Nuisance Models Are Linear

If E[Y|X] and E[D|X] are both estimated by OLS (linear projections), then DML's partialling out is numerically identical to the Frisch-Waugh-Lovell theorem. The DML θ̂ equals the OLS coefficient on D in a regression of Y on D and X.

This means: DML with linear nuisance models = standard OLS. DML adds value precisely when the nuisance functions are nonlinear — it allows flexible control for X while maintaining √n-inference on θ.

**Practical check:** Run DML with linear nuisance models (OLS) and compare to OLS with all controls. They should match. If not, there is a coding error.

### IV with DML Nuisance Models

DML extends naturally to IV. The partially linear IV model:

```
Y = θ₀ D + g₀(X) + ε
D = m₀(X) + v
Z: instrument with E[Z · ε | X] = 0
```

Cross-fitted IV moment: regress residualized Y on residualized D, instrumenting with residualized Z.

```python
# DoubleML: Partially linear IV
pliv = dml.DoubleMLPLIV(
    obj_dml_data=data,   # data must include Z (instrument)
    ml_g=ml_g,           # learner for E[Y|X]
    ml_m=ml_m,           # learner for E[D|X]
    ml_r=ml_r,           # learner for E[Z|X]  — partialling out Z
    n_folds=5,
)
pliv.fit()
print(pliv.summary)
```

### Causal Forests Generalize Local ATE

Standard IV/2SLS at a single instrument value (e.g., an RDD cutoff) gives LATE for compliers at that point. A causal forest with an instrument generalizes this to heterogeneous LATE across the covariate space:

```r
# R: grf — instrumental forest
iv_forest <- instrumental_forest(
  X = X_matrix,
  Y = Y_vector,
  W = W_treatment,   # endogenous treatment
  Z = Z_instrument,  # instrument
  seed = 42
)
tau_late_hat <- predict(iv_forest)$predictions
ate_late <- average_treatment_effect(iv_forest)
```

### Post-LASSO Generalizes 2SLS with Many Instruments

The many-instruments problem (Bekker 1994) causes 2SLS to be inconsistent when the number of instruments grows with n. Post-LASSO selects a sparse set of strong instruments, then runs standard 2SLS on the selected instruments. This connects to LIML and jackknife IV estimators.

```r
# R: hdm — LASSO for many instruments
# First, select relevant instruments using LASSO
lasso_z <- rlasso(D_vector ~ Z_matrix)  # regress D on instruments
selected_z <- which(lasso_z$coef != 0)

# Then run 2SLS with selected instruments
library(fixest)
iv_formula <- as.formula(
  paste("Y ~", paste(X_names, collapse = "+"),
        "| D ~ ", paste(Z_names[selected_z], collapse = "+"))
)
result_iv <- feols(iv_formula, data = df, vcov = "hetero")
print(result_iv)
```

---

## Integration with Plugin Agents and Commands

### Agents to Use Alongside Causal ML

- **`econometric-reviewer`**: Always run after any DML or causal forest estimation. Reviews identification strategy, standard error computation, and whether the target parameter is well-defined.
- **`identification-critic`**: Use when combining ML with IV (PLIV). The identification assumptions (exclusion restriction, relevance) still apply — ML does not relax them.
- **`numerical-auditor`**: Check convergence of ML nuisance models (forest OOB error, LASSO path stability). Verify cross-fitting folds are properly seeded.
- **`results-verifier`**: Verify that reported ATE/CATE matches the code output. Check that confidence intervals in tables correspond to the correct alpha level.
- **`simulation-designer`**: Design Monte Carlo studies to validate DML estimator performance at your sample size before running on real data.

### Commands

- **`/stress-test`**: Run specification curve over ML model choices (LASSO vs random forest vs gradient boosting as nuisance), over K (K=5, K=10), and over samples sizes. Heterogeneous treatment effect estimates are especially sensitive to nuisance model choice.
- **`/diagnose`**: Run diagnostic battery — check nuisance R², residual balance, calibration test, overlap.
- **`/simulate`**: Generate synthetic data with known CATE to validate your causal forest or DML implementation before applying to real data.

### Relationship to `causal-inference` Skill

The `causal-inference` skill covers traditional quasi-experimental methods (IV, DiD, RDD, synthetic control, matching). Causal ML methods in this skill are **complements**, not substitutes:

- Use `causal-inference` to establish the identification strategy (which assumption justifies causal interpretation)
- Use `causal-ml` when implementing the estimator — particularly when controls are high-dimensional or heterogeneity is of primary interest
- DML + IV = valid causal interpretation + flexible control for high-dimensional confounders
- Causal forests + DiD design = heterogeneous event-study effects (see `grf::causal_forest` with panel-adjusted pseudo-outcomes)

---

## Method Selection Guide

### Primary Decision: What Is Your Estimand?

| Primary question | Recommended approach |
|-----------------|----------------------|
| Average effect, many controls, selection on observables | DML (PLR) |
| Average effect, binary treatment, many controls | DML (IRM) |
| Average effect, endogenous treatment, many controls | DML (PLIV) |
| Heterogeneous effects, flexible heterogeneity, large n | Causal Forest (GRF) |
| Heterogeneous effects, want doubly-robust CATE | DR-Learner |
| Variable selection from many controls, then standard OLS/IV | Post-Double Selection LASSO |
| Average effect, moderate n (< 1,000), simple specification | Standard IV/DiD/OLS — see `causal-inference` skill |

### Full Method Comparison Table

| Method | Estimand | Package (Python) | Package (R) | Min n | Key assumption | Key diagnostic |
|--------|----------|-----------------|-------------|-------|----------------|----------------|
| DML-PLR | ATE (θ in PLR) | `doubleml`, `econml` | `DoubleML` | ~500 | Selection on observables, PLR additive structure | Nuisance R², residual balance |
| DML-IRM | ATE (binary D) | `doubleml`, `econml` | `DoubleML` | ~500 | Unconfoundedness, overlap | Propensity AUC, trim threshold |
| DML-PLIV | LATE (endogenous D) | `doubleml`, `econml` | `DoubleML` | ~1,000 | Exclusion restriction + selection on obs | Effective F-stat, first-stage R² |
| Causal Forest | CATE(x) | `econml.dml.CausalForestDML` | `grf::causal_forest` | ~2,000 | Overlap (positivity), unconfoundedness | Calibration test, ATE match |
| DR-Learner | CATE(x) | `econml.dr.DRLearner` | manual or `grf` | ~1,000 | Overlap, unconfoundedness | Propensity calibration, T-Learner comparison |
| PDS-LASSO | ATE (high-dim X) | `sklearn` + manual | `hdm::rlassoEffect` | ~200 (sparse) | Sparsity of confounders | Union size, penalty sensitivity |
| X-Learner | CATE (imbalanced D) | `econml.metalearners.XLearner` | manual | ~1,000 | Overlap, unconfoundedness | Compare to DR-Learner |

### Decision Heuristic

```
1. Is n < 500?
   → Do NOT use causal ML for nuisance estimation.
   → Use standard methods from causal-inference skill.

2. Are controls high-dimensional (p > 20) but you only want ATE?
   → PDS-LASSO (fast, interpretable) or DML-PLR (more flexible)
   → If D is binary: DML-IRM

3. Is heterogeneous treatment effect the primary question?
   → Causal Forest (best for large n, arbitrary heterogeneity)
   → DR-Learner (better calibration, explicit double robustness)

4. Do you have an endogenous treatment and an instrument?
   → DML-PLIV (combines ML nuisance with IV identification)

5. Is treatment imbalanced (rare treatment)?
   → X-Learner (specifically designed for imbalanced treatment)

6. Do you want a quick benchmark to compare against?
   → Always compute T-Learner as a simple baseline
```

### Limitations to State Explicitly

- **ML needs data**: Causal forests require n ≥ 2,000 for reliable CATE inference; DML requires n ≥ 500 for nuisance models to be well-fit. Below these thresholds, use traditional parametric methods.
- **Identification is not relaxed**: ML estimators are flexible nuisance models within the same identification frameworks. If selection on observables does not hold, neither DML nor causal forests can rescue the causal interpretation.
- **CATE inference is hard**: Individual-level CATE confidence intervals are conservative and wide. Policy implications based on individual CATE estimates require additional care.
- **Nonparametric rates for nuisance**: Under smoothness assumptions, nuisance models converge at rates slower than √n. DML results remain valid as long as nuisance estimation errors are o(n^{-1/4}), which is achievable but requires the function class to be rich enough.
- **Publication standard**: As of 2024, DML and causal forests are mainstream in top applied micro journals (AER, QJE, REStat). Results should be compared to traditional estimators, and the choice of ML method should be reported transparently.

## Packages Reference

| Method | Python | R |
|--------|--------|---|
| DML (all models) | `doubleml`, `econml.dml` | `DoubleML` |
| Causal Forest | `econml.dml.CausalForestDML` | `grf::causal_forest` |
| DR-Learner | `econml.dr.DRLearner` | manual / `grf` |
| T/S/X-Learner | `econml.metalearners` | `grf`, `causalml` (Python port) |
| Post-LASSO | manual with `sklearn` | `hdm::rlassoEffect` |
| Propensity / weighting | `econml`, `zEpid` | `WeightIt`, `MatchIt` |
| AIPW (classic) | `econml.dr.LinearDRLearner` | `AIPW`, `grf::average_treatment_effect` |
| Visualization | `matplotlib`, `seaborn` | `ggplot2`, `grf` plotting utilities |

## Reference Files

Read these when implementing a specific method:
- `references/dml.md` — Full DML implementation: PLM, IRM, PLIV estimators with econml/DoubleML code, cross-fitting setup, standard errors, sensitivity analysis
- `references/grf-meta-learners.md` — Causal forests (grf package in R, econml in Python), DR-Learner, T-Learner, X-Learner, AIPW implementations
- `references/high-dim-cross-fitting.md` — Post-LASSO, post-double-selection, Belloni-Chernozhukov-Hansen, sample splitting protocols, cross-fitting code patterns
