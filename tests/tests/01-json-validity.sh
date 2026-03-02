#!/bin/bash
# Test Group 1: JSON configuration file validity and structure (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

group "plugin.json Validity"

# 1
if python3 -c "import json; json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))" 2>/dev/null; then
  pass "plugin.json parses"
else
  must_fix "plugin.json parses" "invalid JSON"
fi

# 2-5: Required fields
for field in name version description license; do
  if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))
assert '$field' in d, 'missing $field'
" 2>/dev/null; then
    pass "plugin.json has '$field'"
  else
    must_fix "plugin.json has '$field'" "field missing"
  fi
done

# 6
if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))
assert isinstance(d.get('author'), dict), 'author must be object'
assert 'name' in d['author'], 'author.name missing'
" 2>/dev/null; then
  pass "plugin.json author is object with name"
else
  must_fix "plugin.json author is object with name" "must be {\"name\": \"...\"} not a string"
fi

group "hooks.json Validity"

# 7
if python3 -c "import json; json.load(open('$PLUGIN_DIR/hooks/hooks.json'))" 2>/dev/null; then
  pass "hooks.json parses"
else
  must_fix "hooks.json parses" "invalid JSON"
fi

# 8
if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
assert 'hooks' in d, 'missing hooks wrapper'
assert isinstance(d['hooks'], dict), 'hooks must be object'
" 2>/dev/null; then
  pass "hooks.json has wrapper structure"
else
  must_fix "hooks.json has wrapper structure" "needs {\"hooks\": {...}} format"
fi

# 9
if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
assert 'description' in d, 'missing description'
" 2>/dev/null; then
  pass "hooks.json has description"
else
  must_fix "hooks.json has description" "top-level description missing"
fi

# 10
if python3 -c "
import json, sys
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
for event, matchers in d['hooks'].items():
    for m in matchers:
        assert 'matcher' in m, f'{event}: missing matcher'
        assert 'hooks' in m, f'{event}: missing hooks array'
        for h in m['hooks']:
            assert 'type' in h, f'{event}: hook missing type'
            if h['type'] == 'command':
                assert 'command' in h, f'{event}: command hook missing command'
            elif h['type'] == 'prompt':
                assert 'prompt' in h, f'{event}: prompt hook missing prompt'
" 2>/dev/null; then
  pass "all hook entries have valid structure"
else
  must_fix "all hook entries have valid structure" "malformed hook entry"
fi

group "Hook Entry Validation"

# 11: All hook events have proper timeouts
if python3 -c "
import json, sys
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
missing = []
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            if h.get('timeout', 0) <= 0:
                missing.append(event)
assert not missing, f'missing timeouts: {missing}'
" 2>/dev/null; then
  pass "all hook events have timeouts"
else
  must_fix "all hook events have timeouts" "one or more hooks missing timeout"
fi

# 12-15: Spot-check specific hook timeouts
for check_event in SessionStart Stop PreToolUse SubagentStop; do
  timeout_val=$(python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
t = d['hooks']['$check_event'][0]['hooks'][0].get('timeout', 0)
assert t > 0, f'no timeout for $check_event'
print(t)
" 2>/dev/null)
  if [ -n "$timeout_val" ]; then
    pass "hook $check_event has timeout ($timeout_val)"
  else
    must_fix "hook $check_event has timeout" "timeout missing"
  fi
done

group "Hook JSON Integrity"

# 16: No trailing commas (common JSON error)
if python3 -c "
import json
json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
" 2>/dev/null; then
  pass "hooks.json has no trailing commas"
else
  must_fix "hooks.json has no trailing commas" "JSON parse error"
fi

# 17: All matchers are non-empty strings
if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
for event, matchers in d['hooks'].items():
    for m in matchers:
        assert isinstance(m['matcher'], str) and len(m['matcher']) > 0, f'{event}: empty matcher'
" 2>/dev/null; then
  pass "all matchers are non-empty strings"
else
  must_fix "all matchers are non-empty strings" "found empty or non-string matcher"
fi

# 18: All prompt hooks have non-trivial prompts (>100 chars)
if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            if h['type'] == 'prompt':
                assert len(h['prompt']) > 100, f'{event}: prompt too short ({len(h[\"prompt\"])} chars)'
" 2>/dev/null; then
  pass "all prompt hooks have substantive content"
else
  must_fix "all prompt hooks have substantive content" "prompt too short"
fi

# 19: Hook types are only 'command' or 'prompt'
if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            assert h['type'] in ('command', 'prompt'), f'{event}: invalid type {h[\"type\"]}'
" 2>/dev/null; then
  pass "all hook types are command or prompt"
else
  must_fix "all hook types are command or prompt" "invalid hook type found"
fi

# 20: plugin.json version is semver format
if python3 -c "
import json, re
d = json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))
assert re.match(r'^\d+\.\d+\.\d+', d['version']), f'not semver: {d[\"version\"]}'
" 2>/dev/null; then
  pass "plugin.json version is semver"
else
  must_fix "plugin.json version is semver" "version must be X.Y.Z format"
fi
