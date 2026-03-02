#!/bin/bash
# Test Group 10: Hook prompt coverage and integration (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

group "Hook Event Coverage"

# 1: All 5 expected events present
EXPECTED_EVENTS=("SessionStart" "UserPromptSubmit" "PostToolUse" "Stop" "PreCompact")
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

# 6: All timeouts within limits (command <=60, prompt <=30)
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

# 11: All 12 domain categories covered
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

group "PostToolUse — Language Coverage"

# 12: PostToolUse covers Python, R, Stata, Julia
ptu_text=$(python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
for m in d['hooks']['PostToolUse']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

LANGUAGES=("Python" "R " "Stata" "Julia")
all_langs=true
for lang in "${LANGUAGES[@]}"; do
  if ! echo "$ptu_text" | grep -qi "$lang"; then
    all_langs=false
    must_fix "PostToolUse covers $lang" "language missing"
  fi
done
if $all_langs; then pass "PostToolUse covers all 4 estimation languages"; fi

# 13: PostToolUse covers bibliography/manuscript files
if echo "$ptu_text" | grep -qi 'bib\|bibliography\|manuscript'; then
  pass "PostToolUse covers bibliography/manuscript"
else
  should_fix "PostToolUse covers bibliography" "missing .bib/.tex coverage"
fi

# 14: PostToolUse covers pipeline files
if echo "$ptu_text" | grep -qi 'Makefile\|Snakefile\|pipeline'; then
  pass "PostToolUse covers pipeline files"
else
  must_fix "PostToolUse covers pipeline files" "missing Makefile/Snakefile coverage"
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

# 15: Stop checks for standard errors
if echo "$stop_text" | grep -qi "standard error"; then
  pass "Stop checks: standard errors"
else
  must_fix "Stop checks: standard errors" "missing"
fi

# 16: Stop checks for seeds
if echo "$stop_text" | grep -qi "seed"; then
  pass "Stop checks: seeds"
else
  must_fix "Stop checks: seeds" "missing"
fi

# 17: Stop checks for sensitivity/robustness
if echo "$stop_text" | grep -qi "sensitiv\|robust"; then
  pass "Stop checks: sensitivity/robustness"
else
  should_fix "Stop checks: sensitivity" "missing"
fi

# 18: Stop references /diagnose or /stress-test commands
if echo "$stop_text" | grep -qE '/diagnose|/stress-test|/replicate'; then
  pass "Stop references utility commands"
else
  should_fix "Stop references utility commands" "should suggest new commands"
fi

group "PreCompact — State Preservation"

precompact_text=$(python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
for m in d['hooks']['PreCompact']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

# 19: PreCompact preserves key state categories
PRESERVES=("identification" "result" "proof" "sensitivity" "diagnostic")
all_preserved=true
for item in "${PRESERVES[@]}"; do
  if ! echo "$precompact_text" | grep -qi "$item"; then
    all_preserved=false
    must_fix "PreCompact preserves: $item" "missing"
  fi
done
if $all_preserved; then pass "PreCompact preserves all key state categories"; fi

# 20: PreCompact preserves workflow state
if echo "$precompact_text" | grep -qi "workflow\|command\|agent"; then
  pass "PreCompact preserves workflow state"
else
  should_fix "PreCompact preserves workflow state" "should track which commands/agents ran"
fi
