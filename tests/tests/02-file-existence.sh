#!/bin/bash
# Test Group 2: All components exist as files with correct counts (21 tests)
source "$(dirname "$0")/../lib/assert.sh"

group "File Existence — Agents"

AGENTS=(
  "review/econometric-reviewer"
  "review/mathematical-prover"
  "review/numerical-auditor"
  "review/identification-critic"
  "review/journal-referee"
  "review/simulation-designer"
  "review/process-architect"
  "review/equilibrium-analyst"
  "review/calibration-assessor"
  "review/results-verifier"
  "research/literature-scout"
  "research/methods-explorer"
  "research/data-detective"
  "research/solutions-archivist"
  "research/benchmark-researcher"
  "workflow/pipeline-validator"
  "workflow/reproducibility-checker"
  "workflow/specification-analyzer"
  "workflow/research-coordinator"
  "workflow/progress-tracker"
)

# 1: all 20 agents exist
all_exist=true
for agent in "${AGENTS[@]}"; do
  if [ ! -f "$PLUGIN_DIR/agents/$agent.md" ]; then
    all_exist=false
    must_fix "agent $(basename $agent) exists" "file not found: agents/$agent.md"
  fi
done
if $all_exist; then
  pass "all 20 agent files exist"
fi

group "File Existence — Commands"

COMMANDS=(
  "workflows/brainstorm"
  "workflows/plan"
  "workflows/work"
  "workflows/review"
  "workflows/compound"
  "estimate"
  "simulate"
  "identify"
  "lfg"
  "slfg"
  "diagnose"
  "tabulate"
  "replicate"
  "visualize"
  "stress-test"
)

# 2: all 15 commands exist
all_exist=true
for cmd in "${COMMANDS[@]}"; do
  if [ ! -f "$PLUGIN_DIR/commands/$cmd.md" ]; then
    all_exist=false
    must_fix "command $(basename $cmd) exists" "file not found: commands/$cmd.md"
  fi
done
if $all_exist; then
  pass "all 15 command files exist"
fi

group "File Existence — Skills"

SKILLS=(
  "strategy-brainstorm"
  "causal-inference"
  "compound-catalog"
  "git-worktree"
  "swarm-orchestration"
  "reproducible-pipelines"
  "project-setup"
  "structural-modeling"
  "submission-guide"
  "empirical-playbook"
)

# 3-4: all 10 skills exist (dir + SKILL.md)
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
if $all_dirs; then pass "all 10 skill directories exist"; fi
if $all_files; then pass "all 10 skill SKILL.md files exist"; fi

group "File Existence — Infrastructure"

# 5-9
assert_file_exists "CLAUDE.md" "$PLUGIN_DIR/CLAUDE.md"
assert_file_exists "README.md" "$PLUGIN_DIR/README.md"
assert_file_exists "LICENSE" "$PLUGIN_DIR/LICENSE"
assert_file_exists "hooks/hooks.json" "$PLUGIN_DIR/hooks/hooks.json"
assert_file_exists "scripts/session-init.sh" "$PLUGIN_DIR/scripts/session-init.sh"

group "Component Counts"

actual_agents=$(find "$PLUGIN_DIR/agents" -name "*.md" | wc -l | tr -d ' ')
actual_commands=$(find "$PLUGIN_DIR/commands" -name "*.md" | wc -l | tr -d ' ')
actual_skills=$(find "$PLUGIN_DIR/skills" -name "SKILL.md" | wc -l | tr -d ' ')
actual_hooks=$(python3 -c "
import json, os
d = json.load(open(os.environ['PLUGIN_DIR'] + '/hooks/hooks.json'))
print(len(d['hooks']))
" 2>/dev/null || echo "0")

# 10-14
assert_count "agents = 20" 20 "$actual_agents"
assert_count "commands = 15" 15 "$actual_commands"
assert_count "skills = 10" 10 "$actual_skills"
assert_count "hooks = 7" 7 "$actual_hooks"

total=$((actual_agents + actual_commands + actual_skills + actual_hooks))
assert_count "total components = 52" 52 "$total"

group "Agent Category Counts"

review_count=$(find "$PLUGIN_DIR/agents/review" -name "*.md" | wc -l | tr -d ' ')
research_count=$(find "$PLUGIN_DIR/agents/research" -name "*.md" | wc -l | tr -d ' ')
workflow_count=$(find "$PLUGIN_DIR/agents/workflow" -name "*.md" | wc -l | tr -d ' ')

# 15-17
assert_count "review agents = 10" 10 "$review_count"
assert_count "research agents = 5" 5 "$research_count"
assert_count "workflow agents = 5" 5 "$workflow_count"

group "README Cross-check"

# 18: README component counts match filesystem
export ACTUAL_AGENTS="$actual_agents" ACTUAL_COMMANDS="$actual_commands" ACTUAL_SKILLS="$actual_skills" ACTUAL_HOOKS="$actual_hooks" ACTUAL_TOTAL="$total"
py_eval "README counts match filesystem" "
import re, os
text = open(os.environ['PLUGIN_DIR'] + '/README.md').read()
counts = {m.group(1): m.group(2) for m in re.finditer(r'(Agents|Commands|Skills|Hooks|Total)\D+?(\d+)', text)}
actual = {'Agents': os.environ['ACTUAL_AGENTS'], 'Commands': os.environ['ACTUAL_COMMANDS'], 'Skills': os.environ['ACTUAL_SKILLS'], 'Hooks': os.environ['ACTUAL_HOOKS'], 'Total': os.environ['ACTUAL_TOTAL']}
assert all(counts.get(k) == v for k, v in actual.items()), f'mismatch: {counts} vs {actual}'
" "Component Counts table is stale"

# 19: Only 3 agent subdirectories exist
agent_dirs=$(find "$PLUGIN_DIR/agents" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_count "agent subdirectories = 3" 3 "$agent_dirs"

# 20: No orphan .md files in agents/ root
orphans=$(find "$PLUGIN_DIR/agents" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
assert_count "no orphan agent files" 0 "$orphans"
