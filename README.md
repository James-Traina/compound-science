# compound-science

A Claude Code plugin for quantitative social science research: structural econometrics, causal inference, game theory, applied micro, identification arguments, Monte Carlo studies, and reproducible pipelines.

Every time you solve a methodological problem (a convergence fix, an identification argument, a numerical issue), that solution gets documented and made findable. The next project starts where the last one left off.

## How it works

The core loop is Plan, Work, Review, Compound, Repeat.

You describe a research task. The plugin plans an approach, executes it with convergence monitoring and quality gates, runs domain-specific review agents (an econometric-reviewer checks your identification, a numerical auditor checks your floating-point stability, a journal-referee tries to reject your paper), and extracts reusable solutions into a knowledge base at `docs/solutions/`.

Workflow commands chain the steps. `/lfg` runs the full loop autonomously; `/slfg` runs review and compound in parallel using agent swarms. Domain commands handle specific tasks: `/estimate` runs a complete estimation pipeline, `/simulate` designs Monte Carlo studies, `/identify` formalizes identification arguments. Utility commands handle output: `/diagnose` runs diagnostic batteries, `/tabulate` generates publication-ready tables, `/visualize` creates research figures, `/stress-test` runs formal robustness analysis, `/replicate` builds AEA-compliant replication packages. Ambient hooks run without being invoked: when you write estimation code the plugin offers relevant agents, and when a session ends it checks for missing standard errors or RNG seeds.

## Install

```bash
claude plugin install https://github.com/James-Traina/compound-science
```

Or from a local clone:

```bash
claude plugin install /path/to/compound-science
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
```

## Commands

### Workflow

| Command | What it does |
|---------|-------------|
| `/workflows:brainstorm` | Explore research approaches with methods-explorer and literature-scout agents |
| `/workflows:plan` | Create implementation plans (auto-selects MINIMAL / MORE / A LOT detail level) |
| `/workflows:work` | Execute the plan with quality gates and convergence monitoring |
| `/workflows:review` | Multi-agent parallel review (econometric-reviewer, numerical-auditor, identification-critic, journal-referee) |
| `/workflows:compound` | Extract reusable solutions into `docs/solutions/` by category |
| `/lfg` | Chain all four steps automatically |
| `/slfg` | Same as `/lfg` with parallel swarm execution for review and compound |

### Domain

| Command | What it does |
|---------|-------------|
| `/estimate` | Run structural estimation pipeline: data validation, identification check, estimation with convergence monitoring, proper standard errors, automated robustness checks, formatted results |
| `/simulate` | Design and run Monte Carlo studies: DGP specification, parameter selection, simulation execution, bias/RMSE/coverage metrics, results tables |
| `/identify` | Formalize identification arguments: target parameter, model specification, derivation, regularity conditions, link to estimation |

### Utility

| Command | What it does |
|---------|-------------|
| `/diagnose` | Run diagnostic battery on estimation results: specification tests, instrument diagnostics, residual analysis, model fit assessment |
| `/tabulate` | Generate publication-ready tables: regression results, summary statistics, Monte Carlo output, balance tables |
| `/replicate` | Build and verify AEA-compliant replication packages: inventory, README, dependency audit, pipeline verification, data documentation |
| `/visualize` | Generate publication-quality research visualization code: event studies, RD plots, coefficient plots, power curves, densities |
| `/stress-test` | Run sensitivity analysis on causal estimates: Oster bounds, Conley et al. bounds, breakdown frontier, specification curve |

## Agents (20)

Organized by role. Each runs as a specialized subagent with deep domain knowledge.

### Review (10) — domain-specific code review and methodology verification

