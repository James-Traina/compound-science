---
name: sensitivity
description: "Run sensitivity analysis on causal estimates: Oster bounds, exclusion restriction tests, breakdown frontier, specification curve"
argument-hint: "<estimation results, baseline specification, or causal claim to stress-test>"
---

# Sensitivity Analysis Pipeline

**Pipeline mode:** This command operates fully autonomously. All decisions are made automatically.

Run a comprehensive sensitivity analysis on causal estimates. Identifies the baseline specification, computes Oster (2019) bounds for omitted variable bias, tests sensitivity to exclusion restriction violations (Conley et al., 2012), calculates the breakdown frontier (Masten & Poirier, 2021), enumerates reasonable specifications for a specification curve analysis (Simonsohn et al., 2020), and produces a structured robustness assessment.

## Input Document

<input_document> #$ARGUMENTS </input_document>

**If no input:** Search the codebase for estimation code with causal interpretation — IV regressions, DiD specifications, treatment effect estimators, or structural models. If found, use the most recently modified causal estimation file. If nothing found, state "No causal estimation found. Provide estimation results, a code file with a causal specification, or describe the causal claim to analyze." and stop.

## Execution Workflow

### Phase 1: Detect Baseline Estimate

Read the estimation code and identify the baseline causal specification to test.

1. **Locate the baseline specification:**
   - Find the primary estimation command in the code (the "main result")
   - If multiple specifications exist: identify the one reported as the baseline (typically the first or the one with all preferred controls)
   - If ambiguous: choose the most fully controlled specification

2. **Extract baseline components:**

   | Component | What to extract |
   |-----------|----------------|
   | **Target parameter** | The causal parameter of interest (e.g., treatment effect, elasticity) |
   | **Point estimate** | β̂ from the baseline specification |
   | **Standard error** | SE(β̂) and the SE method used |
   | **Confidence interval** | 95% CI from baseline |
   | **Identification strategy** | IV / DiD / RDD / selection-on-observables / structural |
   | **Controls included** | List of control variables in the baseline |
   | **Controls available** | Additional controls that could be included |
   | **Sample** | Full sample vs restricted; sample size |
   | **Fixed effects** | FE dimensions included |
   | **Clustering** | Clustering level for inference |

3. **Classify the identification strategy:**

   | Strategy | Sensitivity methods applicable |
   |----------|------------------------------|
   | **Selection on observables** | Oster bounds (primary), specification curve |
   | **IV / 2SLS** | Conley et al. bounds (primary), specification curve |
   | **DiD** | Oster bounds, specification curve, Rambachan-Roth |
   | **RDD** | Bandwidth sensitivity, polynomial order, donut hole |
   | **Structural** | Parameter sensitivity, model perturbation |

   - Select the appropriate sensitivity methods based on the identification strategy
   - Not all methods apply to all strategies — skip inapplicable methods

4. **Dispatch `identification-critic` agent** (via Task tool) with the baseline specification:
   - Identify the most likely sources of bias
   - Suggest the most informative sensitivity analyses for this setting
   - Assess which assumptions are most vulnerable to violation

### Phase 2: Oster Bounds

Assess sensitivity to omitted variable bias using the coefficient stability approach (Oster, 2019; building on Altonji, Elder & Taber, 2005).

**Applicable to:** Selection-on-observables designs, DiD, panel FE. **Skip if:** IV/2SLS with strong instruments (use Conley bounds instead).

1. **Compute the key statistics:**

   | Statistic | Definition | Source |
   |-----------|-----------|--------|
   | **β̃** (short regression) | Coefficient from regression without controls | Run uncontrolled regression |
   | **R̃²** | R² from uncontrolled regression | Same regression |
   | **β̂** (controlled regression) | Coefficient from baseline with controls | Baseline specification |
   | **R̂²** | R² from controlled regression | Baseline specification |
   | **R²_max** | Hypothetical R² if all omitted variables included | Set by researcher or use Oster's bound |

