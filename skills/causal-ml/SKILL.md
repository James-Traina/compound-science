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

Reference: Chernozhukov, Chetverikov, Demirer, Duflo, Hansen, Newey, Robins (2018), "Double/debiased machine learning for treatment and structural parameters," *Econometrics Journal*.

### Core Idea

Naive approach: regress Y on D and X with ML. This fails because ML regularization (LASSO shrinkage, random forest bias) contaminates the coefficient on D. The bias does not vanish even as n → ∞.

DML fix: partial out X from both Y and D using separate ML models, then regress the residuals on each other. The key properties that make this work:

1. **Neyman orthogonality**: The moment condition is locally insensitive to perturbations in the nuisance parameters. Small errors in nuisance estimates have second-order (not first-order) effects on the target parameter.
2. **Cross-fitting**: Estimate nuisance models on a held-out fold to avoid overfitting bias contaminating the main estimate.

### Partially Linear Model (PLR)

The PLR is the workhorse DML specification:

```
Y = θ₀ D + g₀(X) + ε,   E[ε | D, X] = 0
D = m₀(X) + v,           E[v | X] = 0
```

where g₀(X) is an unknown function of controls X, and θ₀ is the ATE of interest. The nuisance functions are g₀ and m₀.

**Identification assumption:** After conditioning on X, D is as good as randomly assigned. This is selection on observables — the same assumption as standard regression, but allowing the functional form of X to be flexible.

### Interactive Regression Model (IRM)

When treatment D is binary and the effect may be heterogeneous:

```
Y = g₀(D, X) + ε,   E[ε | D, X] = 0
D ~ Bernoulli(m₀(X))
```

The IRM estimates the ATE by averaging individual-level predictions:

```
θ₀ = E[g₀(1, X) - g₀(0, X)]
```

Use IRM when:
- D is binary and you suspect treatment effect heterogeneity
- You want ATE rather than a single θ coefficient
- The partially linear assumption (additive separability) seems too strong

### Cross-Fitting Procedure

Cross-fitting prevents overfitting bias from contaminating inference. The K-fold procedure (K=5 is standard):

```python
import numpy as np
from sklearn.model_selection import KFold

def cross_fit_residuals(Y, D, X, ml_model_y, ml_model_d, n_splits=5, random_state=42):
    """
    Cross-fitting step for DML partially linear model.

    Returns:
        W: residuals Y - E[Y|X] (partialled-out Y)
        V: residuals D - E[D|X] (partialled-out D)
    """
    n = len(Y)
    W = np.zeros(n)  # Y residuals
    V = np.zeros(n)  # D residuals

    kf = KFold(n_splits=n_splits, shuffle=True, random_state=random_state)

    for train_idx, test_idx in kf.split(X):
        # Train nuisance models on training fold
        ml_model_y.fit(X[train_idx], Y[train_idx])
        ml_model_d.fit(X[train_idx], D[train_idx])

        # Predict and residualize on held-out test fold
        W[test_idx] = Y[test_idx] - ml_model_y.predict(X[test_idx])
        V[test_idx] = D[test_idx] - ml_model_d.predict(X[test_idx])

    return W, V

def dml_plr_estimate(W, V):
    """
    DML estimate from partialled-out residuals.
    theta_hat = (V'W) / (V'V)  — OLS of W on V (no intercept)
    Standard errors via influence function.
    """
    n = len(W)
    theta_hat = np.dot(V, W) / np.dot(V, V)

    # Influence function: psi_i = V_i * (W_i - theta_hat * V_i)
    psi = V * (W - theta_hat * V)

    # Sandwich variance
    J = -np.mean(V ** 2)
    var_hat = np.mean(psi ** 2) / (J ** 2)
    se = np.sqrt(var_hat / n)

    return theta_hat, se
```

### Using the `DoubleML` Package (Python)

