#!/usr/bin/env bash
# Test Group 6: Cross-reference integrity between components (22 tests)
# v0.6: commands/ removed; cross-references updated for skills-only architecture
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/fixtures.sh"

export HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

group "Cross-References — Agents in Skills"

# 1: Agent references in workflow/wrapper skills resolve to real agent files
ref_count=0
all_valid=true
for skill in "${WORKFLOW_SKILLS[@]}" "${WRAPPER_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  [ -f "$file" ] || continue
  agents_referenced=$(grep -oE '`[a-z]+-[a-z-]+`' "$file" 2>/dev/null | tr -d '`' | sort -u || true)
  for agent_ref in $agents_referenced; do
    if find "$PLUGIN_DIR/agents" -name "$agent_ref.md" 2>/dev/null | grep -q .; then
      ref_count=$((ref_count + 1))
    fi
  done
done
if [ "$ref_count" -gt 0 ]; then
  pass "workflow/wrapper skills reference $ref_count valid agents"
else
  must_fix "workflow/wrapper skills reference agents" "no agent references found"
fi

group "Cross-References — Skills in Skills"

# 2: Workflow skills reference agents (v0.8: agents mediate between workflow skills and domain skills)
ref_count=0
for skill in "${WORKFLOW_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  [ -f "$file" ] || continue
  agents_referenced=$(grep -oE '`[a-z]+-[a-z-]+`' "$file" 2>/dev/null | tr -d '`' | sort -u || true)
  for agent_ref in $agents_referenced; do
    if find "$PLUGIN_DIR/agents" -name "$agent_ref.md" 2>/dev/null | grep -q .; then
      ref_count=$((ref_count + 1))
    fi
  done
done
if [ "$ref_count" -gt 0 ]; then
  pass "workflow skills reference $ref_count valid agents"
else
  should_fix "workflow skills reference agents" "no agent references found"
fi

group "Cross-References — CLAUDE.md Agents"

# 3: CLAUDE.md backtick names resolve to agents or skills
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

# 5: Every skill is mentioned in CLAUDE.md (check dir name, colon form, or base name)
all_mentioned=true
for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  # Also check colon form (workflows-brainstorm → workflows:brainstorm) and base name (brainstorm)
  colon_form=$(echo "$name" | sed 's/-/:/')
  base_name=$(echo "$name" | sed 's/^workflows-//')
  if ! grep -q "$name\|$colon_form\|$base_name" "$PLUGIN_DIR/CLAUDE.md"; then
    all_mentioned=false
    must_fix "skill $name in CLAUDE.md" "skill not documented"
  fi
done
if $all_mentioned; then pass "all skills mentioned in CLAUDE.md"; fi

group "Cross-References — README Skills"

# 6: Slash commands in README exist as skill files
quickstart_cmds=$(python3 -c "
import re, os
text = open(os.environ['PLUGIN_DIR'] + '/README.md').read()
cmds = set(re.findall(r'(?<!\w)/((?:workflows:)?(?:ideate|brainstorm|plan|work|review|compound|estimate|lfg|slfg|replicate))\b', text))
for c in sorted(cmds):
    print('/' + c)
" 2>/dev/null)

all_valid=true
for cmd in $quickstart_cmds; do
  # Convert slash command name to skill directory name
  # /workflows:brainstorm -> workflows-brainstorm, /lfg -> lfg
  skill_name=$(echo "$cmd" | sed 's|^/||; s|:|-|g')
  if [ ! -f "$PLUGIN_DIR/skills/$skill_name/SKILL.md" ]; then
    all_valid=false
    must_fix "README command $cmd exists as skill" "no file at skills/$skill_name/SKILL.md"
  fi
done
if $all_valid; then pass "all README slash commands resolve to skill files"; fi

# 7: Every migrated skill name is mentioned in README
all_mentioned=true
for skill in "${WORKFLOW_SKILLS[@]}" "${CHAIN_SKILLS[@]}" "${WRAPPER_SKILLS[@]}"; do
  # Check for the skill name or its slash-command form
  # workflows-brainstorm -> check for "brainstorm" (appears in /workflows:brainstorm)
  base_name=$(echo "$skill" | sed 's/^workflows-//')
  if ! grep -q "$base_name" "$PLUGIN_DIR/README.md"; then
    all_mentioned=false
    must_fix "skill $skill in README" "skill not documented"
  fi
done
if $all_mentioned; then pass "all migrated skills mentioned in README"; fi

group "Cross-References — Hook Integrity"

# 8: Hook event types are valid Claude Code events
valid_events="SessionStart|SessionEnd|PreToolUse|PostToolUse|PostToolUseFailure|Stop|StopFailure|SubagentStart|SubagentStop|UserPromptSubmit|PreCompact|PostCompact|Notification|PermissionRequest|TaskCreated|TaskCompleted|TeammateIdle|InstructionsLoaded|ConfigChange|CwdChanged|FileChanged|WorktreeCreate|WorktreeRemove|Elicitation|ElicitationResult"
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

# 9: SessionStart is prompt-based (no external script dependency)
py_eval "SessionStart hook is prompt-based" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for h in d['hooks']['SessionStart'][0]['hooks']:
    assert h['type'] == 'prompt', f'expected prompt type, got {h[\"type\"]}'
" "SessionStart should be a prompt hook"

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

# 11: UserPromptSubmit references at least 3 skills (v0.6: skills are the routing targets)
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

group "Cross-References — Workflow Skills"

# 13-14: Workflow skills reference existing agents
for skill in workflows-review workflows-work; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
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
      pass "skill $skill references valid agents"
    else
      should_fix "skill $skill references agents" "no agent references found"
    fi
  fi
done

# 15-16: Wrapper skills reference skills or agents
for skill in "${WRAPPER_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  if [ -f "$file" ]; then
    refs=$(grep -oE '`[a-z]+-[a-z-]+`' "$file" 2>/dev/null | tr -d '`' | sort -u || true)
    found=false
    for ref in $refs; do
      if [ -d "$PLUGIN_DIR/skills/$ref" ] || find "$PLUGIN_DIR/agents" -name "$ref.md" 2>/dev/null | grep -q .; then
        found=true
        break
      fi
    done
    if $found; then
      pass "skill $skill references valid components"
    else
      should_fix "skill $skill references components" "no skill or agent references found"
    fi
  fi
done

group "Cross-References — README Completeness"

# 17-19: All agent categories in README
for cat in "Review" "Research" "Workflow"; do
  if grep -q "$cat" "$PLUGIN_DIR/README.md"; then
    pass "README has $cat agent section"
  else
    must_fix "README has $cat agent section" "missing"
  fi
done

group "Cross-References — Chain Skills"

# 21-22: Chain skills delegate to workflow skills (plan, work, review, compound)
for chain in "${CHAIN_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$chain/SKILL.md"
  if [ -f "$file" ]; then
    delegates_ok=true
    for target in plan work review compound; do
      if ! grep -q "workflows:$target\|workflows-$target\|/$target" "$file"; then
        delegates_ok=false
      fi
    done
    if $delegates_ok; then
      pass "/$chain delegates to all 4 workflow skills"
    else
      must_fix "/$chain delegates to workflows" "missing delegation targets"
    fi
  else
    must_fix "/$chain exists" "file not found"
  fi
done
