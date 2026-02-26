---
name: compound-docs
description: Capture solved research problems as categorized documentation with YAML frontmatter for fast lookup. Use when a methodological, estimation, or data problem has been solved and should be documented for future reference. Triggers on "that worked", "it's fixed", "problem solved", "estimation converges now", "proof is complete", "pipeline runs", or when /workflows:compound invokes solution documentation. Also triggered by "document this solution", "save this fix", "log this resolution".
---

# compound-docs Skill

**Purpose:** Automatically document solved research problems to build searchable institutional knowledge with category-based organization. Each problem is filed under a research domain category and linked to the specialist agent best equipped to handle similar issues in the future.

## Overview

This skill captures problem solutions immediately after confirmation, creating structured documentation that serves as a searchable knowledge base for future sessions. It is the primary knowledge accumulation mechanism in the compound workflow — each cycle of Plan → Work → Review → Compound should produce solution documents that make the next cycle faster.

**Organization:** Single-file architecture — each problem documented as one markdown file in its symptom category directory (e.g., `docs/solutions/estimation-issues/weak-instruments-iv-20250225.md`). Files use YAML frontmatter for metadata and searchability.

---

## Research Problem Categories

Six categories cover the research domain. Each maps to a specialist agent for routing future similar problems.

| Category Directory | Problem Types | Specialist Agent |
|---|---|---|
| `estimation-issues/` | Convergence failures, identification failures, wrong standard errors, numerical instability in optimization | `econometrician` |
| `data-issues/` | Cleaning problems, merge errors, missing data patterns, panel structure issues, variable construction errors | `data-detective` |
| `numerical-issues/` | Floating-point precision, matrix conditioning, gradient accuracy, overflow/underflow, quadrature errors | `numerical-auditor` |
| `methodology-issues/` | Specification errors, robustness failures, wrong estimator choice, misapplied methods, invalid assumptions | `methods-researcher` |
| `derivation-issues/` | Proof gaps, incorrect regularity conditions, wrong limiting distributions, missing edge cases in arguments | `mathematical-prover` |
| `replication-issues/` | Reproducibility failures, missing dependencies, broken pipelines, seed mismatches, environment drift | `pipeline-validator` |

### Category Detection Rules

Classify by the **root cause**, not the symptom:

- Optimization failed to converge → check if the cause is numerical (→ `numerical-issues`) or identification (→ `estimation-issues`)
- Results differ across machines → likely `replication-issues` unless caused by floating-point (→ `numerical-issues`)
- Estimator gives wrong coverage in Monte Carlo → `methodology-issues` if wrong estimator, `numerical-issues` if implementation bug
- Standard errors are wrong → `estimation-issues` (clustering, heteroskedasticity) unless caused by singular Hessian (→ `numerical-issues`)

---

## 7-Step Documentation Process

### Step 1: Detect Confirmation

**Auto-invoke after phrases:**
- "that worked" / "it's fixed" / "working now" / "problem solved"
- "estimation converges now" / "proof checks out" / "pipeline runs clean"
- "results match" / "coverage is correct" / "identification holds"

**OR manual:** invoked by `/workflows:compound`

**Non-trivial problems only — document when:**
- Multiple investigation attempts were needed
- Debugging required domain expertise (econometric, numerical, or methodological)
- The root cause was non-obvious
- Future sessions would benefit from knowing this solution

**Skip documentation for:**
- Simple typos or syntax errors
- Obvious import mistakes immediately corrected
- Trivial configuration changes

### Step 2: Gather Context

Extract from conversation history:

**Required information:**
- **Component**: Which estimation routine, model, or pipeline had the problem
- **Symptom**: Observable error or behavior (exact error messages, wrong results)
- **Investigation attempts**: What didn't work and why
- **Root cause**: Technical explanation of actual problem
- **Solution**: What fixed it (code/config changes, methodological correction)
- **Prevention**: How to avoid in future

**Research-specific details:**
- Estimation method and package (e.g., BLP via PyBLP, 2SLS via linearmodels)
- Language (Python/R/Julia/Stata)
- Data characteristics relevant to the problem (sample size, panel structure, missingness)
- Whether the fix is general or specific to this dataset/model

