# Changelog

All notable changes to compound-science are documented here.

## [0.4.0] — 2025-03-04

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

## [0.3.0] — 2025-01-15

### Added
- Output discipline enforcement across all agents
- `docs/solutions/` directory for compound knowledge accumulation
- Eval harness (`.evals/`) for automated quality testing
- `solutions-archivist` research agent
- `progress-tracker` and `research-coordinator` workflow agents

### Changed
- Test suite expanded to 12 groups with 230+ assertions
- Hook coverage extended across all 7 lifecycle events

## [0.2.0] — 2024-12-01

### Changed
- Agent renames for naming consistency:
  - `econometrician` → `econometric-reviewer`
  - `referee` → `journal-referee`
  - `monte-carlo-designer` → `simulation-designer`
  - `spec-flow-analyzer` → `specification-analyzer`
  - `learnings-researcher` → `solutions-archivist`
- Skill renames: `setup` → `project-setup`, `orchestrating-swarms` → `swarm-orchestration`

## [0.1.0] — 2024-11-01

### Added
- Initial release: 10 review agents, 3 research agents, 3 workflow agents
- 10 skills covering structural modeling, causal inference, reproducible pipelines
- 5 workflow commands (`/workflows:brainstorm`, `plan`, `work`, `review`, `compound`)
- 5 utility commands (`/estimate`, `/simulate`, `/identify`, `/diagnose`, `/tabulate`)
- 7 ambient hooks (SessionStart through SubagentStop)
- `/lfg` and `/slfg` chain commands
