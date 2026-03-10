# compound-science

A Claude Code plugin for quantitative social science research: structural econometrics, causal inference, game theory, applied micro, identification arguments, Monte Carlo studies, and reproducible pipelines.

Every time you solve a methodological problem — a convergence fix, an identification argument, a numerical issue — that solution gets documented and made findable. The next project starts where the last one left off.

## The problem this solves

Empirical research in economics involves a lot of repeated pattern-matching: figuring out which DiD estimator applies when treatment timing is staggered, checking whether your BLP instruments are weak, making sure simulation seeds are set before you write down results, formatting a table to AER style. These problems have standard answers. Finding the right answer at the moment you need it is still slow.

The plugin intercepts your workflow and surfaces relevant expertise without you having to ask. When you write estimation code, it suggests the econometric-reviewer. When a session ends without standard errors being discussed, it flags it. When you open a project, it detects your estimation language and data structure. The idea is that you focus on the research question, not the checklist.

## How it works

The core loop is **Plan → Work → Review → Compound → Repeat**.

1. **Plan** (`/workflows:plan`): You describe the task. The plugin creates an implementation plan, choosing between minimal, moderate, and detailed levels based on complexity. For a BLP demand model, this means settling the inner-loop choice (NFXP vs MPEC), the instruments, the standard errors, and the robustness checks before any code is written.

2. **Work** (`/workflows:work`): The plan executes with quality gates. If optimization fails, the numerical-auditor investigates. If the model produces implausible elasticities, the calibration-assessor flags it.

3. **Review** (`/workflows:review`): Domain-specific review agents examine your work in parallel. The econometric-reviewer checks identification. The numerical-auditor checks floating-point stability and gradient accuracy. The identification-critic evaluates your exclusion restrictions. The journal-referee tries to find reasons to reject the paper. The econometric-reviewer, for instance, knows to ask about Montiel Olea-Pflueger effective F rather than Stock-Yogo, and about clustered wild bootstrap for staggered DiD, not just generic clustering.

4. **Compound** (`/workflows:compound`): Solutions get documented into `docs/solutions/` by category (identification, estimation, numerical, methodology). Future sessions search this via the solutions-archivist agent. The knowledge base grows as the project does.

Run `/lfg [task]` to chain all four steps automatically. Run `/slfg [task]` to parallelize review and compound with agent swarms.

### Ambient hooks

Seven ambient hooks run without being invoked.

- When you **open a session**, the plugin scans your project for `.py`/`.R`/`.do` files, `Makefile`/`Snakemake`/`DVC`, `data/` directories, and `.tex` files, then configures itself for your language, project type, and data setup.

- When you **submit a prompt**, the plugin classifies it across 14 domain categories and adds relevant context to the response. If you ask "is this estimate large?", it notes that you should first confirm whether your identification assumptions hold — evaluating magnitudes before validating the design is a common mistake.

- When you **write code**, the plugin reads what you wrote and suggests a relevant agent. Write a file with `fixest` or `did`, and it surfaces the econometric-reviewer. Write a `.tex` file with `\begin{theorem}`, and it suggests the mathematical-prover. Write a simulation without `set.seed`, and it flags the omission.

- When a **session ends**, the plugin checks 10 completeness conditions. Items 1–4 are blocking: missing standard errors after estimation, an unseeded simulation, unstated regularity conditions in a proof, an unvalidated data merge. Items 5–10 are suggestions: tabulate, stress-test, replicate, compound, check DiD pre-trends, check IV first-stage F. Blocking items must be resolved before the session closes.

## Install

