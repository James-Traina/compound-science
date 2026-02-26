#!/bin/bash
# Test Group 9: Verify stated counts match reality in CLAUDE.md and README.md
source "$(dirname "$0")/../lib/assert.sh"

group "README Count Claims"

# macOS-compatible extraction (no grep -P)
readme_agents=$(python3 -c "
import re
text = open('$PLUGIN_DIR/README.md').read()
m = re.search(r'Agents \| (\d+)', text)
print(m.group(1) if m else '0')
" 2>/dev/null)

readme_commands=$(python3 -c "
import re
text = open('$PLUGIN_DIR/README.md').read()
m = re.search(r'Commands \| (\d+)', text)
print(m.group(1) if m else '0')
" 2>/dev/null)

readme_skills=$(python3 -c "
import re
text = open('$PLUGIN_DIR/README.md').read()
m = re.search(r'Skills \| (\d+)', text)
print(m.group(1) if m else '0')
" 2>/dev/null)

readme_hooks=$(python3 -c "
import re
text = open('$PLUGIN_DIR/README.md').read()
m = re.search(r'Hooks \| (\d+)', text)
print(m.group(1) if m else '0')
" 2>/dev/null)

readme_total=$(python3 -c "
import re
text = open('$PLUGIN_DIR/README.md').read()
# Match: | **Total** | **38 components** | or similar patterns
m = re.search(r'Total.*?\*\*\s*(\d+)', text)
if not m:
    m = re.search(r'Total.*?\|\s*(\d+)', text)
print(m.group(1) if m else '0')
" 2>/dev/null)

actual_agents=$(find "$PLUGIN_DIR/agents" -name "*.md" | wc -l | tr -d ' ')
actual_commands=$(find "$PLUGIN_DIR/commands" -name "*.md" | wc -l | tr -d ' ')
actual_skills=$(find "$PLUGIN_DIR/skills" -name "SKILL.md" | wc -l | tr -d ' ')
actual_hooks=$(python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
print(len(d['hooks']))
" 2>/dev/null || echo "0")

[ "$readme_agents" = "$actual_agents" ] && pass "README agents=$readme_agents matches" || must_fix "README agents count" "claims $readme_agents, actual $actual_agents"
[ "$readme_commands" = "$actual_commands" ] && pass "README commands=$readme_commands matches" || must_fix "README commands count" "claims $readme_commands, actual $actual_commands"
[ "$readme_skills" = "$actual_skills" ] && pass "README skills=$readme_skills matches" || must_fix "README skills count" "claims $readme_skills, actual $actual_skills"
[ "$readme_hooks" = "$actual_hooks" ] && pass "README hooks=$readme_hooks matches" || must_fix "README hooks count" "claims $readme_hooks, actual $actual_hooks"

actual_total=$((actual_agents + actual_commands + actual_skills + actual_hooks))
[ "$readme_total" = "$actual_total" ] && pass "README total=$readme_total matches" || must_fix "README total count" "claims $readme_total, actual $actual_total"

group "README Section Headers"

# Verify section headers match claimed counts
header_agents=$(python3 -c "
import re
text = open('$PLUGIN_DIR/README.md').read()
m = re.search(r'Agents \((\d+)\)', text)
print(m.group(1) if m else '0')
" 2>/dev/null)

header_skills=$(python3 -c "
import re
text = open('$PLUGIN_DIR/README.md').read()
m = re.search(r'Skills \((\d+)\)', text)
print(m.group(1) if m else '0')
" 2>/dev/null)

header_hooks=$(python3 -c "
import re
text = open('$PLUGIN_DIR/README.md').read()
m = re.search(r'Hooks \((\d+)\)', text)
print(m.group(1) if m else '0')
" 2>/dev/null)

[ "$header_agents" = "$actual_agents" ] && pass "README header 'Agents ($header_agents)' matches" || must_fix "README header agents" "says $header_agents, actual $actual_agents"
[ "$header_skills" = "$actual_skills" ] && pass "README header 'Skills ($header_skills)' matches" || must_fix "README header skills" "says $header_skills, actual $actual_skills"
[ "$header_hooks" = "$actual_hooks" ] && pass "README header 'Hooks ($header_hooks)' matches" || must_fix "README header hooks" "says $header_hooks, actual $actual_hooks"
