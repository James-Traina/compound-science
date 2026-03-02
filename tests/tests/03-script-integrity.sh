#!/bin/bash
# Test Group 3: Bash script syntax, permissions, safety, and portability (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

group "Script Syntax"

# 1-2
assert_ok "session-init.sh syntax" bash -n "$PLUGIN_DIR/scripts/session-init.sh"
assert_ok "worktree-manager.sh syntax" bash -n "$PLUGIN_DIR/skills/git-worktree/scripts/worktree-manager.sh"

group "Script Permissions"

# 3-4
if [ -x "$PLUGIN_DIR/scripts/session-init.sh" ]; then
  pass "session-init.sh is executable"
else
  must_fix "session-init.sh is executable" "chmod +x needed"
fi

if [ -x "$PLUGIN_DIR/skills/git-worktree/scripts/worktree-manager.sh" ]; then
  pass "worktree-manager.sh is executable"
else
  must_fix "worktree-manager.sh is executable" "chmod +x needed"
fi

group "Script Safety"

# 5
if head -5 "$PLUGIN_DIR/scripts/session-init.sh" | grep -q 'set -euo pipefail'; then
  pass "session-init.sh has set -euo pipefail"
else
  must_fix "session-init.sh has set -euo pipefail" "missing safety flags"
fi

# 6
if grep -q 'CLAUDE_PROJECT_DIR:-.}' "$PLUGIN_DIR/scripts/session-init.sh" && \
   grep -q 'CLAUDE_ENV_FILE:-/dev/null}' "$PLUGIN_DIR/scripts/session-init.sh"; then
  pass "session-init.sh has proper env defaults"
else
  must_fix "session-init.sh has proper env defaults" "CLAUDE_PROJECT_DIR and CLAUDE_ENV_FILE need defaults"
fi

# 7
if grep -q '.claude/compound-science.local.md' "$PLUGIN_DIR/scripts/session-init.sh" && \
   grep -q 'compound-science.local.md' "$PLUGIN_DIR/scripts/session-init.sh"; then
  pass "session-init.sh checks both .local.md paths"
else
  must_fix "session-init.sh checks both .local.md paths" "should check .claude/ and root"
fi

# 8: No unquoted variable expansion
unquoted=$(PLUGIN_DIR="$PLUGIN_DIR" python3 -c "
import re, os
with open(os.environ['PLUGIN_DIR'] + '/scripts/session-init.sh') as f:
    for i, line in enumerate(f, 1):
        line = line.strip()
        if line.startswith('#') or not line:
            continue
        in_quotes = False
        j = 0
        while j < len(line):
            if line[j] == '\"':
                in_quotes = not in_quotes
            elif line[j] == '\$' and not in_quotes and j+1 < len(line) and line[j+1].isalpha():
                var = re.match(r'[A-Z_a-z]+', line[j+1:])
                if var:
                    print(f'{i}: {line}')
                    break
            j += 1
" 2>/dev/null || true)
if [ -z "$unquoted" ]; then
  pass "session-init.sh variables are properly quoted"
else
  should_fix "session-init.sh variables are properly quoted" "potential unquoted vars found"
fi

group "Hardcoded Paths"

# 9-10
if ! grep -rq '/Users/\|/home/' "$PLUGIN_DIR/scripts/" 2>/dev/null; then
  pass "scripts have no hardcoded user paths"
else
  must_fix "scripts have no hardcoded user paths" "found /Users/ or /home/ references"
fi

if ! grep -q '/Users/\|/home/' "$PLUGIN_DIR/skills/git-worktree/scripts/worktree-manager.sh" 2>/dev/null; then
  pass "worktree-manager.sh has no hardcoded paths"
else
  must_fix "worktree-manager.sh has no hardcoded paths"
fi

group "Hook Portability"

# 11
if grep -q 'CLAUDE_PLUGIN_ROOT' "$PLUGIN_DIR/hooks/hooks.json"; then
  pass "hooks.json uses \${CLAUDE_PLUGIN_ROOT}"
else
  must_fix "hooks.json uses \${CLAUDE_PLUGIN_ROOT}" "hardcoded paths break portability"
fi

# 12: No absolute paths in hooks.json
if ! PLUGIN_DIR="$PLUGIN_DIR" python3 -c "
import json, os
text = open(os.environ['PLUGIN_DIR'] + '/hooks/hooks.json').read()
assert '/Users/' not in text and '/home/' not in text, 'absolute paths found'
" 2>/dev/null; then
  must_fix "hooks.json has no absolute paths" "found /Users/ or /home/"
else
  pass "hooks.json has no absolute paths"
fi

group "Test Infrastructure"

# 13: run-all.sh syntax
assert_ok "run-all.sh syntax" bash -n "$PLUGIN_DIR/tests/run-all.sh"

# 14: assert.sh syntax
assert_ok "assert.sh syntax" bash -n "$PLUGIN_DIR/tests/lib/assert.sh"

# 15: fixtures.sh syntax
assert_ok "fixtures.sh syntax" bash -n "$PLUGIN_DIR/tests/lib/fixtures.sh"

# 16: All test files have valid syntax
all_valid=true
for test_file in "$PLUGIN_DIR"/tests/tests/*.sh; do
  if ! bash -n "$test_file" 2>/dev/null; then
    all_valid=false
    must_fix "$(basename $test_file) syntax" "bash -n failed"
  fi
done
if $all_valid; then pass "all test files have valid bash syntax"; fi

# 17: All test files source assert.sh
all_source=true
for test_file in "$PLUGIN_DIR"/tests/tests/*.sh; do
  if ! grep -q 'source.*assert.sh' "$test_file" 2>/dev/null; then
    all_source=false
    must_fix "$(basename $test_file) sources assert.sh" "missing source line"
  fi
done
if $all_source; then pass "all test files source assert.sh"; fi

# 18: run-all.sh has set -euo pipefail
if head -15 "$PLUGIN_DIR/tests/run-all.sh" | grep -q 'set -euo pipefail'; then
  pass "run-all.sh has set -euo pipefail"
else
  must_fix "run-all.sh has set -euo pipefail" "missing safety flags"
fi

# 19: Test report directory is gitignored
if grep -q 'tests/reports' "$PLUGIN_DIR/.gitignore" 2>/dev/null; then
  pass "tests/reports is gitignored"
else
  should_fix "tests/reports is gitignored" "test reports should not be committed"
fi

# 20: No grep -P in any script (macOS incompatible)
if grep -rn 'grep -P' "$PLUGIN_DIR/scripts/" "$PLUGIN_DIR/tests/" --exclude-dir=reports --exclude='03-script-integrity.sh' 2>/dev/null | head -1 | grep -q .; then
  must_fix "no grep -P usage" "grep -P unavailable on macOS; use python3 regex"
else
  pass "no grep -P usage (macOS compatible)"
fi
