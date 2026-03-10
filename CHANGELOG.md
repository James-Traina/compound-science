# Changelog

All notable changes to compound-science are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning follows [Semantic Versioning](https://semver.org/).

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
