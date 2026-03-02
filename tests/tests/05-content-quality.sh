#!/bin/bash
# Test Group 5: Content quality — no web dev terms, no placeholders, no leaks (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

EXCLUDE="--exclude-dir=tests --exclude-dir=.ralph --exclude-dir=.serena --exclude-dir=.git --exclude-dir=.claude"

group "Web Dev Terms"

# 1
WEB_DEV_TERMS="Rails|React|Angular|Vue\.js|Express\.js|Node\.js|webpack|npm run|yarn |DHH|Kieran|iOS app|Android app|Ruby on Rails|ActiveRecord|middleware|REST API|GraphQL|Redux|Next\.js|Nuxt"
hits=$(grep -rn $EXCLUDE -E "$WEB_DEV_TERMS" "$PLUGIN_DIR" 2>/dev/null || true)
if [ -z "$hits" ]; then
  pass "zero web dev terms"
else
  count=$(echo "$hits" | wc -l | tr -d ' ')
  must_fix "zero web dev terms" "$count hit(s) — $(echo "$hits" | head -3)"
fi

group "Placeholder Markers"

# 2
real_todos=$(grep -rn $EXCLUDE -E '^\s*(#|//|<!--)\s*(TODO|FIXME|XXX|HACK|TBD)\b' "$PLUGIN_DIR" 2>/dev/null || true)
if [ -z "$real_todos" ]; then
  pass "no TODO/FIXME/XXX/HACK/TBD comments"
else
  count=$(echo "$real_todos" | wc -l | tr -d ' ')
  must_fix "no TODO/FIXME/XXX/HACK/TBD comments" "$count found"
fi

# 3
stub_content=$(grep -rn $EXCLUDE -E 'PLACEHOLDER|<insert |<your |CHANGEME|FILL_IN' "$PLUGIN_DIR" 2>/dev/null || true)
if [ -z "$stub_content" ]; then
  pass "no stub/placeholder content"
else
  count=$(echo "$stub_content" | wc -l | tr -d ' ')
  must_fix "no stub/placeholder content" "$count found"
fi

group "Hardcoded Paths"

# 4
personal_paths=$(grep -rn $EXCLUDE '/Users/jat406\|/home/jat406' "$PLUGIN_DIR" --include="*.md" --include="*.sh" --include="*.json" 2>/dev/null | grep -v 'github.com/jat406' || true)
if [ -z "$personal_paths" ]; then
  pass "no hardcoded personal paths"
else
  count=$(echo "$personal_paths" | wc -l | tr -d ' ')
  must_fix "no hardcoded personal paths" "$count found"
fi

group "Domain Consistency"

# 5: No mention of web frameworks in agent prompts
# Note: "docker", "backend", "API endpoint" are dual-use (legitimate in replication/plotting/orchestration contexts)
# Only flag unambiguously web-dev terms: frontend framework/server patterns, web-specific frameworks
WEB_REGEX='react\.js|vue\.js|express\.js|django|flask|webpack|npm install|GraphQL|REST API|JWT|OAuth|microservice'
web_in_agents=$(grep -rn $EXCLUDE -Ei "$WEB_REGEX" "$PLUGIN_DIR/agents/" 2>/dev/null || true)
if [ -z "$web_in_agents" ]; then
  pass "no web terminology in agents"
else
  count=$(echo "$web_in_agents" | wc -l | tr -d ' ')
  should_fix "no web terminology in agents" "$count hit(s)"
fi

# 6: No mention of web frameworks in commands
web_in_commands=$(grep -rn $EXCLUDE -Ei "$WEB_REGEX" "$PLUGIN_DIR/commands/" 2>/dev/null || true)
if [ -z "$web_in_commands" ]; then
  pass "no web terminology in commands"
else
  count=$(echo "$web_in_commands" | wc -l | tr -d ' ')
  should_fix "no web terminology in commands" "$count hit(s)"
fi

# 7: No mention of web frameworks in skills
web_in_skills=$(grep -rn $EXCLUDE -Ei "$WEB_REGEX" "$PLUGIN_DIR/skills/" 2>/dev/null || true)
if [ -z "$web_in_skills" ]; then
  pass "no web terminology in skills"
else
  count=$(echo "$web_in_skills" | wc -l | tr -d ' ')
  should_fix "no web terminology in skills" "$count hit(s)"
fi

group "Content Substance"

# 8: All agents have >50 lines of content
all_deep=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  lines=$(wc -l < "$file" | tr -d ' ')
  if [ "$lines" -lt 50 ]; then
    all_deep=false
    must_fix "agent $name has depth" "only $lines lines, need >=50"
  fi
done
if $all_deep; then pass "all agents have >=50 lines"; fi

