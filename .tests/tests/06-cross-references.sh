#!/usr/bin/env bash
# Test Group 6: Cross-reference integrity between components (22 tests)
source "$(dirname "$0")/../lib/assert.sh"

export HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

group "Cross-References — Agents in Commands"

# 1: Agent references in commands resolve to real agent files
ref_count=0
all_valid=true
for cmd_file in "$PLUGIN_DIR"/commands/*.md "$PLUGIN_DIR"/commands/workflows/*.md; do
  agents_referenced=$(grep -oE '`[a-z]+-[a-z-]+`' "$cmd_file" 2>/dev/null | tr -d '`' | sort -u || true)
  for agent_ref in $agents_referenced; do
    if find "$PLUGIN_DIR/agents" -name "$agent_ref.md" 2>/dev/null | grep -q .; then
      ref_count=$((ref_count + 1))
    fi
  done
done
if [ "$ref_count" -gt 0 ]; then
  pass "commands reference $ref_count valid agents"
else
  must_fix "commands reference agents" "no agent references found"
fi

group "Cross-References — Skills in Commands"

# 2: Skill references in commands resolve to real skill directories
ref_count=0
for cmd_file in "$PLUGIN_DIR"/commands/*.md "$PLUGIN_DIR"/commands/workflows/*.md; do
  skills_referenced=$(grep -oE '`[a-z]+-[a-z-]+`' "$cmd_file" 2>/dev/null | tr -d '`' | sort -u || true)
  for skill_ref in $skills_referenced; do
    if [ -d "$PLUGIN_DIR/skills/$skill_ref" ]; then
      ref_count=$((ref_count + 1))
    fi
  done
done
if [ "$ref_count" -gt 0 ]; then
  pass "commands reference $ref_count valid skills"
else
  should_fix "commands reference skills" "no skill references found"
fi

group "Cross-References — CLAUDE.md Agents"

# 3: CLAUDE.md backtick names resolve to agents, skills, or commands
# Names that are legitimate non-component references (config keys, etc.) are excluded.
claude_names=$(grep -oE '`[a-z]+-[a-z-]+`' "$PLUGIN_DIR/CLAUDE.md" | tr -d '`' | sort -u)
# These hyphenated names appear in CLAUDE.md backticks but are not plugin components.
non_components="disable-model-invocation set-e no-verify"
unresolved=""
for name in $claude_names; do
  # Skip known non-component names
  if echo "$non_components" | grep -qw "$name"; then continue; fi
  if find "$PLUGIN_DIR/agents" -name "$name.md" 2>/dev/null | grep -q .; then
    : # valid agent
  elif [ -d "$PLUGIN_DIR/skills/$name" ]; then
    : # valid skill
  elif [ -f "$PLUGIN_DIR/commands/$name.md" ] || [ -f "$PLUGIN_DIR/commands/workflows/$name.md" ]; then
    : # valid command
  else
    unresolved="$unresolved $name"
  fi
done
if [ -z "$unresolved" ]; then
  pass "all CLAUDE.md component names resolve to files"
else
  should_fix "CLAUDE.md unresolved component names" "not found:$unresolved"
fi

# 4: Every agent file is mentioned in CLAUDE.md
all_mentioned=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q "$name" "$PLUGIN_DIR/CLAUDE.md"; then
    all_mentioned=false
    must_fix "agent $name in CLAUDE.md" "agent not documented"
  fi
done
if $all_mentioned; then pass "all agents mentioned in CLAUDE.md"; fi

# 5: Every skill is mentioned in CLAUDE.md
all_mentioned=true
for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  if ! grep -q "$name" "$PLUGIN_DIR/CLAUDE.md"; then
    all_mentioned=false
    must_fix "skill $name in CLAUDE.md" "skill not documented"
  fi
done
if $all_mentioned; then pass "all skills mentioned in CLAUDE.md"; fi

group "Cross-References — README Commands"

# 6: Slash commands in README exist as files
quickstart_cmds=$(python3 -c "
import re, os
text = open(os.environ['PLUGIN_DIR'] + '/README.md').read()
cmds = set(re.findall(r'(?<!\w)/((?:workflows:)?(?:brainstorm|plan|work|review|compound|estimate|simulate|identify|lfg|slfg|diagnose|tabulate|replicate|visualize|stress-test))\b', text))
for c in sorted(cmds):
    print('/' + c)
" 2>/dev/null)

all_valid=true
for cmd in $quickstart_cmds; do
  cmd_path=$(echo "$cmd" | sed 's|^/||; s|:|/|g')
  if [ ! -f "$PLUGIN_DIR/commands/$cmd_path.md" ]; then
    all_valid=false
    must_fix "README command $cmd exists" "no file at commands/$cmd_path.md"
  fi
done
if $all_valid; then pass "all README commands resolve to files"; fi

# 7: Every command file is mentioned in README
all_mentioned=true
for file in "$PLUGIN_DIR"/commands/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q "$name" "$PLUGIN_DIR/README.md"; then
    all_mentioned=false
    must_fix "command $name in README" "command not documented"
  fi
done
if $all_mentioned; then pass "all root commands mentioned in README"; fi

group "Cross-References — Hook Integrity"

# 8: Hook event types are valid Claude Code events
valid_events="SessionStart|SessionEnd|PreToolUse|PostToolUse|Stop|SubagentStop|UserPromptSubmit|PreCompact|Notification"
hook_events=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for e in d['hooks'].keys():
    print(e)
" 2>/dev/null)

all_valid=true
for event in $hook_events; do
  if ! echo "$event" | grep -qE "^($valid_events)$"; then
    all_valid=false
    must_fix "hook event $event is valid" "not a recognized Claude Code hook event"
  fi
done
if $all_valid; then pass "all hook events are valid Claude Code events"; fi

# 9: SessionStart script path resolves
session_cmd=$(python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for h in d['hooks']['SessionStart'][0]['hooks']:
    if h['type'] == 'command':
        print(h['command'])
" 2>/dev/null || echo "")

if echo "$session_cmd" | grep -q 'CLAUDE_PLUGIN_ROOT.*session-start.sh'; then
  pass "SessionStart hook uses portable path"
else
  must_fix "SessionStart hook uses portable path" "got: $session_cmd"
fi

group "Cross-References — Hook Content"

# 10: UserPromptSubmit references at least 5 agents
ups_agents=$(python3 -c "
import json, re, os
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['UserPromptSubmit']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            agents = set(re.findall(r'\x60([a-z]+-[a-z-]+)\x60', h['prompt']))
            print(len(agents))
" 2>/dev/null || echo "0")
if [ "$ups_agents" -ge 5 ]; then
  pass "UserPromptSubmit references $ups_agents agents"
else
  must_fix "UserPromptSubmit references >=5 agents" "found $ups_agents"
fi

# 11: PostToolUse references at least 3 agents
ptu_agents=$(python3 -c "
import json, re, os
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['PostToolUse']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            agents = set(re.findall(r'\x60([a-z]+-[a-z-]+)\x60', h['prompt']))
            print(len(agents))
" 2>/dev/null || echo "0")
if [ "$ptu_agents" -ge 3 ]; then
  pass "PostToolUse references $ptu_agents agents"
else
  must_fix "PostToolUse references >=3 agents" "found $ptu_agents"
fi

# 12: UserPromptSubmit references at least 3 skills (v0.5: commands removed from UPS, skills are the routing targets)
ups_skills=$(python3 -c "
import json, re, os
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['UserPromptSubmit']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            skills = set(re.findall(r'\x60([\w-]+)\x60\s+skill', h['prompt']))
            print(len(skills))
" 2>/dev/null || echo "0")
if [ "$ups_skills" -ge 3 ]; then
  pass "UserPromptSubmit references $ups_skills skills"
else
  # Fallback: check that UPS references at least 3 backtick-quoted component names
  ups_components=$(python3 -c "
import json, re, os
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['UserPromptSubmit']:
    for h in m['hooks']:
        if h['type'] == 'prompt':
            names = set(re.findall(r'\x60([a-z]+-[a-z-]+)\x60', h['prompt']))
            print(len(names))
" 2>/dev/null || echo "0")
  if [ "$ups_components" -ge 3 ]; then
    pass "UserPromptSubmit references $ups_components component names"
  else
    must_fix "UserPromptSubmit references >=3 components" "found $ups_components"
  fi
fi

group "Cross-References — New Commands"

# 13-14: Non-stub commands reference existing agents (stubs excluded)
# v0.5: diagnose and stress-test are now deprecated stubs — check workflow commands instead
for cmd in workflows/review workflows/work; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  if [ -f "$file" ]; then
    agent_refs=$(grep -oE '`[a-z]+-[a-z-]+`' "$file" 2>/dev/null | tr -d '`' | sort -u || true)
    found=false
    for ref in $agent_refs; do
      if find "$PLUGIN_DIR/agents" -name "$ref.md" 2>/dev/null | grep -q .; then
        found=true
        break
      fi
    done
    if $found; then
      pass "command $(basename $cmd) references valid agents"
    else
      should_fix "command $(basename $cmd) references agents" "no agent references found"
    fi
  fi
done

# 15-16: Non-stub commands reference skills (stubs excluded)
# v0.5: replicate and visualize are now stubs/wrappers — check estimate and replicate wrappers
for cmd in estimate replicate; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  if [ -f "$file" ]; then
    skill_refs=$(grep -oE '`[a-z]+-[a-z-]+`' "$file" 2>/dev/null | tr -d '`' | sort -u || true)
    found=false
    for ref in $skill_refs; do
      if [ -d "$PLUGIN_DIR/skills/$ref" ]; then
        found=true
        break
      fi
    done
    if $found; then
      pass "command $cmd references valid skills"
    else
      should_fix "command $cmd references skills" "no skill references found"
    fi
  fi
done

group "Cross-References — README Completeness"

# 17: All agent categories in README
for cat in "Review" "Research" "Workflow"; do
  if grep -q "$cat" "$PLUGIN_DIR/README.md"; then
    pass "README has $cat agent section"
  else
    must_fix "README has $cat agent section" "missing"
  fi
done

# 20: README mentions all new commands
all_new=true
for cmd in diagnose tabulate replicate visualize stress-test; do
  if ! grep -q "$cmd" "$PLUGIN_DIR/README.md"; then
    all_new=false
    must_fix "README mentions $cmd" "new command not documented"
  fi
done
if $all_new; then pass "README mentions all new commands"; fi

group "Cross-References — Chain Commands"

# 21-22: Chain commands delegate to workflow commands (plan, work, review, compound)
for chain_cmd in lfg slfg; do
  file="$PLUGIN_DIR/commands/$chain_cmd.md"
  if [ -f "$file" ]; then
    delegates_ok=true
    for target in plan work review compound; do
      if ! grep -q "workflows:$target\|/$target" "$file"; then
        delegates_ok=false
      fi
    done
    if $delegates_ok; then
      pass "/$chain_cmd delegates to all 4 workflow commands"
    else
      must_fix "/$chain_cmd delegates to workflows" "missing delegation targets"
    fi
  else
    must_fix "/$chain_cmd exists" "file not found"
  fi
done
