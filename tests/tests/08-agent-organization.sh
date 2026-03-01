#!/bin/bash
# Test Group 8: Agent directory organization and consistency (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

group "Agent Directory Structure"

# 1: Only 3 agent subdirectories exist
agent_dirs=$(find "$PLUGIN_DIR/agents" -mindepth 1 -maxdepth 1 -type d | sort)
dir_count=$(echo "$agent_dirs" | wc -l | tr -d ' ')
assert_count "exactly 3 agent subdirectories" 3 "$dir_count"

# 2-4: Correct directory names
echo "$agent_dirs" | grep -q 'review$' && pass "review/ directory exists" || must_fix "review/ directory exists" "missing"
echo "$agent_dirs" | grep -q 'research$' && pass "research/ directory exists" || must_fix "research/ directory exists" "missing"
echo "$agent_dirs" | grep -q 'workflow$' && pass "workflow/ directory exists" || must_fix "workflow/ directory exists" "missing"

# 5: No methods/ directory (was removed in reorg)
if [ -d "$PLUGIN_DIR/agents/methods" ]; then
  must_fix "no agents/methods/ directory" "should have been removed in reorg"
else
  pass "no agents/methods/ directory"
fi

group "Agent Category Counts"

# 6-8
review_count=$(find "$PLUGIN_DIR/agents/review" -name "*.md" | wc -l | tr -d ' ')
research_count=$(find "$PLUGIN_DIR/agents/research" -name "*.md" | wc -l | tr -d ' ')
workflow_count=$(find "$PLUGIN_DIR/agents/workflow" -name "*.md" | wc -l | tr -d ' ')

assert_count "review/ has 10 agents" 10 "$review_count"
assert_count "research/ has 5 agents" 5 "$research_count"
assert_count "workflow/ has 5 agents" 5 "$workflow_count"

group "Agent Uniqueness"

# 9: No duplicate agent names across directories
all_names=$(find "$PLUGIN_DIR/agents" -name "*.md" -exec basename {} .md \; | sort)
unique_names=$(echo "$all_names" | sort -u)
total=$(echo "$all_names" | wc -l | tr -d ' ')
unique=$(echo "$unique_names" | wc -l | tr -d ' ')
assert_count "all agent names unique ($total)" "$total" "$unique"

# 10: No orphan .md files in agents/ root
orphans=$(find "$PLUGIN_DIR/agents" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
assert_count "no orphan agent files in root" 0 "$orphans"

group "Agent Model Consistency"

# 11: All agents specify model: sonnet
all_sonnet=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q '^model: sonnet' "$file"; then
    all_sonnet=false
    must_fix "agent $name has model: sonnet" "missing or wrong model"
  fi
done
if $all_sonnet; then pass "all 20 agents have model: sonnet"; fi

# 12: All agents have tools field
all_tools=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q '^tools:' "$file"; then
    all_tools=false
    must_fix "agent $name has tools" "missing tools field"
  fi
done
if $all_tools; then pass "all agents have tools field"; fi

group "Agent Content Quality"

# 13: All agents have examples section
all_examples=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q '<examples>' "$file"; then
    all_examples=false
    must_fix "agent $name has examples" "missing <examples> block"
  fi
done
if $all_examples; then pass "all agents have examples section"; fi

# 14: All agents have at least 2 examples
all_multi=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  example_count=$(grep -c '<example>' "$file" 2>/dev/null) || example_count=0
  if [ "$example_count" -lt 2 ]; then
    all_multi=false
    must_fix "agent $name has >=2 examples" "found $example_count"
  fi
done
if $all_multi; then pass "all agents have >=2 examples"; fi

# 15: Review agents mention specific methodological checks
review_depth=true
for file in "$PLUGIN_DIR"/agents/review/*.md; do
  name=$(basename "$file" .md)
  # Check for numbered sections (## 1. or ### 1.)
  section_count=$(grep -cE '^#{2,3} [0-9]+\.' "$file" 2>/dev/null) || section_count=0
  if [ "$section_count" -lt 2 ]; then
    review_depth=false
    should_fix "review agent $name has numbered sections" "found $section_count"
  fi
done
if $review_depth; then pass "all review agents have numbered methodology sections"; fi

group "Agent Naming Conventions"

# 16: All agent filenames use kebab-case
all_kebab=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! echo "$name" | grep -qE '^[a-z]+(-[a-z]+)*$'; then
    all_kebab=false
    must_fix "agent $name uses kebab-case" "invalid naming"
  fi
done
if $all_kebab; then pass "all agent filenames use kebab-case"; fi

# 17: Workflow agents include coordination/process keywords
workflow_relevant=true
for file in "$PLUGIN_DIR"/agents/workflow/*.md; do
  name=$(basename "$file" .md)
  desc=$(grep '^description:' "$file" | head -1)
  if ! echo "$desc" | grep -qiE 'pipeline|reproducib|workflow|coordinat|progress|track|spec|flow'; then
    workflow_relevant=false
    should_fix "workflow agent $name description mentions process" "description: $desc"
  fi
done
if $workflow_relevant; then pass "all workflow agents have process-related descriptions"; fi

# 18: Research agents include investigation/search keywords
research_relevant=true
for file in "$PLUGIN_DIR"/agents/research/*.md; do
  name=$(basename "$file" .md)
  desc=$(grep '^description:' "$file" | head -1)
  if ! echo "$desc" | grep -qiE 'search|investigat|scout|research|quality|solution|find|deep dive'; then
    research_relevant=false
    should_fix "research agent $name description mentions research" "description: $desc"
  fi
done
if $research_relevant; then pass "all research agents have investigation-related descriptions"; fi

# 19: All agents have a Core Principles/Philosophy section
all_principles=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! grep -qiE 'Core Principle|Philosophy|Core|Scope' "$file"; then
    all_principles=false
    should_fix "agent $name has principles section" "missing core principles"
  fi
done
if $all_principles; then pass "all agents have principles/scope section"; fi

# 20: Total agent count is correct
total_agents=$(find "$PLUGIN_DIR/agents" -name "*.md" | wc -l | tr -d ' ')
assert_count "total agents = 20" 20 "$total_agents"
