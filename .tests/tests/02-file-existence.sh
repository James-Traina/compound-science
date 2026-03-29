#!/usr/bin/env bash
# Test Group 2: All components exist as files with correct counts (18 tests)
# v0.8: 7 skills merged; 20 skills remain (10 domain + 6 workflow + 2 chain + 2 wrapper)
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/fixtures.sh"

group "File Existence — Agents"

AGENTS=(
  "review/econometric-reviewer"
  "review/mathematical-prover"
  "review/numerical-auditor"
  "review/identification-critic"
  "review/journal-referee"
  "research/literature-scout"
  "research/methods-explorer"
  "research/data-detective"
  "workflow/reproducibility-auditor"
  "workflow/workflow-coordinator"
)

# 1: all 10 agents exist
all_exist=true
for agent in "${AGENTS[@]}"; do
  if [ ! -f "$PLUGIN_DIR/agents/$agent.md" ]; then
    all_exist=false
    must_fix "agent $(basename $agent) exists" "file not found: agents/$agent.md"
  fi
done
if $all_exist; then
  pass "all 10 agent files exist"
fi

group "File Existence — Skills"

# 2-3: all 20 skills exist (dir + SKILL.md)
all_dirs=true
all_files=true
for skill in "${SKILLS[@]}"; do
  if [ ! -d "$PLUGIN_DIR/skills/$skill" ]; then
    all_dirs=false
    must_fix "skill dir $skill exists" "directory not found"
  fi
  if [ ! -f "$PLUGIN_DIR/skills/$skill/SKILL.md" ]; then
    all_files=false
    must_fix "skill SKILL.md $skill exists" "file not found"
  fi
done
if $all_dirs; then pass "all 20 skill directories exist"; fi
if $all_files; then pass "all 20 skill SKILL.md files exist"; fi

group "File Existence — Infrastructure"

# 4-8
assert_file_exists "CLAUDE.md" "$PLUGIN_DIR/CLAUDE.md"
assert_file_exists "README.md" "$PLUGIN_DIR/README.md"
assert_file_exists "LICENSE" "$PLUGIN_DIR/LICENSE"
assert_file_exists "hooks/hooks.json" "$PLUGIN_DIR/hooks/hooks.json"
assert_file_exists "output-styles/research-mode.md" "$PLUGIN_DIR/output-styles/research-mode.md"

group "Component Counts"

actual_agents=$(find "$PLUGIN_DIR/agents" -name "*.md" | wc -l | tr -d ' ')
actual_skills=$(find "$PLUGIN_DIR/skills" -name "SKILL.md" | wc -l | tr -d ' ')
actual_hooks=$(python3 -c "
import json, os
d = json.load(open(os.environ['PLUGIN_DIR'] + '/hooks/hooks.json'))
print(len(d['hooks']))
" 2>/dev/null || echo "0")

# 9-12
assert_count "agents = 10" 10 "$actual_agents"
assert_count "skills = 20" 20 "$actual_skills"
assert_count "hooks = 5" 5 "$actual_hooks"

total=$((actual_agents + actual_skills + actual_hooks))
assert_count "total components = 35" 35 "$total"

group "Agent Category Counts"

review_count=$(find "$PLUGIN_DIR/agents/review" -name "*.md" | wc -l | tr -d ' ')
research_count=$(find "$PLUGIN_DIR/agents/research" -name "*.md" | wc -l | tr -d ' ')
workflow_count=$(find "$PLUGIN_DIR/agents/workflow" -name "*.md" | wc -l | tr -d ' ')

# 13-15
assert_count "review agents = 5" 5 "$review_count"
assert_count "research agents = 3" 3 "$research_count"
assert_count "workflow agents = 2" 2 "$workflow_count"

group "README Cross-check"

# 16: README component counts match filesystem
# v0.6: commands/ removed; README reports 0 commands, 33 skills.
export ACTUAL_AGENTS="$actual_agents" ACTUAL_SKILLS="$actual_skills" ACTUAL_HOOKS="$actual_hooks" ACTUAL_TOTAL="$total"
py_eval "README counts match filesystem" "
import re, os
text = open(os.environ['PLUGIN_DIR'] + '/README.md').read()

# Extract all numbers from the Component Counts table
agents_m = re.search(r'Agents\s*\|\s*(\d+)', text)
skills_m = re.search(r'Skills\s*\|\s*(\d+)', text)
hooks_m = re.search(r'Hooks\s*\|\s*(\d+)', text)

assert agents_m, 'Agents count not found in README'
assert skills_m, 'Skills count not found in README'
assert hooks_m, 'Hooks count not found in README'

readme_agents = int(agents_m.group(1))
readme_skills = int(skills_m.group(1))
readme_hooks = int(hooks_m.group(1))

actual_agents = int(os.environ['ACTUAL_AGENTS'])
actual_skills = int(os.environ['ACTUAL_SKILLS'])
actual_hooks = int(os.environ['ACTUAL_HOOKS'])

assert readme_agents == actual_agents, f'Agents: README={readme_agents}, filesystem={actual_agents}'
assert readme_skills == actual_skills, f'Skills: README={readme_skills}, filesystem={actual_skills}'
assert readme_hooks == actual_hooks, f'Hooks: README={readme_hooks}, filesystem={actual_hooks}'
" "Component Counts table is stale"

# 17: Only 3 agent subdirectories exist
agent_dirs=$(find "$PLUGIN_DIR/agents" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_count "agent subdirectories = 3" 3 "$agent_dirs"

# 18: No orphan .md files in agents/ root
orphans=$(find "$PLUGIN_DIR/agents" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
assert_count "no orphan agent files" 0 "$orphans"
