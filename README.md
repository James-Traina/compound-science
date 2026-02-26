# compound-science

AI-powered research tools for structural econometrics, causal inference, and quantitative social science. Built on the compound principle: each unit of research work makes subsequent work easier through accumulated solutions in `docs/solutions/`.

## Install

```bash
# From GitHub
claude plugin install https://github.com/James-Traina/Compound-Science

# Or from a local clone
claude plugin install /path/to/Compound-Science
```

## Philosophy

Research is iterative. You estimate a model, discover a convergence problem, fix it, then realize the same problem appears in every BLP-style demand system. The compound workflow captures these solutions so they compound over time:

**Plan → Work → Review → Compound → Repeat**

Every review finding becomes a reusable solution document. Every identification argument gets formalized. Every numerical fix gets cataloged. The next project starts where the last one left off.

## Quick Start

```
# Full autonomous pipeline: plan → work → review → compound
/lfg estimate a BLP demand model for the cereal dataset

# Or step by step:
/workflows:brainstorm approaches for estimating entry games
/workflows:plan implement Rust-Nielson 2012 entry model
/workflows:work
/workflows:review
/workflows:compound

# Domain-specific commands:
/estimate run 2SLS with Bartik instruments
/simulate Monte Carlo for DiD with staggered adoption
/identify formalize the identification argument for auction model
```

## Workflow Commands

| Command | Purpose |
|---------|---------|
| `/workflows:brainstorm` | Explore research approaches with methods-researcher and literature-scout agents |
| `/workflows:plan` | Create implementation plans (auto-selects MINIMAL / MORE / A LOT detail level) |
| `/workflows:work` | Execute the plan with quality gates and convergence monitoring |
| `/workflows:review` | Multi-agent parallel review (econometrician, numerical-auditor, identification-critic, referee) |
| `/workflows:compound` | Extract reusable solutions into `docs/solutions/` by category |
| `/lfg` | Chain all four steps automatically (plan → work → review → compound) |
| `/slfg` | Same as /lfg with parallel swarm execution for review + compound |

## Domain Commands

| Command | Purpose |
|---------|---------|
| `/estimate` | Run structural estimation pipeline: data → identification → estimation → standard errors → robustness → results |
| `/simulate` | Design and run Monte Carlo studies: DGP → parameters → simulation → bias/RMSE/coverage → tables |
| `/identify` | Formalize identification arguments: target parameter → model → derivation → regularity conditions → estimation link |

## Agents (15)

### Review — Domain-Specific Code Review

| Agent | Role |
|-------|------|
| `econometrician` | Reviews identification strategy, endogeneity, standard errors, asymptotic properties, instrument validity |
| `mathematical-prover` | Verifies proof steps, completeness, regularity conditions, fixed-point arguments, quantifier ordering |
| `numerical-auditor` | Checks floating-point stability, convergence, RNG seeding, matrix conditioning, gradient accuracy |
| `identification-critic` | Evaluates identification argument completeness, exclusion restrictions, support conditions, point vs set ID |
| `referee` | Adversarial journal referee simulation — contribution, literature, robustness, external validity |

### Research — Literature & Data Investigation

| Agent | Role |
|-------|------|
| `literature-scout` | Systematic search for related methods, seminal papers, prior applications, intellectual genealogy |
| `methods-researcher` | Deep dive into estimator properties, computational considerations, software implementations |
| `data-detective` | Data quality investigation — distributions, missingness, duplicates, panel structure, merge validation |
| `learnings-researcher` | Search `docs/solutions/` for past methodological solutions and patterns |

### Methods — Methodology-Specific

| Agent | Role |
|-------|------|
| `monte-carlo-designer` | Design simulation studies — DGPs, sample sizes, replications, bias/RMSE/coverage metrics |
| `dgp-architect` | Formalize data generating processes from structural models, verify equilibrium computation |
| `equilibrium-analyst` | Verify equilibrium existence, uniqueness, stability, comparative statics |