2. **Compute δ (coefficient of proportionality):**
   - δ measures the degree of selection on unobservables relative to observables needed to explain away the result
   - Formula: δ such that β*(δ, R²_max) = 0 (the δ that drives the causal effect to zero)
   - If δ > 1: unobservables would need to be more important than observables to nullify the result

3. **Compute bias-adjusted estimate β*:**

   | Parameter | Default | Rationale |
   |-----------|---------|----------|
   | **R²_max** | min(2.2 × R̂², 1) | Oster (2019) recommendation from calibration exercise |
   | **δ** | 1 | Proportional selection assumption |

   - β*(δ=1, R²_max=2.2R̂²): bias-adjusted estimate assuming proportional selection
   - Compute the identified set: [β̂, β*(1, R²_max)]
   - If zero is NOT in the identified set: result survives proportional selection

4. **Sensitivity table:**

   ```
   ┌─────────────────────┬──────────┬───────────────┬───────────────┐
   │                     │ β̃       │ β̂            │ β*(δ=1)       │
   │                     │ (no ctrl)│ (baseline)    │ (Oster)       │
   ├─────────────────────┼──────────┼───────────────┼───────────────┤
   │ Coefficient         │ ...      │ ...           │ ...           │
   │ SE                  │ (...)    │ (...)         │ —             │
   │ R²                  │ ...      │ ...           │ R²_max = ...  │
   ├─────────────────────┼──────────┼───────────────┼───────────────┤
   │ δ for β* = 0        │          │               │ ...           │
   │ Identified set      │          │ [..., ...]    │               │
   │ Contains zero?      │          │ Yes / No      │               │
   └─────────────────────┴──────────┴───────────────┴───────────────┘
   ```

5. **Interpretation guide:**

   | δ value | Interpretation |
   |---------|---------------|
   | δ > 2 | Very robust: unobservables would need to be twice as important as observables |
   | 1 < δ < 2 | Moderately robust: passes proportional selection benchmark |
   | 0 < δ < 1 | Fragile: less-than-proportional selection would nullify the result |
   | δ < 0 | Estimate strengthened by omitted variables (coefficient moves away from zero) |

### Phase 3: Conley et al. Bounds

Assess sensitivity to violations of the exclusion restriction (Conley, Hansen & Rossi, 2012).

**Applicable to:** IV/2SLS/GMM with instrumental variables. **Skip if:** No instruments used.

1. **Setup the relaxed exclusion restriction:**
   - Baseline IV model: Y = Xβ + Zγ + ε, where γ = 0 is the exclusion restriction
   - Relaxed model: allow γ ≠ 0, with γ in some plausible range

2. **Choose the approach:**

   | Approach | Description | When to use |
   |----------|------------|------------|
   | **Local-to-zero** | γ ~ N(0, σ²_γ) with σ²_γ specified by researcher | Researcher has prior about violation magnitude |
   | **Union of confidence intervals** | Compute CI(β) for each γ in a grid | No strong prior; want to map sensitivity |
   | **Support restriction** | γ ∈ [γ_L, γ_U] (bounded violation) | Researcher can bound the direct effect of Z on Y |

3. **Compute bounds for grid of violation magnitudes:**

   | γ (violation) | β̂(γ) | 95% CI | Contains zero? |
   |--------------|--------|--------|---------------|
   | 0 (baseline) | ... | [..., ...] | Yes / No |
   | 0.01 | ... | [..., ...] | Yes / No |
   | 0.05 | ... | [..., ...] | Yes / No |
   | 0.10 | ... | [..., ...] | Yes / No |
   | ... | ... | ... | ... |

4. **Find the breakdown point:**
   - The value of γ at which the confidence interval first includes zero
   - Express in interpretable units: "A direct effect of Z on Y of [γ*] would be needed to nullify the result"
   - Compare γ* to the reduced-form effect of Z on Y: if γ* is large relative to the reduced form, the result is robust

5. **Visualization:**
   - Plot β̂(γ) as a function of γ with confidence bands
   - Mark the baseline (γ = 0) and breakdown point (γ = γ*)
   - Shade the region where the result is significant

