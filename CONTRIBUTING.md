# Contributing to compound-science

## Development Setup

Clone the repo and run the test suite:

```bash
git clone https://github.com/James-Traina/compound-science.git
cd compound-science
bash .tests/run-all.sh
```

## Directory Structure

See [README.md](README.md#layout) for the full layout. Key rules:

- `.claude-plugin/plugin.json` must stay at the repo root (flat structure required)
- Dev-only directories (`.tests/`, `.evals/`) are dot-prefixed to stay hidden from plugin users
- Test reports go to `.tests/reports/` (gitignored)

## Testing

```bash
bash .tests/run-all.sh              # Run full suite
bash .tests/run-all.sh 07           # Run a single group
bash .tests/run-all.sh --list       # List available groups
```

## Known Gotchas

- **`grep -P` unavailable on macOS**: Use `python3 -c "import re; ..."` for Perl-compatible regex
- **QA self-scanning**: Content greps must use `--exclude-dir=.tests,.evals,.ralph,.serena,.git,.claude` to avoid false positives from test fixtures
- **Hook wrapper format**: `hooks.json` requires the `{"description":"...","hooks":{...}}` envelope; missing the outer wrapper silently disables all hooks
- **`grep -c` trap**: `$(grep -c pattern file || echo "0")` is wrong -- grep outputs "0" even on failure, so `|| echo "0"` appends a second zero
- **bash 3 on macOS**: No `declare -A` (associative arrays); use `case` statements for key-value mappings in test scripts
- **Hook prompt bloat limit**: Test 12 fires a should-fix WARN for any hook prompt exceeding 5000 chars
- **Version bumping required**: Claude Code caches plugins; users only see updates if `version` in `plugin.json` is incremented

## Versioning

Bump the `version` field in `.claude-plugin/plugin.json` for every release. Users apply updates with `/plugin update compound-science`.

## v0.5 Migration Notes

### Component count: 59 --> 47

| Category | v0.4.4 | v0.5 | Change |
|----------|--------|------|--------|
| Agents | 20 (10 review + 5 research + 5 workflow) | 14 (9 review + 3 research + 2 workflow) | -6 |
| Skills | 16 | 17 | +1 |
| Commands | 16 (5 workflow + 2 chain + 3 domain + 6 utility) | 9 canonical (5 workflow + 2 wrappers + 2 chain) + 7 deprecated stubs | -7 active |
| Hooks | 7 | 7 | 0 |
| **Total** | **59** | **47 active** | **-12** |

### Key merges

- **calibration-assessor + specification-analyzer --> econometric-reviewer**: Calibration strategy (moment selection, sensitivity to targets) and specification flow (model to estimator to code) are now part of the econometric-reviewer's scope.
- **benchmark-researcher --> methods-explorer**: Benchmark parameter research and calibration target lookup merged into methods-explorer, which already covered estimator properties and software implementations.
- **pipeline-validator + reproducibility-checker --> reproducibility-auditor**: Structural pipeline checks and AEA replication package auditing combined into a single agent.
- **research-coordinator + progress-tracker --> workflow-coordinator**: Multi-agent dispatch, triage, and progress tracking consolidated into one workflow agent.
- **solutions-archivist dissolved**: Solution search capability moved into the compound-catalog skill; no dedicated agent needed.

### Key additions

- **`publication-output` skill**: Covers publication-quality tables (stargazer-style, summary statistics, Monte Carlo output) and figures (event study plots, RD plots, coefficient plots, specification curves). Absorbs functionality from the former `/tabulate` and `/visualize` commands.
- **Agent-scoped Stop hooks**: Three agents (econometric-reviewer, simulation-designer, mathematical-prover) have domain-specific completeness checks in their frontmatter, replacing items 1-3 from the former monolithic Stop hook. This keeps domain logic with the agent that owns it.
- **Hook model routing**: Classification hooks (UserPromptSubmit, PostToolUse) use Haiku for fast, cheap routing. The Stop hook uses Sonnet for deeper reasoning about session completeness.

### Key removals

- **7 command stubs**: `/simulate`, `/identify`, `/diagnose`, `/tabulate`, `/visualize`, `/stress-test`, `/deepen-plan` are now thin stubs that redirect to the agent or skill handling their function. They still work for backwards compatibility but are no longer full command implementations.
- **solutions-archivist agent**: Dissolved; its search-docs-solutions capability is now part of the compound-catalog skill.

### Test suite

Test counts updated for new component totals (14 agents, 17 skills, 9+7 commands). Total assertion count adjusted accordingly.
