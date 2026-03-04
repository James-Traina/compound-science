# compound-science Plugin

AI-powered research tools for quantitative social science: structural econometrics, causal inference, game theory, applied micro, and reproducible pipelines. Built on the compound workflow principle: each unit of research work makes subsequent work easier.

## Core Workflow

**Plan → Work → Review → Compound → Repeat**

1. `/workflows:brainstorm` — Explore research approaches with methods-explorer and literature-scout agents
2. `/workflows:plan` — Create detailed implementation plans (auto-selects MINIMAL / MORE / A LOT detail)
3. `/workflows:work` — Execute the plan with quality gates and convergence monitoring
4. `/workflows:review` — Multi-agent parallel review (econometric-reviewer, numerical-auditor, identification-critic, journal-referee)
5. `/workflows:compound` — Extract reusable solutions into docs/solutions/ by category

Use `/lfg` to chain all four steps automatically, or `/slfg` for parallel swarm execution.

## Domain Commands

- `/estimate` — Run a structural estimation pipeline: data validation → identification → estimation → standard errors → robustness → results
- `/simulate` — Design and run Monte Carlo studies: DGP → parameters → simulation → bias/RMSE/coverage → tables
- `/identify` — Formalize an identification argument: target parameter → model → derivation → regularity conditions → estimation link

## Utility Commands

- `/diagnose` — Run diagnostic battery on estimation results: specification tests, instrument checks, residual analysis, model fit
- `/tabulate` — Generate publication-ready tables: regression results, summary statistics, Monte Carlo output
- `/replicate` — Build and verify AEA-compliant replication packages with dependency audit and pipeline verification
- `/visualize` — Generate publication-quality research visualization code: event studies, RD plots, coefficient plots, power curves
- `/stress-test` — Run sensitivity analysis on causal estimates: Oster bounds, specification curve, breakdown frontier

## Agents

### Review (10) — domain-specific code review and methodology verification
- `econometric-reviewer` — Reviews identification strategy, endogeneity, standard errors, asymptotic properties
- `mathematical-prover` — Verifies proof steps, completeness, regularity conditions, fixed-point arguments
- `numerical-auditor` — Checks floating-point stability, convergence, RNG seeding, matrix conditioning
- `identification-critic` — Evaluates identification argument completeness, exclusion restrictions, support conditions
- `journal-referee` — Adversarial journal referee simulation (contribution, literature, robustness, external validity)
- `simulation-designer` — Design simulation studies: DGPs, sample sizes, replications, metrics
- `process-architect` — Formalize data generating processes from structural models
- `equilibrium-analyst` — Verify equilibrium existence, uniqueness, stability, comparative statics
- `calibration-assessor` — Reviews calibration/moment-matching strategy, parameter identification, sensitivity to targets
- `results-verifier` — Audits reported results against code output: tables, figures, text consistency

### Research (5) — literature and data investigation
- `literature-scout` — Systematic search for related methods, seminal papers, prior applications
- `methods-explorer` — Deep dive into estimator properties, computational considerations, software implementations
- `data-detective` — Data quality investigation: distributions, missingness, duplicates, panel structure
- `solutions-archivist` — Search docs/solutions/ for past methodological solutions
- `benchmark-researcher` — Researches calibration targets, stylized facts, reference parameter values from the literature

### Workflow (5) — process, reproducibility, and coordination
- `pipeline-validator` — Validate reproducible pipelines: no manual steps, seeds set, versions pinned
- `reproducibility-checker` — Pre-submission replication package verification
- `specification-analyzer` — Analyze specification flow from model → estimator → code
- `research-coordinator` — Coordinate multi-agent research workflows, manage handoffs between phases
- `progress-tracker` — Track research progress, maintain running checklist of completed/pending steps

## Skills

- `structural-modeling` — NFXP, MPEC, BLP, dynamic discrete choice, auction models
- `causal-inference` — IV/2SLS/GMM, DiD, RDD, synthetic control, matching
- `causal-ml` — Double ML, causal forests (GRF), DR-Learner, post-LASSO, high-dimensional controls
- `game-theory` — Nash/SPE/BNE equilibria, entry models, conduct testing, bargaining, multiple equilibria
- `identification-proofs` — Formal identification arguments: target parameter → model → rank conditions → regularity conditions
- `bayesian-estimation` — MCMC, Stan/PyMC/Numpyro, prior elicitation, MCMC diagnostics, Bayesian structural models
- `reproducible-pipelines` — Makefile/Snakemake/DVC, Stata pipelines, environment management, replication standards
- `strategy-brainstorm` — Structured research brainstorming techniques
- `compound-catalog` — Solution documentation by category (estimation, data, numerical, methodology)
- `git-worktree` — Parallel branches for concurrent estimation runs
- `swarm-orchestration` — Multi-agent parallel orchestration patterns
- `project-setup` — Configure compound-science.local.md for project-specific settings
- `submission-guide` — Pre-submission checklists, journal-specific formatting for 20+ journals, referee response strategy
- `empirical-playbook` — Method selection decision tree, diagnostics by method, power analysis, reporting standards

