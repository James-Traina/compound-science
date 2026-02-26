---
name: causal-inference
description: Guide for causal inference methods in observational and quasi-experimental settings. Use when the user is implementing, choosing between, or debugging causal identification strategies — including instrumental variables, difference-in-differences, regression discontinuity, synthetic control, or matching estimators. Triggers on "causal effect", "identification strategy", "instrumental variable", "2SLS", "GMM", "difference-in-differences", "DiD", "staggered treatment", "regression discontinuity", "RDD", "synthetic control", "matching", "propensity score", "IPW", "AIPW", "doubly robust", "LATE", "ATT", "ATE", "parallel trends", "exclusion restriction", "first stage", "weak instruments", or "endogeneity".
---

# Causal Inference

Reference for implementing causal inference methods: from identification strategy to estimation to diagnostics and robustness. Covers the major quasi-experimental and observational methods used in applied economics and quantitative social science.

## When to Use This Skill

Use when the user is:
- Choosing an identification strategy for a causal question
- Implementing IV/2SLS, DiD, RDD, synthetic control, or matching
- Debugging specification issues (weak instruments, parallel trends violations, bandwidth sensitivity)
- Running robustness checks or falsification tests
- Working with modern DiD methods for staggered treatment timing

Skip when:
- The task is structural estimation (use `structural-modeling` skill)
- The task is pure prediction/ML (no causal question)
- The user needs simulation design (use `monte-carlo-designer` agent)

## Frameworks

Two complementary frameworks underpin all causal inference:

**Potential Outcomes (Rubin):** Define Y(1), Y(0) as potential outcomes under treatment and control. The causal effect is τ = Y(1) - Y(0). The fundamental problem: we never observe both for the same unit. All methods are strategies for constructing valid counterfactuals.

**DAGs (Pearl):** Graphical models encoding conditional independence assumptions. Use d-separation to determine what must be conditioned on (and what must NOT be conditioned on) to identify causal effects. Particularly useful for reasoning about:
- Bad controls (colliders, mediators)
- Overcontrol bias
- Which instruments satisfy the exclusion restriction

**Practical guidance:** Use potential outcomes notation for formal identification arguments. Use DAGs to communicate assumptions to co-authors and referees.

## Target Parameters

Be precise about what parameter you are estimating:

