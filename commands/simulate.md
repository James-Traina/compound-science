---
name: simulate
description: "Design and run Monte Carlo simulation study with DGP specification, seed management, and coverage analysis"
argument-hint: "<simulation objective, estimator comparison, or DGP description>"
---

# Monte Carlo Simulation Pipeline

**Pipeline mode:** This command operates fully autonomously. All decisions are made automatically.

Design and execute a Monte Carlo simulation study from DGP specification through formatted results tables. Handles the full simulation lifecycle: formalize the DGP, set parameters and seeds, run replications, compute bias/RMSE/coverage, and document findings.

## Input Document

<input_document> #$ARGUMENTS </input_document>

**If no input:** Search for existing simulation code (files with replication loops, DGP functions, or bias/RMSE computation). If found, use the most recently modified simulation file. If nothing found, state "No simulation specification found. Provide a simulation objective (e.g., 'compare IV vs OLS under heterogeneous treatment effects')." and stop.

## Execution Workflow

### Phase 1: DGP Specification

Define or load the data generating process. The DGP must be completely specified before any simulation runs.

1. **Dispatch `dgp-architect` agent** (via Task tool) to formalize the DGP:
   - Translate verbal description into a precise mathematical specification
   - Specify all distributional assumptions
   - Verify the DGP produces data consistent with the features being studied
   - Check that the DGP has sufficient variation for identification

2. **Document DGP in structured format:**

   | Component | Specification |
   |-----------|--------------|
   | **Outcome equation** | Y = f(X, D, U; θ) — full functional form |
   | **Treatment/endogenous variable** | D = g(Z, X, V; γ) — assignment mechanism |
   | **Instruments** (if applicable) | Z ~ distribution, exclusion restriction |
   | **Covariates** | X ~ distribution (joint distribution if correlated) |
   | **Error structure** | (U, V) ~ distribution, correlation structure |
   | **True parameter values** | θ₀ = [values] — the quantities to be recovered |
   | **Sample sizes** | N = [grid or single value] |

3. **DGP validation checks:**
   - Verify DGP parameters produce realistic data (no extreme values, reasonable variance)
   - Confirm identification holds in the DGP (true parameter is actually recoverable)
   - Check DGP matches the empirical features the simulation is studying (e.g., endogeneity, heterogeneity, selection)
   - Run DGP once with N=10,000 and check: do population moments match theoretical values?

4. **If comparing estimators:** Define each estimator precisely:

   | Estimator | Implementation | Expected properties |
   |-----------|---------------|-------------------|
   | Name | Formula or package call | Consistent? Efficient? Rate? |

### Phase 2: Simulation Design

Set parameters for the Monte Carlo study. Dispatch `monte-carlo-designer` agent for design choices.

1. **Dispatch `monte-carlo-designer` agent** (via Task tool) with the DGP and research question:
   - Recommend number of replications
   - Suggest sample size grid
   - Identify which metrics matter most for this comparison
   - Flag any design issues (e.g., too few replications for coverage, need larger N for asymptotic results)

2. **Set simulation parameters:**

   | Parameter | Default | Override when... |
   |-----------|---------|-----------------|
   | **Replications (R)** | 1,000 | Use 5,000 for coverage analysis; 500 for computationally expensive estimators |
   | **Sample sizes (N)** | [100, 500, 1,000, 5,000] | Adjust to match empirical application sample sizes |
   | **Parameter grid** | Single true value | Vary when studying sensitivity (e.g., instrument strength, endogeneity level) |
   | **Significance level** | 0.05 | Also report 0.10 for power analysis |

3. **Seed management:**
   ```
   base_seed = <fixed integer, e.g., 20260226>
   For replication r = 1, ..., R:
       seed_r = base_seed + r
   ```
   - Every replication must use a deterministic seed
   - Document the base seed prominently
   - Seeds must be set BEFORE any random number generation in each replication
   - Use language-appropriate seeding: `np.random.seed()` / `set.seed()` / `Random.seed!()`

