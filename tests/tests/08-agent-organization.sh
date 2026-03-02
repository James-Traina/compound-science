#!/bin/bash
# Test Group 8: Agent directory organization and consistency (10 tests)
source "$(dirname "$0")/../lib/assert.sh"

group "Agent Directory Structure"

# 1-3: Correct directory names
agent_dirs=$(find "$PLUGIN_DIR/agents" -mindepth 1 -maxdepth 1 -type d | sort)
echo "$agent_dirs" | grep -q 'review$' && pass "review/ directory exists" || must_fix "review/ directory exists" "missing"
echo "$agent_dirs" | grep -q 'research$' && pass "research/ directory exists" || must_fix "research/ directory exists" "missing"
echo "$agent_dirs" | grep -q 'workflow$' && pass "workflow/ directory exists" || must_fix "workflow/ directory exists" "missing"

# 4: No methods/ directory (was removed in reorg)
if [ -d "$PLUGIN_DIR/agents/methods" ]; then
  must_fix "no agents/methods/ directory" "should have been removed in reorg"
else
  pass "no agents/methods/ directory"
fi

group "Agent Uniqueness"

# 5: No duplicate agent names across directories
all_names=$(find "$PLUGIN_DIR/agents" -name "*.md" -exec basename {} .md \; | sort)
unique_names=$(echo "$all_names" | sort -u)
total=$(echo "$all_names" | wc -l | tr -d ' ')
unique=$(echo "$unique_names" | wc -l | tr -d ' ')
assert_count "all agent names unique ($total)" "$total" "$unique"

group "Agent Content Quality"

# 6: All agents have at least 2 examples
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

# 7: Review agents have numbered methodology sections
review_depth=true
for file in "$PLUGIN_DIR"/agents/review/*.md; do
  name=$(basename "$file" .md)
  section_count=$(grep -cE '^#{2,3} [0-9]+\.' "$file" 2>/dev/null) || section_count=0
  if [ "$section_count" -lt 2 ]; then
    review_depth=false
    should_fix "review agent $name has numbered sections" "found $section_count"
  fi
done
if $review_depth; then pass "all review agents have numbered methodology sections"; fi

group "Agent Description Quality"

# 8: Workflow agents include coordination/process keywords
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

# 9: Research agents include investigation/search keywords
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

# 10: All agents have a Core Principles/Philosophy section
all_principles=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! grep -qiE 'Core Principle|Philosophy|Core|Scope' "$file"; then
    all_principles=false
    should_fix "agent $name has principles section" "missing core principles"
  fi
done
if $all_principles; then pass "all agents have principles/scope section"; fi