### Phase 4: Breakdown Frontier

Compute how much assumption violation is needed to overturn the causal conclusion (Masten & Poirier, 2021).

**Applicable to:** Any causal estimation. The breakdown frontier generalizes traditional sensitivity analysis by considering multiple assumptions simultaneously.

1. **Define the breakdown concept:**
   - The baseline result "breaks down" when the confidence interval includes zero (or the sign changes)
   - The frontier maps combinations of assumption violations that cause breakdown
   - Provides a multivariate generalization of single-parameter sensitivity

2. **Identify assumption dimensions to vary:**

   | Dimension | Baseline | Violation direction |
   |-----------|---------|-------------------|
   | **Omitted variable bias** | No omitted confounders | Degree of unobserved confounding (δ) |
   | **Exclusion restriction** | γ = 0 (instrument valid) | Direct effect γ ≠ 0 |
   | **Parallel trends** | Common trends hold | Differential pre-trends |
   | **Selection** | Selection on observables | Degree of selection on unobservables |
   | **Measurement error** | No measurement error | Degree of attenuation |

3. **Compute the frontier:**
   - For each pair of assumption dimensions: compute the combinations (δ₁, δ₂) such that the result just breaks down
   - This traces a curve in 2D assumption-violation space
   - Points inside the frontier: result survives. Points outside: result overturned.

4. **Frontier table:**

   ```
   ┌──────────────────┬──────────────────┬──────────────────────────┐
   │ Omitted variable │ Exclusion        │ Result                   │
   │ bias (δ)         │ violation (γ)    │                          │
   ├──────────────────┼──────────────────┼──────────────────────────┤
   │ 0                │ γ* = ...         │ Breakdown via exclusion  │
   │ δ* = ...         │ 0                │ Breakdown via OVB        │
   │ δ*/2             │ γ*/2             │ Joint breakdown          │
   │ ...              │ ...              │ ...                      │
   └──────────────────┴──────────────────┴──────────────────────────┘
   ```

5. **Interpretation:**
   - How far from the maintained assumptions do we need to go before the result breaks?
   - Compare breakdown values to plausible violation magnitudes from the economic context
   - A wide frontier (large violations needed) indicates a robust result

### Phase 5: Specification Curve

Enumerate all reasonable specifications and plot the distribution of estimates (Simonsohn, Simmons & Nelson, 2020).

1. **Define the specification space:**

   | Decision | Options to vary |
   |----------|----------------|
   | **Control variables** | Include/exclude each non-essential control |
   | **Functional form** | Linear, log, quadratic, spline |
   | **Sample restrictions** | Full sample, trim outliers, drop specific subgroups |
   | **Fixed effects** | None, entity FE, time FE, entity + time FE |
   | **SE method** | Robust, clustered (different levels), bootstrap |
   | **Estimation method** | OLS vs IV, different instrument sets |
   | **Outcome variable** | Alternative definitions or transformations |
   | **Treatment variable** | Alternative definitions or timing |

2. **Enumerate specifications:**
   - Not every combination: only specifications that a reasonable researcher might prefer
   - Exclude specifications that are clearly misspecified (e.g., OLS when endogeneity is established)
   - Total specifications should typically be 50-500 (manageable and informative)

3. **Run all specifications:**

   For each specification s = 1, ..., S:
   - Estimate the model with specification s
   - Store: β̂_s, SE_s, CI_s, p-value_s, N_s, specification choices

4. **Compute specification curve statistics:**

   | Statistic | Interpretation |
   |-----------|---------------|
   | **Median estimate** | Central tendency across specifications |
   | **IQR of estimates** | Dispersion of results |
   | **Share significant** | Fraction of specifications with p < 0.05 |
   | **Share same sign** | Fraction with same sign as baseline |
   | **Min / Max estimate** | Full range of results |
   | **Baseline rank** | Where the baseline falls in the sorted estimates |

