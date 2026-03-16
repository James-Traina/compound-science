# compound-science Plugin

AI-powered research tools for quantitative social science: structural econometrics, causal inference, game theory, applied micro, and reproducible pipelines. Built on the compound workflow principle: each unit of research work makes subsequent work easier.

## Core Workflow

**Plan → Work → Review → Compound → Repeat**

1. `/workflows:brainstorm` — Explore research approaches with methods-explorer and literature-scout agents
2. `/workflows:plan` — Create detailed implementation plans (auto-selects MINIMAL / MORE / A LOT detail; includes parallel agent enrichment for complex plans)
3. `/workflows:work` — Execute the plan with quality gates and convergence monitoring
4. `/workflows:review` — Multi-agent parallel review (econometric-reviewer, numerical-auditor, identification-critic, journal-referee)
5. `/workflows:compound` — Extract reusable solutions into docs/solutions/ by category

Use `/lfg` to chain all five steps automatically, or `/slfg` for parallel swarm execution.

## Commands

### Canonical (7)
- `/workflows:brainstorm`, `/workflows:plan`, `/workflows:work`, `/workflows:review`, `/workflows:compound` — the core research workflow
- `/estimate` — Thin wrapper: routes to `/workflows:work` with estimation pipeline context from `empirical-playbook`
- `/replicate` — Thin wrapper: routes to `reproducibility-auditor` agent

### Chain (2)
- `/lfg` — Sequential: plan → work → review → compound
- `/slfg` — Parallel swarm variant of `/lfg`

### Deprecated stubs (7) — compatibility layer, will be removed in v0.6
`/simulate`, `/identify`, `/diagnose`, `/tabulate`, `/visualize`, `/stress-test`, `/deepen-plan` — each redirects to the agent or skill that now handles its function. These exist only for muscle memory; use the canonical commands and agents directly.

## Agents

### Review (9) — domain-specific code review and methodology verification
- `econometric-reviewer` — Reviews identification, inference, standard errors, calibration strategy, specification flow (model → estimator → code)
- `mathematical-prover` — Verifies proof steps, completeness, regularity conditions, fixed-point arguments
- `numerical-auditor` — Checks floating-point stability, convergence, RNG seeding, matrix conditioning
- `identification-critic` — Evaluates identification argument completeness, exclusion restrictions, support conditions
- `journal-referee` — Adversarial journal referee simulation (contribution, literature, robustness, external validity)
- `simulation-designer` — Design simulation studies: DGPs, sample sizes, replications, metrics
- `process-architect` — Formalize data generating processes from structural models
- `equilibrium-analyst` — Verify equilibrium existence, uniqueness, stability, comparative statics
- `results-verifier` — Audits reported results against code output: tables, figures, text consistency

### Research (3) — literature and data investigation
- `literature-scout` — Systematic search for related methods, seminal papers, prior applications
- `methods-explorer` — Estimator properties, computational tradeoffs, software implementations, benchmark parameters and calibration targets
- `data-detective` — Data quality investigation: distributions, missingness, duplicates, panel structure

### Workflow (2) — process, reproducibility, and coordination
- `reproducibility-auditor` — Structural and functional checks for reproducible pipelines and replication packages
- `workflow-coordinator` — Multi-agent workflow coordination, dispatch, triage, and progress tracking

## Skills (17)

- `structural-modeling` — NFXP, MPEC, BLP, dynamic discrete choice, auction models
- `causal-inference` — IV/2SLS/GMM, DiD, RDD, synthetic control, matching
- `causal-ml` — Double ML, causal forests (GRF), DR-Learner, post-LASSO, high-dimensional controls
- `game-theory` — Nash/SPE/BNE equilibria, entry models, conduct testing, bargaining, multiple equilibria
- `identification-proofs` — Formal identification arguments: target parameter → model → rank conditions → regularity conditions
- `bayesian-estimation` — MCMC, Stan/PyMC/Numpyro, prior elicitation, MCMC diagnostics, Bayesian structural models
- `reproducible-pipelines` — Makefile/Snakemake/DVC, Stata pipelines, environment management, replication standards
- `empirical-playbook` — Method selection, diagnostics by method, power analysis, estimation pipeline, sensitivity analysis
- `publication-output` — Publication-quality tables and figures: stargazer-style tables, event study plots, RD plots, specification curves
- `submission-guide` — Pre-submission checklists, journal-specific formatting for 20+ journals, referee response strategy
- `compound-catalog` — Solution documentation and search by category (estimation, data, numerical, methodology)
- `data-acquisition` — FRED and World Bank API access: time series, vintage data, cross-national panels
- `referee-response` — Draft structured author responses to peer review
- `strategy-brainstorm` — Structured research brainstorming techniques
- `swarm-orchestration` — Multi-agent parallel orchestration patterns
- `project-setup` — Configure compound-science.local.md for project-specific settings
- `git-worktree` — Parallel branches for concurrent estimation runs

