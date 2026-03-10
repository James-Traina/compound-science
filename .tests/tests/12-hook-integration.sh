#!/usr/bin/env bash
# Test Group 12: Hook integration and cross-component wiring (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

export HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

group "Hook Count"

# 1: Total hook events = 7
event_count=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
print(len(d['hooks']))
" 2>/dev/null || echo "0")
assert_count "total hook events = 7" 7 "$event_count"

# 2: All 7 events are valid Claude Code hook events
py_eval "all events are valid Claude Code hook events" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
valid = {'SessionStart','SessionEnd','UserPromptSubmit','PreToolUse','PostToolUse','Stop','SubagentStop','PreCompact','Notification'}
for event in d['hooks']:
    assert event in valid, f'invalid: {event}'
" "found invalid event name"

# 3: No duplicate event keys
py_eval "no duplicate event keys" "
import json, os, re
text = open(os.environ['HOOKS_FILE']).read()
keys = re.findall(r'\"((?:Session|User|Pre|Post|Stop|Sub|Notification)\w*)\"(?=\s*:)', text)
dups = len(keys) - len(set(keys))
assert dups == 0, str(dups) + ' duplicate key(s) found'
" "could not check for duplicate event keys"

group "PreToolUse Specifics"

# Extract all PreToolUse fields in one call
if ! ptu_data=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
ptu = d['hooks']['PreToolUse'][0]
h = ptu['hooks'][0]
print(ptu['matcher'])
print(h['type'])
print(h['prompt'])
" 2>/dev/null); then
  must_fix "PreToolUse data extraction" "python3 failed — check HOOKS_FILE syntax"
else
  ptu_matcher=$(echo "$ptu_data" | head -1)
  ptu_type=$(echo "$ptu_data" | sed -n '2p')
  ptu_prompt=$(echo "$ptu_data" | tail -n +3)

  # 4: PreToolUse matcher is exactly "Bash"
  if [ "$ptu_matcher" = "Bash" ]; then
    pass "PreToolUse matcher is exactly Bash"
  else
    must_fix "PreToolUse matcher is Bash" "got: $ptu_matcher"
  fi

  # 5: PreToolUse hook type is "prompt"
  if [ "$ptu_type" = "prompt" ]; then
    pass "PreToolUse hook type is prompt"
  else
    must_fix "PreToolUse hook type is prompt" "got: $ptu_type"
  fi

  # 6: PreToolUse prompt mentions seed/random
  if echo "$ptu_prompt" | grep -qi "seed\|random"; then
    pass "PreToolUse prompt mentions seed/random"
  else
    must_fix "PreToolUse mentions seed/random" "missing"
  fi

  # 7: PreToolUse prompt mentions absolute path
  if echo "$ptu_prompt" | grep -qi "absolute path\|home directory\|relative path"; then
    pass "PreToolUse prompt mentions absolute paths"
  else
    must_fix "PreToolUse mentions absolute paths" "missing"
  fi

  # 8: PreToolUse prompt mentions version/pin
  if echo "$ptu_prompt" | grep -qi "version\|pin"; then
    pass "PreToolUse prompt mentions version/pin"
  else
    must_fix "PreToolUse mentions version/pin" "missing"
  fi
fi

group "SubagentStop Specifics"

# Extract all SubagentStop fields in one call
if ! sas_data=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
sas = d['hooks']['SubagentStop'][0]
h = sas['hooks'][0]
print(sas['matcher'])
print(h['type'])
print(h['prompt'])
" 2>/dev/null); then
  must_fix "SubagentStop data extraction" "python3 failed — check HOOKS_FILE syntax"
else
  sas_matcher=$(echo "$sas_data" | head -1)
  sas_type=$(echo "$sas_data" | sed -n '2p')
  sas_prompt=$(echo "$sas_data" | tail -n +3)

  # 9: SubagentStop matcher is exactly "*"
  if [ "$sas_matcher" = "*" ]; then
    pass "SubagentStop matcher is exactly *"
  else
    must_fix "SubagentStop matcher is *" "got: $sas_matcher"
  fi

  # 10: SubagentStop hook type is "prompt"
  if [ "$sas_type" = "prompt" ]; then
    pass "SubagentStop hook type is prompt"
  else
    must_fix "SubagentStop hook type is prompt" "got: $sas_type"
  fi

  # 11: SubagentStop prompt mentions review agent(s) by name
  if echo "$sas_prompt" | grep -qE "econometric-reviewer|numerical-auditor|identification-critic"; then
    pass "SubagentStop mentions review agents by name"
  else
    must_fix "SubagentStop mentions review agents" "missing agent names"
  fi

  # 12: SubagentStop prompt mentions research agent(s) by name
  if echo "$sas_prompt" | grep -qE "literature-scout|methods-explorer|data-detective"; then
    pass "SubagentStop mentions research agents by name"
  else
    must_fix "SubagentStop mentions research agents" "missing agent names"
  fi

  # 13: SubagentStop prompt mentions /workflows:compound or next steps
  if echo "$sas_prompt" | grep -qE '/workflows:compound|next step'; then
    pass "SubagentStop mentions compound workflow or next steps"
  else
    must_fix "SubagentStop mentions compound/next steps" "missing"
  fi
