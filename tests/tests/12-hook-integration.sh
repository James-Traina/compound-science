#!/bin/bash
# Test Group 12: Hook integration and cross-component wiring (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

group "Hook Count"

# 1: Total hook events = 7
event_count=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
print(len(d['hooks']))
" 2>/dev/null || echo "0")
assert_count "total hook events = 7" 7 "$event_count"

# 2: All 7 events are valid Claude Code hook events
VALID_EVENTS=("SessionStart" "SessionEnd" "UserPromptSubmit" "PreToolUse" "PostToolUse" "Stop" "SubagentStop" "PreCompact" "Notification")
if HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os, sys
d = json.load(open(os.environ['HOOKS_FILE']))
valid = {'SessionStart','SessionEnd','UserPromptSubmit','PreToolUse','PostToolUse','Stop','SubagentStop','PreCompact','Notification'}
for event in d['hooks']:
    if event not in valid:
        print(f'invalid: {event}')
        sys.exit(1)
" 2>/dev/null; then
  pass "all events are valid Claude Code hook events"
else
  must_fix "all events are valid hook events" "found invalid event name"
fi

# 3: No duplicate event keys
dup_count=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os, re
text = open(os.environ['HOOKS_FILE']).read()
# JSON object keys are unique by spec, but check the raw text
keys = re.findall(r'\"((?:Session|User|Pre|Post|Stop|Sub|Notification)\w*)\"(?=\s*:)', text)
print(len(keys) - len(set(keys)))
" 2>/dev/null || echo "0")
assert_count "no duplicate event keys" 0 "$dup_count"

group "PreToolUse Specifics"

ptu_matcher=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
print(d['hooks']['PreToolUse'][0]['matcher'])
" 2>/dev/null || echo "")

ptu_type=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
print(d['hooks']['PreToolUse'][0]['hooks'][0]['type'])
" 2>/dev/null || echo "")

ptu_prompt=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
print(d['hooks']['PreToolUse'][0]['hooks'][0]['prompt'])
" 2>/dev/null || echo "")

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

group "SubagentStop Specifics"

sas_matcher=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
print(d['hooks']['SubagentStop'][0]['matcher'])
" 2>/dev/null || echo "")

sas_type=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
print(d['hooks']['SubagentStop'][0]['hooks'][0]['type'])
" 2>/dev/null || echo "")

sas_prompt=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
print(d['hooks']['SubagentStop'][0]['hooks'][0]['prompt'])
" 2>/dev/null || echo "")

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

group "Cross-Component Wiring"

all_prompts=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            if h['type'] == 'prompt':
                print(h['prompt'])
" 2>/dev/null || echo "")

# 14: All prompt hooks reference >=1 agent name that exists in agents/
AGENT_NAMES=("econometric-reviewer" "mathematical-prover" "numerical-auditor" "identification-critic" "journal-referee" "simulation-designer" "process-architect" "equilibrium-analyst" "calibration-assessor" "results-verifier" "literature-scout" "methods-explorer" "data-detective" "solutions-archivist" "benchmark-researcher" "pipeline-validator" "reproducibility-checker" "specification-analyzer" "research-coordinator" "progress-tracker")

# Check each prompt hook references at least one agent
all_ref=true
for event in SessionStart UserPromptSubmit PostToolUse Stop PreCompact PreToolUse SubagentStop; do
  event_prompt=$(HOOKS_FILE="$HOOKS_FILE" EVENT="$event" python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
event = os.environ['EVENT']
if event in d['hooks']:
    for m in d['hooks'][event]:
        for h in m['hooks']:
            if h['type'] == 'prompt':
                print(h['prompt'])
" 2>/dev/null || echo "")
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
ups_prompt=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
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
agent_count=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
agents = ['econometric-reviewer','mathematical-prover','numerical-auditor','identification-critic','journal-referee','simulation-designer','process-architect','equilibrium-analyst','calibration-assessor','results-verifier','literature-scout','methods-explorer','data-detective','solutions-archivist','benchmark-researcher','pipeline-validator','reproducibility-checker','specification-analyzer','research-coordinator','progress-tracker']
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
cmd_count=$(HOOKS_FILE="$HOOKS_FILE" python3 -c "
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
if HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os, sys
d = json.load(open(os.environ['HOOKS_FILE']))
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            if 'timeout' not in h:
                print(f'missing timeout: {event}')
                sys.exit(1)
" 2>/dev/null; then
  pass "every hook entry has explicit timeout"
else
  must_fix "every hook has timeout" "missing timeout field"
fi

# 19: SessionStart command path includes session-init.sh
if HOOKS_FILE="$HOOKS_FILE" python3 -c "
import json, os, sys
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['SessionStart']:
    for h in m['hooks']:
        if 'command' in h and 'session-init.sh' in h['command']:
            sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
  pass "SessionStart references session-init.sh"
else
  must_fix "SessionStart references session-init.sh" "missing"
fi

# 20: No hook prompt exceeds 5000 characters (bloat guard)
if HOOKS_FILE="$HOOKS_FILE" python3 -c "
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
