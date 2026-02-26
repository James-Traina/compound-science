---
name: workflows:review
description: Run multi-agent econometric review on estimation code, identification arguments, and research artifacts
argument-hint: "<PR number, branch name, plan reference, or latest>"
---

# Review Command

**Pipeline mode:** This command operates fully autonomously. All decisions are made automatically.

Perform exhaustive econometric and methodological review using multi-agent parallel analysis. Domain-specific reviewers check estimation quality, identification strategy, numerical stability, and mathematical rigor, while generic code quality is delegated to the installed `pr-review-toolkit` plugin.

## Input

<review_target> #$ARGUMENTS </review_target>

**If no input is provided:** Review the current branch against the default branch. If on the default branch with no changes, look for the most recent PR and review that.

## Execution Workflow

### Phase 1: Scope Detection

1. **Determine Review Target**

   ```bash
   # Detect review target type
   if [[ "$ARGUMENTS" =~ ^[0-9]+$ ]]; then
     echo "TARGET=pr:$ARGUMENTS"
   elif [[ "$ARGUMENTS" =~ ^http ]]; then
     echo "TARGET=url:$ARGUMENTS"
   elif [[ -n "$ARGUMENTS" ]]; then
     echo "TARGET=branch:$ARGUMENTS"
   else
     echo "TARGET=current-branch"
   fi
   ```

   - **PR number** → fetch metadata with `gh pr view --json title,body,files,commits`
   - **Branch name** → diff against default branch
   - **Empty** → diff current branch against default branch
   - **Plan reference** → find the plan in `docs/plans/`, identify related branch/commits

2. **Fetch Changed Files and Classify Artifacts**

   ```bash
   # Get changed files
   git diff --name-only $default_branch...HEAD

   # Classify artifacts
   # estimation_code: *.py with statsmodels/scipy.optimize/pyblp/linearmodels imports
   #                  *.R with fixest/lfe/AER/gmm imports
   #                  *.jl with Optim/NLsolve imports
   # simulation_code: Monte Carlo loops, DGP code, bias/RMSE computation
   # proofs:          *.tex with theorem/proof environments, *.md with derivation sections
   # pipeline_files:  Makefile, Snakefile, dvc.yaml, *.do
   # data_code:       data loading, cleaning, merge operations
   # generic_code:    everything else (utilities, configs, scripts)
   ```

   This classification drives which domain reviewers to launch.

3. **Load Review Settings**

   Read `compound-science.local.md` in the project root. If found, use `review_agents` from YAML frontmatter. If the markdown body contains review context (e.g., "focus on identification strategy" or "this is a replication package"), pass it to each agent as additional instructions.

   If no settings file exists, use defaults:
   ```yaml
   review_agents:
     - econometrician
     - numerical-auditor
     - identification-critic
   ```

#### Protected Artifacts

The following paths are compound-science pipeline artifacts and must never be flagged for deletion or removal by any review agent:

- `docs/plans/*.md` — Plan files created by `/workflows:plan`
- `docs/brainstorms/*.md` — Brainstorm files created by `/workflows:brainstorm`
- `docs/solutions/*.md` — Solution documents created by `/workflows:compound`
- `docs/simulations/*.md` — Simulation study documentation

If a review agent flags any file in these directories for cleanup or removal, discard that finding during synthesis.

### Phase 2: Agent Dispatch

Launch domain reviewers in parallel using the Task tool. The specific agents depend on artifact classification from Phase 1.

#### Always Run (Core Domain Review)

<parallel_tasks>

Launch all configured review agents in parallel:

```
Task econometrician(changed files + review context)
  → Checks: identification strategy, endogeneity, standard errors, instrument validity,
    sample selection, asymptotic properties, correct package usage

Task numerical-auditor(changed files + review context)
  → Checks: floating-point stability, convergence diagnostics, integration accuracy,
    RNG seeding, matrix conditioning, overflow/underflow, gradient accuracy

Task identification-critic(changed files + review context)
  → Checks: completeness of identification argument, exclusion restriction plausibility,
    functional form assumptions, parametric vs nonparametric claims, support conditions,
    point vs set identification
```

</parallel_tasks>

#### Conditional Agents (Run Based on Artifact Types)

<conditional_agents>

**WRITTEN ARTIFACTS: If PR contains proofs, derivations, or paper sections:**
(Files matching: `*.tex`, `*.md` with theorem/proof/lemma/proposition content, `docs/proofs/*`)

```
Task referee(written artifact files + review context)
  → Simulates top-5 journal referee: contribution clarity, relation to literature,
    identification concerns, economic vs statistical significance, R&R concerns
    (robustness, external validity, mechanism)
```

**PIPELINE/DATA CODE: If PR contains pipeline files or data processing:**
(Files matching: `Makefile`, `Snakefile`, `dvc.yaml`, `*.do`, data loading/cleaning code)

```
Task pipeline-validator(pipeline files + review context)
  → Checks: intermediate files generated by code (no manual steps), seeds documented,
    package versions pinned, end-to-end pipeline, relative paths, data not committed
```

</conditional_agents>

#### Always Run Post-Review

```
Task learnings-researcher(all review findings + changed modules)
  → Searches docs/solutions/ for past issues related to this PR's modules and patterns
  → Flags matches as "Known Pattern" with links to solution docs
```

#### Delegate Generic Code Quality

