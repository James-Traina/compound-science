---
name: estimate
description: "Run structural estimation pipeline with convergence monitoring and robustness checks"
argument-hint: "<model description, estimation specification, or existing code file>"
---

# Structural Estimation Pipeline

**Pipeline mode:** This command operates fully autonomously. All decisions are made automatically.

Run a complete estimation pipeline from data validation through results tables. Handles MLE, GMM, 2SLS, BLP demand, NFXP, MPEC, and other structural estimators with built-in convergence monitoring, proper standard error computation, and automated robustness checks.

## Input Document

<input_document> #$ARGUMENTS </input_document>

**If no input:** Search the codebase for estimation code (files importing statsmodels, linearmodels, pyblp, scipy.optimize, fixest, lfe, AER, gmm, Optim.jl, NLsolve.jl). If found, use the most recently modified estimation file. If nothing found, state "No estimation specification found. Provide a model description or code file." and stop.

## Execution Workflow

### Phase 1: Data Validation

Verify that data inputs are clean and suitable for estimation before spending compute.

1. **Locate data files** referenced in the model specification or estimation code
2. **Profile key variables:**

   | Check | Action |
   |-------|--------|
   | **Existence** | Confirm all referenced variables exist in the dataset |
   | **Missing values** | Count and report missingness rates; flag variables with >5% missing |
   | **Outliers** | Check for extreme values (beyond 5 IQR); report but do not auto-trim |
   | **Panel structure** | If panel data: verify balanced/unbalanced, check for gaps in time dimension |
   | **Instrument relevance** | If IV estimation: quick first-stage regression to confirm instruments have power |
   | **Variable types** | Confirm numeric variables are numeric, categorical are properly coded |
   | **Sample size** | Report N, number of clusters (if clustered), time periods (if panel) |

3. **Data quality assessment:** If critical issues found (key variables all missing, zero variation in dependent variable), report the issue and stop. Otherwise, document any warnings and proceed.

4. **Construct working dataset:** Apply any obvious sample restrictions from the specification (e.g., drop missing observations, restrict to relevant subpopulation). Document all sample construction decisions.

### Phase 2: Identification Check

Before running estimation, verify the model is identified. Dispatch the `identification-critic` agent.

1. **State identification strategy** from the input specification:
   - What is the target parameter?
   - What variation identifies it?
   - What assumptions are needed?

2. **Run identification-critic agent** (via Task tool) with the identification strategy:
   - Check exclusion restrictions are plausible
   - Verify rank conditions (are instruments relevant?)
   - Assess whether functional form is doing the identification work
   - Flag point vs set identification concerns

3. **Identification diagnostics** (compute where applicable):

   | Test | When to run | Concern if fails |
   |------|-------------|-----------------|
   | First-stage F-statistic | IV/2SLS/GMM | Weak instruments (F < 10 is a red flag; use effective F with multiple endogenous regressors) |
   | Rank test (Kleibergen-Paap) | IV with multiple instruments | Under-identification |
   | Anderson-Rubin test | IV with weak instrument concern | Inference robust to weak instruments |
   | Hausman test | When comparing IV to OLS | Endogeneity of regressors |
   | Sargan/Hansen J-test | Overidentified GMM/IV | Invalid instruments |

4. **Decision:**
   - If identification check passes: proceed to estimation
   - If identification is questionable: document concerns prominently but proceed (the researcher may have reasons)
   - If identification clearly fails (F < 4, rank condition violated): report failure, suggest fixes, and stop

### Phase 3: Estimation with Convergence Monitoring

Run the estimation routine with active convergence monitoring. Do not "run and hope."

1. **Detect estimation method** from the specification or code:

   | Method | Key packages | Convergence concerns |
   |--------|-------------|---------------------|
   | OLS/WLS | statsmodels, fixest, lm | Rarely fails; check multicollinearity |
   | 2SLS/IV | linearmodels, ivreg, AER | Check first-stage; numerical issues with many instruments |
   | MLE | scipy.optimize, optim, Optim.jl | Local optima; flat likelihood; boundary issues |
   | GMM | statsmodels, gmm | Weighting matrix convergence; many moments = instability |
   | BLP | pyblp, BLPestimatoR | Contraction mapping convergence; starting values critical |
   | NFXP | Custom code | Inner loop convergence; outer loop convergence; interaction |
   | MPEC | scipy, JuMP | Constraint satisfaction; optimizer tolerance |
   | Nonlinear LS | scipy.optimize, nls, minpack | Starting values; gradient accuracy |

