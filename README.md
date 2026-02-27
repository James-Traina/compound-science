# compound-science

A Claude Code plugin for quantitative social science research: structural econometrics, causal inference, game theory, identification arguments, Monte Carlo studies, and reproducible pipelines.

Every time you solve a methodological problem (a convergence fix, an identification argument, a numerical issue), that solution gets documented and made findable. The next project starts where the last one left off.

## How it works

The core loop is Plan, Work, Review, Compound, Repeat.

You describe a research task. The plugin plans an approach, executes it with convergence monitoring and quality gates, runs domain-specific review agents (an econometrician checks your identification, a numerical auditor checks your floating-point stability, a referee tries to reject your paper), and extracts reusable solutions into a knowledge base at `docs/solutions/`.

Workflow commands chain the steps. `/lfg` runs the full loop autonomously; `/slfg` runs review and compound in parallel using agent swarms. Domain commands handle specific tasks: `/estimate` runs a complete estimation pipeline from data validation through robustness checks, `/simulate` designs Monte Carlo studies, `/identify` formalizes identification arguments. Ambient hooks run without being invoked: when you write estimation code the plugin offers relevant agents, and when a session ends it checks for missing standard errors or RNG seeds.

## Install

```bash
claude plugin install https://github.com/James-Traina/Compound-Science
```

Or from a local clone:

```bash
claude plugin install /path/to/Compound-Science
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

# Domain-specific commands
/estimate run 2SLS with Bartik instruments
/simulate Monte Carlo for DiD with staggered adoption
/identify formalize the identification argument for auction model
```

## Commands

### Workflow

| Command | What it does |
|---------|-------------|
| `/workflows:brainstorm` | Explore research approaches with methods-researcher and literature-scout agents |
| `/workflows:plan` | Create implementation plans (auto-selects MINIMAL / MORE / A LOT detail level) |
| `/workflows:work` | Execute the plan with quality gates and convergence monitoring |
| `/workflows:review` | Multi-agent parallel review (econometrician, numerical-auditor, identification-critic, referee) |
| `/workflows:compound` | Extract reusable solutions into `docs/solutions/` by category |
| `/lfg` | Chain all four steps automatically |
| `/slfg` | Same as `/lfg` with parallel swarm execution for review and compound |

### Domain

| Command | What it does |
|---------|-------------|
| `/estimate` | Run structural estimation pipeline: data validation, identification check, estimation with convergence monitoring, proper standard errors, automated robustness checks, formatted results |
| `/simulate` | Design and run Monte Carlo studies: DGP specification, parameter selection, simulation execution, bias/RMSE/coverage metrics, results tables |
| `/identify` | Formalize identification arguments: target parameter, model specification, derivation, regularity conditions, link to estimation |

## Agents (15)

Organized by role. Each runs as a specialized subagent with deep domain knowledge.

### Review — domain-specific code review

| Agent | What it checks |
|-------|---------------|
| `econometrician` | Identification strategy, endogeneity concerns, standard error computation, asymptotic properties, instrument validity |
| `mathematical-prover` | Proof steps, completeness, regularity conditions, fixed-point arguments, quantifier ordering |
| `numerical-auditor` | Floating-point stability, convergence, RNG seeding, matrix conditioning, gradient accuracy |
| `identification-critic` | Identification argument completeness, exclusion restrictions, support conditions, point vs set identification |
| `referee` | Adversarial journal referee simulation — contribution, literature gaps, robustness, external validity |

### Research — literature and data investigation

| Agent | What it does |
|-------|-------------|
| `literature-scout` | Systematic search for related methods, seminal papers, prior applications, intellectual genealogy |
| `methods-researcher` | Deep dive into estimator properties, computational considerations, software implementations |
| `data-detective` | Data quality investigation — distributions, missingness, duplicates, panel structure, merge validation |
| `learnings-researcher` | Search `docs/solutions/` for past methodological solutions and patterns |

### Methods — methodology-specific