### Workflow — Process & Reproducibility

| Agent | Role |
|-------|------|
| `pipeline-validator` | Validate reproducible pipelines — no manual steps, seeds set, versions pinned, relative paths |
| `reproducibility-checker` | Pre-submission replication package verification |
| `spec-flow-analyzer` | Analyze specification flow from model → estimator → code |

## Skills (8)

| Skill | Content |
|-------|---------|
| `structural-modeling` | NFXP, MPEC, BLP, dynamic discrete choice, auction models — model specification to estimation |
| `causal-inference` | IV/2SLS/GMM, DiD (including staggered), RDD, synthetic control, matching estimators |
| `reproducible-pipelines` | Makefile/Snakemake/DVC patterns, environment management, replication package standards |
| `brainstorming` | Structured research brainstorming techniques for methodology selection |
| `compound-docs` | Solution documentation patterns by category (estimation, data, numerical, methodology) |
| `git-worktree` | Parallel branches for concurrent estimation runs and specification comparisons |
| `orchestrating-swarms` | Multi-agent parallel orchestration patterns for /slfg |
| `setup` | Configure `compound-science.local.md` for project-specific settings |

## Ambient Hooks (5)

The plugin detects research context automatically — no explicit invocation needed:

| Hook | Trigger | Action |
|------|---------|--------|
| **SessionStart** | Session opens | Detects project type, estimation language, data/pipeline presence |
| **UserPromptSubmit** | Every prompt | Injects domain context when research terminology detected (7 categories) |
| **PostToolUse** | After Write/Edit | Suggests relevant agents after writing estimation/simulation/proof code |
| **Stop** | Session ends | Checks for missing critical steps (standard errors, seeds, regularity conditions) |
| **PreCompact** | Context compaction | Preserves research state summary (identification, results, proof progress) |

## Configuration

Create `compound-science.local.md` in your project's `.claude/` directory to customize:

- Which review agents run by default
- Default estimation language (Python/R/Julia/Stata)
- Project type (empirical paper, methodology paper, software package)
- Data sensitivity level

Run the `setup` skill for guided configuration.

## Integration

This plugin works alongside your existing plugins without duplicating their functionality:

| Plugin | Provides | Compound-Science Uses |
|--------|----------|-----------------------|
| `pr-review-toolkit` | Generic code review | `/workflows:review` delegates generic checks to it |
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

## Domain Keywords

This plugin activates when your work involves these areas:

| Domain | Keywords |
|--------|----------|
| Structural Econometrics & Estimation | NFXP, MPEC, BLP, nested fixed point, structural estimation, structural modeling |
| Causal Inference & Empirical Methods | IV, 2SLS, GMM, DiD, RDD, synthetic control, matching, empirical methods, empirical reasoning |
| Identification | exclusion restriction, instrument, rank condition, identification arguments, identification proofs |
| Game Theory & Equilibrium | Nash equilibrium, best response, entry game, auction, equilibrium reasoning, mathematical equilibrium |
| Mathematical Modeling & Simulation | existence, uniqueness, fixed point, contraction mapping, Monte Carlo, DGP, RMSE, coverage |
| Data Science & Engineering | panel data, cross-section, merge validation, imputation, data engineering, empirical microdata |
| Reproducible Pipelines | Makefile, Snakemake, DVC, replication package, version pinning |
| Applied Statistics | MLE, maximum likelihood, bootstrap, clustering, standard errors, business analytics |
| Economic Research & Writing | academic writing, literature review, referee response, empirical microdata |

## QA

Run the test suite before releasing:

```bash
./qa/run-all.sh              # Run all 286 tests
./qa/run-all.sh 07           # Run specific test group
./qa/run-all.sh --list       # List available test groups
```

## Acknowledgments

Ported from [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by Every Inc. The original plugin codified web development workflows; this adaptation reimagines the compound principle for quantitative social science research.

## License

MIT