2. **Starting values strategy** (for nonlinear estimators):
   - Generate at least 3 random starting value vectors from a reasonable domain
   - Use 1 informed starting value (e.g., OLS estimates, prior literature values, simulated method of moments)
   - Run all starting value sets and compare convergence points
   - Flag if different starting values converge to different optima (multiple local optima)

3. **Convergence monitoring** — track during estimation:

   | Metric | Action |
   |--------|--------|
   | **Iteration count** | Flag if approaching limit (default: 1000 for most optimizers) |
   | **Gradient norm** | Should decrease; flag if cycling or stuck |
   | **Objective function** | Should decrease (minimization) / increase (maximization); flag if flat |
   | **Step size** | Flag if extremely small (line search failing) or extremely large (divergence) |
   | **Parameter values** | Flag if any hit boundary constraints or grow without bound |
   | **Inner loop** (nested estimation) | Verify inner solver converges before outer step |

4. **Non-convergence handling:**
   - If convergence fails with BFGS: try Newton-Raphson (if Hessian available) or Nelder-Mead (derivative-free)
   - If all optimizers fail: try simplified model (fewer parameters), rescale variables, or check for near-collinearity
   - Document all convergence attempts and their outcomes
   - If no method converges: report failure with diagnostics and stop

5. **Dispatch `numerical-auditor` agent** (via Task tool) on the estimation code to check:
   - Floating-point stability (log-likelihood not likelihood, stable matrix operations)
   - Condition number of key matrices
   - Gradient computation accuracy (analytic vs numerical gradients match?)

### Phase 4: Inference

Compute standard errors appropriate to the estimation setting.

1. **Select SE method:**

   | Data structure | Default SE method |
   |---------------|-------------------|
   | Cross-section, homoskedastic | Classical (but verify homoskedasticity) |
   | Cross-section, general | HC1 (robust / Eicker-Huber-White) |
   | Panel with entity clustering | Clustered at entity level |
   | Multi-way clustering | Two-way clustered (e.g., firm + time) |
   | Spatial data | Conley SEs or HAC |
   | Complex nonlinear model | Bootstrap (percentile or BCa, >=999 replications) |
   | GMM | GMM sandwich with optimal weighting matrix |

   **Auto-detect rule:** If panel structure detected in Phase 1, default to clustered SEs at the highest reasonable level. If cross-section, default to HC1. If nonlinear with no analytical SE formula, default to bootstrap.

2. **Compute standard errors** using the selected method

3. **Construct inference tables:**
   - Point estimates with SEs, t-statistics (or z-statistics), p-values
   - 95% confidence intervals (and 90% for marginally significant results)
   - Significance indicators: * p<0.10, ** p<0.05, *** p<0.01

4. **SE diagnostics:**
   - Check Hessian is positive definite (for MLE) — if not, SEs are unreliable
   - Compare robust vs classical SEs — large discrepancy suggests heteroskedasticity
   - For clustered SEs: report number of clusters (few clusters = unreliable inference; flag if <30)
   - For bootstrap: check bootstrap distribution for bimodality or extreme outliers

### Phase 5: Robustness Checks

Run automated robustness checks to assess sensitivity of results.

1. **Starting value sensitivity** (nonlinear estimators only):
   - Confirm all starting value vectors from Phase 3 converge to same optimum
   - If not: report the distinct optima and their objective function values
   - Flag which optimum is the global (lowest objective for minimization)

2. **Optimization algorithm sensitivity:**
   - Re-estimate with at least one alternative algorithm
   - Compare point estimates — should agree to at least 3 significant digits
   - If they disagree materially: investigate (flat objective? multiple optima?)

3. **Subsample stability:**
   - Run estimation on 3 random 80% subsamples
   - Compare coefficients — large variation suggests fragile identification or influential observations
   - Flag any coefficient that changes sign across subsamples

4. **Specification sensitivity** (where obvious alternatives exist):
   - Add/remove control variables that are commonly included
   - Try alternative functional forms (log vs level, polynomial vs linear)
   - Test alternative instrument sets (if IV)
   - Document choices and results