| Agent | What it does |
|-------|-------------|
| `monte-carlo-designer` | Design simulation studies — DGPs, sample sizes, replications, bias/RMSE/coverage metrics |
| `dgp-architect` | Formalize data generating processes from structural models, verify equilibrium computation |
| `equilibrium-analyst` | Verify equilibrium existence, uniqueness, stability, comparative statics |

### Workflow — process and reproducibility

| Agent | What it does |
|-------|-------------|
| `pipeline-validator` | Validate reproducible pipelines — no manual steps, seeds set, versions pinned, relative paths |
| `reproducibility-checker` | Pre-submission replication package verification |
| `spec-flow-analyzer` | Analyze specification flow from model to estimator to code |

## Skills (8)

Domain knowledge and methodology references.

| Skill | Content |
|-------|---------|
| `structural-modeling` | NFXP, MPEC, BLP, dynamic discrete choice, auction models — from model specification through estimation |
| `causal-inference` | IV/2SLS/GMM, DiD (including staggered), RDD, synthetic control, matching estimators |
| `reproducible-pipelines` | Makefile/Snakemake/DVC patterns, environment management, replication package standards |
| `brainstorming` | Structured research brainstorming techniques for methodology selection |
| `compound-docs` | Solution documentation patterns by category (estimation, data, numerical, methodology) |
| `git-worktree` | Parallel branches for concurrent estimation runs and specification comparisons |
| `orchestrating-swarms` | Multi-agent parallel orchestration patterns for `/slfg` |
| `setup` | Configure `compound-science.local.md` for project-specific settings |

## Ambient Hooks (5)

The plugin detects research context automatically. Nothing to invoke.

| Hook | When it fires | What it does |
|------|--------------|-------------|
| **SessionStart** | Session opens | Detects project type (empirical/paper), estimation language, data/pipeline presence |
| **UserPromptSubmit** | Every prompt | Injects domain context when research terminology is detected (7 categories) |
| **PostToolUse** | After Write/Edit | Suggests relevant agents after writing estimation, simulation, or proof code |
| **Stop** | Session ends | Checks for missing critical steps (standard errors, seeds, regularity conditions) |
| **PreCompact** | Context compaction | Preserves research state summary (identification progress, results, proof status) |

## Configuration

Create `compound-science.local.md` in your project's `.claude/` directory to configure which review agents run, your default estimation language, project type, and data sensitivity level. Run the `setup` skill for a walkthrough.

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
| Agents | 15 (5 review + 4 research + 3 methods + 3 workflow) |
| Commands | 10 (5 workflow + 3 domain + 2 meta) |
| Skills | 8 |
| Hooks | 5 |
| **Total** | **38 components** |

## Layout

```
.claude-plugin/ plugin.json (manifest — must be at repo root for install to work)
agents/
  review/       econometrician, mathematical-prover, numerical-auditor, identification-critic, referee
  research/     literature-scout, methods-researcher, data-detective, learnings-researcher
  methods/      monte-carlo-designer, dgp-architect, equilibrium-analyst
  workflow/     pipeline-validator, reproducibility-checker, spec-flow-analyzer
commands/
  workflows/    brainstorm, plan, work, review, compound
  estimate, simulate, identify, lfg, slfg
skills/         8 domain knowledge bases with reference material
hooks/          hooks.json (5 ambient hooks)
scripts/        session-init.sh
test/           235 tests across 8 groups (dev-only)
```

## Testing

```bash
bash test/run-all.sh              # Run all 235 tests
bash test/run-all.sh 07           # Run a specific test group
bash test/run-all.sh --list       # List available test groups
```

## Background

This plugin grew out of [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by Every Inc, which codified web development workflows for Claude Code. The core loop — plan, work, review, compound — maps well onto quantitative research, where the same convergence problems, identification pitfalls, and numerical issues recur across projects.

The main adaptation was swapping web-focused agents for domain-specific ones: an econometrician instead of a frontend reviewer, a numerical auditor instead of a performance profiler. The research commands (`/estimate`, `/simulate`, `/identify`) and the ambient hooks (which watch for estimation packages, LaTeX files, and data directories) were added on top.

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

## License

MIT
