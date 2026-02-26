# Compound-Science Plugin

AI-powered research tools for structural econometrics, causal inference, and quantitative social science. Built on the compound workflow principle: each unit of research work makes subsequent work easier.

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

## Agents

### Review (domain-specific code review)
- `econometrician` — Reviews identification strategy, endogeneity, standard errors, asymptotic properties
- `mathematical-prover` — Verifies proof steps, completeness, regularity conditions, fixed-point arguments
- `numerical-auditor` — Checks floating-point stability, convergence, RNG seeding, matrix conditioning
- `identification-critic` — Evaluates identification argument completeness, exclusion restrictions, support conditions
- `referee` — Adversarial journal referee simulation (contribution, literature, robustness, external validity)

### Research
- `literature-scout` — Systematic search for related methods, seminal papers, prior applications
- `methods-researcher` — Deep dive into estimator properties, computational considerations, software implementations
- `data-detective` — Data quality investigation: distributions, missingness, duplicates, panel structure
- `learnings-researcher` — Search docs/solutions/ for past methodological solutions

### Methods
- `monte-carlo-designer` — Design simulation studies: DGPs, sample sizes, replications, metrics
- `dgp-architect` — Formalize data generating processes from structural models
- `equilibrium-analyst` — Verify equilibrium existence, uniqueness, stability, comparative statics

### Workflow
- `pipeline-validator` — Validate reproducible pipelines: no manual steps, seeds set, versions pinned
- `reproducibility-checker` — Pre-submission replication package verification
- `spec-flow-analyzer` — Analyze specification flow from model → estimator → code

## Skills

- `structural-modeling` — NFXP, MPEC, BLP, dynamic discrete choice, auction models
- `causal-inference` — IV/2SLS/GMM, DiD, RDD, synthetic control, matching
- `reproducible-pipelines` — Makefile/Snakemake/DVC, environment management, replication standards
- `brainstorming` — Structured research brainstorming techniques
- `compound-docs` — Solution documentation by category (estimation, data, numerical, methodology)
- `git-worktree` — Parallel branches for concurrent estimation runs
- `orchestrating-swarms` — Multi-agent parallel orchestration patterns
- `setup` — Configure compound-science.local.md for project-specific settings

## Ambient Hooks

The plugin detects research context automatically:
- **SessionStart** — Detects project type (empirical/paper), estimation language, data/pipeline presence
- **UserPromptSubmit** — Injects domain context when research terminology is detected
- **PostToolUse** — Suggests relevant agents after writing estimation/simulation/proof code
- **Stop** — Checks for missing critical steps (standard errors, seeds, regularity conditions)
- **PreCompact** — Preserves research state before context compaction

## Integration

This plugin works alongside: pr-review-toolkit (generic code review), commit-commands (git), document-skills (docs), context7 (framework docs), pyright-lsp (Python types). It does not duplicate their functionality.

## Domain Keywords

Academic Writing, Applied Statistics, Business Analytics, Causal Inference, Data Engineering, Data Science, Economic Research, Empirical Methods, Empirical Microdata, Empirical Reasoning, Equilibrium Reasoning, Game Theory, Identification Arguments, Identification Proofs, Mathematical Equilibrium, Mathematical Modeling, Reproducible Pipelines, Structural Econometrics, Structural Estimation, Structural Modeling.
