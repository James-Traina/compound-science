#!/bin/bash
# Test Group 10: Hook prompt coverage and integration (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

group "Hook Event Coverage"

# 1-7: All 7 expected events present
EXPECTED_EVENTS=("SessionStart" "UserPromptSubmit" "PostToolUse" "Stop" "PreCompact" "PreToolUse" "SubagentStop")
for event in "${EXPECTED_EVENTS[@]}"; do
  if python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
assert '$event' in d['hooks'], '$event missing'
" 2>/dev/null; then
    pass "event $event present"
  else
    must_fix "event $event present" "missing from hooks.json"
  fi
done

group "Hook Timeouts"

# 8-14: All timeouts within limits (command <=60, prompt <=30)
python3 -c "
import json, sys
d = json.load(open('$HOOKS_FILE'))
limits = {'command': 60, 'prompt': 30}
ok = True
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            timeout = h.get('timeout', limits.get(h['type'], 60))
            limit = limits.get(h['type'], 60)
            if timeout > limit:
                print(f'OVER:{event}:{h[\"type\"]}:{timeout}>{limit}')
                ok = False
            else:
                print(f'OK:{event}:{h[\"type\"]}:{timeout}')
if ok:
    sys.exit(0)
else:
    sys.exit(1)
" 2>/dev/null | while IFS=: read -r status event htype timing; do
  if [ "$status" = "OK" ]; then
    pass "timeout $event ($htype) = $timing"
  else
    must_fix "timeout $event ($htype)" "$timing exceeds limit"
  fi
done

group "UserPromptSubmit — Domain Categories"

# 15: All 12 domain categories covered
CATEGORIES=("IDENTIFICATION" "ESTIMATION" "SIMULATION" "PROOF" "EQUILIBRIUM" "PIPELINE" "DATA" "DIAGNOSTICS" "TABLES" "REPLICATION" "SENSITIVITY" "SUBMISSION")

prompt_text=$(python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
for m in d['hooks']['UserPromptSubmit']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

all_cats=true
for cat in "${CATEGORIES[@]}"; do
  if ! echo "$prompt_text" | grep -q "$cat"; then
    all_cats=false
    must_fix "UserPromptSubmit covers $cat" "category missing"
  fi
done
if $all_cats; then pass "UserPromptSubmit covers all 12 categories"; fi

group "PostToolUse — Content Coverage"

# 16: PostToolUse covers all content types (languages + bibliography + pipeline)
ptu_text=$(python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
for m in d['hooks']['PostToolUse']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

ptu_ok=true
for term in "Python" "R estimation" "Stata" "Julia" "bib" "Makefile"; do
  if ! echo "$ptu_text" | grep -qi "$term"; then
    ptu_ok=false
  fi
done
if $ptu_ok; then
  pass "PostToolUse covers all content types (languages + bibliography + pipeline)"
else
  must_fix "PostToolUse covers all content types" "missing language or content type coverage"
fi

group "Stop Hook — Completeness Checks"

stop_text=$(python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
for m in d['hooks']['Stop']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

# 17: Stop checks critical completeness conditions (SE, seeds, sensitivity, commands)
stop_ok=true
for term in "standard error" "seed" "sensitiv" "/diagnose"; do
  if ! echo "$stop_text" | grep -qi "$term"; then
    stop_ok=false
  fi
done
if $stop_ok; then
  pass "Stop checks critical conditions (SE, seeds, sensitivity, commands)"
else
  must_fix "Stop checks critical conditions" "missing SE, seed, sensitivity, or command references"
fi

group "PreCompact — State Preservation"

# 18: PreCompact preserves key research state
precompact_text=$(python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
for m in d['hooks']['PreCompact']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

pc_ok=true
for term in "identification" "result" "proof" "workflow" "diagnostic"; do
  if ! echo "$precompact_text" | grep -qi "$term"; then
    pc_ok=false
  fi
done
if $pc_ok; then
  pass "PreCompact preserves key research state"
else
  must_fix "PreCompact preserves key state" "missing state category"
fi

group "New Hooks — PreToolUse & SubagentStop"

# 19: PreToolUse matcher is "Bash"
if python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
assert d['hooks']['PreToolUse'][0]['matcher'] == 'Bash'
" 2>/dev/null; then
  pass "PreToolUse matcher is Bash"
else
  must_fix "PreToolUse matcher is Bash" "expected matcher 'Bash'"
fi

# 20: SubagentStop matcher is "*"
if python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
assert d['hooks']['SubagentStop'][0]['matcher'] == '*'
" 2>/dev/null; then
  pass "SubagentStop matcher is *"
else
  must_fix "SubagentStop matcher is *" "expected matcher '*'"
fi
