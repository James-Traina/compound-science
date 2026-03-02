---
name: diagnose
description: "Run diagnostic battery on estimation results: specification tests, instrument checks, residual analysis, model fit"
argument-hint: "<estimation output, regression results, or code file to diagnose>"
---

# Estimation Diagnostics Pipeline

**Pipeline mode:** This command operates fully autonomously. All decisions are made automatically.

Run a comprehensive diagnostic battery on estimation results. Detects the estimation method, selects appropriate specification tests, checks instruments (if applicable), analyzes residuals, evaluates model fit, and produces a structured diagnostic report with pass/flag/fail assessments.

## Input Document

<input_document> #$ARGUMENTS </input_document>

**If no input:** Search the codebase for estimation output — regression results, saved model objects, or estimation code (files importing statsmodels, linearmodels, fixest, lfe, AER, pyblp, scipy.optimize). If found, use the most recently modified estimation file. If nothing found, state "No estimation results found. Provide estimation output, a results object, or a code file to diagnose." and stop.

## Execution Workflow

### Phase 1: Detect Estimation Type

Classify the estimation method to determine which diagnostics are appropriate. Different methods require fundamentally different diagnostic batteries.

1. **Read estimation code and results:**
   - Identify the estimator used (package calls, function signatures, model objects)
   - Extract point estimates, standard errors, sample size, and any stored diagnostics
   - Identify the dependent variable, regressors, instruments, and fixed effects

2. **Classify the estimation method:**

   | Method class | Detection signals | Diagnostic battery |
   |-------------|-------------------|-------------------|
   | **OLS / WLS** | `lm`, `ols`, `OLS`, `fixest::feols` without IV | Full specification + residual battery |
   | **IV / 2SLS** | `ivreg`, `iv2sls`, `feols` with `\|`, `AER::ivreg` | Instrument diagnostics + specification tests |
   | **GMM** | `gmm`, `GMMResults`, moment conditions | Overid tests + weighting matrix diagnostics |
   | **MLE** | `MLE`, `logit`, `probit`, `tobit`, `mle2`, `optim` with likelihood | Information criteria + LR tests + separation checks |
   | **Structural** | `pyblp`, `NFXP`, `MPEC`, custom optimization | Convergence diagnostics + numerical stability |
   | **Panel FE/RE** | `plm`, `PanelOLS`, `feols` with `\|` FE | Hausman FE vs RE + within/between variation |

3. **Extract model metadata:**

   | Field | Source |
   |-------|--------|
   | **N (observations)** | Model summary or data dimensions |
   | **K (parameters)** | Number of estimated coefficients |
   | **Clusters** | Clustering variable and number of clusters |
   | **Fixed effects** | FE dimensions and counts |
   | **Instruments** | Instrument list and count (if IV/GMM) |
   | **Endogenous variables** | Variables treated as endogenous (if IV/GMM) |
   | **Dependent variable** | Y variable name, type (continuous/binary/count) |

4. **Build diagnostic plan** based on method class — select which phases apply:

   | Phase | OLS | IV/2SLS | GMM | MLE | Structural | Panel |
   |-------|-----|---------|-----|-----|-----------|-------|
   | Specification tests | Yes | Yes | Partial | Partial | No | Yes |
   | Instrument diagnostics | No | Yes | Yes | No | Partial | If IV |
   | Residual diagnostics | Yes | Yes | No | Limited | No | Yes |
   | Model fit | Yes | Yes | Yes | Yes | Yes | Yes |

### Phase 2: Specification Tests

Run method-appropriate specification tests. Skip tests that do not apply to the detected method.

1. **Hausman test** (when applicable):

   | Context | Comparison | Interpretation |
   |---------|-----------|----------------|
   | IV vs OLS | Compare 2SLS to OLS | Reject => endogeneity present, IV needed |
   | FE vs RE | Compare fixed to random effects | Reject => RE inconsistent, use FE |
   | Parametric vs semiparametric | Compare restricted to flexible | Reject => functional form matters |

   - Report test statistic, degrees of freedom, and p-value
   - Flag if p < 0.05 (conventional) or p < 0.10 (marginal)

2. **RESET test** (Ramsey, 1969):
   - Test for functional form misspecification by including powers of fitted values (ŷ², ŷ³)
   - Applicable to: OLS, IV, panel models
   - Report F-statistic and p-value
   - Flag if p < 0.05: suggests omitted nonlinearities or interactions

