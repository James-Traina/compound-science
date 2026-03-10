---
name: empirical-playbook
description: >-
  Guide for choosing and implementing applied microeconomic empirical methods. Use when the user is selecting an identification strategy, comparing estimators, running diagnostics, designing a research study, or evaluating an empirical strategy. Triggers on "which method", "what estimator", "how to choose", "method comparison", "empirical strategy", "research design", "applied micro", "identification strategy", "power analysis", "design-based", "model-based", "minimum detectable effect", "specification".
---

# Applied Micro Toolkit

Comprehensive reference for applied microeconomic research design: method selection, estimator comparison, standard diagnostics, inference frameworks, common pitfalls, reporting standards, and power analysis. Covers the full landscape from design-based to model-based approaches.

## When to Use This Skill

Use when the user is:
- Choosing between empirical methods for a causal question
- Evaluating which identification strategy fits their data and setting
- Running standard diagnostic tests and unsure which ones apply
- Designing a study and needs to calculate statistical power
- Reviewing or critiquing an empirical strategy
- Preparing the "Empirical Strategy" section of a paper

Skip when:
- Implementation details for a specific method are needed (use `causal-inference` skill for IV, DiD, RDD, SC, matching)
- The task is structural estimation (use `structural-modeling` skill)
- The task is manuscript preparation or journal logistics (use `submission-guide` skill)

After selecting a method, the `econometric-reviewer` agent can review the implementation and the `identification-critic` agent can evaluate the identification argument.

## Method Selection Decision Tree

Start with the fundamental question: **What source of variation identifies the causal effect?**

### Step 1: What is your source of variation?

