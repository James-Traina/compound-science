# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2026-03-02

### Added
- 2 new hooks: PreToolUse (Bash reproducibility guard), SubagentStop (next-step advisor)
- 5 utility commands: `/diagnose`, `/tabulate`, `/replicate`, `/visualize`, `/stress-test`
- 3 new agents: calibration-assessor (review), results-verifier (review), benchmark-researcher (research)
- 2 new skills: submission-guide, empirical-playbook
- CONTRIBUTING.md with PR checklist and known gotchas
- GitHub Actions CI workflow (runs test suite on PR/push)
- Test count guard in runner (detects silently-crashed test scripts)

### Changed
- Agent categories reorganized: review (10), research (5), workflow (5)
- All agents/skills standardized to `word-word` kebab-case naming
- All review agents have SCOPE + CORE PHILOSOPHY sections with FAIL/PASS markers
- All research agents have GUARDRAILS and OUTPUT FORMAT sections
- Hook prompts expanded with macro/DP keywords (Bellman, VFI, calibrate, etc.)
- Test suite expanded: 12 groups, 240 tests (from 120 in v0.1.0)

### Fixed
- Test runner crash on non-matching group arg (`set -u` unbound variable)
- Shell-to-Python injection in test 14 (now uses `os.environ`)
- `set -e` trap in test 6 (skill overlap check)
- Skill trigger overlap test: strips YAML frontmatter before word extraction

## [0.2.0] - 2026-03-01

### Added
- Expanded to 50 components (20 agents, 15 commands, 10 skills, 5 hooks)
- Utility commands: diagnose, tabulate, replicate, visualize, stress-test
- Agent categories: review, research, workflow
- Test suite: 200 tests across 10 groups

## [0.1.0] - 2026-02-28

### Added
- Initial release: 5 workflow commands, 10 agents, 5 skills, 3 hooks
- Core loop: plan, work, review, compound
- Domain commands: estimate, simulate, identify