3. **Omitted variable test** (ovtest / link test):
   - Regress residuals or outcome on predicted values and their square
   - If the squared term is significant: model may be missing relevant variables or functional form
   - For binary outcome models: use Pregibon's link test (regress Y on ŷ and ŷ²; ŷ² should be insignificant)

4. **Multicollinearity check:**

   | Metric | Threshold | Interpretation |
   |--------|-----------|---------------|
   | **VIF** (each regressor) | VIF > 10 | Severe multicollinearity |
   | **Condition number** | κ > 30 | Near-collinearity in design matrix |
   | **Pairwise correlations** | \|r\| > 0.9 | Highly correlated regressors |

   - Report VIF for each regressor
   - Flag any regressor with VIF > 10

5. **Structural break / stability** (if time dimension exists):
   - Chow test for structural break at candidate dates
   - CUSUM test for parameter stability over time
   - Flag if evidence of instability

6. **Compile specification test results:**

   | Test | Statistic | p-value | Assessment |
   |------|-----------|---------|------------|
   | Hausman (IV vs OLS) | χ² = ... | ... | Pass / Flag / Fail |
   | RESET | F = ... | ... | Pass / Flag / Fail |
   | Link test | t = ... | ... | Pass / Flag / Fail |
   | VIF (max) | ... | — | Pass / Flag / Fail |
   | Condition number | κ = ... | — | Pass / Flag / Fail |

### Phase 3: Instrument Diagnostics

**Skip this phase if the estimation does not use instruments.** Run the full instrument diagnostic battery for IV, 2SLS, and GMM models.

1. **First-stage diagnostics:**

   | Test | Statistic | Threshold | Interpretation |
   |------|-----------|-----------|---------------|
   | **First-stage F** | F-statistic | F > 10 (rule of thumb) | Instrument relevance |
   | **Effective F** (Olea & Pflueger) | Eff-F | > 23.1 (10% worst-case bias) | Robust to heteroskedasticity |
   | **Partial R²** | R² from first stage | Context-dependent | Instrument explanatory power |
   | **Shea's partial R²** | Adjusted for multiple endogenous | Higher is better | Independent instrument variation |

   - For each endogenous variable: report the first-stage regression with instrument coefficients
   - Flag if F < 10 (weak instruments) — suggest weak-instrument robust inference (Anderson-Rubin, conditional likelihood ratio)
   - Flag if F < 4 (very weak instruments) — results likely severely biased

2. **Weak instrument robust inference** (if F < 10):
   - Compute Anderson-Rubin confidence set (valid regardless of instrument strength)
   - Compute conditional likelihood ratio test (Moreira, 2003)
   - Compare AR confidence set to Wald confidence interval — divergence confirms weak instrument problem
   - Report Stock-Yogo critical values for the relevant number of instruments and endogenous regressors

3. **Under-identification test:**

   | Test | When to use | Null hypothesis |
   |------|-------------|----------------|
   | **Kleibergen-Paap rk LM** | Heteroskedastic errors | Equation is under-identified |
   | **Anderson canonical correlations** | Homoskedastic errors | Equation is under-identified |

   - Report test statistic and p-value
   - Flag if fail to reject: instruments do not provide enough independent variation

4. **Over-identification test** (if number of instruments > number of endogenous variables):

   | Test | When to use | Null hypothesis |
   |------|-------------|----------------|
   | **Sargan test** | Homoskedastic errors | All instruments are valid |
   | **Hansen J-test** | Heteroskedastic / clustered errors | All instruments are valid |

   - Report test statistic, degrees of freedom, and p-value
   - Flag if p < 0.05: at least one instrument may violate the exclusion restriction
   - Caution: low power with few overidentifying restrictions; do not over-interpret failure to reject

5. **Instrument-specific checks:**
   - For each instrument: report individual first-stage coefficient, t-statistic, and F contribution
   - Identify and flag any individually weak instruments
   - If many instruments: warn about bias toward OLS (many instruments bias)

6. **Compile instrument diagnostic results:**

   | Test | Statistic | p-value | Assessment |
   |------|-----------|---------|------------|
   | First-stage F | F = ... | — | Pass / Flag / Fail |
   | Effective F | Eff-F = ... | — | Pass / Flag / Fail |
   | Kleibergen-Paap LM | LM = ... | ... | Pass / Flag / Fail |
   | Hansen J | J = ... | ... | Pass / Flag / Fail |
   | Anderson-Rubin | AR = ... | ... | [weak-robust inference] |

