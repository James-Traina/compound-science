#!/bin/bash
# Test Group 10: Hook prompt coverage and integration (23 tests)
source "$(dirname "$0")/../lib/assert.sh"

export HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

group "Hook Event Coverage"

# 1-7: All 7 expected events present
EXPECTED_EVENTS=("SessionStart" "UserPromptSubmit" "PostToolUse" "Stop" "PreCompact" "PreToolUse" "SubagentStop")
for event in "${EXPECTED_EVENTS[@]}"; do
  export EVENT="$event"
  py_eval "event $event present" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
assert os.environ['EVENT'] in d['hooks'], os.environ['EVENT'] + ' missing'
" "missing from hooks.json"
done

group "Hook Timeouts"

# 8-14: All timeouts within limits (command <=60, prompt <=30)
timeout_lines=""
if ! timeout_lines=$(python3 -c "
import json, os, sys
d = json.load(open(os.environ['HOOKS_FILE']))
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
" 2>/dev/null); then
  must_fix "timeout checks (all events)" "python3 error parsing hooks.json"
else
  while IFS=: read -r status event htype timing; do
    if [ "$status" = "OK" ]; then
      pass "timeout $event ($htype) = $timing"
    else
      must_fix "timeout $event ($htype)" "$timing exceeds limit"
    fi
  done <<< "$timeout_lines"
fi

group "UserPromptSubmit — Domain Categories"

# 15: All 13 domain categories covered
CATEGORIES=("IDENTIFICATION" "ESTIMATION" "SIMULATION" "PROOF" "EQUILIBRIUM" "PIPELINE" "DATA" "DIAGNOSTICS" "TABLES" "REPLICATION" "SENSITIVITY" "SUBMISSION" "CONVERGENCE")

prompt_text=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
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
if $all_cats; then pass "UserPromptSubmit covers all 13 categories"; fi

# 15a: CONVERGENCE category contains its specific trigger keywords
conv_ok=true
for kw in "optimizer" "Hessian" "BFGS"; do
  if ! echo "$prompt_text" | grep -qi "$kw"; then
    conv_ok=false
    must_fix "UserPromptSubmit CONVERGENCE keyword: $kw" "missing"
  fi
done
if $conv_ok; then pass "UserPromptSubmit CONVERGENCE has trigger keywords (optimizer/Hessian/BFGS)"; fi

group "PostToolUse — Content Coverage"

# 16: PostToolUse covers all content types (languages + bibliography + pipeline)
ptu_text=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['PostToolUse']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

ptu_missing=""
for term in "Python" "R estimation" "Stata" "Julia" "simulation-designer" "mathematical-prover" "bib" "Makefile" "results-verifier" "specification-analyzer"; do
  if ! echo "$ptu_text" | grep -qi "$term"; then
    ptu_missing="$ptu_missing $term"
  fi
done
if [ -z "$ptu_missing" ]; then
  pass "PostToolUse covers all 10 content categories"
else
  must_fix "PostToolUse covers all 10 content categories" "missing:$ptu_missing"
fi

group "Stop Hook — Completeness Checks"

stop_text=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['Stop']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

# 17: Stop checks critical completeness conditions (SE, seeds, sensitivity, commands)
stop_missing=""
for term in "standard error" "seed" "sensitiv" "/diagnose"; do
  if ! echo "$stop_text" | grep -qi "$term"; then
    stop_missing="$stop_missing $term"
  fi
done
if [ -z "$stop_missing" ]; then
  pass "Stop checks critical conditions (SE, seeds, sensitivity, commands)"
else
  must_fix "Stop checks critical conditions" "missing:$stop_missing"
fi

# 17a: Stop prompt contains BLOCKING RULES section (items 1-4 only)
if echo "$stop_text" | grep -q "BLOCKING RULES"; then
  pass "Stop prompt has BLOCKING RULES section"
else
  must_fix "Stop prompt has BLOCKING RULES section" "missing — blocking contract undocumented"
fi

# 17b: Stop prompt explicitly marks items 5-8 as suggestion-only (cannot block)
if echo "$stop_text" | grep -qE "Items 5-8|items 5-8|suggestion.only|MUST NOT block"; then
  pass "Stop prompt marks items 5-8 as suggestion-only"
else
  must_fix "Stop prompt marks items 5-8 as suggestion-only" "missing — at-most-once blocking contract not enforced"
fi

group "PreCompact — State Preservation"

# 18: PreCompact preserves key research state
precompact_text=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['PreCompact']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

pc_missing=""
for term in "identification" "result" "proof" "workflow" "diagnostic"; do
  if ! echo "$precompact_text" | grep -qi "$term"; then
    pc_missing="$pc_missing $term"
  fi
done
if [ -z "$pc_missing" ]; then
  pass "PreCompact preserves key research state"
else
  must_fix "PreCompact preserves key state" "missing:$pc_missing"
fi

group "New Hooks — PreToolUse & SubagentStop"

# 19: PreToolUse matcher is "Bash"
py_eval "PreToolUse matcher is Bash" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
assert d['hooks']['PreToolUse'][0]['matcher'] == 'Bash'
" "expected matcher 'Bash'"

# 20: SubagentStop matcher is "*"
py_eval "SubagentStop matcher is *" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
assert d['hooks']['SubagentStop'][0]['matcher'] == '*'
" "expected matcher '*'"
