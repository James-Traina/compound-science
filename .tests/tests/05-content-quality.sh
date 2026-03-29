#!/usr/bin/env bash
# Test Group 5: Content quality — no web dev terms, no placeholders, no leaks (20 tests)
# v0.6: commands/ removed; web dev and depth checks updated for skills-only architecture
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/fixtures.sh"

EXCLUDE="--exclude-dir=.tests --exclude-dir=.evals --exclude-dir=.ralph --exclude-dir=.serena --exclude-dir=.git --exclude-dir=.claude"

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

# 6: No mention of web frameworks in skills
web_in_skills=$(grep -rn $EXCLUDE -Ei "$WEB_REGEX" "$PLUGIN_DIR/skills/" 2>/dev/null || true)
if [ -z "$web_in_skills" ]; then
  pass "no web terminology in skills"
else
  count=$(echo "$web_in_skills" | wc -l | tr -d ' ')
  should_fix "no web terminology in skills" "$count hit(s)"
fi

group "Content Substance"

# 7: All agents have >50 lines of content
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

# 8: Workflow skills have >100 lines (stubs/wrappers/chains excluded)
all_deep=true
for skill in "${WORKFLOW_SKILLS[@]}"; do
  # workflows-ideate is intentionally lean (divergent phase, not structured multi-phase)
  [ "$skill" = "workflows-ideate" ] && continue
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -lt 100 ]; then
      all_deep=false
      must_fix "skill $skill has depth" "only $lines lines, need >=100"
    fi
  fi
done
if $all_deep; then pass "all workflow skills have >=100 lines (ideate/stubs/wrappers/chains excluded)"; fi

# 9: All original skills have >50 lines (migrated skills checked separately)
all_deep=true
for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  file="$dir/SKILL.md"
  # Skip wrapper and chain skills from depth check (intentionally short)
  case " ${WRAPPER_SKILLS[*]} ${CHAIN_SKILLS[*]} " in *" $name "*) continue ;; esac
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -lt 50 ]; then
      all_deep=false
      must_fix "skill $name has depth" "only $lines lines, need >=50"
    fi
  fi
done
if $all_deep; then pass "all non-stub skills have >=50 lines"; fi

group "Output Format Sections"

# 10: Workflow skills have Output Format section (stubs/wrappers/chains excluded)
all_output=true
for skill in "${WORKFLOW_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  if [ -f "$file" ] && ! grep -qi 'Output Format\|Output\|output' "$file"; then
    all_output=false
    must_fix "skill $skill has output section" "missing output format"
  fi
done
if $all_output; then pass "all workflow skills document output (stubs/wrappers/chains excluded)"; fi

# 11: Workflow skills have Routes To or Handoff section (stubs/wrappers/chains excluded)
all_routes=true
for skill in "${WORKFLOW_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  if [ -f "$file" ] && ! grep -qi 'Routes To\|routes\|Handoff' "$file"; then
    all_routes=false
    should_fix "skill $skill has routes/handoff section" "missing routes or handoff"
  fi
done
if $all_routes; then pass "all workflow skills have routes or handoff (stubs/wrappers/chains excluded)"; fi

group "Emoji Consistency"

# 12: Agents use consistent emoji markers
agents_with_emoji=$(grep -rl '🔴\|✅' "$PLUGIN_DIR/agents/" 2>/dev/null | wc -l | tr -d ' ')
if [ "$agents_with_emoji" -gt 0 ]; then
  pass "agents use FAIL/PASS emoji markers ($agents_with_emoji files)"
else
  should_fix "agents use FAIL/PASS markers" "no emoji markers found"
fi

group "No Sensitive Data"

# 13: No API keys or tokens (python3 for portable regex — \x27 is not supported by BSD grep -E on macOS)
py_eval "no API keys or tokens" "
import re, os
exclude = {'tests', '.ralph', '.serena', '.git', '.claude'}
pat = re.compile(r'sk-[a-z0-9]{20,}|api[_-]?key\s*=\s*[\x22\x27][a-z0-9]|password\s*=\s*[\x22\x27][^\x22\x27]{4,}[\x22\x27]', re.I)
findings = []
for root, dirs, files in os.walk(os.environ['PLUGIN_DIR']):
    dirs[:] = [d for d in dirs if d not in exclude]
    for f in files:
        try:
            text = open(os.path.join(root, f), errors='ignore').read()
            for m in pat.finditer(text):
                findings.append(os.path.basename(root) + '/' + f + ': ' + m.group()[:30])
        except (PermissionError, IsADirectoryError):
            pass
        except OSError as e:
            findings.append('SCAN ERROR: ' + str(e))
assert not findings, 'sensitive data: ' + findings[0]
" "python3 failed — could not scan for credentials"

# 14: No email addresses (except in LICENSE/README)
emails=$(grep -rn $EXCLUDE -Ei '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}' "$PLUGIN_DIR" --include="*.md" --include="*.sh" --include="*.json" 2>/dev/null | grep -v 'LICENSE\|README\|github.com\|noreply' || true)
if [ -z "$emails" ]; then
  pass "no email addresses in code"
else
  should_fix "no email addresses in code" "$(echo "$emails" | wc -l | tr -d ' ') found"
fi

group "Markdown Quality"

# 15: No broken markdown links in README
broken_links=$(python3 -c "
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

# 16-18: CLAUDE.md mentions all agent categories
for cat in Review Research Workflow; do
  if grep -q "$cat" "$PLUGIN_DIR/CLAUDE.md"; then
    pass "CLAUDE.md mentions $cat agents"
  else
    must_fix "CLAUDE.md mentions $cat agents" "category missing"
  fi
done

# 19: All agent and skill names use valid kebab-case naming
all_kebab=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! echo "$name" | grep -qE '^[a-z]+-[a-z]+$'; then
    all_kebab=false
    must_fix "agent $name uses word-word kebab-case" "invalid naming"
  fi
done
for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  # Allow multi-word names like workflows-brainstorm, workflows-compound
  # Allow migrated workflow skills (workflows-*), chain skills, and stubs with single-word names
  if echo "$name" | grep -qE '^workflows-[a-z]+$'; then continue; fi
  # Allow single-word skill names (lfg, slfg, estimate, replicate, simulate, identify, diagnose, tabulate, visualize)
  if echo "$name" | grep -qE '^[a-z]+$'; then continue; fi
  if ! echo "$name" | grep -qE '^[a-z]+-[a-z]+$'; then
    all_kebab=false
    must_fix "skill $name uses valid kebab-case" "invalid naming"
  fi
done
if $all_kebab; then pass "all agent and skill names use valid naming"; fi

# 20: No commands/ directory exists (migration complete)
if [ -d "$PLUGIN_DIR/commands" ]; then
  must_fix "commands/ directory removed" "stale commands/ directory found"
else
  pass "commands/ directory removed (migration complete)"
fi