### Phase 4: Residual Diagnostics

Analyze residuals to detect violations of maintained assumptions. Compute residuals from the estimated model and run the following battery.

1. **Normality tests:**

   | Test | Statistic | Use when |
   |------|-----------|----------|
   | **Jarque-Bera** | JB = N/6(S² + K²/4) | Large samples (N > 100) |
   | **Shapiro-Wilk** | W statistic | Small to moderate samples (N < 5000) |
   | **D'Agostino-Pearson** | K² statistic | General purpose |

   - Report skewness and kurtosis of residuals
   - Flag if normality rejected — note this affects exact inference (t-tests, F-tests) but not consistency
   - If MLE with distributional assumption: normality rejection is more consequential

2. **Heteroskedasticity tests:**

   | Test | Null hypothesis | Best for |
   |------|----------------|----------|
   | **White's test** | Homoskedasticity | General heteroskedasticity detection |
   | **Breusch-Pagan** | Var(u) = σ² (constant) | Linear heteroskedasticity (Var ∝ Xβ) |
   | **Goldfeld-Quandt** | Equal variance in subsamples | Monotone heteroskedasticity in one variable |

   - Run White's test as the default general test
   - Run Breusch-Pagan for more power against specific alternatives
   - If heteroskedasticity detected and classical SEs used: flag as critical — recommend robust SEs
   - If robust SEs already used: note the heteroskedasticity but no action needed

3. **Serial correlation tests** (if time series or panel data):

   | Test | Null hypothesis | Data type |
   |------|----------------|-----------|
   | **Durbin-Watson** | No first-order autocorrelation | Time series |
   | **Breusch-Godfrey** | No autocorrelation up to lag p | Time series / panel |
   | **Wooldridge test** | No first-order autocorrelation | Panel data |

   - Report test statistic and p-value
   - Flag if autocorrelation detected and SEs do not account for it
   - Suggest HAC (Newey-West) or clustered SEs if serial correlation present

4. **Spatial correlation** (if cross-sectional with geographic identifiers):
   - Moran's I test for spatial autocorrelation in residuals
   - If spatial correlation detected: suggest Conley (1999) standard errors
   - Flag if neither clustered nor Conley SEs used

5. **Influential observations:**

   | Metric | Threshold | Action |
   |--------|-----------|--------|
   | **Cook's distance** | D > 4/N | Flag influential points |
   | **DFBETAS** | \|DFBETAS\| > 2/√N | Flag observations that shift specific coefficients |
   | **Leverage** | h > 2K/N | Flag high-leverage points |
   | **Studentized residuals** | \|r*\| > 3 | Flag potential outliers |

   - Report the number of influential observations by each criterion
   - List the top 5 most influential observations with their diagnostics
   - Do NOT recommend automatic removal — flag for researcher review