| Parameter | Definition | Estimated by |
|-----------|-----------|-------------|
| ATE | E[Y(1) - Y(0)] | Randomized experiment, IPW, AIPW |
| ATT | E[Y(1) - Y(0) \| D=1] | DiD, matching, selection-on-observables |
| LATE | E[Y(1) - Y(0) \| compliers] | IV/2SLS (Imbens-Angrist 1994) |
| ATT(g,t) | Group-time specific treatment effect | Staggered DiD (Callaway-Sant'Anna) |
| CATE(x) | E[Y(1) - Y(0) \| X=x] | Heterogeneous treatment effects methods |

**Common mistake:** Reporting "the effect" without specifying which parameter. IV estimates LATE, not ATE. DiD estimates ATT, not ATE. This matters for policy interpretation.

## Instrumental Variables

### Standard 2SLS

```python
from linearmodels.iv import IV2SLS
import pandas as pd

# Basic 2SLS
model = IV2SLS.from_formula(
    'lwage ~ 1 + exper + expersq + [educ ~ nearc4 + nearc2]',
    data=df
)
result = model.fit(cov_type='robust')
print(result.summary)

# Key diagnostics accessible from result:
# result.first_stage — first stage results for each endogenous variable
```

### First-Stage Diagnostics

```python
# Always report the first stage
first_stage = IV2SLS.from_formula(
    'educ ~ 1 + exper + expersq + nearc4 + nearc2',
    data=df
).fit(cov_type='robust')

# Effective F-statistic (Stock-Yogo / Olea-Pflueger)
# Rule of thumb: F > 10 for single endogenous regressor
# For multiple endogenous regressors, use Cragg-Donald or Kleibergen-Paap

# With linearmodels, check:
# result.first_stage.diagnostics — partial F, Shea partial R²
```

### Weak Instruments

When instruments are weak (F < 10), 2SLS is biased toward OLS:

```python
# Anderson-Rubin test: valid regardless of instrument strength
from linearmodels.iv import IV2SLS

# LIML is less biased than 2SLS with weak instruments
from linearmodels.iv import IVLIML
model_liml = IVLIML.from_formula(
    'lwage ~ 1 + exper + expersq + [educ ~ nearc4 + nearc2]',
    data=df
)
result_liml = model_liml.fit(cov_type='robust')

# Compare 2SLS and LIML: if estimates differ substantially,
# weak instruments are a concern
```

### Overidentification

When you have more instruments than endogenous regressors:

```python
# Sargan-Hansen J-test (only valid under homoskedasticity for Sargan)
# result.sargan — Sargan test
# result.wooldridge_overid — robust overidentification test

# Interpretation: rejection means at least one instrument is invalid
# Caution: the test has low power with weak instruments
# Caution: passing the test does NOT prove instruments are valid
```

### IV Diagnostics Checklist

- [ ] **First-stage F > 10** (or use Olea-Pflueger effective F for robust inference)
- [ ] **Exclusion restriction argued** (not testable — must be defended substantively)
- [ ] **Monotonicity** for LATE interpretation (no defiers)
- [ ] **Reduced form significant** (regress Y directly on Z — should be significant)
- [ ] **Overidentification test** reported if over-identified (but interpret cautiously)
- [ ] **Compare OLS vs 2SLS** — direction and magnitude of bias as expected?
- [ ] **Report LATE interpretation** — who are the compliers? Is the local effect policy-relevant?

## Difference-in-Differences

### Classic Two-Period DiD

```python
import statsmodels.formula.api as smf

# Standard 2x2 DiD
model = smf.ols('y ~ treated + post + treated:post', data=df)
result = model.fit(cov_type='cluster', cov_kwds={'groups': df['state']})

# The coefficient on treated:post is the DiD estimate
# Cluster standard errors at the level of treatment assignment
```

### Event Study / Dynamic DiD

```python
# Event study with leads and lags (relative time indicators)
# Omit period -1 as the reference

# Create relative time dummies
df['rel_time'] = df['year'] - df['treatment_year']
df.loc[df['rel_time'].isna(), 'rel_time'] = -1  # never-treated as reference

# Generate indicators for each relative time period
for k in range(-5, 8):
    if k == -1:
        continue  # omit reference period
    col = f'rel_{k}' if k >= 0 else f'rel_m{abs(k)}'
    df[col] = (df['rel_time'] == k).astype(int)

# Regression with fixed effects
import linearmodels.panel as plm

df = df.set_index(['unit', 'year'])
formula = 'y ~ ' + ' + '.join([f'rel_m{k}' for k in range(5, 1, -1)] +
                                [f'rel_{k}' for k in range(0, 8)]) + ' + EntityEffects + TimeEffects'

model = plm.PanelOLS.from_formula(formula, data=df)
result = model.fit(cov_type='clustered', cluster_entity=True)
```

### Pre-Trends Testing

The pre-treatment coefficients in an event study should be statistically indistinguishable from zero. But:

**Limitations of pre-trend tests:**
- Absence of evidence ≠ evidence of absence (low power)
- Pre-trends may be present but too small to detect
- Linear pre-trends that level off at treatment can masquerade as treatment effects

**Better approaches:**
- Rambachan & Roth (2023) sensitivity analysis: "How much can post-treatment violations of parallel trends differ from pre-trends?"
- Bound the treatment effect under alternative trend assumptions

```python
# honestdid package (R) — no mature Python equivalent yet
# In R:
# library(HonestDiD)
# honest_did <- HonestDiD::createSensitivityResults(
#     betahat = event_study_coefs,
#     sigma = event_study_vcov,
#     numPrePeriods = 5,
#     numPostPeriods = 7,
#     Mvec = seq(0, 0.05, by = 0.01)  # grid of M values
# )
```

### Staggered Treatment Timing

**The problem:** With staggered adoption, TWFE (two-way fixed effects) estimates a weighted average of treatment effects where some weights can be **negative**. This means the TWFE estimate can be negative even when all unit-level effects are positive.

**Root cause:** Already-treated units serve as controls for later-treated units, and the "effect" is differenced relative to these already-treated units.

#### Callaway and Sant'Anna (2021)

Estimates group-time ATTs — the effect for group g (units first treated at time g) at time t.

```python
# Python: csdid package (or use R's did package)
# R implementation (more mature):
# library(did)
# result <- att_gt(
#     yname = "y",
#     tname = "year",
#     idname = "unit_id",
#     gname = "first_treat",  # 0 for never-treated
#     data = df,
#     control_group = "nevertreated",  # or "notyettreated"
#     est_method = "dr"  # doubly robust
# )
# agg_result <- aggte(result, type = "dynamic")  # aggregate to event-time
```

**Key choices:**
- **Control group**: "never-treated" (cleaner, but requires never-treated units) vs "not-yet-treated" (more comparison units, weaker assumption)
- **Estimation method**: "dr" (doubly robust — recommended), "ipw", "reg"
- **Aggregation**: "dynamic" (event study), "group" (by cohort), "calendar" (by time period), "simple" (overall)

#### Sun and Abraham (2021)

Interaction-weighted estimator that corrects TWFE with heterogeneous effects:

```python
# R implementation:
# library(fixest)
# result <- feols(
#     y ~ sunab(first_treat, year) | unit + year,
#     data = df,
#     cluster = ~state
# )
# The sunab() function handles the interaction-weighting automatically
```

#### de Chaisemartin and D'Haultfoeuille (2020)

```python
# R: did_multiplegt package
# Estimates treatment effect under minimal assumptions
# Particularly useful when treatment can turn on and off
```

#### Which Staggered DiD Method to Use

| Feature | Callaway-Sant'Anna | Sun-Abraham | de Chaisemartin-D'H |
|---------|-------------------|-------------|---------------------|
| Treatment reversals | No | No | Yes |
| Covariates | Time-varying OK | Baseline only | Limited |
| Aggregation flexibility | High (group, time, event) | Event study | Limited |
| Implementation maturity | R: excellent; Python: developing | R (fixest): excellent | R: good |
| Never-treated required | No (not-yet-treated option) | Recommended | No |

### DiD Diagnostics Checklist

- [ ] **Pre-trends**: Event study shows no significant pre-treatment coefficients
- [ ] **Parallel trends sensitivity**: Rambachan-Roth or similar analysis
- [ ] **Staggered timing**: If treatment timing varies, use Callaway-Sant'Anna or Sun-Abraham, NOT naive TWFE
- [ ] **Clustering level**: Cluster at the level of treatment assignment (typically state/county, not individual)
- [ ] **Anticipation**: Check for effects in the period just before treatment (may indicate anticipation or misspecified timing)
- [ ] **Never-treated vs not-yet-treated**: Report results with both control groups if possible
- [ ] **Bacon decomposition**: If using TWFE, decompose to see which comparisons drive the estimate (`bacondecomp` in R/Stata)

## Regression Discontinuity

### Sharp RDD

```python
# rdrobust package (available in Python, R, Stata)
from rdrobust import rdrobust, rdbwselect, rdplot

# Basic RD estimate
result = rdrobust(y=df['outcome'], x=df['running_var'], c=0)
print(result)
# Reports: point estimate, robust bias-corrected CI, bandwidth, N left/right

# Bandwidth selection
bw = rdbwselect(y=df['outcome'], x=df['running_var'], c=0)
# Reports: MSE-optimal and CER-optimal bandwidths

# RD plot
fig = rdplot(y=df['outcome'], x=df['running_var'], c=0,
             nbins=(20, 20))  # bins left and right of cutoff
```

### Fuzzy RDD

When crossing the threshold increases the probability of treatment but doesn't guarantee it:

```python
# Fuzzy RD = IV where the instrument is 1(X >= c)
result = rdrobust(
    y=df['outcome'],
    x=df['running_var'],
    c=0,
    fuzzy=df['treatment']  # actual treatment indicator
)
# Estimates LATE at the cutoff
```

### McCrary Density Test

Test for manipulation of the running variable around the cutoff:

```python
from rddensity import rddensity, rdplotdensity

# Test for bunching at the cutoff
density_test = rddensity(X=df['running_var'], c=0)
print(f"T-statistic: {density_test.hat['t']:.3f}")
print(f"P-value: {density_test.hat['p']:.3f}")

# Visual: density plot
fig = rdplotdensity(density_test, df['running_var'])
```

### RDD Diagnostics Checklist

- [ ] **McCrary test**: No manipulation of running variable at cutoff
- [ ] **Covariate balance**: Predetermined covariates should be smooth through the cutoff — run RD on each covariate as a "placebo outcome"
- [ ] **Bandwidth sensitivity**: Results stable across a range of bandwidths (0.5×, 0.75×, 1×, 1.5×, 2× optimal)
- [ ] **Polynomial order**: Local linear (p=1) is standard; higher-order polynomials can introduce bias
- [ ] **Donut hole**: Drop observations very close to the cutoff to check for precise manipulation
- [ ] **Placebo cutoffs**: Run RD at placebo cutoffs where no effect should exist
- [ ] **Density of running variable**: Plot histogram — discontinuity in density suggests manipulation

## Synthetic Control

### Standard Synthetic Control

```python
# Python: SparseSC, pensynth, or manual implementation
# The R package Synth is the standard reference implementation

import numpy as np
from scipy.optimize import minimize

def synthetic_control(Y, treated_idx, pre_periods, post_periods):
    """
    Basic synthetic control: find weights W such that
    Y_treated(pre) ≈ Y_controls(pre) @ W

    Y: (T x N) matrix of outcomes
    treated_idx: index of treated unit
    pre_periods: indices of pre-treatment periods
    post_periods: indices of post-treatment periods
    """
    Y_pre = Y[pre_periods, :]
    control_idx = [i for i in range(Y.shape[1]) if i != treated_idx]

    Y1_pre = Y_pre[:, treated_idx]           # treated unit, pre-treatment
    Y0_pre = Y_pre[:, control_idx]            # control units, pre-treatment

    n_controls = len(control_idx)

    # Minimize || Y1_pre - Y0_pre @ w ||^2
    # subject to: w >= 0, sum(w) = 1
    def objective(w):
        return np.sum((Y1_pre - Y0_pre @ w) ** 2)

    constraints = [
        {'type': 'eq', 'fun': lambda w: np.sum(w) - 1}
    ]
    bounds = [(0, 1)] * n_controls

    w0 = np.ones(n_controls) / n_controls
    result = minimize(objective, w0, method='SLSQP',
                      bounds=bounds, constraints=constraints)

    weights = result.x

    # Synthetic control outcome for all periods
    Y_synth = Y[:, control_idx] @ weights

    # Treatment effect = treated - synthetic
    effect = Y[:, treated_idx] - Y_synth

    return weights, Y_synth, effect

# Inference: permutation (placebo) test
def placebo_test(Y, treated_idx, pre_periods, post_periods):
    """
    Run synthetic control for every unit as if it were treated.
    Compare treated unit's gap to placebo distribution.
    """
    effects = {}
    for i in range(Y.shape[1]):
        w, y_synth, eff = synthetic_control(Y, i, pre_periods, post_periods)

        # Pre-treatment RMSPE (for quality filter)
        pre_rmspe = np.sqrt(np.mean(eff[pre_periods] ** 2))
        post_rmspe = np.sqrt(np.mean(eff[post_periods] ** 2))

        effects[i] = {
            'effect': eff,
            'pre_rmspe': pre_rmspe,
            'post_rmspe': post_rmspe,
            'ratio': post_rmspe / pre_rmspe if pre_rmspe > 0 else np.inf
        }

    # p-value: fraction of placebos with ratio >= treated unit's ratio
    treated_ratio = effects[treated_idx]['ratio']
    ratios = [v['ratio'] for v in effects.values()]
    p_value = np.mean([r >= treated_ratio for r in ratios])

    return effects, p_value
```

### Augmented Synthetic Control (Ben-Michael et al. 2021)

Combines synthetic control with outcome modeling to reduce bias:

```python
# R: augsynth package
# library(augsynth)
# result <- augsynth(
#     outcome ~ treatment,
#     unit = unit_id, time = year,
#     data = df,
#     progfunc = "ridge",  # or "none" for standard SC
#     scm = TRUE
# )
# summary(result)
```

### Synthetic Control Diagnostics

- [ ] **Pre-treatment fit**: Synthetic control closely tracks treated unit pre-treatment (plot and report RMSPE)
- [ ] **Weight sparsity**: Examine weights — too many near-zero weights suggest poor donor pool
- [ ] **Placebo tests**: Permutation inference over all donor units
- [ ] **Leave-one-out**: Remove each control unit with positive weight; results should be stable
- [ ] **Time placebo**: Assign treatment to an earlier date; should find no effect
- [ ] **Predictor balance**: Match on pre-treatment covariates, not just outcome

## Matching and Weighting

### Propensity Score Methods

```python
from sklearn.linear_model import LogisticRegression
import numpy as np

# Step 1: Estimate propensity score
pscore_model = LogisticRegression(max_iter=1000, C=1.0)
pscore_model.fit(df[covariates], df['treatment'])
df['pscore'] = pscore_model.predict_proba(df[covariates])[:, 1]

# Check common support
print(f"Treated pscore range: [{df.loc[df.treatment==1, 'pscore'].min():.3f}, "
      f"{df.loc[df.treatment==1, 'pscore'].max():.3f}]")
print(f"Control pscore range: [{df.loc[df.treatment==0, 'pscore'].min():.3f}, "
      f"{df.loc[df.treatment==0, 'pscore'].max():.3f}]")

# Trim non-overlapping regions
trimmed = df[(df['pscore'] > 0.05) & (df['pscore'] < 0.95)]
```

### Inverse Probability Weighting (IPW)

```python
def ipw_ate(y, d, pscore):
    """Horvitz-Thompson IPW estimator for ATE."""
    w1 = d / pscore
    w0 = (1 - d) / (1 - pscore)

    # Normalize weights (Hajek estimator — more stable)
    ate = (w1 * y).sum() / w1.sum() - (w0 * y).sum() / w0.sum()
    return ate

def ipw_att(y, d, pscore):
    """IPW estimator for ATT."""
    n1 = d.sum()
    w0 = pscore / (1 - pscore)  # odds weights for controls

    att = y[d == 1].mean() - (w0[d == 0] * y[d == 0]).sum() / w0[d == 0].sum()
    return att
```

### Doubly Robust / AIPW

The AIPW estimator is consistent if **either** the propensity score model **or** the outcome model is correctly specified (but not necessarily both). This double robustness property makes it the recommended default.

```python
from sklearn.linear_model import LinearRegression

def aipw_ate(y, d, X, pscore):
    """
    Augmented IPW (doubly robust) estimator for ATE.

    τ_AIPW = (1/N) Σ [μ₁(Xᵢ) - μ₀(Xᵢ)
              + Dᵢ(Yᵢ - μ₁(Xᵢ))/e(Xᵢ)
              - (1-Dᵢ)(Yᵢ - μ₀(Xᵢ))/(1-e(Xᵢ))]
    """
    # Outcome models
    mu1_model = LinearRegression().fit(X[d == 1], y[d == 1])
    mu0_model = LinearRegression().fit(X[d == 0], y[d == 0])

    mu1 = mu1_model.predict(X)
    mu0 = mu0_model.predict(X)

    # AIPW estimator
    n = len(y)
    aipw = (1 / n) * np.sum(
        mu1 - mu0
        + d * (y - mu1) / pscore
        - (1 - d) * (y - mu0) / (1 - pscore)
    )

    # Influence function for standard errors
    phi = (mu1 - mu0 - aipw
           + d * (y - mu1) / pscore
           - (1 - d) * (y - mu0) / (1 - pscore))

    se = np.sqrt(np.var(phi) / n)

    return aipw, se
```

### Matching Diagnostics Checklist

- [ ] **Covariate balance**: After weighting/matching, standardized mean differences should be < 0.1
- [ ] **Common support**: Substantial overlap in propensity score distributions
- [ ] **Propensity score model**: Include all confounders; avoid overfitting (which makes overlap worse)
- [ ] **Sensitivity analysis**: Rosenbaum bounds (how much unmeasured confounding would invalidate results?)
- [ ] **Trimming**: Report sensitivity to trimming threshold
- [ ] **Outcome model specification**: For AIPW, results should be similar with different outcome models (linear, flexible)
- [ ] **No post-treatment covariates**: Only condition on pre-treatment variables

## Method Selection Guide

| Scenario | Recommended Method | Key Assumption |
|----------|--------------------|----------------|
| Random assignment with imperfect compliance | IV/2SLS | Exclusion restriction, monotonicity |
| Policy change at a threshold | RDD | No manipulation, local continuity |
| Policy change at a time point, with treated and control groups | DiD | Parallel trends |
| Staggered policy adoption across units | Staggered DiD (C-SA, S-A) | Parallel trends (conditional) |
| Single treated unit, long pre-period | Synthetic control | Weights can reproduce pre-treatment |
| Treatment assignment based on observables | Matching/IPW/AIPW | Selection on observables (no unobserved confounders) |
| Observables + instrument available | IV | Exclusion restriction |

**Decision heuristic:**
1. Is there a sharp threshold? → RDD
2. Is there an instrument? → IV
3. Is there a clean pre/post + treated/control? → DiD
4. Only one treated unit? → Synthetic control
5. Rich observables, selection on observables plausible? → AIPW
6. None of the above → structural model may be needed

## Common Anti-Patterns

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| Using TWFE with staggered timing and heterogeneous effects | Negative weights, biased estimates | Use Callaway-Sant'Anna or Sun-Abraham |
| Reporting 2SLS without first-stage F | Reader cannot assess instrument strength | Always report first-stage F (and LIML as robustness) |
| High-order polynomial in RDD | Overfitting, poor boundary properties | Use local linear (p=1) with rdrobust |
| Matching on post-treatment variables | Conditioning on outcome of treatment | Only match on pre-treatment covariates |
| Claiming parallel trends "hold" because pre-event coefficients are insignificant | Low power; absence of evidence ≠ evidence of absence | Use Rambachan-Roth sensitivity analysis |
| IPW with extreme propensity scores (near 0 or 1) | Huge variance, unstable estimates | Trim, use normalized/Hajek weights, or switch to AIPW |
| Reporting only one bandwidth in RDD | Cherry-picking concern | Show results across bandwidth range |
| Using cluster-robust SEs with few clusters (< 30-40) | Poor finite-sample coverage | Wild cluster bootstrap (Cameron, Gelbach, Miller 2008) |

## Packages Reference

| Method | Python | R | Stata |
|--------|--------|---|-------|
| IV/2SLS | `linearmodels` | `fixest::feols`, `AER::ivreg` | `ivregress` |
| Panel FE | `linearmodels` | `fixest::feols`, `plm` | `xtreg` |
| DiD (classic) | `linearmodels`, `statsmodels` | `fixest::feols` | `reghdfe` |
| DiD (staggered) | `csdid` (developing) | `did`, `fixest::sunab` | `csdid`, `eventstudyinteract` |
| RDD | `rdrobust` | `rdrobust`, `rddensity` | `rdrobust` |
| Synthetic control | `SparseSC` | `Synth`, `augsynth`, `tidysynth` | `synth` |
| Matching/IPW | `causalml`, `econml` | `MatchIt`, `cobalt`, `WeightIt` | `teffects` |
| AIPW | `econml.dr` | `AIPW`, `augsynth` | `teffects aipw` |
| Wild bootstrap | `wildboottest` | `fwildclusterboot` | `boottest` |