## Ambient Hooks

The plugin detects research context automatically through 7 hooks covering 13 domain categories:
- **SessionStart** — Detects project type (empirical/paper), estimation language, data/pipeline presence
- **UserPromptSubmit** — Injects domain context across 13 categories. Trigger words include: `estimate`, `identify`, `GMM`, `Monte Carlo`, `prove`, `equilibrium`, `Makefile`, `merge`, `diagnostic`, `tabulate`, `replication`, `Oster bounds`, `convergence`
- **PostToolUse** — Fires on Write/Edit. Triggers include: Python with `statsmodels`/`pyblp`/`scipy.optimize`, R with `fixest`/`did`, Stata `.do` files, `.tex` with `\begin{table}` or `\begin{theorem}`, `Makefile`/`Snakefile`, Bayesian code with `pymc`/`stan`/`numpyro`/`brms`
- **Stop** — Checks 8 completeness conditions. Blocks (at most once) for: missing standard errors after estimation, unseeded simulations, unstated regularity conditions, unvalidated merges. Suggests (non-blocking): `/tabulate`, `/stress-test`, `/replicate`, `/workflows:compound`
- **PreCompact** — Preserves 10 categories of research state before context compaction (including software environment versions and failed approaches)
- **PreToolUse** — Guards bash commands. Warns on: `python estimate.py` without `--seed`, absolute paths like `/Users/.../data.csv`, `pip install pandas` without `==version`, `dvc repro`/`snakemake` without seed configuration
- **SubagentStop** — Suggests next steps using severity routing: critical findings (convergence, identification) get immediate actions, presentation findings get suggestions. Multi-critical prioritization: identification failure → numerical instability → wrong SEs → robustness. Uses pattern: `[agent]: [finding] → [action]`

## Integration

This plugin works alongside: pr-review-toolkit (generic code review), commit-commands (git), document-skills (docs), context7 (framework docs), pyright-lsp (Python types). It does not duplicate their functionality.

## Development

### Testing
- Run: `bash .tests/run-all.sh` (235 tests across 12 groups)
- Selective: `bash .tests/run-all.sh 07` runs a single group; `--list` shows all groups
- Reports are gitignored at `.tests/reports/`

### Critical Invariants
- **Flat repo structure**: `.claude-plugin/plugin.json` must be at repo root — not nested in a subdirectory. `claude plugin install` won't find it otherwise.
- **Version bumping required for updates**: Claude Code caches plugins; users only get updates if `version` in `plugin.json` is incremented. Current version is tracked in `.claude-plugin/plugin.json`.
- **Hook wrapper format**: `hooks.json` requires the `{"description":"...","hooks":{...}}` envelope. Missing the outer wrapper silently disables all hooks.
- **Dev-only dirs are hidden**: `.tests/` and `.evals/` start with `.` so they don't appear in the default file tree for users who install the plugin. Reports go to `.tests/reports/` (gitignored).
- **grep -P unavailable on macOS**: Use `python3 -c "import re; ..."` for Perl-compatible regex. All QA scripts avoid `grep -P`.
- **QA self-scanning exclusions**: When the plugin root is the repo root, content greps must use `--exclude-dir=.tests,.evals,.ralph,.serena,.git,.claude` to avoid false positives from test fixtures.
- **Chain command frontmatter**: `/lfg` and `/slfg` use `disable-model-invocation: true` so they delegate to sub-commands without an extra model call.

## Domain Keywords

Academic Writing, Applied Micro, Applied Statistics, Business Analytics, Causal Inference, Data Engineering, Data Science, Economic Research, Empirical Methods, Empirical Microdata, Empirical Reasoning, Equilibrium Reasoning, Game Theory, Identification Arguments, Identification Proofs, Mathematical Equilibrium, Mathematical Modeling, Reproducible Pipelines, Structural Econometrics, Structural Estimation, Structural Modeling.