**If critical context is missing** (component, exact error, or resolution steps), infer from the conversation. If genuinely ambiguous, document with a `[needs-clarification]` tag rather than blocking.

### Step 3: Check Existing Docs

Search `docs/solutions/` for similar issues:

```bash
# Search by error message keywords
grep -r "exact error phrase" docs/solutions/

# Search by category
ls docs/solutions/[category]/
```

**If similar issue found:**
- If same root cause → update the existing doc with new context (add "Also seen in:" section)
- If different root cause with similar symptom → create new doc with cross-reference to the similar one
- If unclear → create new doc (prefer separate documents over ambiguous merges)

**If no similar issue found:** proceed directly to Step 4.

### Step 4: Generate Filename

Format: `[sanitized-symptom]-[component]-[YYYYMMDD].md`

**Sanitization rules:**
- Lowercase
- Replace spaces with hyphens
- Remove special characters except hyphens
- Truncate to < 80 characters

**Examples:**
- `weak-instruments-iv-wage-equation-20250225.md`
- `blp-convergence-cereal-demand-20250225.md`
- `singular-hessian-probit-20250225.md`
- `staggered-did-negative-weights-20250225.md`
- `missing-seed-monte-carlo-20250225.md`

### Step 5: Validate YAML Frontmatter

All docs require validated YAML frontmatter.

**Required fields:**

```yaml
---
component: "BLP demand estimation"          # What had the problem
date: 2025-02-25                            # When solved
problem_type: estimation_convergence        # See enum below
category: estimation-issues                 # Directory (derived from problem_type)
symptoms:
  - "Optimizer returns non-convergence after 1000 iterations"
  - "Objective function value jumps between iterations"
root_cause: poor_starting_values            # See enum below
severity: high                              # critical | high | medium | low
estimation_method: blp                      # Optional: method involved
language: python                            # python | r | julia | stata
packages:                                   # Optional: packages involved
  - pyblp
  - numpy
tags: [convergence, blp, starting-values, demand-estimation]
specialist_agent: econometrician            # Which agent handles this category
related_docs: []                            # Cross-references (populated in Step 7)
---
```

**Problem type enum:**

| problem_type | Category | Description |
|---|---|---|
| `estimation_convergence` | estimation-issues | Optimizer fails to converge |
| `identification_failure` | estimation-issues | Model not identified or weakly identified |
| `standard_error_computation` | estimation-issues | Wrong SEs (clustering, bootstrap, sandwich) |
| `endogeneity_issue` | estimation-issues | Unaddressed endogeneity |
| `data_cleaning_error` | data-issues | Errors in data preparation |
| `merge_error` | data-issues | Join/merge produces wrong results |
| `missing_data_handling` | data-issues | Incorrect treatment of missing values |
| `panel_structure_error` | data-issues | Wrong panel ID, time index, or balance |
| `floating_point_error` | numerical-issues | Precision loss, catastrophic cancellation |
| `matrix_conditioning` | numerical-issues | Near-singular matrices, pivot failures |
| `gradient_computation` | numerical-issues | Wrong analytic gradient or bad step size |
| `overflow_underflow` | numerical-issues | Likelihood or probability computation overflow |
| `specification_error` | methodology-issues | Wrong functional form or model specification |
| `robustness_failure` | methodology-issues | Results not robust to reasonable alternatives |
| `wrong_estimator` | methodology-issues | Inappropriate method for the data structure |
| `invalid_assumption` | methodology-issues | Violated assumption (e.g., parallel trends) |
| `proof_gap` | derivation-issues | Missing or incorrect step in proof |
| `regularity_conditions` | derivation-issues | Wrong or missing regularity conditions |
| `limiting_distribution` | derivation-issues | Incorrect asymptotic result |
| `reproducibility_failure` | replication-issues | Results differ across runs or machines |
| `missing_dependency` | replication-issues | Package or data file not included |
| `pipeline_break` | replication-issues | Pipeline fails at some stage |
| `seed_mismatch` | replication-issues | Different seeds produce different "fixed" results |

**Root cause enum:**