5. **Generate specification curve plot:**

   ```
   Top panel:
   - X-axis: specifications sorted by estimate magnitude
   - Y-axis: point estimates with 95% CI
   - Horizontal reference line at zero
   - Highlight baseline specification
   - Shade estimates that are significant at 5%

   Bottom panel:
   - X-axis: same ordering as top panel
   - Y-axis: specification choices (rows)
   - Dots indicating which choices are active for each specification
   - Grouped by decision type (controls, FE, sample, etc.)
   ```

6. **Joint significance test:**
   - Under-the-null permutation test (Simonsohn et al.): is the pattern of results consistent with no effect?
   - Bootstrap the specification curve under the null (permute treatment assignment)
   - Compare observed curve statistics to null distribution

7. **Specification curve summary:**

   ```
   ┌─────────────────────────────┬──────────────────────────┐
   │ Statistic                   │ Value                    │
   ├─────────────────────────────┼──────────────────────────┤
   │ Total specifications        │ S = ...                  │
   │ Median estimate             │ ...                      │
   │ IQR                         │ [..., ...]               │
   │ Share significant (p<0.05)  │ ...% (N specs)           │
   │ Share same sign as baseline │ ...%                     │
   │ Range                       │ [..., ...]               │
   │ Baseline estimate           │ ... (rank: .../S)        │
   │ Joint null test (p-value)   │ ...                      │
   └─────────────────────────────┴──────────────────────────┘
   ```

### Phase 6: Sensitivity Report

Compile all results into a structured assessment and dispatch agents for review.

1. **Dispatch `identification-critic` agent** (via Task tool) with the complete sensitivity results:
   - Assess whether the sensitivity analyses are appropriate for the identification strategy
   - Evaluate the severity of any sensitivity concerns
   - Suggest additional analyses if important dimensions were missed
   - Overall judgment: is the causal claim robust?

2. **Dispatch `econometrician` agent** (via Task tool) with the sensitivity analysis code:
   - Review computation correctness (Oster formula, Conley bounds implementation)
   - Check specification curve is comprehensive but not adversarial
   - Verify statistical procedures (bootstrap, permutation tests)

3. **Compile master sensitivity report:**

   ```
   ┌──────────────────────────────┬──────────┬────────────────────────────┐
   │ Sensitivity Analysis         │ Result   │ Assessment                 │
   ├──────────────────────────────┼──────────┼────────────────────────────┤
   │ OSTER BOUNDS                 │          │                            │
   │   δ for β* = 0               │ ...      │ Robust / Fragile           │
   │   Identified set             │ [.., ..] │ Contains zero? Yes / No    │
   │   Bias-adjusted β*           │ ...      │ Same sign? Yes / No        │
   ├──────────────────────────────┼──────────┼────────────────────────────┤
   │ CONLEY BOUNDS (if IV)        │          │                            │
   │   Breakdown γ*               │ ...      │ Large / Small rel. to RF   │
   │   γ* / reduced form          │ ...%     │ Robust / Fragile           │
   ├──────────────────────────────┼──────────┼────────────────────────────┤
   │ BREAKDOWN FRONTIER           │          │                            │
   │   Max single violation       │ ...      │ Distance from assumptions  │
   │   Joint violation needed     │ ...      │ Robust / Fragile           │
   ├──────────────────────────────┼──────────┼────────────────────────────┤
   │ SPECIFICATION CURVE          │          │                            │
   │   Specifications tested      │ S = ...  │                            │
   │   Share significant          │ ...%     │ Robust / Fragile           │
   │   Share same sign            │ ...%     │ Robust / Fragile           │
   │   Median vs baseline         │ ...      │ Stable / Unstable          │
   └──────────────────────────────┴──────────┴────────────────────────────┘
   ```

4. **Overall robustness assessment:**

   | Rating | Criteria |
   |--------|---------|
   | **ROBUST** | Oster δ > 1, specification curve mostly significant, no breakdown at plausible violations |
   | **MODERATELY ROBUST** | Oster δ close to 1, most specifications agree on sign, breakdown requires substantial violations |
   | **FRAGILE** | Oster δ < 1, many specifications insignificant or sign-switching, breakdown at small violations |
   | **NOT ROBUST** | Result overturned in most sensitivity analyses |