5. **Compile robustness summary:**

   | Check | Result | Concern? |
   |-------|--------|----------|
   | Starting values | [Same/Different optima] | [Yes/No] |
   | Algorithm sensitivity | [Estimates agree within X digits] | [Yes/No] |
   | Subsample stability | [Max coefficient variation: X%] | [Yes/No] |
   | Specification sensitivity | [Key result robust to N alternatives] | [Yes/No] |

### Phase 6: Results

Generate formatted output and dispatch `econometrician` agent for final review.

1. **Coefficient table:**

   ```
   ┌──────────────────┬──────────┬──────────┬──────────┬──────────┐
   │ Variable         │ Estimate │ Std Err  │ t-stat   │ p-value  │
   ├──────────────────┼──────────┼──────────┼──────────┼──────────┤
   │ price            │  -1.432  │  (0.287) │  -4.99   │  0.000***│
   │ income           │   0.891  │  (0.145) │   6.14   │  0.000***│
   │ ...              │          │          │          │          │
   └──────────────────┴──────────┴──────────┴──────────┴──────────┘
   N = ..., R² = ..., Method = ...
   Standard errors: [robust/clustered at .../bootstrap]
   ```

2. **Diagnostic table:**

   | Diagnostic | Value | Interpretation |
   |-----------|-------|----------------|
   | First-stage F | ... | [Strong/Weak instruments] |
   | J-test (p-value) | ... | [Instruments valid/suspect] |
   | Convergence | ... | [Converged in N iterations / gradient norm] |
   | Condition number | ... | [Well/Ill-conditioned] |
   | Sample size (N) | ... | |
   | Clusters | ... | |

3. **Robustness comparison table** (key coefficient across specifications):

   ```
   ┌─────────────────────┬──────────┬──────────┬──────────┐
   │ Specification       │ Baseline │ Alt SE   │ Add ctrl │
   ├─────────────────────┼──────────┼──────────┼──────────┤
   │ price coefficient   │ -1.432   │ -1.430   │ -1.389   │
   │                     │ (0.287)  │ (0.312)  │ (0.294)  │
   └─────────────────────┴──────────┴──────────┴──────────┘
   ```

4. **Dispatch `econometrician` agent** (via Task tool) for final review:
   - Review estimation code quality and correctness
   - Check identification strategy implementation
   - Verify standard error computation is appropriate
   - Flag any methodological concerns

5. **Save results** (if `docs/estimates/` directory exists or can be created):
   - Save to `docs/estimates/YYYY-MM-DD-<model-name>.md`
   - Include all tables, diagnostics, and robustness results
   - Cross-reference the estimation code file(s)

## Output Format

**Success Output:**

```
## Estimation Results: <model name>

### Key Findings
- <parameter>: <estimate> (<SE>), p = <value> [interpretation]
- ...

### Diagnostics
- Convergence: [status]
- Identification: [first-stage F / rank test results]
- SE method: [robust / clustered at X / bootstrap]

### Robustness
- [summary of robustness checks]
- [any concerns flagged]

### Agent Reviews
- econometrician: [key findings]
- numerical-auditor: [key findings]
- identification-critic: [key findings]

### Files
- Results: docs/estimates/YYYY-MM-DD-<model>.md
- Code: <estimation code file(s)>
```

**Failure Output (non-convergence):**

```
## Estimation Failed: <model name>

### Issue
<description of convergence failure or identification problem>

### Attempted
- Algorithm 1: [result]
- Algorithm 2: [result]
- Starting values tried: [count]

### Suggested Fixes
1. <specific suggestion based on diagnostics>
2. <alternative approach>
```

## Routes To

- `/workflows:review` — run full multi-agent review on the estimation
- `/workflows:compound` — capture estimation insights in knowledge base
- `/simulate` — run Monte Carlo to assess estimator properties
- `/identify` — formalize the identification argument

## Skills Used

- `structural-modeling` — methodology reference for BLP, NFXP, MPEC, dynamic discrete choice

## Key Packages Reference

| Language | Packages |
|----------|----------|
| Python | statsmodels, linearmodels, pyblp, scipy.optimize, numpy, pandas |
| R | fixest, lfe, AER, gmm, sandwich, boot, estimatr |
| Julia | Optim.jl, NLsolve.jl, ForwardDiff.jl, GLM.jl |
| Stata | reghdfe, ivreg2, gmm, ml |
