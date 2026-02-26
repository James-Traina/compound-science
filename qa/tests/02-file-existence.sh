#!/bin/bash
# Test Group 2: All components exist as files with correct structure
source "$(dirname "$0")/../lib/assert.sh"

group "File Existence — Agents"

AGENTS=(
  "review/econometrician"
  "review/mathematical-prover"
  "review/numerical-auditor"
  "review/identification-critic"
  "review/referee"
  "research/literature-scout"
  "research/methods-researcher"
  "research/data-detective"
  "research/learnings-researcher"
  "methods/monte-carlo-designer"
  "methods/dgp-architect"
  "methods/equilibrium-analyst"
  "workflow/pipeline-validator"
  "workflow/reproducibility-checker"
  "workflow/spec-flow-analyzer"
)

for agent in "${AGENTS[@]}"; do
  name=$(basename "$agent")
  assert_file_exists "agent: $name" "$PLUGIN_DIR/agents/$agent.md"
done

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
)

for cmd in "${COMMANDS[@]}"; do
  name=$(basename "$cmd")
  assert_file_exists "command: $name" "$PLUGIN_DIR/commands/$cmd.md"
done

group "File Existence — Skills"

SKILLS=(
  "brainstorming"
  "causal-inference"
  "compound-docs"
  "git-worktree"
  "orchestrating-swarms"
  "reproducible-pipelines"
  "setup"
  "structural-modeling"
)

for skill in "${SKILLS[@]}"; do
  assert_dir_exists "skill dir: $skill" "$PLUGIN_DIR/skills/$skill"
  assert_file_exists "skill SKILL.md: $skill" "$PLUGIN_DIR/skills/$skill/SKILL.md"
done

group "File Existence — Other"

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
import json
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
print(len(d['hooks']))
" 2>/dev/null || echo "0")

assert_count "agents = 15" 15 "$actual_agents"
assert_count "commands = 10" 10 "$actual_commands"
assert_count "skills = 8" 8 "$actual_skills"
assert_count "hooks = 5" 5 "$actual_hooks"

total=$((actual_agents + actual_commands + actual_skills + actual_hooks))
assert_count "total components = 38" 38 "$total"