```python
import doubleml as dml
import numpy as np
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.linear_model import LassoCV

# Setup: data object
# Y: outcome (1D array), D: treatment (1D array), X: controls (2D array)
data = dml.DoubleMLData.from_arrays(X=X, y=Y, d=D)

# Choose learners for nuisance functions
# For continuous D: two regression learners
ml_g = RandomForestRegressor(n_estimators=100, max_depth=5, random_state=42)
ml_m = RandomForestRegressor(n_estimators=100, max_depth=5, random_state=42)

# Partially Linear Regression model
plr = dml.DoubleMLPLR(
    obj_dml_data=data,
    ml_g=ml_g,      # learner for E[Y|X]
    ml_m=ml_m,      # learner for E[D|X]
    n_folds=5,
    score='partialling out',
)
plr.fit()
print(plr.summary)

# For binary D: use classification learner for propensity
ml_m_binary = RandomForestClassifier(n_estimators=100, max_depth=5, random_state=42)
irm = dml.DoubleMLIRM(
    obj_dml_data=data,
    ml_g=ml_g,
    ml_m=ml_m_binary,
    n_folds=5,
    score='ATE',
)
irm.fit()
print(irm.summary)

# Cluster-robust standard errors
plr_clustered = dml.DoubleMLPLR(data, ml_g, ml_m, n_folds=5)
plr_clustered.fit()
# Pass cluster variable:
# data = dml.DoubleMLData.from_arrays(X=X, y=Y, d=D, cluster_cols=cluster_ids)
```

### Using the `DoubleML` Package (R)

```r
library(DoubleML)
library(mlr3)
library(mlr3learners)

# Create DoubleML data object
dml_data <- DoubleMLData$new(
  data = df,
  y_col = "outcome",
  d_cols = "treatment",
  x_cols = c("x1", "x2", "x3")  # control variables
)

# Specify learners (mlr3 ecosystem)
learner_g <- lrn("regr.ranger", num.trees = 100, max.depth = 5)
learner_m <- lrn("regr.ranger", num.trees = 100, max.depth = 5)

# Partially linear regression
plr <- DoubleMLPLR$new(
  data = dml_data,
  ml_g = learner_g,
  ml_m = learner_m,
  n_folds = 5
)
plr$fit()
plr$summary()

# For binary treatment (IRM)
learner_m_cls <- lrn("classif.ranger", num.trees = 100, max.depth = 5,
                     predict_type = "prob")
irm <- DoubleMLIRM$new(
  data = dml_data,
  ml_g = learner_g,
  ml_m = learner_m_cls,
  n_folds = 5,
  score = "ATE"
)
irm$fit()
irm$summary()
```

### DML Diagnostic Checklist

- [ ] **Nuisance fit quality**: Report R² (or classification accuracy) for both nuisance models (E[Y|X] and E[D|X]). Low R² on E[D|X] implies weak "first stage" — the controls barely explain treatment variation.
- [ ] **Residual balance**: After partialling out, regress V (D residuals) on X — coefficients should be near zero. If not, the ML model for E[D|X] is misspecified.
- [ ] **Cross-fitting fold stability**: Repeat with different random seeds. Estimates should be stable across seeds. Large variation implies insufficient sample size for the chosen ML method.
- [ ] **Compare K=5 vs K=10**: If estimates differ substantially, sample size may be too small for cross-fitting to work well.
- [ ] **Neyman orthogonality check**: Perturb nuisance estimates slightly — the main estimate should be insensitive. Large sensitivity suggests the score is not sufficiently orthogonal.
- [ ] **Trim extreme propensity scores**: For binary D, trim observations where E[D|X] is near 0 or 1 (e.g., below 0.01 or above 0.99). Extreme values inflate variance.

### Common DML Pitfalls

| Pitfall | Problem | Fix |
|---------|---------|-----|
| No cross-fitting | Overfitting bias in theta | Always use K-fold cross-fitting |
| Same learner for Y and D | Correlated errors across folds | Use separate model instances |
| Using DML R² as goodness-of-fit for causal claim | ML fit ≠ identification validity | Causal assumption is selection on observables — argue it separately |
| Ignoring clustering | Underestimated SEs in panel/clustered data | Pass cluster variable to DoubleML |
| Insufficient n for deep forests | ML models overfit → noisy nuisance | Use shallower trees, LASSO, or ElasticNet for smaller n |

---

## Causal Forests (Generalized Random Forests)

