#!/usr/bin/env bash
# Test Group 12: Hook integration and cross-component wiring (16 tests)
source "$(dirname "$0")/../lib/assert.sh"

export HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

group "Hook Count"

# 1: Total hook events = 5
event_count=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
print(len(d['hooks']))
" 2>/dev/null || echo "0")
assert_count "total hook events = 5" 5 "$event_count"

# 2: All 5 events are valid Claude Code hook events
py_eval "all events are valid Claude Code hook events" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
valid = {'SessionStart','SessionEnd','UserPromptSubmit','PreToolUse','PostToolUse','PostToolUseFailure','Stop','StopFailure','SubagentStart','SubagentStop','PreCompact','PostCompact','Notification','PermissionRequest','TaskCreated','TaskCompleted','TeammateIdle','InstructionsLoaded','ConfigChange','CwdChanged','FileChanged','WorktreeCreate','WorktreeRemove','Elicitation','ElicitationResult'}
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
AGENT_NAMES=("econometric-reviewer" "mathematical-prover" "numerical-auditor" "identification-critic" "journal-referee" "literature-scout" "methods-explorer" "data-detective" "reproducibility-auditor" "workflow-coordinator")
export AGENT_NAMES_STR="${AGENT_NAMES[*]}"

# Check each prompt hook references at least one agent
all_ref=true
# SessionStart is a meta-level hook (project detection) — no specific agents
for event in UserPromptSubmit Stop PreCompact SubagentStop; do
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

# 15: UserPromptSubmit mentions agents/skills for each domain area
# v0.6: All commands migrated to skills. UPS routes to agents/skills directly.
ups_prompt=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['UserPromptSubmit']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            print(h['prompt'])
" 2>/dev/null || echo "")

util_ok=true
# Check that UPS references the skills/agents for each domain area
for component in "empirical-playbook" "publication-output" "identification-critic" "numerical-auditor" "reproducibility-auditor"; do
  if ! echo "$ups_prompt" | grep -q "$component"; then
    util_ok=false
  fi
done
if $util_ok; then
  pass "UserPromptSubmit mentions replacement agents/skills for each domain area"
else
  must_fix "UserPromptSubmit mentions replacement components" "missing one or more of empirical-playbook/publication-output/identification-critic/numerical-auditor/reproducibility-auditor"
fi

# 16: Stop prompt mentions >=2 component names (agents or skills)
# v0.6: Stop hook routes to agents/skills directly
component_count=$(python3 -c "
import json, re, os
d = json.load(open(os.environ['HOOKS_FILE']))
text = ''
for m in d['hooks']['Stop']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            text += h['prompt']
# Count backtick-quoted component names plus /workflows: references
components = set(re.findall(r'\x60([a-z]+-[a-z-]+)\x60', text))
workflows = set(re.findall(r'/workflows:\w+', text))
print(len(components) + len(workflows))
" 2>/dev/null || echo "0")

if [ "$component_count" -ge 2 ]; then
  pass "Stop prompt mentions >= 2 components ($component_count)"
else
  must_fix "Stop mentions >= 2 components" "got $component_count"
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

# 19: SessionStart prompt detects research project types
py_eval "SessionStart prompt covers project detection" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
prompt = ''
for m in d['hooks']['SessionStart']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            prompt += h['prompt']
for kw in ['Python', 'Stata', 'LaTeX', 'empirical', 'paper', 'Pipeline']:
    assert kw.lower() in prompt.lower(), f'SessionStart prompt missing: {kw}'
" "missing project detection keywords"

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