6. **Residual summary:**

   | Diagnostic | Value | Assessment |
   |-----------|-------|------------|
   | Skewness | ... | Normal: ~0 |
   | Kurtosis | ... | Normal: ~3 |
   | Jarque-Bera (p) | ... | Pass / Flag |
   | White test (p) | ... | Pass / Flag |
   | Breusch-Pagan (p) | ... | Pass / Flag |
   | Durbin-Watson | ... | Pass / Flag / N/A |
   | Breusch-Godfrey (p) | ... | Pass / Flag / N/A |
   | Influential obs (Cook's) | ... count | Pass / Flag |

### Phase 5: Model Fit

Evaluate overall model performance using metrics appropriate to the estimation method.

1. **Standard goodness-of-fit measures:**

   | Metric | Formula | Applicable to |
   |--------|---------|--------------|
   | **R²** | 1 - SS_res/SS_tot | OLS, IV, panel |
   | **Adjusted R²** | 1 - (1-R²)(N-1)/(N-K-1) | OLS, IV, panel |
   | **Within R²** | R² from demeaned regression | Panel FE |
   | **Pseudo R²** | 1 - LL/LL₀ (McFadden) | MLE (logit, probit) |
   | **Log-likelihood** | Σ log f(yᵢ|xᵢ; θ̂) | MLE |

2. **Information criteria** (for model comparison):

   | Criterion | Formula | Select model with... |
   |-----------|---------|---------------------|
   | **AIC** | -2LL + 2K | Lowest AIC |
   | **BIC** | -2LL + K·ln(N) | Lowest BIC (penalizes complexity more) |
   | **HQIC** | -2LL + 2K·ln(ln(N)) | Lowest HQIC (between AIC and BIC) |

   - Report all three criteria
   - If comparing specifications: rank by each criterion and note agreement/disagreement

3. **Predictive performance:**

   | Metric | Method | Interpretation |
   |--------|--------|---------------|
   | **In-sample RMSE** | √(Σ(yᵢ - ŷᵢ)²/N) | Prediction accuracy (lower is better) |
   | **MAE** | Σ\|yᵢ - ŷᵢ\|/N | Robust prediction accuracy |
   | **MAPE** | Σ\|yᵢ - ŷᵢ\|/\|yᵢ\|/N | Percentage prediction error |
   | **Cross-validation RMSE** | K-fold CV (K=5 or 10) | Out-of-sample accuracy |

   - Compute in-sample metrics always
   - Compute cross-validation if N > 200 and computation is feasible
   - Flag large gap between in-sample and CV performance (overfitting)

4. **Classification metrics** (for binary outcome models):

   | Metric | Interpretation |
   |--------|---------------|
   | **Percent correctly predicted** | Accuracy at 0.5 cutoff |
   | **AUC-ROC** | Discrimination ability (0.5 = random, 1.0 = perfect) |
   | **Hosmer-Lemeshow** | Calibration (predicted probabilities match observed rates) |
   | **Confusion matrix** | Sensitivity, specificity, precision, recall |

5. **Convergence diagnostics** (for iterative estimators):

   | Metric | Good | Bad |
   |--------|------|-----|
   | **Final gradient norm** | < 1e-6 | > 1e-3 |
   | **Iterations** | Well below limit | At or near iteration limit |
   | **Hessian condition number** | κ < 1e6 | κ > 1e10 |
   | **Hessian positive definite** | Yes | No (SEs unreliable) |
   | **Objective function** | Decreasing monotonically | Cycling or flat |

6. **Model fit summary:**

   | Metric | Value | Assessment |
   |--------|-------|------------|
   | R² (or Pseudo R²) | ... | Context-dependent |
   | AIC | ... | — (compare across models) |
   | BIC | ... | — (compare across models) |
   | In-sample RMSE | ... | — |
   | CV RMSE | ... | — |
   | Convergence | ... | Pass / Flag / Fail |

### Phase 6: Diagnostic Report

Compile all results into a structured report and dispatch agents for expert review.

1. **Dispatch `econometric-reviewer` agent** (via Task tool) with the full diagnostic results:
   - Review whether the right tests were applied
   - Assess the severity of any flagged issues
   - Recommend corrective actions for failures
   - Evaluate whether the estimation results are trustworthy given the diagnostics

2. **Dispatch `numerical-auditor` agent** (via Task tool) if convergence or numerical issues were detected:
   - Review condition numbers and numerical stability
   - Check for floating-point issues in the estimation code
   - Assess whether convergence diagnostics suggest reliable optimization

3. **Compile master diagnostic report:**

   ```
   ┌──────────────────────────────┬──────────┬────────────────────────────┐
   │ Diagnostic                   │ Result   │ Assessment                 │
   ├──────────────────────────────┼──────────┼────────────────────────────┤
   │ SPECIFICATION                │          │                            │
   │   Hausman test               │ p = ...  │ Pass / Flag / Fail         │
   │   RESET test                 │ p = ...  │ Pass / Flag / Fail         │
   │   Link test                  │ p = ...  │ Pass / Flag / Fail         │
   │   Max VIF                    │ ...      │ Pass / Flag / Fail         │
   ├──────────────────────────────┼──────────┼────────────────────────────┤
   │ INSTRUMENTS (if applicable)  │          │                            │
   │   First-stage F              │ F = ...  │ Pass / Flag / Fail         │
   │   Under-identification       │ p = ...  │ Pass / Flag / Fail         │
   │   Over-identification        │ p = ...  │ Pass / Flag / Fail         │
   ├──────────────────────────────┼──────────┼────────────────────────────┤
   │ RESIDUALS                    │          │                            │
   │   Normality                  │ p = ...  │ Pass / Flag / Fail         │
   │   Heteroskedasticity         │ p = ...  │ Pass / Flag / Fail         │
   │   Serial correlation         │ p = ...  │ Pass / Flag / Fail / N/A   │
   │   Influential observations   │ count    │ Pass / Flag                │
   ├──────────────────────────────┼──────────┼────────────────────────────┤
   │ MODEL FIT                    │          │                            │
   │   R² (or Pseudo R²)         │ ...      │ Context-dependent          │
   │   Information criteria       │ AIC/BIC  │ Compare across models      │
   │   Convergence                │ status   │ Pass / Flag / Fail         │
   └──────────────────────────────┴──────────┴────────────────────────────┘
   ```

4. **Overall assessment:**

   | Rating | Criteria |
   |--------|---------|
   | **PASS** | No failures, at most minor flags | Estimation results are reliable |
   | **FLAG** | One or more non-critical flags | Results usable with caveats noted |
   | **FAIL** | One or more critical failures | Results should not be reported without addressing issues |

   Classification of critical failures:
   - Weak instruments (F < 4) with no robust inference
   - Heteroskedasticity detected with classical SEs reported
   - Non-convergence or non-positive-definite Hessian
   - VIF > 100 (near-perfect collinearity)

5. **Actionable recommendations:**
   - For each flag or failure: provide a specific corrective action
   - Prioritize recommendations by impact on results reliability
   - Reference specific commands for follow-up: `/estimate` to re-run with corrections, `/stress-test` for robustness

6. **Save diagnostic report** (if `docs/diagnostics/` directory exists or can be created):
   - Save to `docs/diagnostics/YYYY-MM-DD-<model-name>-diagnostics.md`
   - Include all test results, agent reviews, and recommendations
   - Cross-reference the estimation code and results files

## Output Format

**Success Output:**

```
## Diagnostic Report: <model name>

### Estimation Summary
- Method: <OLS / IV / GMM / MLE / Structural>
- N = ..., K = ..., Clusters = ...
- Dependent variable: <name>

### Overall Assessment: [PASS / FLAG / FAIL]

### Specification Tests
| Test | Result | Assessment |
|------|--------|------------|
| ... | ... | ... |

### Instrument Diagnostics (if applicable)
| Test | Result | Assessment |
|------|--------|------------|
| ... | ... | ... |

### Residual Diagnostics
| Test | Result | Assessment |
|------|--------|------------|
| ... | ... | ... |

### Model Fit
| Metric | Value |
|--------|-------|
| ... | ... |

### Recommendations
1. [Critical] <action for any failures>
2. [Advisory] <action for any flags>

### Agent Reviews
- econometric-reviewer: [key findings]
- numerical-auditor: [key findings, if dispatched]

### Files
- Report: docs/diagnostics/YYYY-MM-DD-<model>-diagnostics.md
- Estimation code: <source file(s)>
```

**Failure Output (cannot diagnose):**

```
## Diagnostic Failed: <model name>

### Issue
<description of why diagnostics could not be completed>

### Attempted
- <what was tried>
- <why it failed>

### Suggested Fixes
1. <specific action to make diagnostics possible>
2. <alternative approach>
```

## Routes To

- `/estimate` — re-run estimation with corrections from diagnostic findings
- `/stress-test` — run sensitivity analysis on flagged results
- `/workflows:review` — full multi-agent review incorporating diagnostics
- `/workflows:compound` — capture diagnostic patterns in knowledge base

## Assessment Thresholds Reference

| Test | Pass | Flag | Fail |
|------|------|------|------|
| First-stage F | F > 10 | 4 < F < 10 | F < 4 |
| Overid (J-test) | p > 0.10 | 0.05 < p < 0.10 | p < 0.05 |
| White test | p > 0.05 | — | p < 0.05 (with classical SEs) |
| VIF | VIF < 10 | 10 < VIF < 100 | VIF > 100 |
| Condition number | κ < 30 | 30 < κ < 1000 | κ > 1000 |
| DW statistic | 1.5 < DW < 2.5 | 1.0 < DW < 1.5 or 2.5 < DW < 3.0 | DW < 1.0 or DW > 3.0 |
| Cook's distance | All D < 4/N | Some D > 4/N | Many D > 4/N or any D > 1 |

## Key Packages Reference

| Language | Packages |
|----------|----------|
| Python | statsmodels.stats.diagnostic, linearmodels.iv.diagnostics, scipy.stats, sklearn.metrics |
| R | lmtest, sandwich, car (vif), spdep (Moran), AER, fixest, plm |
| Julia | GLM.jl, HypothesisTests.jl, StatsBase.jl |
| Stata | estat, ovtest, linktest, vif, ivreg2, xttest |
