# Changelog

All notable changes to compound-science are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning follows [Semantic Versioning](https://semver.org/).

## [0.4.4] - 2026-03-09

### Changed
- **Progressive disclosure for 8 skills**: Moved deep reference content (code examples, full API tables, per-method implementation details) to `references/` subdirectories, keeping SKILL.md files lean (197–358 lines). All 237 tests pass. Skills affected:
  - `causal-ml` (1,049 → 358 lines): created `references/dml.md`, `references/grf-meta-learners.md`, `references/high-dim-cross-fitting.md`
  - `game-theory` (1,179 → 316 lines): created `references/equilibrium-computation.md`, `references/io-applications.md`, `references/estimation-diagnostics.md`
  - `reproducible-pipelines` (787 → 323 lines): created `references/stata-and-crosslang.md`, `references/environment-and-seeds.md`, `references/replication-package.md`
  - `bayesian-estimation` (850 → 220 lines): created `references/implementation.md`, `references/diagnostics-guide.md`, `references/structural-models.md`
  - `empirical-playbook` (643 → 250 lines): created `references/reporting-standards.md`
  - `submission-guide` (544 → 264 lines): created `references/journal-profiles.md`, `references/referee-tactics.md`
  - `causal-inference` (591 → 224 lines): created `references/method-implementations.md`, `references/staggered-did.md`, `references/synthetic-control.md`
  - `structural-modeling` (599 → 197 lines): created `references/estimation-methods.md`, `references/diagnostics-and-se.md`, `references/jax-guide.md`
- 21 reference files total, 4,708 total SKILL.md lines (down from ~8,200)

## [0.4.3] - 2026-03-09

### Changed
- **`UserPromptSubmit` hook**: Added category 14 — DESIGN BEFORE RESULTS. Fires when the user asks whether an estimate is reasonable, large, or significant before the identification design has been validated. Injects Cunningham's norm: evaluate whether assumptions hold before evaluating magnitudes. Directs to `/identify` or `identification-critic`.
- **`Stop` hook**: Added two method-specific suggestion checks (items 9-10):
  - Item 9: DiD estimation without pre-trends — triggers when DiD code appears in the conversation but no event-study or parallel trends test is visible; suggests CS21/SA21/BJS24 for staggered DiD
  - Item 10: IV/2SLS without first-stage diagnostics — triggers when IV estimation appears but no first-stage F is discussed; directs to Montiel Olea-Pflueger effective F (not Stock-Yogo)
  - Updated blocking rule: items 5-10 are suggestion-only (was: items 5-8)

## [0.4.2] - 2026-03-09

### Added
- **`econometric-reviewer` agent**: method-specific checklists for staggered DiD (CS21/SA21/BJS24/dCDH20, forbidden comparisons, Goodman-Bacon decomposition), IV/2SLS (Montiel Olea-Pflueger effective F, Anderson-Rubin CIs, LATE vs ATE distinction), RDD (rdrobust MSE-optimal bandwidth, rddensity, Gelman-Imbens polynomial guidance, placebo cutoffs), and R package API gotchas (`did`/`fastdid`, `rdrobust`, `clubSandwich`, `felm` deprecation). Also adds mandatory sanity check gate (sign/magnitude/dynamics plausibility before any robustness discussion) and explicit causal language audit (hedging must match identification design strength)
- **`journal-referee` agent**: journal-specific calibration profiles for 11 journals: Top-5/General Interest (AER, ECMA, JPE, QJE, REStud) with referee culture notes; Applied/Policy (AEJ-Applied, AEJ-Policy, JHR, JHE, RAND, JPubE)
- **`numerical-auditor` agent**: cross-language replication protocol — R/Stata/Python orthogonality of hallucination errors, 6-decimal-place tolerance thresholds, language-specific trap table, discrepancy classification (EXACT/NUMERICAL/EQUIVALENT/DISCREPANT)
- **`reproducible-pipelines` skill**: Stata-to-R tolerance threshold table (integers = exact, point estimates < 0.01, SEs < 0.05) and trap table (8 known systematic discrepancy sources: clustering df, `areg` vs `feols`, bootstrap seed, probit MFX, multi-way clustering, wild cluster bootstrap, time-series operators, panel balance)
- **New skill: `data-acquisition`** — FRED API (800k+ series, vintage/ALFRED real-time data, built-in transformations, GeoFRED) and World Bank API (240+ cross-national indicators), with curated series dictionaries, panel assembly best practices, and missingness auditing. Fills a genuine gap: no prior skill covered programmatic macroeconomic data access
- **New skill: `referee-response`** — Structured author response workflow: comment classification (7 types), point-by-point format templates (accept/partial/decline), identification challenge protocol with 7 robustness response types, journal-specific tone calibration, cover letter template, multi-round revision tracking. Fills an ecosystem-wide gap — no existing tool covered response drafting
- **New command: `/deepen-plan`** — Enriches a research plan by spawning parallel specialist agents (literature-scout, identification-critic, benchmark-researcher, methods-explorer) with targeted research questions, then synthesizes findings back as `### Research Insights` subsections with `⚠️` flags for urgent items

## [0.4.1] - 2026-03-09

### Added
- `## Updating` section to `README.md`

### Changed
- All 20 agents: `description:` migrated to `>-` folded block format; `<example>` blocks moved into frontmatter; agent body cleared
- All 14 skill `SKILL.md` files: `description:` converted to `>-` format
- 13 commands: added `allowed-tools:` field (chain commands `lfg`/`slfg` excluded)
- `hooks/hooks.json`: `SessionStart` command updated from `scripts/session-init.sh` → `hooks/session-start.sh`
- `scripts/session-init.sh` relocated to `hooks/session-start.sh` (consistent with hook-script colocation convention)
- All test library files (`run-all.sh`, `lib/assert.sh`, `lib/fixtures.sh`): `#!/bin/bash` → `#!/usr/bin/env bash`
- Test `01-json-validity.sh`: version check corrected — now asserts semver version is present (not absent)

### Fixed
- Test files `03`, `06`, `07`, `12`: path references updated from `scripts/session-init.sh` to `hooks/session-start.sh`
- Test `03-script-integrity.sh`: stale display labels updated to `session-start.sh`
- Test `03-script-integrity.sh`: hardcoded-path and `grep -P` checks were vacuously passing after `scripts/` was deleted; now correctly scan `hooks/`
- Test `08-agent-organization.sh`: numbered-section regex anchored to `^` missed YAML-indented sections (2 spaces); removed anchor. Description keyword checks were reading only the `description: >-` line; now scan the full file
- `progress-tracker.md`: corrupt `0x08` (backspace) byte in `\begin{table}` — would break strict YAML parsers
- Test `01-json-validity.sh`: semver regex tightened from `re.match` to `re.fullmatch` — previously accepted non-semver suffixes

### Refactored
- `run-all.sh`: four `grep -c` passes over the report file replaced with a single `awk` pass; removed unused `all_reports` glob
- `hooks/session-start.sh`: `ls glob` calls replaced with `compgen -G` (bash builtin, no subprocess); four sequential `echo >> ENV_FILE` writes batched into one grouped redirect
- `fixtures.sh`: four `grep | sed` pipelines for env-file parsing replaced with a single `while read` loop
- `12-hook-integration.sh`: agent name list was duplicated verbatim in bash and Python; now exports `AGENT_NAMES_STR` once and reads via `os.environ` in the Python block

## [0.4.0] - 2025-03-04

### Added
- **4 new skills**: `causal-ml` (Double ML, causal forests, DR-Learner), `game-theory` (Nash/SPE/BNE, entry models, conduct testing), `identification-proofs` (7-step canonical structure, regularity conditions checklist), `bayesian-estimation` (Stan/PyMC/Numpyro, MCMC diagnostics)
- `SubagentStop` hook: multi-critical prioritization (identification failure → numerical instability → wrong SEs → robustness)
- `research-coordinator` agent: formal Coordination Handoff and Triage Summary output templates
- `progress-tracker` agent: fallback detection strategy when `docs/` is absent (git log, file timestamps, glob)

### Changed
- `UserPromptSubmit`: added "fragile", "fragile results", "my results are sensitive" trigger words
- `PostToolUse`: added category 11 for Bayesian/probabilistic code (pymc, numpyro, cmdstanpy, stan, brms)
- `PreToolUse`: added rule 5 guarding unseeded `dvc repro`/`snakemake` execution
- `PreCompact`: added items 9 (software environment versions) and 10 (failed approaches) to preserved state
- `reproducible-pipelines` skill: full Stata section + enhanced DVC (remote storage, `dvc dag/params/metrics`, experiment strategies)

## [0.3.0] - 2025-01-15

### Added
- Output discipline enforcement across all agents
- `docs/solutions/` directory for compound knowledge accumulation
- Eval harness (`.evals/`) for automated quality testing
- `solutions-archivist` research agent
- `progress-tracker` and `research-coordinator` workflow agents

### Changed
- Test suite expanded to 12 groups with 230+ assertions
- Hook coverage extended across all 7 lifecycle events

## [0.2.0] - 2024-12-01

### Changed
- Agent renames for naming consistency:
  - `econometrician` → `econometric-reviewer`
  - `referee` → `journal-referee`
  - `monte-carlo-designer` → `simulation-designer`
  - `spec-flow-analyzer` → `specification-analyzer`
  - `learnings-researcher` → `solutions-archivist`
- Skill renames: `setup` → `project-setup`, `orchestrating-swarms` → `swarm-orchestration`

## [0.1.0] - 2024-11-01

### Added
- Initial release: 10 review agents, 3 research agents, 3 workflow agents
- 10 skills covering structural modeling, causal inference, reproducible pipelines
- 5 workflow commands (`/workflows:brainstorm`, `plan`, `work`, `review`, `compound`)
- 5 utility commands (`/estimate`, `/simulate`, `/identify`, `/diagnose`, `/tabulate`)
- 7 ambient hooks (SessionStart through SubagentStop)
- `/lfg` and `/slfg` chain commands
