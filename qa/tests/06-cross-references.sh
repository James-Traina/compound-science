#!/bin/bash
# Test Group 6: Cross-reference integrity between components
source "$(dirname "$0")/../lib/assert.sh"

group "Cross-References — Agents in Commands"

# Extract agent names referenced in command files and verify they exist
for cmd_file in "$PLUGIN_DIR"/commands/*.md "$PLUGIN_DIR"/commands/workflows/*.md; do
  cmd_name=$(basename "$cmd_file" .md)

  # Find backtick-quoted agent names in the command
  agents_referenced=$(grep -oE '`[a-z]+-[a-z-]+`' "$cmd_file" 2>/dev/null | tr -d '`' | sort -u || true)

  for agent_ref in $agents_referenced; do
    # Check if this is actually an agent (exists in agents/)
    if find "$PLUGIN_DIR/agents" -name "$agent_ref.md" 2>/dev/null | grep -q .; then
      pass "command $cmd_name → agent $agent_ref exists"
    fi
    # If it's not an agent, it might be a skill or other reference — skip silently
  done
done

group "Cross-References — Skills in Commands"

for cmd_file in "$PLUGIN_DIR"/commands/*.md "$PLUGIN_DIR"/commands/workflows/*.md; do
  cmd_name=$(basename "$cmd_file" .md)

  # Find skill references (backtick-quoted names that match skill directories)
  skills_referenced=$(grep -oE '`[a-z]+-[a-z-]+`' "$cmd_file" 2>/dev/null | tr -d '`' | sort -u || true)

  for skill_ref in $skills_referenced; do
    if [ -d "$PLUGIN_DIR/skills/$skill_ref" ]; then
      pass "command $cmd_name → skill $skill_ref exists"
    fi
  done
done

group "Cross-References — CLAUDE.md Accuracy"

# Every agent name in CLAUDE.md should be a real file
claude_agents=$(grep -oE '`[a-z]+-[a-z-]+`' "$PLUGIN_DIR/CLAUDE.md" | tr -d '`' | sort -u)
for name in $claude_agents; do
  if find "$PLUGIN_DIR/agents" -name "$name.md" 2>/dev/null | grep -q .; then
    pass "CLAUDE.md agent $name exists"
  elif [ -d "$PLUGIN_DIR/skills/$name" ]; then
    pass "CLAUDE.md skill $name exists"
  fi
  # Other backtick names (like command names) — skip
done

group "Cross-References — README Quick Start"

# Verify slash commands in Quick Start section exist
# Only match /word or /word:word patterns (not URL paths like /path/to/)
quickstart_cmds=$(python3 -c "
import re
text = open('$PLUGIN_DIR/README.md').read()
# Match /word or /word:word but not /path/to/ style
cmds = set(re.findall(r'(?<!\w)/((?:workflows:)?(?:brainstorm|plan|work|review|compound|estimate|simulate|identify|lfg|slfg))\b', text))
for c in sorted(cmds):
    print('/' + c)
" 2>/dev/null)

for cmd in $quickstart_cmds; do
  cmd_path=$(echo "$cmd" | sed 's|^/||; s|:|/|g')
  if [ -f "$PLUGIN_DIR/commands/$cmd_path.md" ]; then
    pass "README command $cmd exists"
  else
    must_fix "README command $cmd exists" "no file at commands/$cmd_path.md"
  fi
done

group "Cross-References — Hook Integrity"

# Verify hook event types are valid Claude Code events
valid_events="SessionStart|SessionEnd|PreToolUse|PostToolUse|Stop|SubagentStop|UserPromptSubmit|PreCompact|Notification"
hook_events=$(python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
for e in d['hooks'].keys():
    print(e)
" 2>/dev/null)

for event in $hook_events; do
  if echo "$event" | grep -qE "^($valid_events)$"; then
    pass "hook event $event is valid"
  else
    must_fix "hook event $event is valid" "not a recognized Claude Code hook event"
  fi
done

# Verify SessionStart script path resolves
session_cmd=$(python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
for h in d['hooks']['SessionStart'][0]['hooks']:
    if h['type'] == 'command':
        print(h['command'])
" 2>/dev/null || echo "")

if echo "$session_cmd" | grep -q 'CLAUDE_PLUGIN_ROOT.*session-init.sh'; then
  pass "SessionStart hook uses portable path"
else
  must_fix "SessionStart hook uses portable path" "got: $session_cmd"
fi