For non-domain code quality concerns (style, dead code, type safety, test coverage), delegate to the installed `pr-review-toolkit` plugin. Do NOT duplicate its capabilities.

```
Task code-reviewer(changed files)        # pr-review-toolkit agent
Task silent-failure-hunter(changed files) # pr-review-toolkit agent (if error handling present)
```

### Phase 3: Finding Assembly

**Wait for all Phase 2 agents to complete before proceeding.**

1. **Collect All Findings**

   Gather outputs from all parallel agents into a unified findings list.

2. **Categorize by Severity**

   | Severity | Criteria | Action |
   |----------|----------|--------|
   | **CRITICAL** | Incorrect identification argument, biased estimator, wrong standard errors, numerical instability producing wrong results, missing convergence check | Must fix before merge |
   | **WARNING** | Suboptimal estimation approach, missing robustness check, incomplete diagnostics, weak instruments not flagged, reproducibility gap | Should fix |
   | **NOTE** | Style improvements, alternative approaches worth considering, minor efficiency gains, documentation gaps | Nice to have |

3. **Deduplicate and Cross-Reference**

   - Remove duplicate findings across agents (e.g., econometrician and identification-critic may both flag the same exclusion restriction)
   - Surface learnings-researcher results: if past solutions are relevant, tag findings as "Known Pattern — see docs/solutions/[path]"
   - Discard any findings that recommend deleting files in protected artifact directories

4. **Estimation-Specific Synthesis**

   For estimation code changes, synthesize a unified assessment:

   | Dimension | Status | Details |
   |-----------|--------|---------|
   | **Identification** | [valid/concerns/invalid] | Summary from econometrician + identification-critic |
   | **Estimation** | [correct/issues/incorrect] | Summary from econometrician + numerical-auditor |
   | **Inference** | [valid/concerns/invalid] | Standard error assessment from econometrician |
   | **Numerical Stability** | [stable/warnings/unstable] | Summary from numerical-auditor |
   | **Reproducibility** | [complete/gaps/missing] | Summary from pipeline-validator (if run) |
   | **Rigor** | [publication-ready/needs-work/insufficient] | Summary from referee (if run) |

### Phase 4: Action

1. **Create Todos for All Findings**

   Use TodoWrite to create actionable items for all CRITICAL and WARNING findings:

   ```
   TodoWrite([
     { id: "review-001", task: "[CRITICAL] description", status: "pending" },
     { id: "review-002", task: "[WARNING] description", status: "pending" },
     ...
   ])
   ```

   For NOTES: include as a summary list — do not create individual todos unless the note is actionable.

2. **Generate Review Summary**

   ```markdown
   ## Econometric Review Complete

   **Review Target:** [PR/branch description]
   **Branch:** [branch-name]

   ### Estimation Assessment
   | Dimension | Status |
   |-----------|--------|
   | Identification | [status] |
   | Estimation | [status] |
   | Inference | [status] |
   | Numerical Stability | [status] |
   | Reproducibility | [status] |
   | Rigor | [status] |

   ### Findings Summary
   - **CRITICAL:** [count] — must fix before merge
   - **WARNING:** [count] — should fix
   - **NOTE:** [count] — suggestions

   ### CRITICAL Findings
   1. [finding with agent source and file location]
   2. ...

   ### WARNING Findings
   1. [finding with agent source and file location]
   2. ...

   ### Notes
   - [summarized notes]

   ### Known Patterns (from docs/solutions/)
   - [any matches from learnings-researcher]

   ### Review Agents Used
   - econometrician
   - numerical-auditor
   - identification-critic
   - [conditional agents if triggered]
   - learnings-researcher
   - pr-review-toolkit (code quality)

   ### Next Steps
   1. Address CRITICAL findings (blocks merge)
   2. Address WARNING findings (recommended)
   3. Run `/workflows:compound` to document any novel solutions
   ```

---

## Review Perspectives

The review evaluates changes from multiple research-relevant angles:

### Methodological Rigor
- Is the identification strategy valid and complete?
- Are the maintained assumptions stated and plausible?
- Does the estimation approach match the identification argument?
- Are diagnostics and specification tests appropriate?

### Numerical Quality
- Does estimation code handle floating-point correctly?
- Are convergence criteria appropriate?
- Is the code robust to ill-conditioned data?
- Are random seeds set for all stochastic operations?

### Reproducibility
- Can results be reproduced from the replication package?
- Are all dependencies pinned?
- Does the pipeline run end-to-end without manual steps?
- Are data sources documented and accessible?

### Contribution (Referee Perspective, if triggered)
- Is the contribution clearly stated?
- How does this relate to existing literature?
- Are results economically meaningful (not just statistically significant)?
- What would a skeptical referee ask for?

---

## Configuring Review Agents

Review agents are configured in `compound-science.local.md` at the project root. The YAML frontmatter controls which agents run:

```yaml
---
review_agents:
  - econometrician
  - numerical-auditor
  - identification-critic
  # Uncomment to always include:
  # - referee
  # - pipeline-validator
---
```

The markdown body provides additional context passed to all review agents:

```markdown
## Review Context
Focus on identification strategy — this paper uses a shift-share instrument
and we need to verify the exclusion restriction argument is complete.
```

To create or modify settings, run the `setup` skill.

---

## Routes To

- `/workflows:compound` — document solutions to issues found during review
- `/workflows:work` — implement fixes for review findings
- `pr-review-toolkit` — generic code quality (automatically delegated)