| Source of Variation | Method Family | Key Assumption |
|--------------------|---------------|----------------|
| Randomized assignment (with full compliance) | Experimental analysis (OLS on treatment indicator) | Random assignment |
| Randomized assignment (with imperfect compliance) | IV / 2SLS using random assignment as instrument | Exclusion restriction, monotonicity |
| Policy change at a sharp threshold | Sharp RDD | Continuity of potential outcomes at cutoff |
| Policy change at a threshold with imperfect compliance | Fuzzy RDD (= IV at the cutoff) | Continuity + monotonicity at cutoff |
| Policy change at a point in time, with affected and unaffected groups | Difference-in-differences | Parallel trends |
| Staggered policy adoption across units over time | Staggered DiD (Callaway-Sant'Anna, Sun-Abraham, etc.) | Parallel trends (conditional on group and time) |
| Rare event affecting a single unit, long pre-treatment data | Synthetic control | Pre-treatment fit implies post-treatment counterfactual |
| Exogenous shifter of treatment that does not affect outcome directly | IV / 2SLS / GMM | Exclusion restriction, relevance, monotonicity |
| Rich set of observables that plausibly captures all confounders | Matching, IPW, AIPW (selection on observables) | Conditional independence (no unobserved confounders) |
| No credible exogenous variation | Sensitivity analysis, bounds, partial identification | Depends on bounding assumptions |

### Step 2: Refinements Within Method Families

**Within DiD:**

```
Is treatment timing staggered?
├── No → Classic 2x2 DiD (TWFE is fine)
└── Yes
    ├── Can treatment turn off (reversals)?
    │   ├── Yes → de Chaisemartin-D'Haultfoeuille (2020)
    │   └── No
    │       ├── Do you have never-treated units?
    │       │   ├── Yes → Callaway-Sant'Anna (2021) with never-treated controls
    │       │   └── No → Callaway-Sant'Anna with not-yet-treated controls
    │       │           or Sun-Abraham (2021)
    │       └── Are effects likely heterogeneous across cohorts?
    │           ├── Yes → Callaway-Sant'Anna or Sun-Abraham (NOT TWFE)
    │           └── No → TWFE is OK, but report Bacon decomposition
```

**Within IV:**

```
How many instruments for how many endogenous regressors?
├── Exactly identified (K instruments = K endogenous)
│   └── 2SLS (= IV = Wald estimator for single instrument)
├── Over-identified (K instruments > K endogenous)
│   ├── 2SLS (default)
│   ├── GMM (efficient, use if heteroskedasticity suspected)
│   └── LIML (less biased with weak instruments)
└── Under-identified (K instruments < K endogenous)
    └── Cannot identify all parameters — need more instruments or fewer endogenous regressors
```

**Within RDD:**

```
Does crossing the threshold guarantee treatment?
├── Yes → Sharp RDD
└── No → Fuzzy RDD
    └── Is the running variable continuous?
        ├── Yes → Standard rdrobust
        └── No (discrete / few mass points)
            └── Cattaneo-Idrobo-Titiunik (2019) discrete RD methods
```

**Within Matching / Selection on Observables:**

```
Is the selection-on-observables assumption plausible?
├── No → Need a different identification strategy
└── Yes
    ├── Do you need ATE or ATT?
    │   ├── ATE → IPW or AIPW
    │   └── ATT → Matching or IPW with ATT weights
    ├── Is the propensity score model well-specified?
    │   ├── Uncertain → Use AIPW (doubly robust, consistent if either PS or outcome model is correct)
    │   └── Confident → IPW or regression adjustment
    └── Many covariates or nonlinear confounding?
        ├── Yes → ML-based methods (causal forests, DML)
        └── No → Parametric PS model + AIPW
```

## Estimator Comparison by Setting

### When DiD is Preferred Over Synthetic Control

| Factor | Favors DiD | Favors Synthetic Control |
|--------|-----------|------------------------|
| Number of treated units | Many | One (or very few) |
| Pre-treatment periods | Few needed (2+ suffice) | Many needed (long pre-treatment series) |
| Control group | Clear comparison group exists | No obvious comparison group; SC constructs one |
| Aggregate vs micro data | Micro-level data available | Aggregate data (state/country level) |
| Staggered adoption | Natural fit (use modern DiD) | Harder to implement with staggered timing |
| Covariates | Can incorporate covariates flexibly | Covariates enter through matching, less flexible |

### When RDD is Preferred Over IV

| Factor | Favors RDD | Favors IV |
|--------|-----------|-----------|
| Source of variation | Sharp threshold in a running variable | Excluded instrument available |
| Scope of effect | Local (at the cutoff only) | Local to compliers (LATE) but population more dispersed |
| Assumption strength | Continuity (hard to violate if no manipulation) | Exclusion restriction (often debatable) |
| Data requirement | Dense observations near the cutoff | Variation in instrument across population |
| Testability | McCrary test, covariate balance at cutoff — partially testable | Exclusion restriction is untestable |
| External validity | Limited to cutoff neighborhood | Limited to compliers |

### When Matching is Acceptable vs When It Is Not

| Acceptable | Not Acceptable |
|-----------|---------------|
| Rich administrative data with detailed pre-treatment covariates | Key confounders are unobserved (ability, motivation, preferences) |
| Treatment assignment is primarily based on observables (e.g., program eligibility formula) | Treatment is self-selected based on private information |
| Combined with Oster (2019) or Rosenbaum bounds showing robustness to modest unobserved confounding | No sensitivity analysis for unobserved confounders |
| Used alongside quasi-experimental methods as a complement | Used as the sole identification strategy when quasi-experimental alternatives exist |
| Augmented with doubly robust estimation (AIPW) | Propensity scores are extreme (near 0 or 1), indicating poor overlap |

For method-specific diagnostics (IV, DiD, RDD, Synthetic Control, Matching), see the `causal-inference` skill, which contains implementation details and diagnostic checklists for each method.

## Design-Based vs Model-Based Inference

### Framework Comparison

| Dimension | Design-Based | Model-Based |
|-----------|-------------|-------------|
| Source of randomness | Treatment assignment mechanism | Outcome is a random draw from a superpopulation |
| Population concept | Finite population; inference is about these specific units | Infinite superpopulation; inference is about population parameters |
| Key assumption | Known or modeled treatment assignment | Correct outcome model specification |
| Variance estimation | Randomization inference, permutation tests | Standard errors from asymptotic theory |
| Examples | Experiments, natural experiments, RDD, DiD | OLS with random sampling, structural models, matching |
| Advantages | Transparent; does not require outcome model | More powerful; extends to complex settings |
| Risks | May be underpowered; limited to simple estimands | Model misspecification can bias results |

### When Design-Based Inference Applies

Design-based inference is appropriate when:
- Treatment assignment mechanism is known or plausibly approximated (experiments, lotteries, cutoff rules)
- The "as-if random" argument is credible
- Fisher randomization inference or permutation tests can be implemented
- Clustered treatment assignment maps naturally to clustered permutation

Common design-based settings:
- Randomized controlled trials (treatment was literally randomized)
- RDD (as-if random variation near the cutoff)
- DiD (parallel trends approximates what a randomized trial would deliver)
- Natural experiments with known assignment rules (draft lottery, weather shocks)

### When Model-Based Inference Applies

Model-based inference is appropriate when:
- Random sampling from a population is a reasonable assumption
- Interest is in population parameters, not just the specific sample
- Structural models are being estimated (parameters of utility functions, production functions)
- Complex estimands that cannot be expressed as simple treatment-control comparisons

Common model-based settings:
- Structural estimation (demand estimation, dynamic discrete choice)
- Cross-sectional surveys with sampling weights
- Selection-on-observables designs (matching, AIPW)
- Any setting where you want to generalize beyond the specific sample

### Hybrid Approaches

Many modern empirical papers combine elements:
- **Design-based identification + model-based inference**: Use a natural experiment for identification but standard asymptotic inference (e.g., 2SLS with heteroskedasticity-robust standard errors).
- **Doubly robust estimation**: Model-based outcome regression combined with design-based reweighting. Consistent if either model is correct.
- **Randomization inference as robustness**: Report standard asymptotic p-values as the main result, then randomization inference p-values as a robustness check.

## Common Pitfalls by Method

### Bad Controls (Angrist and Pischke 2009)

A "bad control" is a variable that is itself an outcome of treatment. Conditioning on a bad control introduces selection bias.

| Variable Type | Example | Why It Is Bad | What to Do |
|--------------|---------|---------------|------------|
| Post-treatment outcome | Controlling for occupation when estimating returns to education | Education affects occupation choice; conditioning on it selects on an outcome of treatment | Only control for pre-treatment variables |
| Mediator | Controlling for wages when estimating effect of training on employment | Training affects wages; conditioning on wages blocks part of the causal effect | Do not control for mediators unless doing mediation analysis |
| Collider | Conditioning on "survived" when estimating health effects | Survival depends on both treatment and health; conditioning opens a non-causal path | Do not condition on colliders |
| Descendant of collider | Controlling for hospital admission when studying drug efficacy | Hospital admission depends on severity and treatment | Trace the DAG; remove descendants of colliders |

**Rule of thumb:** If you cannot be sure a variable is determined before treatment, do not include it as a control. When in doubt, draw the DAG.

### Forbidden Regressions

A "forbidden regression" arises when you use predicted values from a first-stage regression inside a second-stage regression that is not the standard IV/2SLS setup.

| Mistake | Why It Is Wrong | Correct Approach |
|---------|----------------|-----------------|
| Running first stage, saving predicted values, then running OLS with predicted values manually | Standard errors in the second stage are wrong (they do not account for estimation error in the first stage) | Use a proper 2SLS command (`ivreg2`, `ivregress`, `IV2SLS`) |
| Using a nonlinear first stage (probit/logit) then plugging predictions into a linear second stage | Not a valid IV estimator; not consistent in general | Use linear first stage for 2SLS. If first stage is inherently nonlinear, use control function approach with bootstrap SEs |
| Residual inclusion without proper correction | Residuals from a first step are generated regressors; naive SEs are wrong | Bootstrap the entire two-step procedure |

### Staggered DiD with Heterogeneous Treatment Effects

| Mistake | Consequence | Fix |
|---------|------------|-----|
| Running TWFE (`y ~ treated_post + unit_FE + time_FE`) with staggered timing | Already-treated units used as controls; negative weights on some treatment effects; estimate can have wrong sign | Use Callaway-Sant'Anna, Sun-Abraham, or other modern DiD estimator |
| Including unit-specific linear trends in TWFE | Can exacerbate bias from heterogeneous effects; absorbs treatment effects if effects are linear | Avoid unit trends; use modern DiD methods that do not require them |
| Using a single post-treatment indicator for all cohorts | Masks heterogeneity in treatment effects across cohorts | Estimate group-time ATTs separately, then aggregate |
| Not reporting the Bacon decomposition | Reader cannot assess how much of the TWFE estimate comes from problematic comparisons | Report `bacondecomp` output |

### Fuzzy RDD Misconceptions

| Misconception | Reality | Correct Understanding |
|--------------|---------|----------------------|
| "Fuzzy RDD is just IV" | It is IV, but only at the cutoff — the instrument is the cutoff indicator | The LATE is estimated for compliers at the cutoff, not for all compliers in the population |
| "I can use any instrument in an RDD" | The instrument is 1(X >= c); the RDD assumptions apply to this specific instrument | Do not combine external instruments with the RDD instrument unless you have a clear framework |
| "The bandwidth should be chosen based on first-stage strength" | Bandwidth should be chosen by MSE-optimal or CER-optimal criteria (rdrobust default) | Use rdrobust for bandwidth selection; do not cherry-pick bandwidths to maximize the first stage |
| "If the first stage is weak at the cutoff, use a wider bandwidth" | Wider bandwidth introduces more bias; weak first stage may indicate small discontinuity in treatment | Report the first-stage discontinuity; if it is small, the fuzzy RDD may not be viable |

### Clustering Errors

| Mistake | Consequence | Fix |
|---------|------------|-----|
| Clustering at too fine a level (individual when treatment is at state level) | Standard errors too small; over-rejection of null | Cluster at the level of treatment assignment |
| Clustering at too coarse a level without justification | Standard errors too large; unnecessary power loss | Cluster at the level at which treatment varies |
| Few clusters (< 30-40) with standard cluster-robust SEs | Poor finite-sample properties; SEs can be too small | Wild cluster bootstrap (Cameron-Gelbach-Miller 2008) |
| Not clustering at all when treatment varies at group level | Standard errors dramatically understated | Always cluster at least at the level of treatment assignment |
| Multi-way clustering without clear justification | Can produce very large SEs; unclear which dimensions matter | Cluster at the primary dimension of treatment assignment; report multi-way as robustness |

**Clustering decision rule:**
1. Identify the level at which treatment is assigned → cluster at that level (minimum)
2. If there are within-cluster correlations beyond treatment (e.g., spatial), consider multi-way clustering
3. If the number of clusters is small (< 30-40), use wild cluster bootstrap
4. If the number of clusters is very small (< 10), cluster-robust methods may not work at all — consider randomization inference or aggregate to the cluster level

## Minimum Reporting Standards

Based on Brodeur et al. (2020), Christensen and Miguel (2018), and AEA Data Editor guidelines.

### Every Empirical Paper Must Report

| Item | Where | Why |
|------|-------|-----|
| Sample construction | Data section | Reader must be able to reconstruct your sample from the raw data |
| Summary statistics | Table 1 | Means, SDs, N, and key percentiles for all variables used in analysis |
| Main specification | Empirical strategy section | Written as an equation with all variables defined |
| Coefficient + SE + stars | Results tables | Standard errors in parentheses; state clustering level and type |
| Number of observations | Every regression table | N for each column; explain if N varies across columns |
| R-squared or goodness-of-fit | Every regression table | Adjusted R-squared, within R-squared for FE, pseudo R-squared for nonlinear |
| Economic magnitude | Results discussion | Interpret coefficients in meaningful units (% of mean, SD change, dollar amount) |
| Identification assumptions | Empirical strategy section | Formally state (numbered if possible); discuss testable implications |
| Robustness checks | Robustness section | At minimum: alternative specifications, alternative samples, alternative standard errors |
| Falsification / placebo tests | Robustness section | Placebo outcomes, placebo treatments, placebo samples |
| Data and code availability | Footnote or appendix | State where replication package is or will be deposited |

### Method-Specific Minimum Reporting

**For IV / 2SLS:**
- First-stage regression (full table, not just F-statistic)
- First-stage F-statistic (Kleibergen-Paap if heteroskedasticity-robust)
- Reduced form (Y on Z) results
- OLS for comparison (with discussion of expected bias direction)
- Overidentification test (if overidentified)
- Discussion of LATE interpretation and complier characterization

**For DiD:**
- Event study plot with pre-treatment and post-treatment coefficients
- Pre-trend test (formal F-test on pre-treatment coefficients)
- Raw outcome means by group and period
- Discussion of parallel trends assumption with institutional context
- If staggered: Bacon decomposition or modern DiD estimator
- Sensitivity analysis for parallel trends (Rambachan-Roth)

**For RDD:**
- RD plot with binned means
- McCrary density test
- Covariate balance at cutoff
- Bandwidth sensitivity (table or plot across bandwidth range)
- Effective sample size (N within bandwidth, left and right)
- Local linear preferred; report polynomial sensitivity

**For Synthetic Control:**
- Pre-treatment fit plot (treated vs synthetic)
- Donor unit weights
- Predictor balance table (treated vs synthetic)
- Permutation (placebo) test with p-value
- Leave-one-out robustness
- RMSPE ratio

**For Matching / AIPW:**
- Propensity score distributions by treatment status (overlap plot)
- Covariate balance (Love plot or SMD table) before and after matching
- Sensitivity analysis (Oster bounds, Rosenbaum bounds, or Altonji-Elder-Taber ratio)
- Results under alternative PS specifications
- Trimming sensitivity
- Effective sample size after weighting

## Power Analysis Guide

### Why Power Matters

An underpowered study that fails to reject the null is uninformative — it cannot distinguish "no effect" from "too little data to detect an effect." Power analysis should be done before data collection (prospective) or, for observational studies, before running the main specification (to set expectations about what effects are detectable).

### Core Concepts

| Concept | Definition | Typical Value |
|---------|-----------|---------------|
| Significance level (alpha) | Probability of rejecting H0 when H0 is true (Type I error) | 0.05 |
| Power (1 - beta) | Probability of rejecting H0 when H1 is true | 0.80 (minimum) |
| Minimum Detectable Effect (MDE) | Smallest effect size the study can detect with specified power | Depends on context |
| Effect size (Cohen's d) | Standardized effect: d = (mu1 - mu0) / sigma | Small: 0.2, Medium: 0.5, Large: 0.8 |
| Intraclass correlation (ICC) | Share of variance between clusters (for cluster-randomized) | 0.01-0.20 typical |

### MDE Formula for Standard Designs

**Simple two-group comparison:**

```
MDE = (t_alpha/2 + t_beta) * sigma * sqrt(1/N_T + 1/N_C)

Where:
  t_alpha/2 = 1.96 for alpha = 0.05 (two-sided)
  t_beta    = 0.84 for power = 0.80
  sigma     = standard deviation of outcome
  N_T, N_C  = sample sizes in treatment and control
```

**With equal groups (N_T = N_C = N/2):**

```
MDE = 2.8 * sigma / sqrt(N)
```

This means you need `N = (2.8 * sigma / MDE)^2` total observations.

**Cluster-randomized design:**

```
MDE = (t_alpha/2 + t_beta) * sigma * sqrt((1 + (m-1)*ICC) * (1/J_T + 1/J_C) / m)

Where:
  J_T, J_C = number of clusters in treatment and control
  m        = average cluster size
  ICC      = intraclass correlation
```

The design effect `(1 + (m-1)*ICC)` inflates the MDE. With ICC = 0.05 and m = 50, the design effect is 3.45 — you need 3.45 times as many observations as a non-clustered design.

### Power for DiD

```
MDE_DiD = (t_alpha/2 + t_beta) * sigma_epsilon * sqrt(1 / (N_T * T_post * (1 - R^2)))

Where:
  sigma_epsilon = residual SD after removing unit and time FEs
  T_post        = number of post-treatment periods
  R^2           = R-squared from the outcome regression (higher = more power)
```

Key insight: DiD gains power from more post-treatment periods and from higher within-group correlation (which is absorbed by FEs, reducing residual variance).

### Power for IV / 2SLS

IV estimates have larger standard errors than OLS. As a rule of thumb:

```
SE_IV ≈ SE_OLS / first_stage_coefficient

Equivalently:
MDE_IV ≈ MDE_OLS / |pi| * sqrt(1 + 1/F)

Where:
  pi = first-stage coefficient
  F  = first-stage F-statistic
```

With a first-stage F of 10, the IV MDE is approximately `MDE_OLS / |pi| * sqrt(1.1)` — much larger than the OLS MDE when pi is small.

**Implication:** IV requires much larger samples than OLS to detect the same effect. If your instrument is weak (small pi, low F), you may need orders of magnitude more data.

### Power for RDD

RDD uses only observations near the cutoff, so effective sample size is much smaller than total N:

```
Effective N ≈ N * h / range(X)

Where:
  h        = bandwidth
  range(X) = range of the running variable
```

If only 10% of observations fall within the bandwidth, the effective sample size is roughly N/10. MDE calculations should use this effective N.

**Practical guidance:** RDD is inherently less powered than designs that use the full sample. Effect sizes at the cutoff must be large to be detectable.

### Simulation-Based Power

For nonstandard designs where analytical formulas do not exist, simulate:

```python
import numpy as np
from scipy import stats

def power_simulation(n, effect_size, sigma, n_sims=5000, alpha=0.05):
    """
    Simulate power for a two-group comparison.
    Extend this template for more complex designs.
    """
    rejections = 0
    n_treat = n // 2
    n_control = n - n_treat

    for _ in range(n_sims):
        y_control = np.random.normal(0, sigma, n_control)
        y_treat = np.random.normal(effect_size, sigma, n_treat)

        t_stat, p_value = stats.ttest_ind(y_treat, y_control)
        if p_value < alpha:
            rejections += 1

    return rejections / n_sims

# Example: 80% power to detect effect of 0.3 SD with N=350
power = power_simulation(n=350, effect_size=0.3, sigma=1.0)
print(f"Power: {power:.3f}")
```

**For DiD:**

```python
def power_did_simulation(n_units, n_periods, treat_share, effect_size,
                          sigma_unit, sigma_time, sigma_eps,
                          n_sims=2000, alpha=0.05):
    """
    Simulate power for a canonical DiD design.

    Parameters:
        n_units: total number of units
        n_periods: total number of periods (half pre, half post)
        treat_share: fraction of units treated
        effect_size: true treatment effect
        sigma_unit: SD of unit fixed effects
        sigma_time: SD of time fixed effects
        sigma_eps: SD of idiosyncratic error
    """
    import statsmodels.formula.api as smf
    import pandas as pd

    rejections = 0
    n_treat = int(n_units * treat_share)
    t_post = n_periods // 2  # half are post-treatment

    for _ in range(n_sims):
        # Generate panel data
        unit_fe = np.random.normal(0, sigma_unit, n_units)
        time_fe = np.random.normal(0, sigma_time, n_periods)
        treat = np.array([1]*n_treat + [0]*(n_units - n_treat))

        rows = []
        for i in range(n_units):
            for t in range(n_periods):
                post = int(t >= t_post)
                y = (unit_fe[i] + time_fe[t]
                     + effect_size * treat[i] * post
                     + np.random.normal(0, sigma_eps))
                rows.append({'unit': i, 'time': t, 'y': y,
                            'treat': treat[i], 'post': post,
                            'treat_post': treat[i] * post})

        df = pd.DataFrame(rows)
        model = smf.ols('y ~ C(unit) + C(time) + treat_post', data=df)
        result = model.fit()

        p_val = result.pvalues.get('treat_post', 1.0)
        if p_val < alpha:
            rejections += 1

    return rejections / n_sims
```

**For Cluster-Randomized Designs:**

```python
def power_cluster_simulation(n_clusters, cluster_size, effect_size,
                              icc, sigma, n_sims=2000, alpha=0.05):
    """
    Simulate power for a cluster-randomized design.
    """
    rejections = 0
    n_treat_clusters = n_clusters // 2

    sigma_between = np.sqrt(icc) * sigma
    sigma_within = np.sqrt(1 - icc) * sigma

    for _ in range(n_sims):
        treat = np.array([1]*n_treat_clusters + [0]*(n_clusters - n_treat_clusters))
        cluster_effects = np.random.normal(0, sigma_between, n_clusters)

        y_list = []
        t_list = []
        c_list = []

        for j in range(n_clusters):
            y_j = (effect_size * treat[j]
                   + cluster_effects[j]
                   + np.random.normal(0, sigma_within, cluster_size))
            y_list.extend(y_j)
            t_list.extend([treat[j]] * cluster_size)
            c_list.extend([j] * cluster_size)

        y = np.array(y_list)
        t = np.array(t_list)

        # Cluster-level means (equivalent to cluster-robust inference)
        cluster_means_t = [np.mean(y[(np.array(c_list)==j)])
                          for j in range(n_clusters) if treat[j]==1]
        cluster_means_c = [np.mean(y[(np.array(c_list)==j)])
                          for j in range(n_clusters) if treat[j]==0]

        t_stat, p_value = stats.ttest_ind(cluster_means_t, cluster_means_c)
        if p_value < alpha:
            rejections += 1

    return rejections / n_sims
```

### Power Analysis Reporting

Every power analysis should report:

| Item | Description |
|------|-------------|
| Target parameter | What effect are you trying to detect? |
| MDE | The minimum effect you can detect with 80% power (or your chosen power level) |
| MDE in context | Is the MDE substantively meaningful? Compare to existing estimates, policy-relevant thresholds, or effect sizes from related studies |
| Assumptions | Outcome variance, ICC (for clustered), autocorrelation (for panel), first-stage strength (for IV) |
| Method | Analytical formula, simulation-based, or both |
| Sensitivity | How MDE changes with N, alpha, ICC, etc. |

**MDE Interpretation Guide:**

| MDE relative to existing estimates | Assessment |
|------------------------------------|------------|
| MDE < 0.5 * prior estimate | Well-powered for the expected effect |
| MDE ≈ prior estimate | Marginal power — 50/50 chance of detecting the effect |
| MDE > 2 * prior estimate | Underpowered — null result will be uninformative |
| No prior estimate available | Compare MDE to smallest policy-relevant effect |

## Specification Curve Analysis

When there are many defensible specification choices, a specification curve (Simonsohn, Simmons, and Nelson 2020) shows how results vary across all of them.

### What to Vary

| Dimension | Example Choices |
|-----------|----------------|
| Control variables | None, demographic controls, full controls, kitchen-sink |
| Sample definition | Full sample, balanced panel, no outliers, alternative age/time cutoffs |
| Functional form | Linear, log, levels, first differences |
| Standard errors | Robust, clustered (at different levels), wild bootstrap |
| Outcome variable | Alternative measures of the same concept |
| Treatment definition | Binary vs continuous, different treatment timing, intent-to-treat vs treatment-on-treated |
| Estimation method | OLS, IV, matching, doubly robust |
| Fixed effects | None, unit FE, time FE, unit + time FE, unit trends |

### Implementation

```python
import itertools

# Define specification choices
specs = {
    'controls': ['none', 'basic', 'full'],
    'sample': ['full', 'balanced', 'no_outliers'],
    'se_type': ['robust', 'clustered_state'],
    'fe': ['unit_time', 'unit_time_trends'],
}

# Generate all combinations
all_specs = list(itertools.product(*specs.values()))
# For each specification, estimate the model and store:
# (coefficient, se, p_value, specification_choices)

# Plot: sort specifications by coefficient, show CI for each
# Mark "preferred" specification
# Report: median coefficient, share significant, share positive
```

### Reporting

- Plot all specifications sorted by effect size, with confidence intervals.
- Highlight the "preferred" specification but show it is not cherry-picked.
- Report: share of specifications with significant effects, share with the same sign, median effect size.
- This is a complement to robustness tables, not a replacement. The specification curve shows the full distribution; the robustness table explains the key choices.

## Research Design Checklist

Use this checklist when starting a new empirical project.

### Before Touching Data

- [ ] **Research question**: What causal parameter are you trying to estimate? Write it as a formal estimand.
- [ ] **Identification strategy**: What source of variation identifies the effect? Draw the DAG.
- [ ] **Assumptions**: List all identification assumptions explicitly. Which are testable?
- [ ] **Threats**: For each assumption, what is the most plausible violation? How would you detect it?
- [ ] **Power**: Given your expected sample size, what is the MDE? Is it policy-relevant?
- [ ] **Pre-analysis plan**: For prospective studies, register the plan before seeing outcomes. For observational studies, write down the specification before running it.

### During Analysis

- [ ] **Data cleaning documented**: Every sample restriction justified and recorded.
- [ ] **Summary statistics**: Know your data before running regressions.
- [ ] **Main specification**: Run the main spec first. Resist the urge to search for significance.
- [ ] **Diagnostics**: Run all standard diagnostics for your method (see tables above).
- [ ] **Robustness**: Vary specification choices systematically.
- [ ] **Magnitude interpretation**: Can you explain the coefficient in plain language?

### Before Submission

- [ ] **All diagnostics reported**: See method-specific minimum reporting standards above.
- [ ] **Replication package**: Code runs from raw data to all tables and figures.
- [ ] **Seeds set**: All random number generators seeded for reproducibility.
- [ ] **Limitations discussed**: What are the strongest objections? Address them in the paper.
- [ ] **Literature positioned**: Have you cited and compared to the 5 closest papers?
