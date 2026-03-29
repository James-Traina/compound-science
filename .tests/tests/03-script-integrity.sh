#!/usr/bin/env bash
# Test Group 3: Bash script syntax, permissions, safety, and portability (14 tests)
source "$(dirname "$0")/../lib/assert.sh"

group "Script Syntax"

# 1
assert_ok "worktree-manager.sh syntax" bash -n "$PLUGIN_DIR/skills/workflows-work/scripts/worktree-manager.sh"

group "Script Permissions"

# 2
if [ -x "$PLUGIN_DIR/skills/workflows-work/scripts/worktree-manager.sh" ]; then
  pass "worktree-manager.sh is executable"
else
  must_fix "worktree-manager.sh is executable" "chmod +x needed"
fi

group "Hardcoded Paths"

# 3
if ! grep -q '/Users/\|/home/' "$PLUGIN_DIR/skills/workflows-work/scripts/worktree-manager.sh" 2>/dev/null; then
  pass "worktree-manager.sh has no hardcoded paths"
else
  must_fix "worktree-manager.sh has no hardcoded paths"
fi

group "Hook Portability"

# 4: No absolute paths in hooks.json
py_eval "hooks.json has no absolute paths" "
import json, os
text = open(os.environ['PLUGIN_DIR'] + '/hooks/hooks.json').read()
assert '/Users/' not in text and '/home/' not in text, 'absolute paths found'
" "found /Users/ or /home/"

group "Test Infrastructure"

# 6: run-all.sh syntax
assert_ok "run-all.sh syntax" bash -n "$PLUGIN_DIR/.tests/run-all.sh"

# 7: assert.sh syntax
assert_ok "assert.sh syntax" bash -n "$PLUGIN_DIR/.tests/lib/assert.sh"

# 8: fixtures.sh syntax
assert_ok "fixtures.sh syntax" bash -n "$PLUGIN_DIR/.tests/lib/fixtures.sh"

# 9: All test files have valid syntax
all_valid=true
for test_file in "$PLUGIN_DIR"/.tests/tests/*.sh; do
  if ! bash -n "$test_file" 2>/dev/null; then
    all_valid=false
    must_fix "$(basename $test_file) syntax" "bash -n failed"
  fi
done
if $all_valid; then pass "all test files have valid bash syntax"; fi

# 10: All test files source assert.sh
all_source=true
for test_file in "$PLUGIN_DIR"/.tests/tests/*.sh; do
  if ! grep -q 'source.*assert.sh' "$test_file" 2>/dev/null; then
    all_source=false
    must_fix "$(basename $test_file) sources assert.sh" "missing source line"
  fi
done
if $all_source; then pass "all test files source assert.sh"; fi

# 11: run-all.sh has set -euo pipefail
if head -15 "$PLUGIN_DIR/.tests/run-all.sh" | grep -q 'set -euo pipefail'; then
  pass "run-all.sh has set -euo pipefail"
else
  must_fix "run-all.sh has set -euo pipefail" "missing safety flags"
fi

# 12: Test report directory is gitignored
if grep -q '\.tests/reports' "$PLUGIN_DIR/.gitignore" 2>/dev/null; then
  pass ".tests/reports is gitignored"
else
  should_fix ".tests/reports is gitignored" "test reports should not be committed"
fi

# 13: No grep -P in any script (macOS incompatible)
if grep -rn 'grep -P' "$PLUGIN_DIR/hooks/" "$PLUGIN_DIR/.tests/" --exclude-dir=reports --exclude='03-script-integrity.sh' 2>/dev/null | head -1 | grep -q .; then
  must_fix "no grep -P usage" "grep -P unavailable on macOS; use python3 regex"
else
  pass "no grep -P usage (macOS compatible)"
fi

# 14: All hooks are prompt-based (no external script dependencies)
py_eval "all hooks are prompt-based" "
import json, os
d = json.load(open(os.environ['PLUGIN_DIR'] + '/hooks/hooks.json'))
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            assert h['type'] == 'prompt', f'{event}: expected prompt type, got {h[\"type\"]}'
" "found non-prompt hooks"