Reference: Athey, Tibshirani, Wager (2019), "Generalized random forests," *Annals of Statistics*. Wager and Athey (2018), "Estimation and inference of heterogeneous treatment effects using random forests," *JASA*.

### Core Idea

Causal forests estimate the CATE τ(x) = E[Y(1) - Y(0) | X = x] at any point x. The key innovation over standard random forests is **honesty**: the tree structure is learned on one subsample, and the leaf-level treatment effect is estimated on a separate subsample. This prevents overfitting from conflating the splitting criterion with the estimation.

Honesty is necessary for valid confidence intervals. Without it, leaf estimates are biased and confidence intervals have poor coverage.

### Intuition: Local ATE via Weighted Neighbors

Causal forests solve:

```
τ̂(x) = argmin_τ Σᵢ αᵢ(x) · [Yᵢ - m̂(Xᵢ) - τ · (Dᵢ - ê(Xᵢ))]²
```

where αᵢ(x) are forest weights (how much unit i's neighborhood contributes to τ(x)), and m̂(X), ê(X) are residualized outcomes and propensities. Units that are neighbors of x in feature space get high weight. Units far away get low weight.

This is local ATE estimation, where "local" is defined by proximity in the feature space learned by the forest.

### Python: CausalForestDML via `econml`

```python
from econml.dml import CausalForestDML
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
import numpy as np

# X: features for CATE heterogeneity (can differ from controls W)
# T: binary or continuous treatment
# Y: outcome
# W: high-dimensional controls to partial out (optional, separate from X)

cf = CausalForestDML(
    model_y=RandomForestRegressor(n_estimators=100, random_state=42),
    model_t=RandomForestClassifier(n_estimators=100, random_state=42),
    n_estimators=500,
    min_samples_leaf=5,
    max_depth=None,
    random_state=42,
    cv=5,           # cross-fitting folds
    honest=True,    # always use honest splitting
)
cf.fit(Y=y, T=t, X=X, W=W)  # W is additional controls not in X

# Estimate CATE for each observation
tau_hat = cf.effect(X)

# Estimate ATE and confidence interval
ate_result = cf.ate(X, T0=0, T1=1)
print(f"ATE: {ate_result:.4f}")

# Confidence intervals for each unit (conservative)
tau_lb, tau_ub = cf.effect_interval(X, alpha=0.05)

# Best linear projection of CATE onto features
from econml.inference import LinearModelFinalInference
blp = cf.const_marginal_effect_inference(X)
print(blp.summary_frame())
```

### R: `grf` Package

```r
library(grf)

# Prepare data
# X: matrix of features, Y: outcome vector, W: treatment vector

cf <- causal_forest(
  X = X_matrix,
  Y = Y_vector,
  W = W_treatment,
  num.trees = 2000,
  honesty = TRUE,          # required for valid inference
  min.node.size = 5,
  seed = 42
)

# Average treatment effect
ate <- average_treatment_effect(cf, target.sample = "all")
cat("ATE:", ate["estimate"], "+/-", 1.96 * ate["std.err"], "\n")

# ATT
att <- average_treatment_effect(cf, target.sample = "treated")

# CATE predictions with confidence intervals
tau_hat <- predict(cf, estimate.variance = TRUE)
tau_vals <- tau_hat$predictions
tau_se   <- sqrt(tau_hat$variance.estimates)

# Test for heterogeneity: BLP calibration test
# Chernozhukov, Demirer, Duflo, Fernandez-Val (2022)
calibration <- test_calibration(cf)
print(calibration)
# mean.forest.prediction: should be ~1 if CATE is well-calibrated
# differential.forest.prediction: should be >0 if heterogeneity is real

# Best linear projection of CATE on covariates
blp <- best_linear_projection(cf, A = X_matrix)
print(blp)
```

### CATE Heterogeneity: Calibration Test

The calibration test (Chernozhukov, Demirer, Duflo, Fernandez-Val 2022) estimates a linear projection:

```
τᵢ = α₀ + α₁ · τ̂ᵢ + εᵢ
```

using an AIPW-based approach. Interpretation:
- α₁ ≈ 1: forest predictions are well-calibrated on average
- α₁ > 0 and significant: there is real heterogeneity (the forest is detecting genuine variation, not noise)
- α₁ = 0: forest's heterogeneity is indistinguishable from noise

Report this test whenever presenting CATE estimates.

```r
# R (grf)
cal <- test_calibration(cf)
# Examine: mean.forest.prediction coefficient and its p-value
# Examine: differential.forest.prediction coefficient and its p-value

# Python (econml): use the best_linear_projection API
```

### Causal Forest Diagnostic Checklist

- [ ] **Honesty enabled**: Always set `honest = TRUE` (R) or `honest=True` (Python). Without honesty, confidence intervals are invalid.
- [ ] **Calibration test**: Run `test_calibration()`. Report both coefficients. Significant differential coefficient supports real heterogeneity.
- [ ] **ATE recovery**: Compare forest ATE to a standard doubly-robust ATE estimator. They should agree closely. Large discrepancy suggests a problem with nuisance models.
- [ ] **Overlap / positivity**: Check that propensity scores ê(X) are bounded away from 0 and 1. Forest fails when treatment assignment is deterministic given X.
- [ ] **Variable importance**: Examine `variable_importance(cf)` (R) or `cf.feature_importances_` (Python). Dominant variables driving heterogeneity should be interpretable.
- [ ] **Minimum leaf size**: Default `min.node.size=5` is a starting point. Increase for small samples; the forest should not have near-empty leaves.
- [ ] **Number of trees**: Use at least 2,000 trees for stable variance estimates. More trees reduce Monte Carlo error in τ̂(x).
- [ ] **Subgroup analysis**: Pre-specify subgroups before running the forest. Post-hoc "we found heterogeneity along dimension k" inflates false discovery rates.

### Common Causal Forest Pitfalls

| Pitfall | Problem | Fix |
|---------|---------|-----|
| `honest = FALSE` | Biased leaf estimates, invalid CIs | Always use honest splitting |
| Reporting CATE for individuals without calibration test | May be noise, not signal | Always report calibration test alongside individual CATEs |
| Using forest CATE for policy targeting without welfare analysis | High-variance individual CIs | Target subgroups defined by stable covariates, not individual predictions |
| X and W conflated | Controls that should be partialled out inflate variance in X | Separate: X = heterogeneity features; W = nuisance controls |
| Too few trees for stable variance | Variance estimates fluctuate across runs | Use 2000+ trees; check stability with different seeds |

---

## DR-Learner and Meta-Learners

Meta-learners decompose the CATE estimation problem into standard supervised learning sub-problems. The choice of meta-learner determines the statistical properties of τ̂(x).

Reference: Kennedy (2023), "Towards optimal doubly robust estimation of heterogeneous causal effects," *Electronic Journal of Statistics*. Künzel et al. (2019), "Meta-learners for estimating heterogeneous treatment effects using machine learning," *PNAS*.

### Overview of Meta-Learners

| Learner | Procedure | Pros | Cons |
|---------|-----------|------|------|
| T-Learner | Separate outcome models μ₁(x), μ₀(x); τ̂(x) = μ̂₁(x) - μ̂₀(x) | Simple | Regularization not targeted at τ; shrinks both toward zero rather than toward effect |
| S-Learner | Single model μ(x, d); τ̂(x) = μ̂(x,1) - μ̂(x,0) | Simple | Treatment effect may be shrunk to zero if D is not selected |
| X-Learner | Two-stage: impute counterfactuals, then regress; weighted combination | Works well in imbalanced treatment | Tuning heavy; depends on propensity weighting |
| DR-Learner | Regress DR pseudo-outcomes on X; τ̂(x) = learned function of DR scores | Best statistical properties; doubly robust at CATE level | Requires good nuisance estimates; more moving parts |

**Recommendation for applied work:** DR-Learner when sample is large enough for nuisance estimation. T-Learner as a simple benchmark. Report both.

### DR-Learner: Doubly Robust CATE

The DR-Learner constructs pseudo-outcomes:

```
ψᵢ = μ̂₁(Xᵢ) - μ̂₀(Xᵢ)
    + Dᵢ(Yᵢ - μ̂₁(Xᵢ)) / ê(Xᵢ)
    - (1-Dᵢ)(Yᵢ - μ̂₀(Xᵢ)) / (1 - ê(Xᵢ))
```

Then regresses these pseudo-outcomes on X to get τ̂(x). The pseudo-outcomes are doubly robust: if either the outcome model or propensity model is correct, the pseudo-outcome has the correct expectation.

```python
from econml.dr import DRLearner
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.linear_model import RidgeCV

# DR-Learner
dr = DRLearner(
    model_propensity=RandomForestClassifier(n_estimators=100, random_state=42),
    model_regression=RandomForestRegressor(n_estimators=100, random_state=42),
    model_final=RidgeCV(),       # final CATE model (can be any regressor)
    cv=5,
    random_state=42,
)
dr.fit(Y=y, T=t, X=X, W=W)

# CATE estimates
tau_dr = dr.effect(X)

# ATE from DR-Learner
ate_dr = dr.ate(X)
print(f"ATE (DR-Learner): {ate_dr:.4f}")

# Confidence intervals
ate_interval = dr.ate_interval(X, alpha=0.05)
print(f"95% CI: [{ate_interval[0]:.4f}, {ate_interval[1]:.4f}]")

# T-Learner for comparison
from econml.metalearners import TLearner

tl = TLearner(
    models=RandomForestRegressor(n_estimators=100, random_state=42)
)
tl.fit(y, t, X=X)
tau_tl = tl.effect(X)
```

### When to Use Each Meta-Learner

- **T-Learner**: Quick baseline; when treatment groups are roughly balanced; when you have very large n and flexible models
- **S-Learner**: When treatment effect is expected to be small or zero for most units (LASSO/tree won't shrink effect to zero unlike T-Learner)
- **X-Learner**: When treatment is rare or imbalanced (many control, few treated); designed specifically for this case
- **DR-Learner**: When you want the best-calibrated CATE estimates with valid inference; default for serious empirical work

### DR-Learner Diagnostic Checklist

- [ ] **Propensity model quality**: Check AUC and calibration of propensity score. Miscalibrated propensities inflate DR pseudo-outcome variance.
- [ ] **Outcome model quality**: Report R² for μ̂₁(X) and μ̂₀(X) separately. Low R² reduces efficiency but does not invalidate doubly-robust property (as long as propensity is right).
- [ ] **Compare T-Learner and DR-Learner**: If they agree closely, results are likely robust. Large disagreements suggest a nuisance specification problem.
- [ ] **ATE vs. mean of CATE**: `np.mean(tau_dr)` should match `dr.ate(X)` — if not, there is a weighting issue.
- [ ] **Calibration**: Apply Chernozhukov calibration test logic: project CATE onto a low-dimensional summary; check that projection coefficient is not zero.

---

## High-Dimensional Controls

Reference: Belloni, Chernozhukov, Hansen (2014), "Inference on treatment effects after selection among high-dimensional controls," *Review of Economic Studies*.

### When You Need This

You have many candidate control variables (p large relative to n) and want to:
1. Avoid overfitting by selecting controls automatically
2. Maintain valid inference on a treatment effect after selection
3. Avoid the Leeb-Pötscher problem: you cannot do inference on θ after LASSO selection of X unless you account for selection

**Key insight:** Running LASSO to predict Y and then doing OLS on the selected variables gives biased inference on D. You need post-double selection (PDS-LASSO) to avoid this.

### Post-Double Selection LASSO (PDS-LASSO)

The Belloni-Chernozhukov-Hansen (2014) procedure:

1. Run LASSO of Y on X → select variables S₁
2. Run LASSO of D on X → select variables S₂
3. Union: S = S₁ ∪ S₂
4. Run OLS of Y on D and all variables in S

The union step is critical: including variables that predict D (even if they don't add predictive power for Y) controls for confounders. Including variables that predict Y (even if they don't add for D) improves efficiency.

### Python: Manual PDS-LASSO

```python
import numpy as np
from sklearn.linear_model import LassoCV
import statsmodels.api as sm

def pds_lasso(Y, D, X, n_splits=5, random_state=42):
    """
    Post-double selection LASSO.

    Returns OLS estimate of treatment effect and standard error,
    controlling for selected variables.
    """
    # Step 1: LASSO of Y on X
    lasso_y = LassoCV(cv=n_splits, random_state=random_state)
    lasso_y.fit(X, Y)
    selected_y = np.where(np.abs(lasso_y.coef_) > 0)[0]

    # Step 2: LASSO of D on X
    lasso_d = LassoCV(cv=n_splits, random_state=random_state)
    lasso_d.fit(X, D)
    selected_d = np.where(np.abs(lasso_d.coef_) > 0)[0]

    # Step 3: Union of selected variables
    selected = np.union1d(selected_y, selected_d)
    print(f"Variables selected by Y-LASSO: {len(selected_y)}")
    print(f"Variables selected by D-LASSO: {len(selected_d)}")
    print(f"Union size: {len(selected)}")

    # Step 4: OLS with selected controls
    if len(selected) > 0:
        controls = X[:, selected]
        regressors = np.column_stack([D, controls])
    else:
        regressors = D.reshape(-1, 1)

    regressors_with_const = sm.add_constant(regressors)
    ols = sm.OLS(Y, regressors_with_const).fit(cov_type='HC3')

    # Treatment effect is the coefficient on D (index 1 after constant)
    theta_hat = ols.params[1]
    se = ols.bse[1]
    ci = ols.conf_int().iloc[1]

    return {
        'theta': theta_hat,
        'se': se,
        'ci_lo': ci[0],
        'ci_hi': ci[1],
        'n_selected': len(selected),
        'selected_idx': selected,
    }
```

### R: `hdm` Package

```r
library(hdm)

# Post-double selection LASSO via hdm
# Single treatment variable
pds <- rlassoEffect(
  x = X_matrix,        # control variables (n x p matrix)
  y = Y_vector,        # outcome
  d = D_vector,        # treatment
  method = "double selection"
)
print(pds)

# Inference on multiple treatment variables simultaneously
pds_multi <- rlassoEffects(
  x = X_matrix,
  y = Y_vector,
  d = D_matrix,        # multiple treatment variables
  method = "double selection"
)
summary(pds_multi)

# LASSO for variable selection only (then examine selected set)
lasso_y <- rlasso(Y_vector ~ X_matrix)
lasso_d <- rlasso(D_vector ~ X_matrix)

selected_y <- which(lasso_y$coef != 0)
selected_d <- which(lasso_d$coef != 0)
selected_union <- union(selected_y, selected_d)
cat("Union size:", length(selected_union), "\n")
```

### Practical Guidance for High-Dimensional Controls

**Choosing the LASSO penalty:**
- Use theory-based (Belloni-Chernozhukov) penalty: λ = 2c · σ̂ · √(n log p) for some constant c. This is what `hdm::rlasso` uses by default.
- Cross-validation (LassoCV) is common in practice but does not have the same theoretical guarantees for post-selection inference. Prefer `hdm` for formal inference.

**When p > n:**
- PDS-LASSO still works if the true model is sparse (few controls truly matter)
- If the true model is dense (many controls each with small effect), consider ridge or elastic net nuisance models within DML instead

**Interactions and polynomials:**
- You may want to include interactions D × X in the control set for the Y-LASSO step (to detect effect modifiers)
- But do NOT include D × X in the D-LASSO step — these are endogenous by construction

### PDS-LASSO Diagnostic Checklist

- [ ] **Selected variable set is interpretable**: Review which controls were selected. Variables strongly correlated with both Y and D should appear in the union.
- [ ] **First-stage effective F-stat**: After union selection, check that D is not partialled out (residual variance is not too small). Compute F from regression of D on selected controls.
- [ ] **Sensitivity to LASSO penalty**: Vary λ by factor of 0.5 and 2. Selected set should not change dramatically.
- [ ] **Compare PDS to OLS with all controls**: If PDS estimate differs substantially from OLS with full X, either the high-dimensional OLS is overfitting or there is important nonlinearity.
- [ ] **Sparsity assumption**: PDS-LASSO requires that few controls truly matter. If you expect dense effects (all controls matter a little), DML with ridge/elastic net is more appropriate.
- [ ] **Post-selection F-stat on treatment**: After union selection, report the partial F-statistic on D in the first-stage regression — confirms that the selected controls do not absorb all variation in D.

### Common PDS-LASSO Pitfalls

| Pitfall | Problem | Fix |
|---------|---------|-----|
| Using LassoCV without union step | Biased inference (post-selection problem) | Always use the union of Y-LASSO and D-LASSO selected sets |
| One-step LASSO (LASSO of Y on D and X jointly) | Treatment coefficient is regularized toward zero | Use PDS or DML — never regularize the causal parameter |
| Ignoring penalty choice | CV lambda is optimized for prediction, not inference | Use theory-based lambda (hdm package) for inference |
| p >> n without sparsity | LASSO may select noise variables | Validate selection stability; consider ridge DML instead |

---

## Heterogeneous Treatment Effects: Inference and Reporting

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
from econml.dml import CausalForestDML
blp = cf.const_marginal_effect_inference(X).summary_frame()
print(blp)  # coefficient on each X variable in BLP of CATE
```

```r
# R: grf
blp <- best_linear_projection(cf, A = X_matrix)
print(blp)
# Coefficients tell you: which observed characteristics predict larger/smaller CATE
```

### Visualization of CATE Distribution

```python
import matplotlib.pyplot as plt
import numpy as np

tau_hat = cf.effect(X)

fig, axes = plt.subplots(1, 2, figsize=(12, 4))

# CATE histogram
axes[0].hist(tau_hat, bins=50, edgecolor='k', alpha=0.7)
axes[0].axvline(tau_hat.mean(), color='red', linestyle='--',
                label=f'ATE = {tau_hat.mean():.3f}')
axes[0].set_xlabel('Estimated CATE')
axes[0].set_ylabel('Count')
axes[0].set_title('Distribution of Estimated CATE')
axes[0].legend()

# CATE vs. key covariate (e.g., age)
covariate_idx = 0  # first covariate
axes[1].scatter(X[:, covariate_idx], tau_hat, alpha=0.3, s=10)
axes[1].set_xlabel('X[:, 0]')
axes[1].set_ylabel('Estimated CATE')
axes[1].set_title('CATE vs. Covariate')

plt.tight_layout()
plt.savefig('cate_heterogeneity.pdf', bbox_inches='tight')
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

---

## Sample Splitting and Cross-Fitting

### Why Naive ML-in-Regression Fails

Consider fitting Y ~ θD + g(X) with LASSO. The LASSO regularizer penalizes θ just as it penalizes the coefficients on X. Even with large n, θ̂ is biased toward zero by the regularization — this bias does not vanish.

More generally, if you use the same data to (a) learn the nuisance function g(X) and (b) estimate θ, the estimation error in (a) contaminates (b) at first order. The result is that √n-convergence of θ̂ breaks down.

**Solution:** Cross-fitting separates these two estimation tasks across data folds.

### K-Fold Cross-Fitting Step by Step

```
1. Partition {1, ..., n} into K folds I₁, ..., I_K of approximately equal size.

2. For k = 1, ..., K:
   a. Training set: I^c_k = {1,...,n} \ I_k  (all folds except fold k)
   b. Fit nuisance model ĝ_k on training set I^c_k
   c. Compute residuals Ŵ_i = Y_i - ĝ_k(X_i) for all i ∈ I_k

3. Each observation gets one residual Ŵ_i from the fold in which it was held out.

4. Same procedure for D: Ṽ_i = D_i - m̂_k(X_i) for i ∈ I_k

5. Pool all residuals: use (Ŵ₁, ..., Ŵ_n) and (Ṽ₁, ..., Ṽ_n) for final inference.

6. θ̂ = (Σ Ṽ_i Ŵ_i) / (Σ Ṽ_i²) — OLS of Ŵ on Ṽ (no intercept)
```

### Practical Choices for K

| K | When to use | Trade-off |
|---|-------------|-----------|
| K = 2 | Minimal (not recommended) | Low computation, but each training set is only n/2 |
| K = 5 | Default (recommended) | Good balance of bias and training set size |
| K = 10 | Large samples | Small held-out set; each nuisance model trained on 90% |
| K = n (LOOCV) | Do not use for DML | Computationally infeasible; no clear benefit |

**Tip:** With K=5, each nuisance model is trained on 80% of the data. This is large enough for random forests and LASSO to be well-fit on most empirically realistic samples (n > 1,000).

### Cross-Fitting from Scratch (Illustrative)

```python
import numpy as np
from sklearn.model_selection import KFold
from sklearn.ensemble import RandomForestRegressor
import statsmodels.api as sm

def dml_crossfit(Y, D, X, n_splits=5, seed=42):
    """
    Full DML cross-fitting with inference.
    Assumes partially linear model: Y = theta*D + g(X) + eps
    """
    n = len(Y)
    W_hat = np.zeros(n)  # Y - E[Y|X]
    V_hat = np.zeros(n)  # D - E[D|X]

    kf = KFold(n_splits=n_splits, shuffle=True, random_state=seed)

    r2_y_list, r2_d_list = [], []

    for fold_idx, (train_idx, test_idx) in enumerate(kf.split(X)):
        # Nuisance models
        rf_y = RandomForestRegressor(n_estimators=200, max_depth=5, random_state=seed)
        rf_d = RandomForestRegressor(n_estimators=200, max_depth=5, random_state=seed)

        rf_y.fit(X[train_idx], Y[train_idx])
        rf_d.fit(X[train_idx], D[train_idx])

        Y_pred = rf_y.predict(X[test_idx])
        D_pred = rf_d.predict(X[test_idx])

        W_hat[test_idx] = Y[test_idx] - Y_pred
        V_hat[test_idx] = D[test_idx] - D_pred

        # Nuisance fit diagnostics
        ss_res_y = np.sum((Y[test_idx] - Y_pred) ** 2)
        ss_tot_y = np.sum((Y[test_idx] - Y[test_idx].mean()) ** 2)
        r2_y_list.append(1 - ss_res_y / ss_tot_y)

        ss_res_d = np.sum((D[test_idx] - D_pred) ** 2)
        ss_tot_d = np.sum((D[test_idx] - D[test_idx].mean()) ** 2)
        r2_d_list.append(1 - ss_res_d / ss_tot_d)

    print(f"Mean R2 (Y nuisance): {np.mean(r2_y_list):.3f}")
    print(f"Mean R2 (D nuisance): {np.mean(r2_d_list):.3f}")

    # DML estimate
    theta_hat = np.dot(V_hat, W_hat) / np.dot(V_hat, V_hat)

    # Influence function SE
    psi = V_hat * (W_hat - theta_hat * V_hat)
    J = np.mean(V_hat ** 2)
    var = np.mean(psi ** 2) / J ** 2
    se = np.sqrt(var / n)

    ci_lo = theta_hat - 1.96 * se
    ci_hi = theta_hat + 1.96 * se

    print(f"\nDML Estimate: {theta_hat:.4f}")
    print(f"SE:           {se:.4f}")
    print(f"95% CI:       [{ci_lo:.4f}, {ci_hi:.4f}]")

    return theta_hat, se

# Usage
theta, se = dml_crossfit(Y=y, D=d, X=X_controls)
```

### Aggregating Estimates Across Folds

When implementing DML with repeated cross-fitting (recommended for stability), run the full K-fold procedure M times with different random seeds and aggregate:

```python
def dml_repeated(Y, D, X, n_splits=5, n_reps=5):
    """DML with repeated cross-fitting for stability."""
    estimates = []
    for rep in range(n_reps):
        theta_r, _ = dml_crossfit(Y, D, X, n_splits=n_splits, seed=rep * 42)
        estimates.append(theta_r)

    # Median aggregation (more robust than mean)
    theta_final = np.median(estimates)
    print(f"Median across {n_reps} repetitions: {theta_final:.4f}")
    print(f"Std across repetitions: {np.std(estimates):.4f}")
    return theta_final
```

A large standard deviation across repetitions signals that the ML models are unstable — either the sample is too small or the models are too complex.

---

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