| root_cause | Description |
|---|---|
| `poor_starting_values` | Optimization started far from solution |
| `weak_instruments` | Instruments have low predictive power |
| `misspecified_model` | Model doesn't match data generating process |
| `numerical_precision` | Floating-point arithmetic issues |
| `singular_matrix` | Matrix inversion failed or nearly singular |
| `wrong_clustering` | Standard errors clustered at wrong level |
| `data_contamination` | Outliers, duplicates, or coding errors in data |
| `merge_key_mismatch` | Join keys don't align across datasets |
| `missing_not_random` | Missingness is informative, not handled |
| `wrong_functional_form` | Linear when should be nonlinear (or vice versa) |
| `violated_assumption` | Key identifying assumption doesn't hold |
| `implementation_bug` | Code doesn't implement intended estimator |
| `environment_drift` | Package versions or platform differences |
| `missing_seed` | Random seed not set or not propagated |
| `path_dependency` | Absolute paths or machine-specific config |

**Validation:** Verify all required fields are present and enum values match. If a problem doesn't fit existing enums, use the closest match and add a `notes` field explaining the deviation.

### Step 6: Create Documentation

Determine category from `problem_type` using the mapping table above.

```bash
CATEGORY="estimation-issues"  # from problem_type mapping
FILENAME="weak-instruments-iv-wage-equation-20250225.md"
DOC_PATH="docs/solutions/${CATEGORY}/${FILENAME}"

mkdir -p "docs/solutions/${CATEGORY}"
```

**Document template:**

```markdown
---
[validated YAML frontmatter from Step 5]
---

# [Descriptive Title]

## Symptom

[What was observed — exact error messages, wrong numerical results, unexpected behavior]

## Investigation

### What was tried
1. [First attempt and why it didn't work]
2. [Second attempt and why it didn't work]
3. [...]

### Key diagnostic
[The observation or test that revealed the root cause]

## Root Cause

[Technical explanation of why the problem occurred]

## Solution

[What fixed it — specific code changes, parameter adjustments, methodological corrections]

```python
# Before (broken)
result = model.fit(method='bfgs', maxiter=100)

# After (fixed)
x0 = get_starting_values(data, method='ols')  # informed starting values
result = model.fit(method='bfgs', maxiter=5000, x0=x0, gtol=1e-8)
```

## Prevention

[How to avoid this in future — checks to run, patterns to follow]

## Context

- **Dataset:** [description]
- **Sample size:** [N]
- **Estimation method:** [method]
- **Packages:** [list with versions]
- **Related docs:** [cross-references]
```

### Step 7: Cross-Reference and Pattern Detection

**If similar issues found in Step 3:**
- Add bidirectional cross-references (update both docs)
- Update `related_docs` in YAML frontmatter of both files

**Pattern detection — if 3+ similar issues exist:**

Create or update `docs/solutions/patterns/common-patterns.md`:

```markdown
## [Pattern Name]

**Common symptom:** [Description]
**Root cause:** [Technical explanation]
**Solution pattern:** [General approach]
**Category:** [category] → **Agent:** [specialist_agent]

**Examples:**
- [Link to doc 1]
- [Link to doc 2]
- [Link to doc 3]
```

**Critical pattern promotion:**

If the issue has indicators suggesting it's critical:
- Severity: `critical`
- Affects foundational code (identification, core estimation, data pipeline)
- Non-obvious solution that every researcher on the project should know

Then add to `docs/solutions/patterns/critical-patterns.md` with the ❌/✅ format:

```markdown
## Pattern N: [Name]

❌ **WRONG:**
```python
result = IV2SLS.from_formula(...).fit()
# No first-stage F-statistic check
```

✅ **CORRECT:**
```python
result = IV2SLS.from_formula(...).fit()
first_stage = result.first_stage
assert first_stage.diagnostics['f.stat'].stat > 10, "Weak instruments"
```

**Why:** [Explanation]
```

---

## Post-Documentation Actions

After successful documentation, auto-select the most appropriate next action:

1. **If invoked by `/workflows:compound`** → return control to the compound workflow
2. **If 3+ similar issues exist** → auto-create the pattern entry, then continue
3. **If severity is critical** → auto-promote to critical patterns, then continue
4. **Otherwise** → confirm documentation complete and continue workflow