4. **Metrics to compute:**

   | Metric | Formula | Interpretation |
   |--------|---------|---------------|
   | **Bias** | E[θ̂] - θ₀ | Systematic over/under-estimation |
   | **RMSE** | √(E[(θ̂ - θ₀)²]) | Overall estimation accuracy |
   | **MAE** | E[|θ̂ - θ₀|] | Robust accuracy measure |
   | **Median bias** | median(θ̂) - θ₀ | Robust bias measure |
   | **Coverage (95%)** | Pr(θ₀ ∈ CI₉₅) | Should be ~0.95; <0.90 is a red flag |
   | **Coverage (90%)** | Pr(θ₀ ∈ CI₉₀) | Should be ~0.90 |
   | **Size** | Pr(reject H₀ | H₀ true) | Should equal nominal level |
   | **Power** | Pr(reject H₀ | H₁ true) | Higher is better; compare across estimators |

### Phase 3: Execution

Run the simulation with progress tracking and early stopping for obvious failures.

1. **Pre-flight check:**
   - Verify DGP code runs without error for a single replication
   - Verify each estimator runs without error on DGP-generated data
   - Confirm output dimensions match expectations
   - Time a single replication to estimate total runtime

2. **Early stopping check** — run first 100 replications:
   - If >10% produce NaN/Inf: stop and diagnose
   - If estimator variance is zero: stop and diagnose (likely a coding error)
   - If all estimates are identical: stop and diagnose (seed not changing?)
   - If no issues: continue to full R replications

3. **Execute full simulation:**
   ```
   results = empty array [R × num_estimators × num_metrics]

   for r in 1..R:
       set seed = base_seed + r
       data = generate_data(DGP, N)
       for each estimator:
           estimate, se, ci = run_estimator(data)
           store(r, estimator, estimate, se, ci)
       if r % (R/10) == 0:
           report progress: "Replication r/R complete"
   ```

4. **Parallel execution** (where supported):
   - Split replications across available cores
   - Ensure each core uses independent seed streams (base_seed + r is sufficient)
   - Collect and merge results

5. **Dispatch `numerical-auditor` agent** (via Task tool) on the simulation code:
   - Check for numerical stability issues
   - Verify seed management is correct
   - Flag any floating-point concerns in estimator implementations

### Phase 4: Analysis

Compute statistics and format results. Flag anomalies.

1. **Compute Monte Carlo statistics** for each estimator × sample size combination:

   ```
   For each (estimator, N):
       bias        = mean(estimates) - true_value
       rmse        = sqrt(mean((estimates - true_value)^2))
       mae         = mean(abs(estimates - true_value))
       median_bias = median(estimates) - true_value
       coverage_95 = mean(true_value >= ci_lower_95 & true_value <= ci_upper_95)
       coverage_90 = mean(true_value >= ci_lower_90 & true_value <= ci_upper_90)
       size        = mean(p_values < 0.05)  # under H0
       power       = mean(p_values < 0.05)  # under H1 (if applicable)
   ```

2. **Main results table:**

   ```
   ┌────────────┬──────┬────────┬────────┬────────┬──────────┬──────────┐
   │ Estimator  │  N   │  Bias  │  RMSE  │  MAE   │ Cov(95%) │ Cov(90%) │
   ├────────────┼──────┼────────┼────────┼────────┼──────────┼──────────┤
   │ OLS        │  100 │  0.312 │  0.458 │  0.341 │   0.824  │   0.743  │
   │ OLS        │  500 │  0.298 │  0.342 │  0.301 │   0.831  │   0.752  │
   │ OLS        │ 1000 │  0.295 │  0.318 │  0.296 │   0.839  │   0.758  │
   │ IV/2SLS    │  100 │  0.021 │  0.523 │  0.389 │   0.937  │   0.882  │
   │ IV/2SLS    │  500 │  0.008 │  0.231 │  0.178 │   0.948  │   0.897  │
   │ IV/2SLS    │ 1000 │  0.003 │  0.162 │  0.124 │   0.951  │   0.901  │
   └────────────┴──────┴────────┴────────┴────────┴──────────┴──────────┘
   R = 1000, base_seed = 20260226
   ```