Via the [science-plugins](https://github.com/James-Traina/science-plugins) marketplace (recommended — enables one-command updates):

```bash
/plugin marketplace add James-Traina/science-plugins
/plugin install compound-science@science-plugins
```

Or directly from GitHub:

```bash
claude plugin install https://github.com/James-Traina/compound-science
```

Or from a local clone:

```bash
claude plugin install /path/to/compound-science
```

To update after a new release:

```bash
/plugin update compound-science
```

## Quick start

```bash
# Full autonomous pipeline: plan, implement, review, document
/lfg estimate a BLP demand model for the cereal dataset

# Or step by step
/workflows:brainstorm approaches for estimating entry games
/workflows:plan implement Bresnahan-Reiss entry model
/workflows:work
/workflows:review
/workflows:compound

# Domain commands
/estimate run 2SLS with Bartik instruments
/simulate Monte Carlo for DiD with staggered adoption
/identify formalize the identification argument for auction model

# Utility commands
/diagnose check my IV regression results
/tabulate format regression table for AER submission
/stress-test run Oster bounds on baseline estimate
/visualize create event study plot with confidence intervals
/replicate build replication package for journal submission
/deepen-plan enrich my research plan with specialist agent research
```

## Commands

### Workflow commands

These chain together into the Plan → Work → Review → Compound loop. Run them individually or use `/lfg` to run all four automatically.

| Command | What it does |
|---------|-------------|
| `/workflows:brainstorm` | Explore research approaches with methods-explorer and literature-scout agents. Good when you have a question but aren't sure which method applies, or want to survey recent literature before committing to a design. |
| `/workflows:plan` | Create an implementation plan. The plugin picks between MINIMAL (simple task), MORE (moderate complexity), and A LOT (new estimator, identification challenge, multiple robustness checks). Returns a plan you can edit before execution. |
| `/workflows:work` | Execute the current plan with quality gates. Monitors convergence, routes problems to the relevant agent. |
| `/workflows:review` | Run the four review agents in parallel: econometric-reviewer, numerical-auditor, identification-critic, journal-referee. Each returns a report with numbered findings and severity ratings. |
| `/workflows:compound` | Extract methodological insights from the session into `docs/solutions/`. Creates searchable entries by category (identification arguments, convergence fixes, instrument choices) that future sessions can find via the solutions-archivist. |
| `/lfg` | Chains brainstorm → plan → work → review → compound. Use for the full autonomous pipeline. |
| `/slfg` | Same as `/lfg` but parallelizes review and compound using agent swarms. Faster when you have multiple reviewers queued. |

### Domain commands

These handle specific research tasks as multi-phase pipelines. Each prompts for the relevant inputs and then runs a defined sequence with checkpoints.

| Command | What it does |
|---------|-------------|
| `/estimate` | Structural estimation pipeline: data validation → identification check (exclusion restrictions, rank condition, instrument strength) → estimation with convergence monitoring → standard errors (clustered, robust, or bootstrap as appropriate) → robustness checks → results summary |
| `/simulate` | Monte Carlo studies: DGP specification → parameter selection with literature calibration → simulation with seeded RNG → bias/RMSE/coverage metrics → results tables. The simulation-designer agent checks DGP correctness. |
| `/identify` | Formalizes an identification argument: target parameter → model primitives and observables → rank/order conditions → key assumptions (exclusion, monotonicity, parallel trends, continuity) → regularity conditions → feasible estimator. Produces a formal proposition ready for a theory appendix. |

### Utility commands

| Command | What it does |
|---------|-------------|
| `/diagnose` | Diagnostic battery: specification tests (Hausman, Sargan-Hansen), instrument diagnostics (Montiel Olea-Pflueger effective F), residual analysis, model fit. Findings go to the econometric-reviewer for interpretation. |
| `/tabulate` | Publication-ready LaTeX tables: regression results (significance stars, clustered SE notation, N), summary statistics, Monte Carlo output (bias/RMSE/coverage), balance tables. Follows the target journal's formatting if specified. |
| `/replicate` | AEA-compliant replication package: file inventory, README generation, dependency audit (software and package versions), pipeline verification (master script runs from scratch, all seeds set), data documentation. |
| `/visualize` | Visualization code: event study plots (with pre-trend tests and 95% CIs), RD plots (with density test), coefficient plots, power curves, distribution densities. |
| `/stress-test` | Sensitivity analysis: Oster (2019) proportional selection bounds, Conley et al. (2012) plausibly exogenous IV bounds, breakdown frontier, specification curve across alternative specifications. |
| `/deepen-plan` | Spawns four parallel specialist agents (literature-scout, identification-critic, benchmark-researcher, methods-explorer) with targeted research questions, then synthesizes findings back as `### Research Insights` subsections. `⚠️` flags mark items that should change the plan. |

## Agents (20)

Each agent runs as a specialized subagent with its own structured output format. Review agents return numbered findings with severity ratings (critical, must-fix, should-fix, suggestion). Research agents return structured reports with citations and follow-up questions.

### Review agents (10)

Invoked during `/workflows:review` or by ambient hooks when you write relevant code.

| Agent | What it examines | When it's most useful |
|-------|-----------------|----------------------|
| `econometric-reviewer` | Identification strategy, endogeneity, standard errors (clustering level, wild cluster bootstrap for small clusters), asymptotic properties, instrument strength via Montiel Olea-Pflueger effective F | After writing estimation code or completing a regression |
| `mathematical-prover` | Proof step validity, assumption completeness, regularity condition sufficiency, fixed-point arguments, quantifier ordering | Writing theory appendices, proving identification propositions, verifying contraction mapping arguments |
| `numerical-auditor` | Floating-point stability (log-sum-exp, integration tolerances), convergence diagnostics (gradient norms, step sizes), RNG seeding, matrix conditioning, gradient accuracy | After structural estimation, simulation, or any numerical optimization |
| `identification-critic` | Identification argument completeness — exclusion restrictions, support conditions, rank conditions, partial identification, observational equivalence | Before finalizing an empirical strategy or submitting |
| `journal-referee` | Adversarial peer review simulation: contribution relative to the literature, methodological concerns, robustness gaps, external validity, exposition. Calibrated for 11 journals (AER, ECMA, JPE, QJE, REStud, AEJ-Applied, AEJ-Policy, JHR, JHE, RAND, JPubE) | Before submitting, or to stress-test a draft before an R&R response |
| `simulation-designer` | DGP correctness (does the simulation reflect the theoretical model?), sample size adequacy, replication count, metric selection (bias vs RMSE vs coverage) | Designing or reviewing Monte Carlo studies |
| `process-architect` | DGP formalization from structural primitives, equilibrium computation correctness, model completeness | Building structural IO models, entry games, or auction models |
| `equilibrium-analyst` | Equilibrium existence (fixed-point conditions), uniqueness (Banach contraction, dominant strategy), stability (best-response dynamics), comparative statics | Specifying or solving game-theoretic models |
| `calibration-assessor` | Moment selection (which moments pin down which parameters?), target values, sensitivity to targets (how much does the estimate shift if a moment moves by one SE?), overidentification | Model calibration or moment-matching estimation |
| `results-verifier` | Reported results vs code output: table accuracy, in-text coefficient references, significance star consistency, N counts, fit measures | Before submission; catches errors that don't throw warnings |

### Research agents (5)

These investigate literature, data, and past solutions. Most useful at the start of a project or when the estimation is stuck.

| Agent | What it does |
|-------|-------------|
| `literature-scout` | Searches for related methods, seminal papers, prior applications, and intellectual genealogy. Useful for knowing what comparable papers did and how they defend their identification. |
| `methods-explorer` | Digs into estimator properties, computational tradeoffs, and software implementations. Ask "what are the tradeoffs between CS21 and Sun-Abraham for my setting?" and get a structured comparison. |
| `data-detective` | Data quality: distributions, missingness patterns, duplicate records, panel structure (balanced?), merge validation (how many observations were lost and why?). Catches a class of problems that only surface late in estimation. |
| `solutions-archivist` | Searches `docs/solutions/` for past methodological solutions documented via `/workflows:compound`. Ask "how did we handle weak instruments last time?" |
| `benchmark-researcher` | Researches calibration targets, stylized facts, and reference parameter values from the literature. Useful when you need plausible ranges for elasticities, discount factors, or cost parameters. |

### Workflow agents (5)

These coordinate processes and track state across long-running projects.

| Agent | What it does |
|-------|-------------|
| `pipeline-validator` | Validates reproducible pipelines: no manual steps, no hardcoded paths, seeds set, package versions pinned, master script runs from scratch |
| `reproducibility-checker` | Pre-submission replication package audit: the AEA Data Editor checklist, plus a trace from every table in the paper to a specific line of code |
| `specification-analyzer` | Traces the specification flow from model → estimator → code → output. Catches mismatches between what the model says and what the code does. |
| `research-coordinator` | Coordinates multi-agent workflows. Manages handoffs between phases, tracks which subagents ran and what they found, synthesizes findings into a Coordination Summary. |
| `progress-tracker` | Maintains a running checklist of completed and pending steps. Detects progress from git history, file timestamps, and conversation context. Useful when resuming after a break. |

## Skills (16)

Skills are domain knowledge references that load when you need them. Each has a lean `SKILL.md` with method selection guides and quick reference tables, plus a `references/` directory with full implementation code and API details. The idea is that you get a useful overview quickly and drill into the reference when you're implementing.

| Skill | What it covers |
|-------|---------------|
| `structural-modeling` | NFXP, MPEC, BLP demand, dynamic discrete choice (Rust, Hotz-Miller CCP), auction models. From model specification through estimation and post-estimation. |
| `causal-inference` | IV/2SLS/GMM with instrument validity checks, DiD including staggered adoption (Callaway-Sant'Anna, Sun-Abraham, de Chaisemartin-D'Haultfoeuille), RDD (sharp/fuzzy, rdrobust), synthetic control, matching and doubly-robust estimators. |
| `causal-ml` | Double ML (Chernozhukov et al. 2018) with cross-fitting, causal forests (GRF), DR-Learner, T/S/X-learners, post-double-selection LASSO, heterogeneous treatment effect inference. |
| `game-theory` | Nash/SPE/BNE equilibria and computation, entry models (Bresnahan-Reiss, Berry 1992, Ciliberto-Tamer), conduct testing, bargaining, multiple equilibria problem and selection. |
| `identification-proofs` | Seven-step identification argument: target parameter → model primitives → source of variation → assumptions → identification result → regularity conditions → estimation link. Covers IFT approach, completeness conditions, LATE, RD identification, BLP inversion. |
| `bayesian-estimation` | Stan, PyMC, NumPyro, brms from setup through MCMC diagnostics (R-hat, ESS, divergences), posterior inference (HDI, predictive checks, LOO-CV), and Bayesian structural models. |
| `reproducible-pipelines` | Makefile and Snakemake patterns, DVC for large data, Stata pipelines (master.do, batch mode, ado versioning), environment management (conda/renv/Docker), random seed management, AEA replication standards. |
| `empirical-playbook` | Method selection decision tree (what source of variation do you have?), within-method refinements (which DiD estimator given your timing and controls?), diagnostics by method, inference framework selection, power analysis, minimum reporting standards. |
| `submission-guide` | Pre-submission checklists (manuscript, tables, figures, replication package, cover letter), journal-specific formatting for 20+ journals, referee response strategy, revision management. |
| `strategy-brainstorm` | Structured brainstorming for methodology selection: parsimony-first thinking, literature survey questions, comparison to alternatives. |
| `compound-catalog` | Solution documentation patterns: how to write a solution entry, the `problem_type` taxonomy, frontmatter structure. |
| `git-worktree` | Parallel worktrees for concurrent estimation runs and specification comparisons — useful when you need to run five robustness checks simultaneously without branch-switching overhead. |
| `swarm-orchestration` | Multi-agent parallel orchestration patterns used by `/slfg`. How to structure parallel agent calls, synthesize heterogeneous outputs, handle conflicting findings. |
| `project-setup` | Configuring `compound-science.local.md`: which agents to run by default, preferred estimation language, project type, data sensitivity level. |
| `data-acquisition` | FRED API (800k+ economic series, vintage/ALFRED real-time data, built-in transformations) and World Bank API (240+ cross-national indicators), with series dictionaries, panel assembly guidance, and missingness auditing. |
| `referee-response` | Author response workflow: comment classification (identification, data, inference, exposition, literature, robustness, other), point-by-point format templates, identification challenge protocol, journal-specific tone, multi-round revision tracking. |

## Ambient Hooks (7)

The plugin watches your session. Nothing to invoke.

| Hook | When it fires | What it does |
|------|--------------|-------------|
| **SessionStart** | Session opens | Scans for estimation scripts (`.py`, `.R`, `.do`, `.jl`), pipeline files (`Makefile`, `Snakemake`, `dvc.yaml`), data directories, and LaTeX files. Detects project type (empirical, paper, or empirical-paper), estimation language, and whether data and pipeline infrastructure exist. Loads `compound-science.local.md` if present. |
| **UserPromptSubmit** | Every prompt | Classifies your prompt across 14 domain categories and adds relevant context to the response. ESTIMATION prompts get econometric context. SIMULATION prompts get Monte Carlo guidance. PROOF prompts get formal structure advice. If you ask whether a coefficient is large before the identification design is validated, it applies Cunningham's norm: confirm the assumptions hold before evaluating magnitudes. |
| **PostToolUse** | After file write/edit | Reads what you wrote and suggests the relevant agent. `fixest`/`did` → econometric-reviewer. `\begin{theorem}` → mathematical-prover. `pymc`/`stan`/`brms` → numerical-auditor for MCMC diagnostics. `Makefile`/`Snakemake` → pipeline-validator. `\begin{table}` → results-verifier. |
| **Stop** | Session ends | Checks 10 completeness conditions. Items 1–4 are blocking: missing standard errors after estimation, unseeded simulation, unstated regularity conditions in a proof, unvalidated data merge. Items 5–10 are suggestions: tabulate, stress-test, replicate, compound, check DiD pre-trends, check IV first-stage F via Montiel Olea-Pflueger. Blocking items must be resolved before the session closes. |
| **PreCompact** | Context compaction | Before the context window compresses, preserves 10 categories of research state: identification strategy, estimation results and convergence status, proof steps and regularity conditions, pipeline configuration, methodology decisions and rejections, sensitivity analysis results, diagnostic findings, submission status, software environment versions, and failed approaches. |
| **PreToolUse** | Before Bash | Guards reproducibility. Warns on: running `python estimate.py` without `--seed`, absolute paths like `/Users/.../data.csv`, `pip install pandas` without `==version`, `dvc repro` or `snakemake` without seed configuration. |
| **SubagentStop** | After any agent completes | Routes findings to the right next action. Critical findings (identification failure, numerical instability) get required actions. Suggestion-level findings get options. Priority order: identification failure → numerical instability → wrong SEs → robustness gaps. Format: `[agent]: [finding] → [action]`. |

## Configuration

Create `compound-science.local.md` in your project's `.claude/` directory to configure the plugin for your project. You can specify which review agents to run by default, your preferred estimation language, project type, and data sensitivity level. Run the `project-setup` skill for a guided walkthrough.

## Integration

This plugin handles domain-specific research methodology. It doesn't duplicate generic code review, git operations, or document handling.

| Plugin | What it provides | How compound-science uses it |
|--------|-----------------|----------------------------|
| `pr-review-toolkit` | Generic code review (style, naming, modularity) | `/workflows:review` delegates non-domain checks to it |
| `commit-commands` | Git commit/push/PR | Workflow commands use git for version-tagging submissions |
| `document-skills` | PDF, XLSX, DOCX export | Results export from `/tabulate` and `/replicate` |
| `context7` | Up-to-date framework docs | Library documentation lookup for estimation packages |
| `pyright-lsp` | Python type checking | Type validation in estimation code |

## Component Counts

| Category | Count |
|----------|-------|
| Agents | 20 (10 review + 5 research + 5 workflow) |
| Commands | 16 (5 workflow + 2 chain + 3 domain + 6 utility) |
| Skills | 16 |
| Hooks | 7 |
| **Total** | **59 components** |

## Layout

```
.claude-plugin/   plugin.json (manifest), settings.json
CHANGELOG.md      version history
agents/
  review/         econometric-reviewer, mathematical-prover, numerical-auditor,
                  identification-critic, journal-referee, simulation-designer,
                  process-architect, equilibrium-analyst, calibration-assessor, results-verifier
  research/       literature-scout, methods-explorer, data-detective, solutions-archivist,
                  benchmark-researcher
  workflow/       pipeline-validator, reproducibility-checker, specification-analyzer,
                  research-coordinator, progress-tracker
commands/
  workflows/      brainstorm, plan, work, review, compound
  estimate, simulate, identify, lfg, slfg
  diagnose, tabulate, replicate, visualize, stress-test, deepen-plan
skills/           16 domain knowledge bases; 8 have references/ subdirs with detail
hooks/            hooks.json (7 ambient hooks, 14 domain categories)
.tests/           237 tests across 12 groups (dev-only, gitignored reports)
.evals/           evaluation harness (dev-only)
```

## Testing

```bash
bash .tests/run-all.sh              # Run all 237 tests
bash .tests/run-all.sh 07           # Run a specific test group
bash .tests/run-all.sh --list       # List available test groups
```

## Background & Attribution

This plugin is directly inspired by [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by [Every](https://every.to), which pioneered the compound workflow pattern for web development in Claude Code. The core loop and the idea of ambient hooks that watch for domain artifacts both come from their work. compound-science adapts that pattern to quantitative social science research.

The main adaptation was swapping web-focused agents for domain-specific ones: an `econometric-reviewer` instead of a frontend reviewer, a `numerical-auditor` instead of a performance profiler. The research commands and utility commands handle workflows that have no web equivalent, and the hooks watch for estimation packages, LaTeX files, and data directories rather than JavaScript frameworks and API endpoints.

## Domain Keywords

| Domain | Keywords |
|--------|----------|
| Structural Econometrics & Estimation | NFXP, MPEC, BLP, nested fixed point, Structural Estimation, Structural Modeling |
| Causal Inference & Empirical Methods | IV, 2SLS, GMM, DiD, RDD, synthetic control, matching, Empirical Methods, Empirical Reasoning |
| Identification | exclusion restriction, instrument, rank condition, Identification Arguments, Identification Proofs |
| Game Theory & Equilibrium | Nash equilibrium, best response, entry game, auction, Equilibrium Reasoning, Mathematical Equilibrium |
| Mathematical Modeling & Simulation | existence, uniqueness, fixed point, contraction mapping, Monte Carlo, DGP, Mathematical Modeling |
| Data Science & Engineering | panel data, cross-section, merge validation, imputation, Data Engineering, Data Science, Empirical Microdata |
| Reproducible Pipelines | Makefile, Snakemake, DVC, replication package, version pinning |
| Applied Statistics & Research | MLE, bootstrap, clustering, standard errors, Applied Statistics, Business Analytics, Academic Writing, Economic Research |
| Applied Micro & Research Design | method selection, power analysis, specification curve, research design, Applied Micro |

## Updating

```bash
/plugin update compound-science
```

## License

MIT