## Domain Signal → Agent Routing

When compaction drops context, use this table to route research questions:

| Signal | Primary Agent | Skill |
|--------|--------------|-------|
| Identification, instruments, exclusion, endogeneity | `identification-critic` | `causal-inference` |
| Estimation, SEs, convergence, calibration | `econometric-reviewer` | `empirical-playbook` |
| Proof, theorem, regularity conditions | `mathematical-prover` | `identification-proofs` |
| Floating-point, Hessian, conditioning, MCMC diagnostics | `numerical-auditor` | `bayesian-estimation` |
| Simulation, DGP, Monte Carlo, power | `simulation-designer` | `empirical-playbook` |
| Equilibrium, Nash, entry, auction | `equilibrium-analyst` | `game-theory` |
| Data quality, merge, panel, missing | `data-detective` | — |
| Literature, citations, related work | `literature-scout` | — |
| Estimator choice, packages, benchmarks | `methods-explorer` | `structural-modeling` |
| Pipeline, seeds, versions, replication | `reproducibility-auditor` | `reproducible-pipelines` |
| Tables, figures, LaTeX output | `results-verifier` | `publication-output` |
| Journal, referee, submission, R&R | `journal-referee` | `submission-guide` |
| Workflow coordination, next steps | `workflow-coordinator` | `swarm-orchestration` |

## Ambient Hooks

7 hooks covering 14 domain categories:
- **SessionStart** — Detects project type (empirical/paper), estimation language, data/pipeline presence
- **UserPromptSubmit** — Injects domain context across 14 categories (Haiku classifier)
- **PostToolUse** — Fires on Write/Edit for research artifacts: estimation code, proofs, pipelines, Bayesian code (Haiku classifier)
- **Stop** — Cross-cutting completeness checks: unvalidated merges (blocking), sensitivity analysis, replication package, DiD pre-trends, IV first-stage (suggestions). Domain-specific checks (SEs, seeds, regularity conditions) are scoped to agent frontmatter (Sonnet)
- **PreCompact** — Preserves 10 categories of research state before context compaction
- **PreToolUse** — Guards bash commands: unseeded estimation scripts, absolute paths, unversioned pip install
- **SubagentStop** — Severity-routed next steps: identification failure → numerical instability → wrong SEs → robustness

## Integration

Works alongside optional companions: commit-commands (git), document-skills (docs), context7 (framework docs), pyright-lsp (Python types). No external plugins are required.

## Development

### Directory Structure
```
.claude-plugin/   plugin.json manifest (must stay at repo root)
agents/
  review/         9 domain-specific review agents
  research/       3 literature and data investigation agents
  workflow/       2 process and coordination agents
commands/
  workflows/      5 workflow commands (brainstorm, plan, work, review, compound)
  *.md            11 commands (2 wrappers + 2 chain + 7 deprecated stubs)
skills/           17 skill directories (each has SKILL.md; 9 have references/)
hooks/            hooks.json + session-start.sh
docs/solutions/   reusable solutions by category (data, estimation, identification, numerical)
.tests/           test suite (dev-only, hidden from users)
.evals/           evaluation harness (dev-only, hidden from users)
.github/workflows/ CI pipeline (JSON validation + test suite)
```

### Testing
- Run: `bash .tests/run-all.sh`
- Selective: `bash .tests/run-all.sh 07` runs a single group; `--list` shows all groups
- Reports are gitignored at `.tests/reports/`

### CI
- GitHub Actions runs on push/PR to `main` (`.github/workflows/ci.yml`)
- Validates JSON (plugin.json, hooks.json) then runs full test suite

### Critical Invariants
- **Flat repo structure**: `.claude-plugin/plugin.json` must be at repo root — not nested in a subdirectory.
- **Version bumping required for updates**: Claude Code caches plugins; users only get updates if `version` in `plugin.json` is incremented.
- **Hook wrapper format**: `hooks.json` requires the `{"description":"...","hooks":{...}}` envelope. Missing the outer wrapper silently disables all hooks.
- **Dev-only dirs are hidden**: `.tests/` and `.evals/` start with `.` so they don't appear in the default file tree for users who install the plugin.
- **grep -P unavailable on macOS**: Use `python3 -c "import re; ..."` for Perl-compatible regex.
- **Chain command frontmatter**: `/lfg` and `/slfg` use `disable-model-invocation: true` so they delegate to sub-commands without an extra model call.

## Domain Keywords

Academic Writing, Applied Micro, Applied Statistics, Business Analytics, Causal Inference, Data Engineering, Data Science, Economic Research, Empirical Methods, Empirical Microdata, Empirical Reasoning, Equilibrium Reasoning, Game Theory, Identification Arguments, Identification Proofs, Mathematical Equilibrium, Mathematical Modeling, Reproducible Pipelines, Structural Econometrics, Structural Estimation, Structural Modeling.
