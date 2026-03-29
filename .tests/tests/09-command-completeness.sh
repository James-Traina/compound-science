#!/usr/bin/env bash
# Test Group 9: Skill structure, completeness, and integration (24 tests)
# v0.6: commands/ removed; all tests now check skills
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/fixtures.sh"

group "Skill Categories"

# 1: Workflow skills exist
wf_count=0
for skill in "${WORKFLOW_SKILLS[@]}"; do
  if [ -d "$PLUGIN_DIR/skills/$skill" ]; then
    wf_count=$((wf_count + 1))
  fi
done
assert_count "workflow skills = 6" 6 "$wf_count"

# 2: Chain + wrapper + stub skills exist
migrated_count=0
for skill in "${CHAIN_SKILLS[@]}" "${WRAPPER_SKILLS[@]}"; do
  if [ -d "$PLUGIN_DIR/skills/$skill" ]; then
    migrated_count=$((migrated_count + 1))
  fi
done
assert_count "chain + wrapper skills = 4" 4 "$migrated_count"

# 3: Total skills
total_count=$(find "$PLUGIN_DIR/skills" -name "SKILL.md" | wc -l | tr -d ' ')
assert_count "total skills = 20" 20 "$total_count"

group "Stub/Wrapper Skill Depth"

# 4-5: Wrapper skills checked for appropriate size
for skill in "${WRAPPER_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -le 40 ]; then
      pass "skill $skill exists as thin wrapper ($lines lines)"
    else
      should_fix "skill $skill is a wrapper" "$lines lines — expected <=40 for a wrapper"
    fi
  else
    must_fix "skill $skill exists" "file not found"
  fi
done

group "Skill Structure"

# 9: Workflow skills have Input handling (stubs/wrappers/chains excluded)
all_input=true
for skill in "${WORKFLOW_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  if [ -f "$file" ] && ! grep -qi 'Input Document\|input\|If no input\|ARGUMENTS\|arguments\|Usage\|context' "$file"; then
    all_input=false
    must_fix "skill $skill has input handling" "missing input section"
  fi
done
if $all_input; then pass "all workflow skills handle input (stubs/wrappers/chains excluded)"; fi

# 10: Workflow skills have multiple phases (stubs/wrappers/chains excluded)
all_phases=true
for skill in "${WORKFLOW_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  phase_count=$(grep -cE '### Phase|## Phase' "$file" 2>/dev/null) || phase_count=0
  if [ "$phase_count" -lt 3 ]; then
    all_phases=false
    must_fix "skill $skill has >=3 phases" "found $phase_count"
  fi
done
if $all_phases; then pass "all workflow skills have >=3 phases (stubs/wrappers/chains excluded)"; fi

# 11: Chain skills are minimal (delegate only)
for chain in "${CHAIN_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$chain/SKILL.md"
  lines=$(wc -l < "$file" | tr -d ' ')
  if [ "$lines" -lt 50 ]; then
    pass "chain $chain is minimal ($lines lines)"
  else
    should_fix "chain $chain is minimal" "$lines lines seems too long for a delegator"
  fi
done

group "Skill Agent References"

# 13: /estimate wrapper references a skill or /workflows:work
if grep -qE 'empirical-playbook|/workflows:work|workflows-work' "$PLUGIN_DIR/skills/estimate/SKILL.md" 2>/dev/null; then
  pass "/estimate wrapper references empirical-playbook or /workflows:work"
else
  must_fix "/estimate wrapper references skill/workflow" "missing"
fi

# 14: /replicate references reproducibility-auditor
if grep -qE 'reproducibility-auditor' "$PLUGIN_DIR/skills/replicate/SKILL.md" 2>/dev/null; then
  pass "/replicate references workflow agents"
else
  must_fix "/replicate references workflow agents" "should reference reproducibility-auditor"
fi

group "Skill Naming"

# 19: All skill directory names use valid kebab-case or single word
all_valid=true
for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  if ! echo "$name" | grep -qE '^[a-z]+(-[a-z]+)*$'; then
    all_valid=false
    must_fix "skill $name uses valid naming" "invalid name format"
  fi
done
if $all_valid; then pass "all skill directory names use valid naming"; fi

# 20: Workflow skills reference other skills or agents
workflow_refs=true
for skill in "${WORKFLOW_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  if [ -f "$file" ]; then
    if ! grep -qE '/workflows:|workflows-|`[a-z]+-[a-z-]+`|Task tool|Agent tool' "$file"; then
      workflow_refs=false
      should_fix "workflow skill $skill references components" "no references found"
    fi
  fi
done
if $workflow_refs; then pass "all workflow skills reference other components"; fi