**Output format:**

```
Solution documented:
  docs/solutions/[category]/[filename].md
  Category:  [category] → Agent: [specialist_agent]
  Severity:  [severity]
  [Cross-referenced with: docs/solutions/.../similar-doc.md]  (if applicable)
  [Added to common patterns]  (if 3+ similar)
  [Promoted to critical patterns]  (if critical)
```

---

## Integration Points

**Invoked by:**
- `/workflows:compound` command (primary interface)
- Auto-detection of confirmation phrases in conversation
- `learnings-researcher` agent references this skill's output for searching past solutions

**Agent routing:**
When a new problem is encountered, `learnings-researcher` searches `docs/solutions/` by category. The `specialist_agent` field in frontmatter tells the system which agent to consult for similar problems:
- `estimation-issues/` → `econometrician`
- `data-issues/` → `data-detective`
- `numerical-issues/` → `numerical-auditor`
- `methodology-issues/` → `methods-researcher`
- `derivation-issues/` → `mathematical-prover`
- `replication-issues/` → `pipeline-validator`

---

## Search Patterns

To find past solutions, use these search strategies:

```bash
# By category
ls docs/solutions/estimation-issues/
ls docs/solutions/numerical-issues/

# By error message
grep -r "convergence" docs/solutions/
grep -r "singular" docs/solutions/numerical-issues/

# By package
grep -r "pyblp" docs/solutions/ --include="*.md"
grep -r "linearmodels" docs/solutions/estimation-issues/

# By tag in frontmatter
grep -r "tags:.*bootstrap" docs/solutions/
grep -r "tags:.*weak-instruments" docs/solutions/

# By severity
grep -r "severity: critical" docs/solutions/

# By specialist agent
grep -r "specialist_agent: econometrician" docs/solutions/
```

---

## Example Scenario

**User:** "The BLP estimation finally converges — the issue was starting values."

**Skill activates:**

1. **Detect confirmation:** "finally converges" triggers auto-invoke
2. **Gather context:**
   - Component: BLP demand estimation for cereal market
   - Symptom: `pyblp.Problem.solve()` returns non-convergence after 1000 iterations, objective jumps
   - Failed attempts: Increased `maxiter` (didn't help), tried different optimization methods (BFGS, L-BFGS-B)
   - Solution: Used logit estimates as starting values for sigma (random coefficients), scaled starting values for Pi
   - Root cause: Default zero starting values too far from solution; contraction mapping oscillates
3. **Check existing:** No similar BLP convergence doc found
4. **Generate filename:** `blp-convergence-cereal-demand-20250225.md`
5. **Validate YAML:**
   ```yaml
   component: "BLP demand estimation"
   date: 2025-02-25
   problem_type: estimation_convergence
   category: estimation-issues
   symptoms:
     - "pyblp.Problem.solve() returns non-convergence after 1000 iterations"
     - "Objective function value oscillates between iterations"
   root_cause: poor_starting_values
   severity: high
   estimation_method: blp
   language: python
   packages: [pyblp, numpy]
   tags: [convergence, blp, starting-values, demand-estimation, random-coefficients]
   specialist_agent: econometrician
   related_docs: []
   ```
6. **Create documentation:** `docs/solutions/estimation-issues/blp-convergence-cereal-demand-20250225.md`
7. **Cross-reference:** None needed (first BLP issue documented)

**Output:**
```
Solution documented:
  docs/solutions/estimation-issues/blp-convergence-cereal-demand-20250225.md
  Category:  estimation-issues → Agent: econometrician
  Severity:  high
```

---

## Anti-Patterns

- **Documenting trivial fixes** — a missing import or typo doesn't need a solution doc
- **Vague descriptions** — "fixed the model" is not searchable; include exact errors and code
- **Wrong category** — classify by root cause, not symptom (a convergence failure caused by data issues goes in `data-issues`, not `estimation-issues`)
- **No code examples** — always include before/after code showing the fix
- **Skipping cross-references** — if a similar issue exists, link them; this is how patterns emerge
- **Over-documenting** — one doc per problem; don't create separate docs for each debugging step
