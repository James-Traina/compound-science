#!/bin/bash
# Test Group 5: Content quality — no web dev terms, no placeholders, no leaks
source "$(dirname "$0")/../lib/assert.sh"

group "Web Dev Terms"

# Primary exclusion list (from design spec: "Replace ALL web dev references")
WEB_DEV_TERMS="Rails|React|Angular|Vue\.js|Express\.js|Node\.js|webpack|npm run|yarn |DHH|Kieran|iOS app|Android app|Ruby on Rails|ActiveRecord|middleware|REST API|GraphQL|Redux|Next\.js|Nuxt"

hits=$(grep -rn --exclude-dir=qa --exclude-dir=.ralph --exclude-dir=.serena --exclude-dir=.git --exclude-dir=.claude -E "$WEB_DEV_TERMS" "$PLUGIN_DIR" 2>/dev/null || true)
if [ -z "$hits" ]; then
  pass "zero web dev terms"
else
  count=$(echo "$hits" | wc -l | tr -d ' ')
  must_fix "zero web dev terms" "$count hit(s) — $(echo "$hits" | head -3)"
fi

group "Placeholder Markers"

# Real TODO/FIXME markers (not substring matches in words like "placeholder")
real_todos=$(grep -rn --exclude-dir=qa --exclude-dir=.ralph --exclude-dir=.serena --exclude-dir=.git --exclude-dir=.claude -E '^\s*(#|//|<!--)\s*(TODO|FIXME|XXX|HACK|TBD)\b' "$PLUGIN_DIR" 2>/dev/null || true)
if [ -z "$real_todos" ]; then
  pass "no TODO/FIXME/XXX/HACK/TBD comments"
else
  count=$(echo "$real_todos" | wc -l | tr -d ' ')
  must_fix "no TODO/FIXME/XXX/HACK/TBD comments" "$count found"
fi

# Actual placeholder content (not the word "placeholder" used descriptively)
stub_content=$(grep -rn --exclude-dir=qa --exclude-dir=.ralph --exclude-dir=.serena --exclude-dir=.git --exclude-dir=.claude -E 'PLACEHOLDER|<insert |<your |CHANGEME|FILL_IN' "$PLUGIN_DIR" 2>/dev/null || true)
if [ -z "$stub_content" ]; then
  pass "no stub/placeholder content"
else
  count=$(echo "$stub_content" | wc -l | tr -d ' ')
  must_fix "no stub/placeholder content" "$count found"
fi

group "Hardcoded Paths"

# Personal paths (excluding README install URL which intentionally has GitHub username)
personal_paths=$(grep -rn --exclude-dir=qa --exclude-dir=.ralph --exclude-dir=.serena --exclude-dir=.git --exclude-dir=.claude '/Users/jat406\|/home/jat406' "$PLUGIN_DIR" --include="*.md" --include="*.sh" --include="*.json" 2>/dev/null | grep -v 'github.com/jat406' || true)
if [ -z "$personal_paths" ]; then
  pass "no hardcoded personal paths"
else
  count=$(echo "$personal_paths" | wc -l | tr -d ' ')
  must_fix "no hardcoded personal paths" "$count found"
fi

group "Content Depth"

# Agents should be substantive (>100 lines)
shallow_agents=0
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  lines=$(wc -l < "$file" | tr -d ' ')
  if [ "$lines" -lt 100 ]; then
    should_fix "agent $name depth" "only $lines lines (expected >100)"
    shallow_agents=$((shallow_agents + 1))
  fi
done
[ "$shallow_agents" -eq 0 ] && pass "all agents >100 lines"

# Skills should be substantive (>150 lines)
shallow_skills=0
for file in "$PLUGIN_DIR"/skills/*/SKILL.md; do
  name=$(basename "$(dirname "$file")")
  lines=$(wc -l < "$file" | tr -d ' ')
  if [ "$lines" -lt 150 ]; then
    should_fix "skill $name depth" "only $lines lines (expected >150)"
    shallow_skills=$((shallow_skills + 1))
  fi
done
[ "$shallow_skills" -eq 0 ] && pass "all skills >150 lines"

# Commands should be substantive (>100 lines, except chain commands)
shallow_cmds=0
for file in "$PLUGIN_DIR"/commands/*.md "$PLUGIN_DIR"/commands/workflows/*.md; do
  name=$(basename "$file" .md)
  lines=$(wc -l < "$file" | tr -d ' ')
  # Chain commands (lfg, slfg) are intentionally short
  if [ "$name" = "lfg" ] || [ "$name" = "slfg" ]; then
    if [ "$lines" -lt 5 ]; then
      should_fix "command $name depth" "only $lines lines"
      shallow_cmds=$((shallow_cmds + 1))
    fi
  elif [ "$lines" -lt 100 ]; then
    should_fix "command $name depth" "only $lines lines (expected >100)"
    shallow_cmds=$((shallow_cmds + 1))
  fi
done
[ "$shallow_cmds" -eq 0 ] && pass "all commands have appropriate depth"