fi

group "Cross-Component Wiring"

# 14: All prompt hooks reference >=1 agent name that exists in agents/
AGENT_NAMES=("econometric-reviewer" "mathematical-prover" "numerical-auditor" "identification-critic" "journal-referee" "simulation-designer" "process-architect" "equilibrium-analyst" "calibration-assessor" "results-verifier" "literature-scout" "methods-explorer" "data-detective" "solutions-archivist" "benchmark-researcher" "pipeline-validator" "reproducibility-checker" "specification-analyzer" "research-coordinator" "progress-tracker")
export AGENT_NAMES_STR="${AGENT_NAMES[*]}"

# Check each prompt hook references at least one agent
all_ref=true
for event in SessionStart UserPromptSubmit PostToolUse Stop PreCompact PreToolUse SubagentStop; do
  export EVENT="$event"
  if ! event_prompt=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
event = os.environ['EVENT']
if event in d['hooks']:
    for m in d['hooks'][event]:
        for h in m['hooks']:
            if h['type'] == 'prompt':
                print(h['prompt'])
" 2>/dev/null); then
    all_ref=false
    must_fix "hook $event references an agent" "python3 failed — check HOOKS_FILE"
    continue
  fi
  if [ -z "$event_prompt" ]; then continue; fi
  found=false
  for agent in "${AGENT_NAMES[@]}"; do
    if echo "$event_prompt" | grep -q "$agent"; then
      found=true
      break
    fi
  done
  if ! $found; then
    all_ref=false
    must_fix "hook $event references an agent" "no agent name found"
  fi
done
if $all_ref; then pass "all prompt hooks reference existing agents"; fi

# 15: UserPromptSubmit mentions all 5 utility commands
ups_prompt=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['UserPromptSubmit']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

util_ok=true
for cmd in "/diagnose" "/tabulate" "/replicate" "/visualize" "/stress-test"; do
  if ! echo "$ups_prompt" | grep -q "$cmd"; then
    util_ok=false
  fi
done
if $util_ok; then
  pass "UserPromptSubmit mentions all 5 utility commands"
else
  must_fix "UserPromptSubmit mentions utility commands" "missing one or more of /diagnose /tabulate /replicate /visualize /stress-test"
fi

# 16: PostToolUse mentions >=3 distinct agent names
agent_count=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
agents = os.environ['AGENT_NAMES_STR'].split()
text = ''
for m in d['hooks']['PostToolUse']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            text += h['prompt']
found = sum(1 for a in agents if a in text)
print(found)
" 2>/dev/null || echo "0")

if [ "$agent_count" -ge 3 ]; then
  pass "PostToolUse mentions >= 3 agent names ($agent_count)"
else
  must_fix "PostToolUse mentions >= 3 agents" "got $agent_count"
fi

# 17: Stop prompt mentions >=2 command names
cmd_count=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
cmds = ['/estimate','/simulate','/identify','/diagnose','/tabulate','/replicate','/visualize','/stress-test','/workflows:']
text = ''
for m in d['hooks']['Stop']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            text += h['prompt']
found = sum(1 for c in cmds if c in text)
print(found)
" 2>/dev/null || echo "0")

if [ "$cmd_count" -ge 2 ]; then
  pass "Stop prompt mentions >= 2 commands ($cmd_count)"
else
  must_fix "Stop mentions >= 2 commands" "got $cmd_count"
fi

group "Structural Integrity"

# 18: Every hook entry has an explicit timeout field
py_eval "every hook entry has explicit timeout" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            assert 'timeout' in h, f'missing timeout: {event}'
" "missing timeout field"

# 19: SessionStart command path includes session-start.sh
py_eval "SessionStart references session-start.sh" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
found = any(
    'command' in h and 'session-start.sh' in h['command']
    for m in d['hooks']['SessionStart']
    for h in m['hooks']
)
assert found, 'session-start.sh not referenced'
" "missing"

# 20: No hook prompt exceeds 5000 characters (bloat guard)
if python3 -c "
import json, os, sys
d = json.load(open(os.environ['HOOKS_FILE']))
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            if h['type'] == 'prompt' and len(h['prompt']) > 5000:
                print(f'bloat: {event} = {len(h[\"prompt\"])} chars')
                sys.exit(1)
" 2>/dev/null; then
  pass "no hook prompt exceeds 5000 characters"
else
  should_fix "hook prompt bloat" "a prompt exceeds 5000 chars"
fi
