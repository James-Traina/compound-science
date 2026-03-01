# compound-science Plugin

AI-powered research tools for quantitative social science: structural econometrics, causal inference, game theory, applied micro, and reproducible pipelines. Built on the compound workflow principle: each unit of research work makes subsequent work easier.

## Core Workflow

**Plan → Work → Review → Compound → Repeat**

1. `/workflows:brainstorm` — Explore research approaches with methods-researcher and literature-scout agents
2. `/workflows:plan` — Create detailed implementation plans (auto-selects MINIMAL / MORE / A LOT detail)
3. `/workflows:work` — Execute the plan with quality gates and convergence monitoring
4. `/workflows:review` — Multi-agent parallel review (econometrician, numerical-auditor, identification-critic, referee)
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
- `/sensitivity` — Run sensitivity analysis on causal estimates: Oster bounds, specification curve, breakdown frontier

## Agents

### Review (10) — domain-specific code review and methodology verification
- `econometrician` — Reviews identification strategy, endogeneity, standard errors, asymptotic properties
- `mathematical-prover` — Verifies proof steps, completeness, regularity conditions, fixed-point arguments
- `numerical-auditor` — Checks floating-point stability, convergence, RNG seeding, matrix conditioning
- `identification-critic` — Evaluates identification argument completeness, exclusion restrictions, support conditions
- `referee` — Adversarial journal referee simulation (contribution, literature, robustness, external validity)
- `monte-carlo-designer` — Design simulation studies: DGPs, sample sizes, replications, metrics
- `dgp-architect` — Formalize data generating processes from structural models
- `equilibrium-analyst` — Verify equilibrium existence, uniqueness, stability, comparative statics
- `calibration-reviewer` — Reviews calibration/moment-matching strategy, parameter identification, sensitivity to targets
- `results-auditor` — Audits reported results against code output: tables, figures, text consistency

### Research (5) — literature and data investigation
- `literature-scout` — Systematic search for related methods, seminal papers, prior applications
- `methods-researcher` — Deep dive into estimator properties, computational considerations, software implementations
- `data-detective` — Data quality investigation: distributions, missingness, duplicates, panel structure
- `learnings-researcher` — Search docs/solutions/ for past methodological solutions
- `benchmark-researcher` — Researches calibration targets, stylized facts, reference parameter values from the literature

### Workflow (5) — process, reproducibility, and coordination
- `pipeline-validator` — Validate reproducible pipelines: no manual steps, seeds set, versions pinned
- `reproducibility-checker` — Pre-submission replication package verification
- `spec-flow-analyzer` — Analyze specification flow from model → estimator → code
- `research-coordinator` — Coordinate multi-agent research workflows, manage handoffs between phases
- `progress-tracker` — Track research progress, maintain running checklist of completed/pending steps

## Skills

- `structural-modeling` — NFXP, MPEC, BLP, dynamic discrete choice, auction models
- `causal-inference` — IV/2SLS/GMM, DiD, RDD, synthetic control, matching
- `reproducible-pipelines` — Makefile/Snakemake/DVC, environment management, replication standards
- `brainstorming` — Structured research brainstorming techniques
- `compound-docs` — Solution documentation by category (estimation, data, numerical, methodology)
- `git-worktree` — Parallel branches for concurrent estimation runs
- `orchestrating-swarms` — Multi-agent parallel orchestration patterns
- `setup` — Configure compound-science.local.md for project-specific settings
- `journal-submission` — Pre-submission checklists, journal-specific formatting for 20+ journals, referee response strategy
- `applied-micro-toolkit` — Method selection decision tree, diagnostics by method, power analysis, reporting standards

## Ambient Hooks

The plugin detects research context automatically through 5 hooks covering 12 domain categories:
- **SessionStart** — Detects project type (empirical/paper), estimation language, data/pipeline presence
- **UserPromptSubmit** — Injects domain context across 12 categories: identification, estimation, simulation, proof, equilibrium, pipeline, data, diagnostics, tables, replication, sensitivity, submission
- **PostToolUse** — Suggests relevant agents after writing estimation (Python/R/Stata/Julia), simulation, proof, pipeline, or manuscript code
- **Stop** — Checks for 8 completeness conditions: standard errors, convergence, seeds, merge validation, results saved, sensitivity, replication, diagnostics
- **PreCompact** — Preserves 8 categories of research state before context compaction

## Integration

This plugin works alongside: pr-review-toolkit (generic code review), commit-commands (git), document-skills (docs), context7 (framework docs), pyright-lsp (Python types). It does not duplicate their functionality.

## Development

### Testing
- Run: `bash tests/run-all.sh` (200 tests across 10 groups)
- Selective: `bash tests/run-all.sh 07` runs a single group; `--list` shows all groups
- Reports are gitignored at `tests/reports/`

### Critical Invariants
- **Flat repo structure**: `.claude-plugin/plugin.json` must be at repo root — not nested in a subdirectory. `claude plugin install` won't find it otherwise.
- **Hook wrapper format**: `hooks.json` requires the `{"description":"...","hooks":{...}}` envelope. Missing the outer wrapper silently disables all hooks.
- **grep -P unavailable on macOS**: Use `python3 -c "import re; ..."` for Perl-compatible regex. All QA scripts avoid `grep -P`.
- **QA self-scanning exclusions**: When the plugin root is the repo root, content greps must use `--exclude-dir=tests,.ralph,.serena,.git,.claude` to avoid false positives from test fixtures.
- **Chain command frontmatter**: `/lfg` and `/slfg` use `disable-model-invocation: true` so they delegate to sub-commands without an extra model call.

## Domain Keywords

Academic Writing, Applied Micro, Applied Statistics, Business Analytics, Causal Inference, Data Engineering, Data Science, Economic Research, Empirical Methods, Empirical Microdata, Empirical Reasoning, Equilibrium Reasoning, Game Theory, Identification Arguments, Identification Proofs, Mathematical Equilibrium, Mathematical Modeling, Reproducible Pipelines, Structural Econometrics, Structural Estimation, Structural Modeling.