3. **Anomaly detection:**

   | Anomaly | Threshold | Action |
   |---------|-----------|--------|
   | Coverage far from nominal | 95% CI covers <85% or >99% | Flag prominently; investigate SE computation |
   | Size distortion | Rejection rate >0.10 or <0.02 under H₀ | Flag; likely SE or critical value problem |
   | Non-decreasing RMSE | RMSE doesn't shrink with N | Flag; possible inconsistency or coding error |
   | Extreme outlier replications | Any estimate >10× median | Report count; consider trimmed statistics |
   | Non-normal distribution | Heavy tails, bimodality in estimates | Note; may affect CI interpretation |

4. **Estimator comparison summary:**
   - Rank estimators by RMSE at the largest sample size
   - Note bias-variance tradeoffs across estimators
   - Identify the sample size at which each estimator's coverage reaches nominal level
   - Highlight any estimator that dominates uniformly

### Phase 5: Documentation

Save complete results for reproducibility.

1. **Create output document** at `docs/simulations/YYYY-MM-DD-<topic>.md`:

   ```markdown
   # Monte Carlo: <topic>

   Date: YYYY-MM-DD
   Base seed: <seed>
   Replications: <R>

   ## DGP Specification
   <full DGP from Phase 1>

   ## Estimators
   <table from Phase 1>

   ## Design
   - Sample sizes: <N grid>
   - Replications: <R>
   - Seeds: base_seed + r for r = 1..R

   ## Results
   <main results table from Phase 4>

   ## Key Findings
   1. <finding about bias>
   2. <finding about coverage>
   3. <finding about relative performance>

   ## Anomalies
   <any flagged issues>

   ## Code
   <path to simulation code>
   ```

2. **Cross-reference** any related estimation work in `docs/estimates/`

3. **Save simulation code** if newly written (should already be committed if run during `/workflows:work`)

## Output Format

**Success Output:**

```
## Simulation Complete: <topic>

### Design
- DGP: <brief description>
- Estimators: <list>
- R = <replications>, N = <sample sizes>
- Base seed: <seed>

### Key Results
<main comparison table>

### Findings
1. <key finding>
2. <key finding>
3. <key finding>

### Anomalies
- [any flagged issues, or "None detected"]

### Agent Reviews
- dgp-architect: [DGP assessment]
- monte-carlo-designer: [design assessment]
- numerical-auditor: [stability assessment]

### Files
- Results: docs/simulations/YYYY-MM-DD-<topic>.md
- Code: <simulation code file(s)>
```

**Failure Output (early stopping):**

```
## Simulation Aborted: <topic>

### Issue
<description of early stopping trigger>

### Diagnostics
- Replications completed: <count> / <total>
- NaN rate: <percentage>
- [other relevant diagnostics]

### Suggested Fixes
1. <specific suggestion>
2. <alternative approach>
```

## Routes To

- `/estimate` — run the winning estimator on real data
- `/identify` — formalize the identification argument underlying the DGP
- `/workflows:compound` — capture simulation insights in knowledge base
- `/workflows:review` — review simulation code quality

## Common DGP Patterns

| Scenario | DGP features |
|----------|-------------|
| **Endogeneity** | Correlated errors (U, V), instrument Z excluded from outcome |
| **Heterogeneous effects** | Treatment effect varies with X: τ(X) = α + βX |
| **Weak instruments** | Low correlation between Z and D (first-stage R² < 0.05) |
| **Many instruments** | k instruments >> endogenous regressors; bias toward OLS |
| **Staggered DiD** | Multiple treatment cohorts, heterogeneous timing |
| **Selection** | Truncation or sample selection correlated with outcome |
| **Measurement error** | X observed with noise: X* = X + η |
| **Spatial dependence** | Errors correlated across units by distance |

## Key Packages Reference

| Language | Packages |
|----------|----------|
| Python | numpy, scipy, statsmodels, linearmodels, multiprocessing, joblib |
| R | parallel, foreach, doParallel, fixest, sandwich, boot |
| Julia | Distributed, Random, GLM.jl, DataFrames.jl |