| Agent | What it checks |
|-------|---------------|
| `econometric-reviewer` | Identification strategy, endogeneity concerns, standard error computation, asymptotic properties, instrument validity |
| `mathematical-prover` | Proof steps, completeness, regularity conditions, fixed-point arguments, quantifier ordering |
| `numerical-auditor` | Floating-point stability, convergence, RNG seeding, matrix conditioning, gradient accuracy |
| `identification-critic` | Identification argument completeness, exclusion restrictions, support conditions, point vs set identification |
| `journal-referee` | Adversarial journal referee simulation — contribution, literature gaps, robustness, external validity |
| `simulation-designer` | Design simulation studies — DGPs, sample sizes, replications, bias/RMSE/coverage metrics |
| `process-architect` | Formalize data generating processes from structural models, verify equilibrium computation |
| `equilibrium-analyst` | Verify equilibrium existence, uniqueness, stability, comparative statics |
| `calibration-assessor` | Calibration/moment-matching strategy, parameter identification from moments, sensitivity to targets |
| `results-verifier` | Audit reported results against code output — table accuracy, text consistency, significance stars |

### Research (5) — literature and data investigation

| Agent | What it does |
|-------|-------------|
| `literature-scout` | Systematic search for related methods, seminal papers, prior applications, intellectual genealogy |
| `methods-explorer` | Deep dive into estimator properties, computational considerations, software implementations |
| `data-detective` | Data quality investigation — distributions, missingness, duplicates, panel structure, merge validation |
| `solutions-archivist` | Search `docs/solutions/` for past methodological solutions and patterns |
| `benchmark-researcher` | Research calibration targets, stylized facts, reference parameter values from the economics literature |

### Workflow (5) — process, reproducibility, and coordination

| Agent | What it does |
|-------|-------------|
| `pipeline-validator` | Validate reproducible pipelines — no manual steps, seeds set, versions pinned, relative paths |
| `reproducibility-checker` | Pre-submission replication package verification |
| `specification-analyzer` | Analyze specification flow from model to estimator to code |
| `research-coordinator` | Coordinate multi-agent research workflows, manage handoffs between estimation/simulation/identification phases |
| `progress-tracker` | Track research progress, maintain running checklist of completed and pending research steps |

## Skills (14)

Domain knowledge and methodology references.

| Skill | Content |
|-------|---------|
| `structural-modeling` | NFXP, MPEC, BLP, dynamic discrete choice, auction models — from model specification through estimation |
| `causal-inference` | IV/2SLS/GMM, DiD (including staggered), RDD, synthetic control, matching estimators |
| `causal-ml` | Double ML (Chernozhukov et al.), causal forests (GRF), DR-Learner, post-double-selection LASSO, heterogeneous treatment effects |
| `game-theory` | Nash/SPE/BNE equilibria, entry models (Bresnahan-Reiss, Ciliberto-Tamer), conduct testing, bargaining, multiple equilibria problem |
| `identification-proofs` | Formal identification argument architecture: target parameter → model primitives → rank conditions → regularity conditions → estimation link |
| `bayesian-estimation` | MCMC (Stan/PyMC/Numpyro), prior elicitation, MCMC diagnostics (R-hat, ESS, divergences), Bayesian structural models |
| `reproducible-pipelines` | Makefile/Snakemake/DVC patterns, Stata pipelines (master.do, batch mode), environment management, replication package standards |
| `strategy-brainstorm` | Structured research brainstorming techniques for methodology selection |
| `compound-catalog` | Solution documentation patterns by category (estimation, data, numerical, methodology) |
| `git-worktree` | Parallel branches for concurrent estimation runs and specification comparisons |
| `swarm-orchestration` | Multi-agent parallel orchestration patterns for `/slfg` |
| `project-setup` | Configure `compound-science.local.md` for project-specific settings |
| `submission-guide` | Pre-submission checklists, journal-specific formatting for 20+ journals, referee response strategy, revision management |
| `empirical-playbook` | Method selection decision tree, estimator comparison, diagnostics by method, power analysis, minimum reporting standards |

## Ambient Hooks (7)

The plugin detects research context automatically. Nothing to invoke.

