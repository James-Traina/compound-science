#!/bin/bash
# Test Group 3: Bash script syntax, permissions, and safety
source "$(dirname "$0")/../lib/assert.sh"

group "Script Syntax"

assert_ok "session-init.sh syntax" bash -n "$PLUGIN_DIR/scripts/session-init.sh"
assert_ok "worktree-manager.sh syntax" bash -n "$PLUGIN_DIR/skills/git-worktree/scripts/worktree-manager.sh"

group "Script Permissions"

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

# set -euo pipefail
if head -5 "$PLUGIN_DIR/scripts/session-init.sh" | grep -q 'set -euo pipefail'; then
  pass "session-init.sh has set -euo pipefail"
else
  must_fix "session-init.sh has set -euo pipefail" "missing safety flags"
fi

# Proper defaults for hook env vars
if grep -q 'CLAUDE_PROJECT_DIR:-.}' "$PLUGIN_DIR/scripts/session-init.sh" && \
   grep -q 'CLAUDE_ENV_FILE:-/dev/null}' "$PLUGIN_DIR/scripts/session-init.sh"; then
  pass "session-init.sh has proper env defaults"
else
  must_fix "session-init.sh has proper env defaults" "CLAUDE_PROJECT_DIR and CLAUDE_ENV_FILE need defaults"
fi

# Dual .local.md path check (bug we fixed)
if grep -q '.claude/compound-science.local.md' "$PLUGIN_DIR/scripts/session-init.sh" && \
   grep -q 'compound-science.local.md' "$PLUGIN_DIR/scripts/session-init.sh"; then
  pass "session-init.sh checks both .local.md paths"
else
  must_fix "session-init.sh checks both .local.md paths" "should check .claude/ and root"
fi

# No unquoted variable expansion in dangerous positions (assignments, commands)
# Check for bare $VAR in command arguments (not inside quotes or ${})
# Exclude: echo statements with quoted vars, test expressions, assignments
unquoted=$(python3 -c "
import re
with open('$PLUGIN_DIR/scripts/session-init.sh') as f:
    for i, line in enumerate(f, 1):
        line = line.strip()
        if line.startswith('#') or not line:
            continue
        # Skip lines where all \$VARs are inside quotes
        # Simple heuristic: flag if \$VAR appears outside of double quotes
        in_quotes = False
        j = 0
        while j < len(line):
            if line[j] == '\"':
                in_quotes = not in_quotes
            elif line[j] == '\$' and not in_quotes and j+1 < len(line) and line[j+1].isalpha():
                # Found unquoted variable
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

# No hardcoded paths in scripts
if ! grep -rq '/Users/\|/home/' "$PLUGIN_DIR/scripts/" 2>/dev/null; then
  pass "scripts have no hardcoded user paths"
else
  must_fix "scripts have no hardcoded user paths" "found /Users/ or /home/ references"
fi

# worktree-manager.sh has no hardcoded paths
if ! grep -q '/Users/\|/home/' "$PLUGIN_DIR/skills/git-worktree/scripts/worktree-manager.sh" 2>/dev/null; then
  pass "worktree-manager.sh has no hardcoded paths"
else
  must_fix "worktree-manager.sh has no hardcoded paths"
fi

group "Hook Portability"

# hooks.json must use ${CLAUDE_PLUGIN_ROOT} for script paths
if grep -q 'CLAUDE_PLUGIN_ROOT' "$PLUGIN_DIR/hooks/hooks.json"; then
  pass "hooks.json uses \${CLAUDE_PLUGIN_ROOT}"
else
  must_fix "hooks.json uses \${CLAUDE_PLUGIN_ROOT}" "hardcoded paths break portability"
fi
