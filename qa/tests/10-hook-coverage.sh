#!/bin/bash
# Test Group 10: Hook prompt content covers design requirements
source "$(dirname "$0")/../lib/assert.sh"

HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

group "Hook Timeouts"

python3 -c "
import json, sys
d = json.load(open('$HOOKS_FILE'))
limits = {'command': 60, 'prompt': 30}
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            timeout = h.get('timeout', limits.get(h['type'], 60))
            limit = limits.get(h['type'], 60)
            if timeout > limit:
                print(f'OVER:{event}:{h[\"type\"]}:{timeout}>{limit}')
            else:
                print(f'OK:{event}:{h[\"type\"]}:{timeout}')
" 2>/dev/null | while IFS=: read -r status event htype timing; do
  if [ "$status" = "OK" ]; then
    pass "timeout $event ($htype) = $timing"
  else
    must_fix "timeout $event ($htype)" "$timing exceeds limit"
  fi
done

group "UserPromptSubmit — Domain Categories"

# Design spec requires 7 categories
CATEGORIES=("IDENTIFICATION" "ESTIMATION" "SIMULATION" "PROOF" "EQUILIBRIUM" "PIPELINE" "DATA")

prompt_text=$(python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
for m in d['hooks']['UserPromptSubmit']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

for cat in "${CATEGORIES[@]}"; do
  if echo "$prompt_text" | grep -q "$cat"; then
    pass "UserPromptSubmit covers $cat"
  else
    must_fix "UserPromptSubmit covers $cat" "category missing from prompt"
  fi
done

group "Stop Hook — Completeness Checks"

stop_text=$(python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
for m in d['hooks']['Stop']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

CHECKS=("standard error" "convergence" "seed" "merge")
for check in "${CHECKS[@]}"; do
  if echo "$stop_text" | grep -qi "$check"; then
    pass "Stop hook checks: $check"
  else
    must_fix "Stop hook checks: $check" "missing from stop prompt"
  fi
done

group "PreCompact — State Preservation"

precompact_text=$(python3 -c "
import json
d = json.load(open('$HOOKS_FILE'))
for m in d['hooks']['PreCompact']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

PRESERVES=("identification" "result" "proof")
for item in "${PRESERVES[@]}"; do
  if echo "$precompact_text" | grep -qi "$item"; then
    pass "PreCompact preserves: $item"
  else
    must_fix "PreCompact preserves: $item" "missing from precompact prompt"
  fi
done