5. **Actionable recommendations:**
   - For each fragile dimension: suggest how to strengthen the result
   - Suggest additional data or instruments that could improve robustness
   - Note which sensitivity results should be reported in the paper (and where: main text vs appendix)

6. **Save sensitivity report** (if `docs/sensitivity/` directory exists or can be created):
   - Save to `docs/sensitivity/YYYY-MM-DD-<model-name>-sensitivity.md`
   - Include all tables, specification curve data, and agent reviews
   - Cross-reference the estimation code and baseline results

## Output Format

**Success Output:**

```
## Sensitivity Analysis: <model name>

### Baseline Estimate
- Parameter: <target>
- Estimate: <β̂> (<SE>), p = <value>
- Identification: <strategy>

### Overall Assessment: [ROBUST / MODERATELY ROBUST / FRAGILE / NOT ROBUST]

### Oster Bounds
- δ for β* = 0: <value> [interpretation]
- Identified set: [<lower>, <upper>]
- Contains zero: Yes / No

### Conley Bounds (if IV)
- Breakdown γ*: <value> (<X>% of reduced form)
- [Plot of β̂(γ) with CI]

### Breakdown Frontier
- <summary of how far assumptions can be violated>

### Specification Curve
- Specifications: S = <count>
- Significant: <X>%, Same sign: <Y>%
- [Specification curve plot]

### Agent Reviews
- identification-critic: [key findings]
- econometrician: [key findings]

### Files
- Report: docs/sensitivity/YYYY-MM-DD-<model>-sensitivity.md
- Spec curve data: docs/sensitivity/YYYY-MM-DD-<model>-speccurve.csv
- Code: <sensitivity analysis code file(s)>
```

**Failure Output:**

```
## Sensitivity Analysis Incomplete

### Issue
<description of why the analysis could not be completed>

### Completed Analyses
- [which sensitivity methods were successfully run]

### Blocked Analyses
- <method>: <reason it could not be run>

### Suggested Fixes
1. <specific action to enable blocked analyses>
2. <alternative sensitivity approach>
```

## Routes To

- `/estimate` — re-run estimation with alternative specification
- `/diagnose` — run diagnostics on the baseline or alternative specifications
- `/visualize` — generate specification curve and sensitivity plots
- `/workflows:compound` — capture sensitivity patterns in knowledge base
- `/identify` — formalize the identification argument and its assumptions

## Sensitivity Methods Reference

| Method | Reference | Key idea | Software |
|--------|----------|----------|----------|
| **Oster bounds** | Oster (2019) | Coefficient stability + R² movements | `psacalc` (Stata), `sensemakr` (R) |
| **Conley et al.** | Conley, Hansen & Rossi (2012) | Sensitivity to exclusion restriction | `plausexog` (Stata), custom code |
| **Breakdown frontier** | Masten & Poirier (2021) | Multivariate assumption violation | Custom code |
| **Specification curve** | Simonsohn et al. (2020) | Enumerate all reasonable specifications | `specr` (R), `specification_curve` (Python) |
| **Rambachan-Roth** | Rambachan & Roth (2023) | Sensitivity to parallel trends violations | `HonestDiD` (R) |
| **sensemakr** | Cinelli & Hazlett (2020) | Omitted variable bias benchmarking | `sensemakr` (R, Stata) |
| **E-value** | VanderWeele & Ding (2017) | Minimum confounding strength to explain away | `EValue` (R) |

## Key Packages Reference

| Language | Packages |
|----------|----------|
| Python | statsmodels, linearmodels, specification_curve, custom (Oster, Conley) |
| R | sensemakr, HonestDiD, specr, psacalc (via Stata), fixest, modelsummary |
| Stata | psacalc, plausexog, regsensitivity, specurve |
| Julia | Custom implementations using Optim.jl, GLM.jl |
