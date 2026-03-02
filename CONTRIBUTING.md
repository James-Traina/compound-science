# Contributing to compound-science

## Adding Components

### Agents

1. Create `agents/<category>/<agent-name>.md` where category is `review/`, `research/`, or `workflow/`
2. Use `word-word` kebab-case for the name (e.g., `econometric-reviewer`, not `reviewer` or `econometric_reviewer`)
3. Include YAML frontmatter: `name`, `description`, `model` (sonnet), `tools`
4. Include `<examples>` block with 2-3 trigger examples
5. Include body sections with domain knowledge
6. End with `## SCOPE` and `## CORE PHILOSOPHY` sections
7. Review agents must include FAIL/PASS markers (`🔴 FAIL:` / `✅ PASS:`)
8. Research agents should include `## GUARDRAILS` and `## OUTPUT FORMAT` sections

### Commands

1. Create `commands/<command-name>.md` (or `commands/<group>/<command-name>.md` for grouped commands)
2. Use `word-word` kebab-case
3. Include YAML frontmatter: `name`, `description`, and optionally `allowed-tools`, `disable-model-invocation`
4. Chain commands (`lfg`, `slfg`) use `disable-model-invocation: true` to delegate without extra model calls

### Skills

1. Create `skills/<skill-name>/SKILL.md`
2. Use `word-word` kebab-case
3. Skills should have >=100 lines, >=3 `##` sections, code examples, and >=500 words
4. The first non-frontmatter paragraph serves as the trigger description — make it >=50 chars with domain keywords

### Hooks

1. Edit `hooks/hooks.json` — do not create separate files
2. The file requires the `{"description":"...","hooks":{...}}` wrapper envelope. Missing it silently disables all hooks.
3. Each hook entry needs: `matcher`, `hooks` array with `type` (`command` or `prompt`), and explicit `timeout`
4. Prompt hooks should be conservative — false positives are worse than false negatives
5. Every prompt hook should reference at least one agent name for cross-component wiring

## Naming Conventions

- All agents and skills use `word-word` kebab-case (exactly two hyphenated words)
- Commands may use single words (`estimate`) or grouped names (`workflows:plan`)
- Hook events use PascalCase as defined by Claude Code: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `PreCompact`, `SubagentStop`

## Test Structure

- 12 test groups in `tests/tests/`, each targeting exactly 20 tests
- `tests/lib/assert.sh` provides: `pass`, `must_fix`, `should_fix`, `skip`, `assert_ok`, `assert_file_exists`, `assert_dir_exists`, `assert_count`, `py_eval`
- Run all: `bash tests/run-all.sh` (240 tests)
- Run one group: `bash tests/run-all.sh 07`
- List groups: `bash tests/run-all.sh --list`
- Reports are gitignored at `tests/reports/`

### Adding Tests

1. Tests go in `tests/tests/XX-name.sh` where XX is the group number
2. Source `$(dirname "$0")/../lib/assert.sh` at the top
3. Use `group "Section Name"` to organize, then `pass`/`must_fix`/`should_fix` for assertions
4. Keep each group at exactly 20 tests — restructure if needed when adding new checks

## Known Gotchas

These are lessons from development that prevent common mistakes:

- **`grep -P` unavailable on macOS**: macOS ships bash 3 and BSD grep. Use `python3 -c "import re; ..."` for Perl-compatible regex. All test scripts avoid `grep -P`.
- **bash 3 on macOS**: No `declare -A` (associative arrays). Use `case` statements for key-value mappings.
- **`grep -c` trap**: `$(grep -c pattern file || echo "0")` is WRONG — `grep -c` outputs `0` (not failure) when no match, so `|| echo "0"` appends a second zero. Use `$(grep -c pattern file)` and handle the result separately.
- **Test self-referencing**: grep-based tests that search the test directory can match their own report files. Use `--exclude-dir=reports`.
- **Case-insensitive regex pitfalls**: `grep -i "angular"` matches "triangular"; `grep -i "SSO"` matches "regressors". Use specific terms only.
- **Hook prompt portability**: Don't put literal `/Users/` or `/home/` in hook prompts — the absolute path test scans hooks.json raw text.
- **QA self-scanning**: When grep-searching the repo root, exclude `--exclude-dir=tests,.ralph,.serena,.git,.claude` to avoid false positives.
- **Plugin install path**: `.claude-plugin/plugin.json` MUST be at repo root, not nested in a subdirectory. `claude plugin install` won't find it otherwise.

## PR Checklist

Before submitting:

- [ ] All 240 tests pass (`bash tests/run-all.sh`) with 0 must-fix
- [ ] New components follow `word-word` kebab-case naming
- [ ] New agents have SCOPE + CORE PHILOSOPHY sections
- [ ] hooks.json is valid JSON (no trailing commas)
- [ ] All hook prompts reference at least one agent name
- [ ] Component counts in `CLAUDE.md` and `README.md` are updated if components were added
- [ ] Test counts are still at 20 per group (no inflation from loops)