# 9: All domain/utility commands have >100 lines
all_deep=true
for cmd in estimate simulate identify diagnose tabulate replicate visualize stress-test; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -lt 100 ]; then
      all_deep=false
      must_fix "command $cmd has depth" "only $lines lines, need >=100"
    fi
  fi
done
if $all_deep; then pass "all domain/utility commands have >=100 lines"; fi

# 10: All skills have >50 lines
all_deep=true
for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  file="$dir/SKILL.md"
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -lt 50 ]; then
      all_deep=false
      must_fix "skill $name has depth" "only $lines lines, need >=50"
    fi
  fi
done
if $all_deep; then pass "all skills have >=50 lines"; fi

group "Output Format Sections"

# 11: Domain/utility commands have Output Format section
all_output=true
for cmd in estimate simulate identify diagnose tabulate replicate visualize stress-test; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  if [ -f "$file" ] && ! grep -qi 'Output Format\|Output\|output' "$file"; then
    all_output=false
    must_fix "command $cmd has output section" "missing output format"
  fi
done
if $all_output; then pass "all domain/utility commands document output"; fi

# 12: Domain/utility commands have Routes To section
all_routes=true
for cmd in estimate simulate identify diagnose tabulate replicate visualize stress-test; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  if [ -f "$file" ] && ! grep -qi 'Routes To\|routes' "$file"; then
    all_routes=false
    should_fix "command $cmd has routes section" "missing routes to"
  fi
done
if $all_routes; then pass "all domain/utility commands have routes"; fi

group "Emoji Consistency"

# 13: Agents use consistent emoji markers
agents_with_emoji=$(grep -rl '🔴\|✅' "$PLUGIN_DIR/agents/" 2>/dev/null | wc -l | tr -d ' ')
if [ "$agents_with_emoji" -gt 0 ]; then
  pass "agents use FAIL/PASS emoji markers ($agents_with_emoji files)"
else
  should_fix "agents use FAIL/PASS markers" "no emoji markers found"
fi

group "No Sensitive Data"

# 14: No API keys or tokens
sensitive=$(grep -rn $EXCLUDE -Ei 'sk-[a-z0-9]{20,}|api[_-]?key\s*=\s*["\x27][a-z0-9]|password\s*=\s*["\x27][^\x27"]+["\x27]' "$PLUGIN_DIR" 2>/dev/null || true)
if [ -z "$sensitive" ]; then
  pass "no API keys or tokens"
else
  must_fix "no API keys or tokens" "sensitive data found"
fi

# 15: No email addresses (except in LICENSE/README)
emails=$(grep -rn $EXCLUDE -Ei '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}' "$PLUGIN_DIR" --include="*.md" --include="*.sh" --include="*.json" 2>/dev/null | grep -v 'LICENSE\|README\|github.com\|noreply' || true)
if [ -z "$emails" ]; then
  pass "no email addresses in code"
else
  should_fix "no email addresses in code" "$(echo "$emails" | wc -l | tr -d ' ') found"
fi

group "Markdown Quality"

# 16: No broken markdown links in README
broken_links=$(PLUGIN_DIR="$PLUGIN_DIR" python3 -c "
import re, os
text = open(os.environ['PLUGIN_DIR'] + '/README.md').read()
links = re.findall(r'\[([^\]]+)\]\(([^\)]+)\)', text)
for label, url in links:
    if url.startswith('#') or url.startswith('http'):
        continue
    if not os.path.exists(os.path.join(os.environ['PLUGIN_DIR'], url)):
        print(f'{label} -> {url}')
" 2>/dev/null || true)
if [ -z "$broken_links" ]; then
  pass "no broken local links in README"
else
  should_fix "no broken local links in README" "$broken_links"
fi

# 17: CLAUDE.md mentions all agent categories
for cat in Review Research Workflow; do
  if grep -q "$cat" "$PLUGIN_DIR/CLAUDE.md"; then
    pass "CLAUDE.md mentions $cat agents"
  else
    must_fix "CLAUDE.md mentions $cat agents" "category missing"
  fi
done

# 18: All agent and skill names use word-word kebab-case (no single words, no abbreviations, no 3+ words)
all_kebab=true
exceptions="git-worktree"  # git is a proper noun — justified exception
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! echo "$name" | grep -qE '^[a-z]+-[a-z]+$'; then
    all_kebab=false
    must_fix "agent $name uses word-word kebab-case" "invalid naming"
  fi
done
for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  if [ "$name" = "git-worktree" ]; then continue; fi
  if ! echo "$name" | grep -qE '^[a-z]+-[a-z]+$'; then
    all_kebab=false
    must_fix "skill $name uses word-word kebab-case" "invalid naming"
  fi
done
if $all_kebab; then pass "all agent and skill names use word-word kebab-case"; fi