| Hook | When it fires | What it does |
|------|--------------|-------------|
| **SessionStart** | Session opens | Detects project type (empirical/paper), estimation language, data/pipeline presence |
| **UserPromptSubmit** | Every prompt | Injects domain context across 13 categories: identification, estimation, simulation, proof, equilibrium, pipeline, data, diagnostics, tables, replication, sensitivity, submission, convergence |
| **PostToolUse** | After file write/edit | Suggests relevant agents after writing estimation (Python/R/Stata/Julia), simulation, proof, pipeline, or manuscript code |
| **Stop** | Session ends | Checks 8 completeness conditions (standard errors, convergence, seeds, merge validation, results saved, sensitivity, replication, diagnostics) |
| **PreCompact** | Context compaction | Preserves 10 categories of research state (identification, estimation, proof, pipeline, methodology, sensitivity, diagnostics, submission, software environment, failed approaches) |
| **PreToolUse** | Before Bash | Guards reproducibility: missing seeds, absolute paths, unversioned pip installs, uncaptured output |
| **SubagentStop** | After agent completes | Suggests next steps: fixes for review findings, follow-ups for research results, commands for workflow gaps |

## Configuration

Create `compound-science.local.md` in your project's `.claude/` directory to configure which review agents run, your default estimation language, project type, and data sensitivity level. Run the `project-setup` skill for a walkthrough.

## Integration

This plugin is designed to work alongside:

| Plugin | What it provides | How compound-science uses it |
|--------|-----------------|----------------------------|
| `pr-review-toolkit` | Generic code review | `/workflows:review` delegates non-domain checks to it |
| `commit-commands` | Git commit/push/PR | Workflow commands use git operations |
| `document-skills` | PDF, XLSX, DOCX | Results export |
| `context7` | Framework docs | Library documentation lookup |
| `pyright-lsp` | Python type checking | Type validation in estimation code |

## Component Counts

| Category | Count |
|----------|-------|
| Agents | 20 (10 review + 5 research + 5 workflow) |
| Commands | 15 (5 workflow + 2 chain + 3 domain + 5 utility) |
| Skills | 14 |
| Hooks | 7 |
| **Total** | **56 components** |

## Layout

```
.claude-plugin/ plugin.json (manifest — must be at repo root for install to work)
marketplace.json (marketplace listing)
agents/
  review/       econometric-reviewer, mathematical-prover, numerical-auditor, identification-critic,
                journal-referee, simulation-designer, process-architect, equilibrium-analyst,
                calibration-assessor, results-verifier
  research/     literature-scout, methods-explorer, data-detective, solutions-archivist,
                benchmark-researcher
  workflow/     pipeline-validator, reproducibility-checker, specification-analyzer,
                research-coordinator, progress-tracker
commands/
  workflows/    brainstorm, plan, work, review, compound
  estimate, simulate, identify, lfg, slfg
  diagnose, tabulate, replicate, visualize, stress-test
skills/         14 domain knowledge bases with reference material
hooks/          hooks.json (7 ambient hooks, 13 domain categories)
scripts/        session-init.sh
.tests/         235 tests across 12 groups (dev-only, gitignored reports)
.evals/         evaluation harness (dev-only)
```

## Testing

```bash
bash .tests/run-all.sh              # Run all 235 tests
bash .tests/run-all.sh 07           # Run a specific test group
bash .tests/run-all.sh --list       # List available test groups
```

## Background & Attribution

This plugin is directly inspired by [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by [Every](https://every.to), which pioneered the compound workflow pattern for web development in Claude Code. The core loop — plan, work, review, compound — and the structural idea of ambient hooks that watch for domain artifacts both come from their work. compound-science adapts that pattern to quantitative social science research.

The main adaptation was swapping web-focused agents for domain-specific ones: an `econometric-reviewer` instead of a frontend reviewer, a `numerical-auditor` instead of a performance profiler. The research commands (`/estimate`, `/simulate`, `/identify`) and utility commands (`/diagnose`, `/tabulate`, `/replicate`, `/visualize`, `/stress-test`) handle domain-specific workflows that have no web equivalent, and the ambient hooks watch for estimation packages, LaTeX files, and data directories rather than JavaScript frameworks and API endpoints.

## Domain Keywords

This plugin activates when your work involves these areas:

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

## License

MIT
